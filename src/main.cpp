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
#include <QQuickWindow>
#include <QTimer>
#include <QFile>
#include <cstdio>
#include <cstdlib>
#include "SystemController.hpp"
#include "AndroidAutoVideoItem.hpp"

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

#ifndef _WIN32
#include <execinfo.h>
#include <signal.h>
#include <unistd.h>

static void crashHandler(int sig) {
    void *array[30];
    size_t size = backtrace(array, 30);
    fprintf(stderr, "\n\n*** CRASH SIGNAL %d CAUGHT ***\n", sig);
    backtrace_symbols_fd(array, size, STDERR_FILENO);
    fflush(stderr);
    _exit(1);
}
#endif

int main(int argc, char *argv[])
{
#ifndef _WIN32
    signal(SIGSEGV, crashHandler);
    signal(SIGABRT, crashHandler);
#endif
    fprintf(stdout, "[MAIN] Step 1: Starting Apex IVI\n");
    fflush(stdout);

    qInstallMessageHandler(apexMessageHandler);

    // High DPI scaling is enabled by default in Qt 6
    QGuiApplication app(argc, argv);
    fprintf(stdout, "[MAIN] Step 2: QGuiApplication created\n");
    fflush(stdout);

    app.setApplicationName("Apex IVI");
    app.setOrganizationName("Apex");

    // Load bundled typography fonts
    QFontDatabase::addApplicationFont(":/assets/fonts/Roboto-Regular.ttf");
    QFontDatabase::addApplicationFont(":/assets/fonts/Roboto-Medium.ttf");
    QFontDatabase::addApplicationFont(":/assets/fonts/Roboto-Bold.ttf");

    QFont defaultFont("Roboto", 14);
    defaultFont.setStyleHint(QFont::SansSerif);
    app.setFont(defaultFont);
    fprintf(stdout, "[MAIN] Step 3: Fonts loaded\n");
    fflush(stdout);

    QIcon appIcon(":/assets/branding/apex_logo.png");
    if (appIcon.isNull()) {
        appIcon = QIcon(":/assets/apex_logo.png");
    }
    qDebug() << "[Apex IVI] Application icon loaded:" << !appIcon.isNull();
    app.setWindowIcon(appIcon);

    QQuickStyle::setStyle("Basic");

    fprintf(stdout, "[MAIN] Step 4: Creating SystemController\n");
    fflush(stdout);
    SystemController systemController;
    fprintf(stdout, "[MAIN] Step 5: SystemController created successfully\n");
    fflush(stdout);

    GlobalActivityFilter activityFilter(&systemController, &app);
    app.installEventFilter(&activityFilter);

    qmlRegisterType<AndroidAutoVideoItem>("com.apex.ivi", 1, 0, "AndroidAutoVideoItem");

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("systemController", &systemController);
    fprintf(stdout, "[MAIN] Step 6: Loading QML\n");
    fflush(stdout);

    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url, &systemController](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);

            QQuickWindow *win = qobject_cast<QQuickWindow*>(obj);
            if (win) {
                QTimer *snapTimer = new QTimer(win);
                snapTimer->setInterval(500);
                QObject::connect(snapTimer, &QTimer::timeout, win, [win, &systemController]() {
                    if (QFile::exists("/tmp/navigate_to")) {
                        QFile f("/tmp/navigate_to");
                        if (f.open(QIODevice::ReadOnly)) {
                            QString target = QString::fromUtf8(f.readAll()).trimmed();
                            f.close();
                            QFile::remove("/tmp/navigate_to");
                            systemController.openAndroidAuto(target);
                        }
                    }
                    if (QFile::exists("/tmp/aa_cmd")) {
                        QFile f("/tmp/aa_cmd");
                        if (f.open(QIODevice::ReadOnly)) {
                            QString cmd = QString::fromUtf8(f.readAll()).trimmed();
                            f.close();
                            QFile::remove("/tmp/aa_cmd");
                            QStringList parts = cmd.split(" ");
                            if (parts[0] == "key" && parts.size() > 1) {
                                qInfo() << "[Apex IVI IPC] Sending AA Key:" << parts[1].toInt();
                                systemController.sendAndroidAutoKey(parts[1].toInt());
                            } else if (parts[0] == "tap" && parts.size() > 2) {
                                int tx = parts[1].toInt();
                                int ty = parts[2].toInt();
                                qInfo() << "[Apex IVI IPC] Sending AA Tap at (" << tx << "," << ty << ")";
                                systemController.sendAndroidAutoTouch(0, tx, ty);
                                QTimer::singleShot(60, &systemController, [&systemController, tx, ty]() {
                                    systemController.sendAndroidAutoTouch(1, tx, ty);
                                });
                            }
                        }
                    }
                    if (QFile::exists("/tmp/take_screenshot")) {
                        QFile::remove("/tmp/take_screenshot");
                        QImage img = win->grabWindow();
                        img.save("/tmp/apex_screenshot.png");
                        qInfo() << "[Apex IVI] Screenshot captured to /tmp/apex_screenshot.png ("
                                << img.width() << "x" << img.height() << ")";
                    }
                });
                snapTimer->start();
            }
        },
        Qt::QueuedConnection
    );

    engine.load(url);

    return app.exec();
}
