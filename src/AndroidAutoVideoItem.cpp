#include "AndroidAutoVideoItem.hpp"
#include <QMouseEvent>
#include <QTouchEvent>
#include <QDateTime>
#include <cmath>
#include <QDebug>

AndroidAutoVideoItem::AndroidAutoVideoItem(QQuickItem *parent)
    : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
}

AndroidAutoVideoItem::~AndroidAutoVideoItem()
{
    if (m_controller) {
        disconnect(m_controller, nullptr, this, nullptr);
        m_controller = nullptr;
    }
}

void AndroidAutoVideoItem::setController(QObject *ctrl)
{
    if (m_controller == ctrl) return;
    if (m_controller) {
        disconnect(m_controller, nullptr, this, nullptr);
        disconnect(this, nullptr, m_controller, nullptr);
    }
    m_controller = ctrl;
    if (m_controller) {
        // Direct C++ signal-to-slot connection bypassing QML JavaScript engine
        connect(m_controller, SIGNAL(androidAutoFrameReady(QImage)),
                this, SLOT(onNewFrame(QImage)), Qt::QueuedConnection);
        connect(m_controller, SIGNAL(androidAutoConnectedChanged()),
                this, SLOT(onConnectedChanged()));
    }
    emit controllerChanged();
}

void AndroidAutoVideoItem::onConnectedChanged()
{
    if (m_controller) {
        bool connected = m_controller->property("androidAutoConnected").toBool();
        if (!connected) {
            clearVideo();
        }
    }
}

void AndroidAutoVideoItem::onNewFrame(const QImage &image)
{
    {
        QMutexLocker locker(&m_imageMutex);
        m_image = image;
        m_imageDirty = true;
        if (m_image.width() != m_videoWidth || m_image.height() != m_videoHeight) {
            m_videoWidth = m_image.width();
            m_videoHeight = m_image.height();
            emit videoSizeChanged();
        }
    }

    if (!m_hasVideo) {
        m_hasVideo = true;
        emit hasVideoChanged(true);
    }

    update();
}

void AndroidAutoVideoItem::clearVideo()
{
    {
        QMutexLocker locker(&m_imageMutex);
        m_image = QImage();
        m_imageDirty = true;
    }
    if (m_hasVideo) {
        m_hasVideo = false;
        emit hasVideoChanged(false);
    }
    update();
}

QSGNode *AndroidAutoVideoItem::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *)
{
    QSGSimpleTextureNode *textureNode = static_cast<QSGSimpleTextureNode *>(oldNode);

    QImage imgToPaint;
    bool hasData = false;
    {
        QMutexLocker locker(&m_imageMutex);
        if (!m_image.isNull()) {
            imgToPaint = m_image;
            hasData = true;
        }
    }

    if (!hasData) {
        if (textureNode && textureNode->texture()) {
            delete textureNode->texture();
        }
        delete oldNode;
        return nullptr;
    }

    if (!textureNode) {
        textureNode = new QSGSimpleTextureNode();
        textureNode->setOwnsTexture(false);
    }

    if (m_imageDirty && window()) {
        QSGTexture *oldTex = textureNode->texture();
        QSGTexture *texture = window()->createTextureFromImage(imgToPaint);
        textureNode->setTexture(texture);
        textureNode->setOwnsTexture(false);
        if (oldTex) {
            delete oldTex;
        }
        m_imageDirty = false;
    }

    textureNode->setRect(boundingRect());
    textureNode->setFiltering(QSGTexture::Linear);
    return textureNode;
}


