#ifndef BLUEZBLUETOOTHMANAGER_HPP
#define BLUEZBLUETOOTHMANAGER_HPP

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QSet>
#include <QTimer>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusObjectPath>
#include <QDBusAbstractAdaptor>
#include <QDBusInterface>
#include <QDBusMetaType>

typedef QMap<QString, QVariantMap> InterfaceList;
typedef QMap<QDBusObjectPath, InterfaceList> ManagedObjectList;
Q_DECLARE_METATYPE(InterfaceList)
Q_DECLARE_METATYPE(ManagedObjectList)

class BluezBluetoothManager;

// ============================================================================
// D-Bus Agent implementing org.bluez.Agent1
// ============================================================================
class BluezAgentAdaptor : public QDBusAbstractAdaptor
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.bluez.Agent1")

public:
    explicit BluezAgentAdaptor(BluezBluetoothManager *parent);

public slots:
    void Release();
    QString RequestPinCode(const QDBusObjectPath &device);
    void DisplayPinCode(const QDBusObjectPath &device, const QString &pincode);
    uint RequestPasskey(const QDBusObjectPath &device);
    void DisplayPasskey(const QDBusObjectPath &device, uint passkey, ushort entered);
    void RequestConfirmation(const QDBusObjectPath &device, uint passkey, const QDBusMessage &message);
    void RequestAuthorization(const QDBusObjectPath &device);
    void AuthorizeService(const QDBusObjectPath &device, const QString &uuid);
    void Cancel();

private:
    BluezBluetoothManager *m_manager;
};

// ============================================================================
// BluezBluetoothManager - Pure BlueZ D-Bus Controller for Automotive IVI
// ============================================================================
class BluezBluetoothManager : public QObject
{
    Q_OBJECT

public:
    explicit BluezBluetoothManager(QObject *parent = nullptr);
    ~BluezBluetoothManager() override;

    bool init();

    // Adapter Control (Requirement 1, 2)
    QString adapterPath() const { return m_adapterPath; }
    bool isPowered() const { return m_isPowered; }
    void setPowered(bool powered);
    bool isDiscoverable() const { return m_isDiscoverable; }
    void setDiscoverable(bool discoverable);
    void setAdapterName(const QString &name);

    // Passkey / Authentication (Requirement 3)
    QString passkey() const { return m_passkey; }
    void setPasskey(const QString &key) { m_passkey = key; }
    bool isPairingPromptActive() const { return m_isPairingPromptActive; }
    QString incomingPairingName() const { return m_incomingPairingName; }
    QString incomingPairingPasskey() const { return m_incomingPairingPasskey; }
    QString incomingPairingMac() const { return m_incomingPairingMac; }
    void confirmPairing();
    void rejectPairing();

    // Discovery & Add Device (Requirement 4, 5)
    bool isDiscovering() const { return m_isDiscovering; }
    void startDiscovery();
    void stopDiscovery();
    QVariantList discoveredDevices() const;
    void clearDiscoveredDevices();

    // Device Actions (Requirement 5, 6, 7)
    void pairDevice(const QString &mac);
    void connectDevice(const QString &mac);
    void disconnectDevice(const QString &mac);
    void removeDevice(const QString &mac);

    // Ground-truth Paired Devices List
    void refreshAllManagedObjects();
    QVariantList pairedDevices() const;

    // Battery Level (org.bluez.Battery1)
    void queryDeviceBattery(const QString &mac);
    int getDeviceBattery(const QString &mac) const;
    bool isInputDevice(const QString &mac) const;

signals:
    void adapterChanged();
    void powerStateChanged(bool powered);
    void discoverableChanged(bool discoverable);
    void discoveryStateChanged(bool discovering);
    void discoveredDevicesChanged();
    void pairedDevicesChanged();
    
    // Pairing prompt notification to IVI UI
    void pairingConfirmationRequested(const QString &mac, const QString &name, const QString &passkey);
    void pairingAuthenticated(const QString &mac);
    void pairingFinished(const QString &mac, bool success, const QString &errorMsg);

    // Connection & Removal notifications
    void deviceConnected(const QString &mac);
    void deviceDisconnected(const QString &mac);
    void deviceRemoved(const QString &mac);

    // Battery Notification
    void batteryLevelChanged(const QString &mac, int percentage);

private slots:
    void onPropertiesChanged(const QString &interface, const QVariantMap &changedProperties, const QStringList &invalidatedProperties, const QDBusMessage &msg);
    void onInterfacesAdded(const QDBusObjectPath &objectPath, const InterfaceList &interfaces);
    void onInterfacesRemoved(const QDBusObjectPath &objectPath, const QStringList &interfaces);
    void checkAdapterHealth();

private:
    friend class BluezAgentAdaptor;

    void registerAgent();
    void unregisterAgent();
    QString macFromObjectPath(const QString &path) const;
    QString objectPathFromMac(const QString &mac) const;
    QVariantMap parseDeviceProperties(const QString &path, const QVariantMap &props) const;

    QString m_adapterPath{"/org/bluez/hci0"};
    bool m_isPowered{true};
    bool m_isDiscoverable{false};
    bool m_targetDiscoverable{false};
    bool m_isDiscovering{false};
    QString m_adapterName{"APEX IVI"};
    QString m_passkey{"0000"};

    // Pairing Agent State
    bool m_isPairingPromptActive{false};
    QString m_incomingPairingName;
    QString m_incomingPairingPasskey;
    QString m_incomingPairingMac;
    QDBusMessage m_pendingConfirmationMessage;
    bool m_waitingForPhoneAuth{false};

    // Discovered Devices (during active Add Device scan)
    QMap<QString, QVariantMap> m_discoveredDevices; // key: MAC

    // Paired Devices
    QMap<QString, QVariantMap> m_pairedDevices; // key: MAC
    QSet<QString> m_removedMacs;
    QMap<QString, int> m_deviceBatteries;

    QTimer *m_healthTimer{nullptr};
    QTimer *m_discoveryTimeoutTimer{nullptr};
    QTimer *m_batteryPollTimer{nullptr};
};

#endif // BLUEZBLUETOOTHMANAGER_HPP
