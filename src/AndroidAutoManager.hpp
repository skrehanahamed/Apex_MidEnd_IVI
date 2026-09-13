/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: AndroidAutoManager.hpp
 * ============================================================================
 */

#pragma once

#include <QObject>
#include <QString>
#include <QThread>
#include <QMutex>
#include <QAtomicInt>
#include <QTimer>
#include <QImage>
#include <atomic>
#include "AndroidAutoSession.hpp"

#ifdef __has_include
#if __has_include(<libusb-1.0/libusb.h>)
#include <libusb-1.0/libusb.h>
#define HAVE_LIBUSB 1
#endif
#endif

class AndroidAutoWorker;

class AndroidAutoManager : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool phoneAttached READ isPhoneAttached NOTIFY phoneAttachedChanged)
    Q_PROPERTY(bool accessoryConnected READ isAccessoryConnected NOTIFY accessoryConnectedChanged)
    Q_PROPERTY(QString deviceName READ deviceName NOTIFY deviceNameChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(int aoaVersion READ aoaVersion NOTIFY aoaVersionChanged)

public:
    explicit AndroidAutoManager(QObject *parent = nullptr);
    ~AndroidAutoManager() override;

    bool isPhoneAttached() const;
    bool isAccessoryConnected() const;
    QString deviceName() const;
    QString statusMessage() const;
    int aoaVersion() const;

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void triggerHandshake();
    Q_INVOKABLE void sendTouch(int action, int x, int y);
    Q_INVOKABLE void sendKey(uint32_t keyCode);
    Q_INVOKABLE void requestVideoFocus(bool focused);

    void setBluetoothAddress(const QString &addr);
    QString bluetoothAddress() const { return m_bluetoothAddress; }

signals:
    void phoneAttachedChanged(bool attached);
    void accessoryConnectedChanged(bool connected);
    void deviceNameChanged(const QString &name);
    void statusMessageChanged(const QString &status);
    void aoaVersionChanged(int version);
    void projectionReady();
    void frameReady(const QImage &frame);
    void exitRequested();
    void audioFocusGained();

private slots:
    void onWorkerStatusUpdated(bool attached, bool accessory, const QString &name, const QString &status, int aoaVer);
    void onWorkerFrameReady(const QImage &frame);

private:
    QThread *m_workerThread{nullptr};
    AndroidAutoWorker *m_worker{nullptr};

    bool m_phoneAttached{false};
    bool m_accessoryConnected{false};
    QString m_deviceName;
    QString m_statusMessage{"Waiting for USB connection..."};
    int m_aoaVersion{0};
    QString m_bluetoothAddress;

    std::atomic<bool> m_dragInFlight{false};
    std::atomic<bool> m_hasPendingDrag{false};
    std::atomic<int> m_pendingDragX{0};
    std::atomic<int> m_pendingDragY{0};
    std::atomic<uint64_t> m_lastDragDispatchMs{0};
};


class AndroidAutoWorker : public QObject {
    Q_OBJECT

public:
    explicit AndroidAutoWorker(QObject *parent = nullptr);
    ~AndroidAutoWorker() override;

public slots:
    void startMonitoring();
    void stopMonitoring();
    void manualHandshake();
    void sendTouch(int action, int x, int y);
    void sendKey(uint32_t keyCode);
    void requestVideoFocus(bool focused);
    void setBluetoothAddress(const QString &addr);

signals:
    void statusUpdated(bool attached, bool accessory, const QString &name, const QString &status, int aoaVer);
    void frameReady(const QImage &frame);
    void exitRequested();
    void audioFocusGained();

private slots:
    void scanDevices();

private:
    bool performAOAHandshake(void *devicePtr, uint16_t vid, uint16_t pid, QString &outName, int &outAoaVer);

    QTimer *m_scanTimer{nullptr};
    QTimer *m_restartCooldownTimer{nullptr};  // Enforces 2s gap between session restarts
    AndroidAutoSession *m_session{nullptr};
    bool m_running{false};
    bool m_lastAttached{false};
    bool m_lastAccessory{false};
    QString m_lastDeviceName;
    QString m_lastStatus;
    int m_lastAoaVersion{0};
    QString m_bluetoothAddress;
    bool m_sessionInCooldown{false};  // Blocks restart for 2s after session ends

#ifdef HAVE_LIBUSB
    libusb_context *m_usbCtx{nullptr};
#endif
};
