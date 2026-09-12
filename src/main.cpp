/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: main.cpp
 * ============================================================================
 */

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QFontDatabase>
#include <QFont>
#include <QIcon>
#include <QEvent>
#include <QKeyEvent>
#include <cstdio>
#include <cstdlib>
#include "SystemController.hpp"

static void apexMessageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    // Filter out internal Qt font database OpenType script fallback warnings and alias notices
    if (msg.contains(QLatin1String("OpenType support missing")) ||
        msg.contains(QLatin1String("Populating font family aliases")) ||
        msg.contains(QLatin1String("Replace uses of missing font family")) ||
        msg.contains(QLatin1String("Mipmap settings changed without having image data")) ||
        (context.category && strcmp(context.category, "qt.text.font.db") == 0)) {
        return;
    }

    QByteArray localMsg = msg.toLocal8Bit();
    switch (type) {
    case QtDebugMsg:
        fprintf(stdout, "%s\n", localMsg.constData());
        break;
    case QtInfoMsg:
        fprintf(stdout, "[INFO] %s\n", localMsg.constData());
        break;
    case QtWarningMsg:
        fprintf(stderr, "[WARN] %s\n", localMsg.constData());
        break;
    case QtCriticalMsg:
        fprintf(stderr, "[CRITICAL] %s\n", localMsg.constData());
        break;
    case QtFatalMsg:
        fprintf(stderr, "[FATAL] %s\n", localMsg.constData());
        abort();
    }
    fflush(stdout);
    fflush(stderr);
}

class GlobalActivityFilter : public QObject
{
public:
    explicit GlobalActivityFilter(SystemController *controller, QObject *parent = nullptr)
        : QObject(parent), m_controller(controller) {}

protected:
    bool eventFilter(QObject *watched, QEvent *event) override
    {
        if (!m_controller) return false;

        switch (event->type()) {
        case QEvent::MouseButtonPress:
        case QEvent::TouchBegin:
            m_controller->reportActivity();
            break;

        case QEvent::KeyPress: {
            m_controller->reportActivity();
            QKeyEvent *ke = static_cast<QKeyEvent *>(event);
            if (ke->key() == Qt::Key_Up) {
                m_controller->increaseVolume();
                return true;
            } else if (ke->key() == Qt::Key_Down) {
                m_controller->decreaseVolume();
                return true;
            }
            break;
        }

        case QEvent::MouseMove:
        case QEvent::MouseButtonRelease:
        case QEvent::TouchUpdate:
        case QEvent::TouchEnd:
        case QEvent::Wheel:
        case QEvent::KeyRelease:
            // If screen is awake, restart the 20s countdown
            if (!m_controller->displayOff()) {
                m_controller->reportActivity();
            }
            break;

        default:
            break;
        }

        return false;
    }

private:
    SystemController *m_controller{nullptr};
};

int main(int argc, char *argv[])
{
    qInstallMessageHandler(apexMessageHandler);

    // High DPI scaling is enabled by default in Qt 6
    QGuiApplication app(argc, argv);
    app.setApplicationName("Apex IVI");
    app.setOrganizationName("Apex");

    // Load bundled typography fonts
    QFontDatabase::addApplicationFont(":/assets/fonts/Roboto-Regular.ttf");
    QFontDatabase::addApplicationFont(":/assets/fonts/Roboto-Medium.ttf");
    QFontDatabase::addApplicationFont(":/assets/fonts/Roboto-Bold.ttf");

    QFont defaultFont("Roboto", 14);
    defaultFont.setStyleHint(QFont::SansSerif);
    app.setFont(defaultFont);

    QIcon appIcon(":/assets/branding/apex_logo.png");
    if (appIcon.isNull()) {
        appIcon = QIcon(":/assets/apex_logo.png");
    }
    qDebug() << "[Apex IVI] Application icon loaded:" << !appIcon.isNull();
    app.setWindowIcon(appIcon);

    QQuickStyle::setStyle("Basic");

    SystemController systemController;
    GlobalActivityFilter activityFilter(&systemController, &app);
    app.installEventFilter(&activityFilter);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("systemController", &systemController);

    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection
    );

    engine.load(url);

    return app.exec();
}
