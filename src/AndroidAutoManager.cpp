/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: AndroidAutoManager.cpp
 * ============================================================================
 */

#include "AndroidAutoManager.hpp"
#include <QDebug>

#define GOOGLE_VID           0x18d1
#define AOA_ACCESSORY_PID    0x2d00
#define AOA_ACCESSORY_ADB    0x2d01

#define AOA_GET_PROTOCOL     51
#define AOA_SEND_STRING      52
#define AOA_START_ACCESSORY  53

AndroidAutoManager::AndroidAutoManager(QObject *parent)
    : QObject(parent)
{
    m_workerThread = new QThread(this);
    m_worker = new AndroidAutoWorker();
    m_worker->moveToThread(m_workerThread);

    connect(m_workerThread, &QThread::started,
            m_worker, &AndroidAutoWorker::startMonitoring);
    connect(m_workerThread, &QThread::finished,
            m_worker, &QObject::deleteLater);

    connect(m_worker, &AndroidAutoWorker::statusUpdated,
            this, &AndroidAutoManager::onWorkerStatusUpdated);
    connect(m_worker, &AndroidAutoWorker::frameReady,
            this, &AndroidAutoManager::onWorkerFrameReady);
    connect(m_worker, &AndroidAutoWorker::exitRequested,
            this, &AndroidAutoManager::exitRequested);
    connect(m_worker, &AndroidAutoWorker::audioFocusGained,
            this, &AndroidAutoManager::audioFocusGained);

    m_workerThread->start();
}

AndroidAutoManager::~AndroidAutoManager()
{
    stop();
}

bool AndroidAutoManager::isPhoneAttached() const
{
    return m_phoneAttached;
}

bool AndroidAutoManager::isAccessoryConnected() const
{
    return m_accessoryConnected;
}

QString AndroidAutoManager::deviceName() const
{
    return m_deviceName;
}

QString AndroidAutoManager::statusMessage() const
{
    return m_statusMessage;
}

int AndroidAutoManager::aoaVersion() const
{
    return m_aoaVersion;
}

void AndroidAutoManager::start()
{
    if (m_workerThread && !m_workerThread->isRunning()) {
        m_workerThread->start();
    }
}

void AndroidAutoManager::stop()
{
    if (m_workerThread && m_workerThread->isRunning()) {
        QMetaObject::invokeMethod(m_worker, "stopMonitoring", Qt::BlockingQueuedConnection);
        m_workerThread->quit();
        m_workerThread->wait(2000);
    }
}

void AndroidAutoManager::triggerHandshake()
{
    if (m_worker) {
        QMetaObject::invokeMethod(m_worker, "manualHandshake", Qt::QueuedConnection);
    }
}

void AndroidAutoManager::sendTouch(int action, int x, int y)
{
    if (!m_worker) return;

    if (action == 0) { // PRESS
        m_hasPendingDrag.store(false);
        m_dragInFlight.store(false);
        QMetaObject::invokeMethod(m_worker, "sendTouch", Qt::QueuedConnection,
                                  Q_ARG(int, 0), Q_ARG(int, x), Q_ARG(int, y));
        return;
    }

    if (action == 1) { // RELEASE
        if (m_hasPendingDrag.exchange(false)) {
            QMetaObject::invokeMethod(m_worker, "sendTouch", Qt::QueuedConnection,
                                      Q_ARG(int, 2), Q_ARG(int, m_pendingDragX.load()), Q_ARG(int, m_pendingDragY.load()));
        }
        m_dragInFlight.store(false);
        QMetaObject::invokeMethod(m_worker, "sendTouch", Qt::QueuedConnection,
                                  Q_ARG(int, 1), Q_ARG(int, x), Q_ARG(int, y));
        return;
    }

    if (action == 2) { // DRAG: retain only newest x/y while a prior drag is waiting
        m_pendingDragX.store(x);
        m_pendingDragY.store(y);
        m_hasPendingDrag.store(true);

        // If a drag task is already in flight, do not queue another;
        // the worker task will pick up the newest x/y when it executes.
        if (m_dragInFlight.exchange(true)) {
            return;
        }

        QMetaObject::invokeMethod(m_worker, [this]() {
            if (m_worker && m_hasPendingDrag.exchange(false)) {
                m_worker->sendTouch(2, m_pendingDragX.load(), m_pendingDragY.load());
            }
            m_dragInFlight.store(false);
        }, Qt::QueuedConnection);
        return;
    }
}


void AndroidAutoManager::sendKey(uint32_t keyCode)
{
    if (m_worker) {
        QMetaObject::invokeMethod(m_worker, "sendKey", Qt::QueuedConnection,
                                  Q_ARG(uint32_t, keyCode));
    }
}

void AndroidAutoManager::requestVideoFocus(bool focused)
{
    if (m_worker) {
        QMetaObject::invokeMethod(m_worker, "requestVideoFocus", Qt::QueuedConnection,
                                  Q_ARG(bool, focused));
    }
}

void AndroidAutoManager::setBluetoothAddress(const QString &addr)
{
    m_bluetoothAddress = addr;
    if (m_worker) {
        QMetaObject::invokeMethod(m_worker, "setBluetoothAddress", Qt::QueuedConnection,
                                  Q_ARG(QString, addr));
    }
}

void AndroidAutoManager::onWorkerFrameReady(const QImage &frame)
{
    emit frameReady(frame);
}

void AndroidAutoManager::onWorkerStatusUpdated(bool attached, bool accessory, const QString &name, const QString &status, int aoaVer)
{
    bool changed = false;

    if (m_phoneAttached != attached) {
        m_phoneAttached = attached;
        emit phoneAttachedChanged(m_phoneAttached);
        changed = true;
    }

    if (m_accessoryConnected != accessory) {
        m_accessoryConnected = accessory;
        emit accessoryConnectedChanged(m_accessoryConnected);
        if (m_accessoryConnected) {
            emit projectionReady();
        }
        changed = true;
    }

    if (m_deviceName != name) {
        m_deviceName = name;
        emit deviceNameChanged(m_deviceName);
        changed = true;
    }

    if (m_statusMessage != status) {
        m_statusMessage = status;
        emit statusMessageChanged(m_statusMessage);
        changed = true;
    }

    if (m_aoaVersion != aoaVer) {
        m_aoaVersion = aoaVer;
        emit aoaVersionChanged(m_aoaVersion);
        changed = true;
    }

    if (changed) {
        qDebug() << "[AndroidAutoManager] State update -> Attached:" << m_phoneAttached
                 << "Accessory:" << m_accessoryConnected
                 << "Device:" << m_deviceName
                 << "Status:" << m_statusMessage;
    }
}

// ============================================================================
// AndroidAutoWorker Implementation
// ============================================================================

AndroidAutoWorker::AndroidAutoWorker(QObject *parent)
    : QObject(parent)
{
}

AndroidAutoWorker::~AndroidAutoWorker()
{
    stopMonitoring();
}

void AndroidAutoWorker::startMonitoring()
{
    if (m_running) return;

#ifdef HAVE_LIBUSB
    int ret = libusb_init(&m_usbCtx);
    if (ret < 0) {
        qWarning() << "[AndroidAutoWorker] Failed to initialize libusb:" << ret;
        emit statusUpdated(false, false, "", "libusb initialization failed", 0);
        return;
    }
    qDebug() << "[AndroidAutoWorker] libusb initialized successfully";
#else
    qDebug() << "[AndroidAutoWorker] Compiled without libusb support (Mock mode)";
#endif

    m_running = true;
    m_scanTimer = new QTimer(this);
    connect(m_scanTimer, &QTimer::timeout, this, &AndroidAutoWorker::scanDevices);
    m_scanTimer->start(1200);

    // Initial immediate scan
    scanDevices();
}

void AndroidAutoWorker::stopMonitoring()
{
    m_running = false;
    if (m_restartCooldownTimer) {
        m_restartCooldownTimer->stop();
        delete m_restartCooldownTimer;
        m_restartCooldownTimer = nullptr;
    }
    if (m_scanTimer) {
        m_scanTimer->stop();
        delete m_scanTimer;
        m_scanTimer = nullptr;
    }

    if (m_session) {
        m_session->stopSession();
        m_session->wait(1000);
        delete m_session;
        m_session = nullptr;
    }

#ifdef HAVE_LIBUSB
    if (m_usbCtx) {
        libusb_exit(m_usbCtx);
        m_usbCtx = nullptr;
    }
#endif
}

void AndroidAutoWorker::manualHandshake()
{
    scanDevices();
}

void AndroidAutoWorker::sendTouch(int action, int x, int y)
{
    if (m_session && m_session->isRunningSession()) {
        m_session->sendTouch(action, x, y);
    } else {
        qWarning() << "[AndroidAutoWorker] sendTouch ignored: session not running!";
    }
}

void AndroidAutoWorker::sendKey(uint32_t keyCode)
{
    if (m_session && m_session->isRunningSession()) {
        m_session->sendKeyEvent(keyCode);
    }
}

void AndroidAutoWorker::requestVideoFocus(bool focused)
{
    if (m_session && m_session->isRunningSession()) {
        m_session->requestVideoFocus(focused);
    }
}

void AndroidAutoWorker::setBluetoothAddress(const QString &addr)
{
    m_bluetoothAddress = addr;
    qDebug() << "[AndroidAutoWorker] Dynamic Bluetooth adapter address set:" << m_bluetoothAddress;
}

#ifdef HAVE_LIBUSB
static int sendAoaStringHelper(libusb_device_handle *handle, int index, const char *str)
{
    int len = strlen(str) + 1;
    return libusb_control_transfer(
        handle,
        LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE | LIBUSB_ENDPOINT_OUT,
        AOA_SEND_STRING,
        0,
        index,
        (unsigned char *)str,
        len,
        1000
    );
}
#endif

bool AndroidAutoWorker::performAOAHandshake(void *devicePtr, uint16_t vid, uint16_t pid, QString &outName, int &outAoaVer)
{
#ifdef HAVE_LIBUSB
    libusb_device *dev = static_cast<libusb_device *>(devicePtr);
    libusb_device_handle *handle = nullptr;

    int err = libusb_open(dev, &handle);
    if (err != 0 || !handle) {
        return false;
    }

    libusb_set_auto_detach_kernel_driver(handle, 1);

    // Query AOA protocol version
    unsigned char proto_buf[2] = {0};
    int r = libusb_control_transfer(
        handle,
        LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE | LIBUSB_ENDPOINT_IN,
        AOA_GET_PROTOCOL,
        0,
        0,
        proto_buf,
        2,
        1000
    );

    if (r != 2) {
        libusb_close(handle);
        return false;
    }

    outAoaVer = proto_buf[0] | (proto_buf[1] << 8);
    outName = QString("Android Device (0x%1:0x%2)")
                  .arg(QString::number(vid, 16).rightJustified(4, '0'))
                  .arg(QString::number(pid, 16).rightJustified(4, '0'));

    qDebug() << "[AndroidAutoWorker] Phone supports AOA version:" << outAoaVer
             << "Sending Android Auto identification...";

    // Send identification strings (standard Android Auto headunit identification)
    sendAoaStringHelper(handle, 0, "Android");
    sendAoaStringHelper(handle, 1, "Android Auto");
    sendAoaStringHelper(handle, 2, "Android Auto");
    sendAoaStringHelper(handle, 3, "2.0.1");
    sendAoaStringHelper(handle, 4, "https://f1xstudio.com");
    sendAoaStringHelper(handle, 5, "HU-AAAAAA001");

    // Start Accessory mode
    r = libusb_control_transfer(
        handle,
        LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_RECIPIENT_DEVICE | LIBUSB_ENDPOINT_OUT,
        AOA_START_ACCESSORY,
        0,
        0,
        nullptr,
        0,
        1000
    );

    qDebug() << "[AndroidAutoWorker] START_ACCESSORY command dispatched, return:" << r;

    libusb_close(handle);
    return true;
#else
    Q_UNUSED(devicePtr);
    Q_UNUSED(vid);
    Q_UNUSED(pid);
    Q_UNUSED(outName);
    Q_UNUSED(outAoaVer);
    return false;
#endif
}

void AndroidAutoWorker::scanDevices()
{
    if (!m_running) return;

#ifdef HAVE_LIBUSB
    if (!m_usbCtx) return;

    libusb_device **list = nullptr;
    ssize_t count = libusb_get_device_list(m_usbCtx, &list);
    if (count < 0) {
        return;
    }

    bool attached = false;
    bool accessory = false;
    QString deviceName;
    QString statusText = "Ready. Connect phone via USB cable.";
    int aoaVer = 0;
    libusb_device *accessoryDev = nullptr;

    // Check for Google Accessory first (0x18d1:0x2d00 or 0x2d01)
    for (ssize_t i = 0; i < count; ++i) {
        libusb_device_descriptor desc;
        if (libusb_get_device_descriptor(list[i], &desc) < 0) continue;

        if (desc.idVendor == GOOGLE_VID &&
            (desc.idProduct == AOA_ACCESSORY_PID || desc.idProduct == AOA_ACCESSORY_ADB)) {
            attached = true;
            accessory = true;
            aoaVer = 2;
            accessoryDev = list[i];

            // Only probe string descriptor if session is NOT currently running to prevent USB endpoint resets
            if (!m_session || !m_session->isRunningSession()) {
                libusb_device_handle *handle = nullptr;
                if (libusb_open(list[i], &handle) == 0 && handle) {
                    unsigned char strDesc[256] = {0};
                    if (desc.iProduct > 0 && libusb_get_string_descriptor_ascii(handle, desc.iProduct, strDesc, sizeof(strDesc)) > 0) {
                        deviceName = QString::fromUtf8((char*)strDesc);
                    }
                    libusb_close(handle);
                }
            } else {
                deviceName = m_lastDeviceName.isEmpty() ? QStringLiteral("Android") : m_lastDeviceName;
            }
            if (deviceName.isEmpty()) {
                deviceName = "Android Auto Device";
            }

            statusText = QString("Android Auto Connected (%1)").arg(
                desc.idProduct == AOA_ACCESSORY_ADB ? "Accessory + ADB" : "Accessory Mode");
            break;
        }
    }

    // If accessory mode is detected, start or maintain the projection session
    if (accessory && accessoryDev) {
        if (!m_sessionInCooldown) {
            if (!m_session || !m_session->isRunningSession()) {
                if (m_session) {
                    // Fully block until the previous session's QThread exits
                    // and its cleanup thread has released the libusb interface.
                    m_session->stopSession();
                    if (!m_session->wait(5000)) {
                        qWarning() << "[AndroidAutoWorker] Old session thread did not exit in 5s, forcing delete";
                    }
                    delete m_session;
                    m_session = nullptr;
                    // Give libusb 500ms to re-attach the kernel driver after interface release
                    QThread::msleep(500);
                }
                m_session = new AndroidAutoSession(this);
                connect(m_session, &AndroidAutoSession::frameReady, this, &AndroidAutoWorker::frameReady);
                connect(m_session, &AndroidAutoSession::exitRequested, this, &AndroidAutoWorker::exitRequested);
                connect(m_session, &AndroidAutoSession::audioFocusGained, this, &AndroidAutoWorker::audioFocusGained);
                connect(m_session, &AndroidAutoSession::statusChanged, this, [this](const QString &st) {
                    emit statusUpdated(true, true, m_lastDeviceName, st, 2);
                });
                connect(m_session, &AndroidAutoSession::sessionStopped, this, [this]() {
                    qWarning() << "[AndroidAutoWorker] Session stopped -> cooldown 2s before auto-restart";
                    m_sessionInCooldown = true;

                    // One-shot 2s timer: clears cooldown so the next scan cycle can reconnect
                    if (!m_restartCooldownTimer) {
                        m_restartCooldownTimer = new QTimer(this);
                        m_restartCooldownTimer->setSingleShot(true);
                        connect(m_restartCooldownTimer, &QTimer::timeout, this, [this]() {
                            qInfo() << "[AndroidAutoWorker] Cooldown elapsed, ready to reconnect";
                            m_sessionInCooldown = false;
                        });
                    }
                    m_restartCooldownTimer->start(4000);
                });
                m_session->startSession(accessoryDev, m_usbCtx, m_bluetoothAddress);
                qInfo() << "[AndroidAutoWorker] Started AASDK AndroidAutoSession for accessory device with BT:" << m_bluetoothAddress;
            }
        }
    } else {
        if (m_session) {
            qInfo() << "[AndroidAutoWorker] Accessory disconnected, stopping session";
            try {
                m_session->stopSession();
                m_session->wait(2000);
                delete m_session;
            } catch (const std::exception &e) {
                qWarning() << "[AndroidAutoWorker] Exception during session cleanup:" << e.what();
            } catch (...) {
                qWarning() << "[AndroidAutoWorker] Unknown exception during session cleanup";
            }
            m_session = nullptr;
        }
        // Phone fully disconnected: cancel cooldown and allow fresh session on replug
        if (m_restartCooldownTimer) m_restartCooldownTimer->stop();
        m_sessionInCooldown = false;
    }

    // If not in accessory mode, search for Android phone to handshake
    if (!accessory) {
        for (ssize_t i = 0; i < count; ++i) {
            libusb_device_descriptor desc;
            if (libusb_get_device_descriptor(list[i], &desc) < 0) continue;

            // Known Android OEM VIDs
            bool isPotentialAndroid = false;
            switch (desc.idVendor) {
            case 0x18d1: // Google
            case 0x04e8: // Samsung
            case 0x2717: // Xiaomi
            case 0x22b8: // Motorola
            case 0x0bb4: // HTC
            case 0x12d1: // Huawei
            case 0x1004: // LG
            case 0x2a70: // OnePlus
            case 0x0fce: // Sony
            case 0x2e04: // Oppo
            case 0x2d95: // Vivo
            case 0x2970: // Realme
            case 0x1bbb: // Alcatel
            case 0x1782: // Spreadtrum
            case 0x0e8d: // MediaTek
                isPotentialAndroid = true;
                break;
            default:
                break;
            }

            if (isPotentialAndroid && desc.bDeviceClass != LIBUSB_CLASS_HUB) {
                attached = true;
                statusText = "Android phone detected. Starting AOA Handshake...";

                QString hName;
                int hVer = 0;
                if (performAOAHandshake(list[i], desc.idVendor, desc.idProduct, hName, hVer)) {
                    deviceName = hName;
                    aoaVer = hVer;
                    statusText = "Handshake sent! Switching phone to Accessory mode...";
                    break;
                }
            }
        }
    }

    libusb_free_device_list(list, 1);

    if (attached != m_lastAttached || accessory != m_lastAccessory ||
        deviceName != m_lastDeviceName || statusText != m_lastStatus || aoaVer != m_lastAoaVersion) {
        m_lastAttached = attached;
        m_lastAccessory = accessory;
        m_lastDeviceName = deviceName;
        m_lastStatus = statusText;
        m_lastAoaVersion = aoaVer;
        emit statusUpdated(attached, accessory, deviceName, statusText, aoaVer);
    }
#endif
}
