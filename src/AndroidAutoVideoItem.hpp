#pragma once

#include <QQuickItem>
#include <QSGSimpleTextureNode>
#include <QQuickWindow>
#include <QImage>
#include <QMutex>

class AndroidAutoVideoItem : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(bool hasVideo READ hasVideo NOTIFY hasVideoChanged)
    Q_PROPERTY(int videoWidth READ videoWidth NOTIFY videoSizeChanged)
    Q_PROPERTY(int videoHeight READ videoHeight NOTIFY videoSizeChanged)
    Q_PROPERTY(QObject* controller READ controller WRITE setController NOTIFY controllerChanged)

public:
    explicit AndroidAutoVideoItem(QQuickItem *parent = nullptr);
    ~AndroidAutoVideoItem() override;

    bool hasVideo() const { return m_hasVideo; }
    int videoWidth() const { return m_videoWidth; }
    int videoHeight() const { return m_videoHeight; }

    QObject* controller() const { return m_controller; }
    void setController(QObject *ctrl);

public slots:
    void onNewFrame(const QImage &image);
    void clearVideo();
    void onConnectedChanged();

signals:
    void hasVideoChanged(bool hasVideo);
    void videoSizeChanged();
    void controllerChanged();

protected:
    QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) override;

private:
    QObject *m_controller = nullptr;
    QImage m_image;
    QMutex m_imageMutex;
    bool m_hasVideo = false;
    bool m_imageDirty = false;
    int m_videoWidth = 1280;
    int m_videoHeight = 720;
};
