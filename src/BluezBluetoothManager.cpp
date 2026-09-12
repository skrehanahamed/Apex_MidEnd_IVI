#include "BluezBluetoothManager.hpp"
#include <QDBusConnectionInterface>
#include <QDBusReply>
#include <QDBusPendingCall>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDBusMetaType>
#include <QDebug>
#include <QRegularExpression>

static const QString BLUEZ_SERVICE = "org.bluez";
static const QString ADAPTER_INTERFACE = "org.bluez.Adapter1";
static const QString DEVICE_INTERFACE = "org.bluez.Device1";
static const QString AGENT_MANAGER_INTERFACE = "org.bluez.AgentManager1";
static const QString AGENT_PATH = "/org/bluez/agent";
static const QString PROPERTIES_INTERFACE = "org.freedesktop.DBus.Properties";
static const QString OBJECT_MANAGER_INTERFACE = "org.freedesktop.DBus.ObjectManager";

// ============================================================================
// BluezAgentAdaptor Implementation
// ============================================================================
BluezAgentAdaptor::BluezAgentAdaptor(BluezBluetoothManager *parent)
    : QDBusAbstractAdaptor(parent), m_manager(parent)
{
    setAutoRelaySignals(true);
}

void BluezAgentAdaptor::Release()
{
    qDebug() << "[BluezAgent] Agent released by BlueZ";
}

QString BluezAgentAdaptor::RequestPinCode(const QDBusObjectPath &device)
{
    QString mac = m_manager->macFromObjectPath(device.path());
    qDebug() << "[BluezAgent] RequestPinCode for device:" << mac << "returning passkey:" << m_manager->passkey();
    return m_manager->passkey();
}

void BluezAgentAdaptor::DisplayPinCode(const QDBusObjectPath &device, const QString &pincode)
{
    qDebug() << "[BluezAgent] DisplayPinCode for device:" << device.path() << "PIN:" << pincode;
}

uint BluezAgentAdaptor::RequestPasskey(const QDBusObjectPath &device)
{
    bool ok = false;
    uint pk = m_manager->passkey().toUInt(&ok);
    qDebug() << "[BluezAgent] RequestPasskey for device:" << device.path() << "returning:" << (ok ? pk : 0);
    return ok ? pk : 0;
}

void BluezAgentAdaptor::DisplayPasskey(const QDBusObjectPath &device, uint passkey, ushort entered)
{
    Q_UNUSED(entered);
    qDebug() << "[BluezAgent] DisplayPasskey for device:" << device.path() << "Passkey:" << passkey;
}

void BluezAgentAdaptor::RequestConfirmation(const QDBusObjectPath &device, uint passkey, const QDBusMessage &message)
{
    message.setDelayedReply(true);
    m_manager->m_pendingConfirmationMessage = message;

    QString devPath = device.path();
    QString mac = m_manager->macFromObjectPath(devPath);

    // Resolve human-readable name from device properties
    QString name = "Bluetooth Device";
    QDBusInterface devProps(BLUEZ_SERVICE, devPath, PROPERTIES_INTERFACE, QDBusConnection::systemBus());
    if (devProps.isValid()) {
        QDBusReply<QVariant> aliasReply = devProps.call("Get", DEVICE_INTERFACE, "Alias");
        if (aliasReply.isValid() && !aliasReply.value().toString().isEmpty()) {
            name = aliasReply.value().toString();
        } else {
            QDBusReply<QVariant> nameReply = devProps.call("Get", DEVICE_INTERFACE, "Name");
            if (nameReply.isValid() && !nameReply.value().toString().isEmpty()) {
                name = nameReply.value().toString();
            }
        }
    }

    QString passkeyStr = QString("%1").arg(passkey, 6, 10, QChar('0'));
    qDebug() << "[BluezAgent] RequestConfirmation from device:" << name << "(" << mac << ") Passkey:" << passkeyStr;

    m_manager->m_isPairingPromptActive = false; // Automotive UI uses Connecting modal
    m_manager->m_incomingPairingMac = mac;
    m_manager->m_incomingPairingName = name;
    m_manager->m_incomingPairingPasskey = passkeyStr;
    m_manager->m_waitingForPhoneAuth = true;

    // Automatically send confirmation reply from IVI so phone can confirm pairing:
    QDBusMessage reply = message.createReply();
    bool sent = QDBusConnection::systemBus().send(reply);
    qDebug() << "[BluezAgent] Sent IVI confirmation reply:" << sent << "- Phone will prompt user with passkey";

    emit m_manager->pairingConfirmationRequested(mac, name, passkeyStr);
}

void BluezAgentAdaptor::RequestAuthorization(const QDBusObjectPath &device)
{
    qDebug() << "[BluezAgent] RequestAuthorization for device:" << device.path() << "accepted automatically.";
    if (m_manager->m_waitingForPhoneAuth) {
        m_manager->m_waitingForPhoneAuth = false;
        QString mac = m_manager->macFromObjectPath(device.path());
        emit m_manager->pairingAuthenticated(mac);
    }
}

void BluezAgentAdaptor::AuthorizeService(const QDBusObjectPath &device, const QString &uuid)
{
    qDebug() << "[BluezAgent] AuthorizeService for device:" << device.path() << "UUID:" << uuid << "authorized.";
    if (m_manager->m_waitingForPhoneAuth) {
        m_manager->m_waitingForPhoneAuth = false;
        QString mac = m_manager->macFromObjectPath(device.path());
        emit m_manager->pairingAuthenticated(mac);
    }
}

void BluezAgentAdaptor::Cancel()
{
    qDebug() << "[BluezAgent] Pairing cancelled by BlueZ";
    m_manager->m_isPairingPromptActive = false;
    m_manager->m_waitingForPhoneAuth = false;
    m_manager->m_pendingConfirmationMessage = QDBusMessage();
    emit m_manager->pairingFinished(m_manager->m_incomingPairingMac, false, "Pairing cancelled");
}

// ============================================================================
// BluezBluetoothManager Implementation
// ============================================================================
BluezBluetoothManager::BluezBluetoothManager(QObject *parent)
    : QObject(parent),
      m_healthTimer(new QTimer(this)),
      m_discoveryTimeoutTimer(new QTimer(this))
{
    m_discoveryTimeoutTimer->setSingleShot(true);
    connect(m_discoveryTimeoutTimer, &QTimer::timeout, this, [this]() {
        stopDiscovery();
    });

    connect(m_healthTimer, &QTimer::timeout, this, &BluezBluetoothManager::checkAdapterHealth);
}

BluezBluetoothManager::~BluezBluetoothManager()
{
    unregisterAgent();
}

bool BluezBluetoothManager::init()
{
    QDBusConnection systemBus = QDBusConnection::systemBus();
    if (!systemBus.isConnected()) {
        qCritical() << "[BluezManager] Cannot connect to D-Bus system bus!";
        return false;
    }

    // Register ObjectManager meta types for automatic D-Bus demarshalling
    qDBusRegisterMetaType<InterfaceList>();
    qDBusRegisterMetaType<ManagedObjectList>();

    // Register our D-Bus Pairing Agent
    registerAgent();

    // Listen for D-Bus ObjectManager signals (device addition/removal)
    systemBus.connect(BLUEZ_SERVICE, "/", OBJECT_MANAGER_INTERFACE, "InterfacesAdded",
                      this, SLOT(onInterfacesAdded(QDBusObjectPath, InterfaceList)));
    systemBus.connect(BLUEZ_SERVICE, "/", OBJECT_MANAGER_INTERFACE, "InterfacesRemoved",
                      this, SLOT(onInterfacesRemoved(QDBusObjectPath, QStringList)));

    // Listen for D-Bus property changes (connection/disconnection/pairing/discoverable)
    systemBus.connect(BLUEZ_SERVICE, "", PROPERTIES_INTERFACE, "PropertiesChanged",
                      this, SLOT(onPropertiesChanged(QString, QVariantMap, QStringList, QDBusMessage)));

    // Ensure adapter is powered, pairable, and discoverable only on Add Device screen
    setPowered(true);
    setDiscoverable(false);

    // Initial enumeration of all paired and existing devices
    refreshAllManagedObjects();

    // Start periodic health check to ensure discoverable remains active
    m_healthTimer->start(10000);

    // Continuous 5-second async battery poller for live charging updates
    m_batteryPollTimer = new QTimer(this);
    connect(m_batteryPollTimer, &QTimer::timeout, this, [this]() {
        for (auto it = m_pairedDevices.begin(); it != m_pairedDevices.end(); ++it) {
            if (it.value()["connected"].toBool() && !it.value()["isInput"].toBool()) {
                queryDeviceBattery(it.key());
            }
        }
    });
    m_batteryPollTimer->start(5000);

    qDebug() << "[BluezManager] BlueZ D-Bus Bluetooth Manager initialized successfully.";
    return true;
}

void BluezBluetoothManager::registerAgent()
{
    QDBusConnection systemBus = QDBusConnection::systemBus();

    // Unregister existing adaptor on this path if any
    systemBus.unregisterObject(AGENT_PATH);

    // Create the adaptor attached to this manager
    new BluezAgentAdaptor(this);

    if (!systemBus.registerObject(AGENT_PATH, this)) {
        qWarning() << "[BluezManager] Failed to register agent object on D-Bus path:" << AGENT_PATH;
        return;
    }

    // Call org.bluez.AgentManager1.RegisterAgent(AGENT_PATH, "KeyboardDisplay")
    QDBusInterface agentManager(BLUEZ_SERVICE, "/org/bluez", AGENT_MANAGER_INTERFACE, systemBus);
    if (!agentManager.isValid()) {
        qWarning() << "[BluezManager] AgentManager1 interface not valid at /org/bluez";
        return;
    }

    QDBusReply<void> regReply = agentManager.call("RegisterAgent", QDBusObjectPath(AGENT_PATH), "KeyboardDisplay");
    if (!regReply.isValid()) {
        qWarning() << "[BluezManager] Error registering agent with BlueZ:" << regReply.error().message();
    } else {
        qDebug() << "[BluezManager] Agent registered with capability 'KeyboardDisplay'";
    }

    // Request to be the default agent
    QDBusReply<void> defReply = agentManager.call("RequestDefaultAgent", QDBusObjectPath(AGENT_PATH));
    if (!defReply.isValid()) {
        qWarning() << "[BluezManager] Error setting default agent:" << defReply.error().message();
    } else {
        qDebug() << "[BluezManager] Agent set as default pairing agent in BlueZ";
    }
}

void BluezBluetoothManager::unregisterAgent()
{
    QDBusConnection systemBus = QDBusConnection::systemBus();
    QDBusInterface agentManager(BLUEZ_SERVICE, "/org/bluez", AGENT_MANAGER_INTERFACE, systemBus);
    if (agentManager.isValid()) {
        agentManager.call("UnregisterAgent", QDBusObjectPath(AGENT_PATH));
    }
    systemBus.unregisterObject(AGENT_PATH);
}

// ============================================================================
// Adapter Controls (Requirements 1 & 2)
// ============================================================================
void BluezBluetoothManager::setPowered(bool powered)
{
    QDBusInterface props(BLUEZ_SERVICE, m_adapterPath, PROPERTIES_INTERFACE, QDBusConnection::systemBus());
    if (props.isValid()) {
        props.call("Set", ADAPTER_INTERFACE, "Powered", QVariant::fromValue(QDBusVariant(powered)));
        m_isPowered = powered;
        emit powerStateChanged(powered);
    }
}

void BluezBluetoothManager::setDiscoverable(bool discoverable)
{
    m_targetDiscoverable = discoverable;
    QDBusInterface props(BLUEZ_SERVICE, m_adapterPath, PROPERTIES_INTERFACE, QDBusConnection::systemBus());
    if (props.isValid()) {
        props.asyncCall("Set", ADAPTER_INTERFACE, "DiscoverableTimeout", QVariant::fromValue(QDBusVariant(static_cast<uint>(0))));
        props.asyncCall("Set", ADAPTER_INTERFACE, "PairableTimeout", QVariant::fromValue(QDBusVariant(static_cast<uint>(0))));
        props.asyncCall("Set", ADAPTER_INTERFACE, "Pairable", QVariant::fromValue(QDBusVariant(true)));
        props.asyncCall("Set", ADAPTER_INTERFACE, "Discoverable", QVariant::fromValue(QDBusVariant(discoverable)));
        m_isDiscoverable = discoverable;
        emit discoverableChanged(discoverable);
        qDebug() << "[BluezManager] Adapter discoverable set to:" << discoverable;
    }
}

void BluezBluetoothManager::setAdapterName(const QString &name)
{
    if (name.trimmed().isEmpty()) return;
    m_adapterName = name.trimmed();

    QDBusInterface props(BLUEZ_SERVICE, m_adapterPath, PROPERTIES_INTERFACE, QDBusConnection::systemBus());
    if (props.isValid()) {
        props.asyncCall("Set", ADAPTER_INTERFACE, "Alias", QVariant::fromValue(QDBusVariant(m_adapterName)));
        qDebug() << "[BluezManager] Bluetooth adapter name set to:" << m_adapterName;
    }
}

void BluezBluetoothManager::checkAdapterHealth()
{
    if (!m_isPowered || !m_targetDiscoverable) return;

    QDBusInterface props(BLUEZ_SERVICE, m_adapterPath, PROPERTIES_INTERFACE, QDBusConnection::systemBus());
    if (props.isValid()) {
        QDBusReply<QVariant> discReply = props.call("Get", ADAPTER_INTERFACE, "Discoverable");
        if (discReply.isValid() && !discReply.value().toBool()) {
            qDebug() << "[BluezManager] Discoverable became false while on Add Device screen, restoring...";
            setDiscoverable(true);
        }
    }
}

// ============================================================================
// Passkey / Authentication Handlers (Requirement 3)
// ============================================================================
void BluezBluetoothManager::confirmPairing()
{
    if (!m_isPairingPromptActive || m_pendingConfirmationMessage.type() != QDBusMessage::MethodCallMessage) {
        qWarning() << "[BluezManager] Cannot confirm pairing: prompt not active or invalid message type";
        return;
    }

    qDebug() << "[BluezManager] User confirmed pairing for:" << m_incomingPairingMac;
    QDBusMessage reply = m_pendingConfirmationMessage.createReply();
    bool sent = QDBusConnection::systemBus().send(reply);
    qDebug() << "[BluezManager] Sent pairing confirmation reply result:" << sent;

    // Trust device so future connections don't re-prompt
    QString devPath = objectPathFromMac(m_incomingPairingMac);
    QDBusInterface devProps(BLUEZ_SERVICE, devPath, PROPERTIES_INTERFACE, QDBusConnection::systemBus());
    if (devProps.isValid()) {
        devProps.asyncCall("Set", DEVICE_INTERFACE, "Trusted", QVariant::fromValue(QDBusVariant(true)));
    }

    m_isPairingPromptActive = false;
    m_pendingConfirmationMessage = QDBusMessage();
    // pairingFinished will be emitted once authoritatively by onPropertiesChanged when BlueZ sets Paired=true
}

void BluezBluetoothManager::rejectPairing()
{
    if (!m_isPairingPromptActive) return;

    qDebug() << "[BluezManager] User rejected pairing for:" << m_incomingPairingMac;
    if (m_pendingConfirmationMessage.type() == QDBusMessage::MethodCallMessage) {
        QDBusMessage errorReply = m_pendingConfirmationMessage.createErrorReply(
            "org.bluez.Error.Rejected", "Pairing rejected by IVI user");
        QDBusConnection::systemBus().send(errorReply);
    }

    m_isPairingPromptActive = false;
    m_waitingForPhoneAuth = false;
    m_pendingConfirmationMessage = QDBusMessage();
    emit pairingFinished(m_incomingPairingMac, false, "Rejected by user");
}

// ============================================================================
// Discovery & Add Device (Requirement 4 & 5)
// ============================================================================
void BluezBluetoothManager::startDiscovery()
{
    m_discoveredDevices.clear();
    emit discoveredDevicesChanged();

    QDBusInterface adapter(BLUEZ_SERVICE, m_adapterPath, ADAPTER_INTERFACE, QDBusConnection::systemBus());
    if (adapter.isValid()) {
        QDBusReply<void> reply = adapter.call("StartDiscovery");
        if (!reply.isValid()) {
            // If already discovering, treat as success
            if (reply.error().name() != "org.bluez.Error.InProgress") {
                qWarning() << "[BluezManager] StartDiscovery error:" << reply.error().message();
                return;
            }
        }
        m_isDiscovering = true;
        emit discoveryStateChanged(true);
        qDebug() << "[BluezManager] Discovery started successfully.";

        // Auto-stop discovery after 18 seconds to conserve bandwidth
        m_discoveryTimeoutTimer->start(18000);
    }
}

void BluezBluetoothManager::stopDiscovery()
{
    m_discoveryTimeoutTimer->stop();
    if (!m_isDiscovering) return;

    QDBusInterface adapter(BLUEZ_SERVICE, m_adapterPath, ADAPTER_INTERFACE, QDBusConnection::systemBus());
    if (adapter.isValid()) {
        adapter.call("StopDiscovery");
    }
    m_isDiscovering = false;
    emit discoveryStateChanged(false);
    qDebug() << "[BluezManager] Discovery stopped.";
}

QVariantList BluezBluetoothManager::discoveredDevices() const
{
    QVariantList list;
    for (const auto &dev : m_discoveredDevices) {
        list.append(dev);
    }
    return list;
}

void BluezBluetoothManager::clearDiscoveredDevices()
{
    m_discoveredDevices.clear();
    emit discoveredDevicesChanged();
}

// ============================================================================
// Device Operations: Pair, Connect, Disconnect, Remove (Requirements 5, 6, 7)
// ============================================================================
void BluezBluetoothManager::pairDevice(const QString &mac)
{
    QString path = objectPathFromMac(mac);
    qDebug() << "[BluezManager] Pairing with device:" << mac << "at D-Bus path:" << path;

    QDBusInterface device(BLUEZ_SERVICE, path, DEVICE_INTERFACE, QDBusConnection::systemBus());
    if (device.isValid()) {
        QDBusPendingCall pcall = device.asyncCall("Pair");
        auto watcher = new QDBusPendingCallWatcher(pcall, this);
        connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, mac, watcher]() {
            QDBusPendingReply<void> reply = *watcher;
            if (reply.isError()) {
                qWarning() << "[BluezManager] Pair failed for" << mac << ":" << reply.error().message();
                emit pairingFinished(mac, false, reply.error().message());
            } else {
                qDebug() << "[BluezManager] Pair succeeded for" << mac;
                // Auto-trust and connect upon successful pair
                connectDevice(mac);
            }
            watcher->deleteLater();
        });
    }
}

void BluezBluetoothManager::connectDevice(const QString &mac)
{
    QString path = objectPathFromMac(mac);
    qDebug() << "[BluezManager] Connecting to device:" << mac << "at D-Bus path:" << path;

    // First ensure device is Trusted
    QDBusInterface devProps(BLUEZ_SERVICE, path, PROPERTIES_INTERFACE, QDBusConnection::systemBus());
    if (devProps.isValid()) {
        devProps.call("Set", DEVICE_INTERFACE, "Trusted", QVariant::fromValue(QDBusVariant(true)));
    }

    QDBusInterface device(BLUEZ_SERVICE, path, DEVICE_INTERFACE, QDBusConnection::systemBus());
    if (device.isValid()) {
        QDBusPendingCall pcall = device.asyncCall("Connect");
        auto watcher = new QDBusPendingCallWatcher(pcall, this);
        connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, mac, watcher]() {
            QDBusPendingReply<void> reply = *watcher;
            if (reply.isError()) {
                qWarning() << "[BluezManager] Connect failed for" << mac << ":" << reply.error().message();
            } else {
                qDebug() << "[BluezManager] Connect succeeded for" << mac;
            }
            watcher->deleteLater();
        });
    }
}

void BluezBluetoothManager::disconnectDevice(const QString &mac)
{
    QString path = objectPathFromMac(mac);
    qDebug() << "[BluezManager] Disconnecting device:" << mac;

    QDBusInterface device(BLUEZ_SERVICE, path, DEVICE_INTERFACE, QDBusConnection::systemBus());
    if (device.isValid()) {
        device.asyncCall("Disconnect");
    }
}

void BluezBluetoothManager::removeDevice(const QString &mac)
{
    QString upperMac = mac.trimmed().toUpper();
    QString path = objectPathFromMac(upperMac);
    qDebug() << "[BluezManager] Removing device from BlueZ:" << upperMac << "path:" << path;

    m_removedMacs.insert(upperMac);
    QTimer::singleShot(10000, this, [this, upperMac]() {
        m_removedMacs.remove(upperMac);
    });

    QDBusInterface adapter(BLUEZ_SERVICE, m_adapterPath, ADAPTER_INTERFACE, QDBusConnection::systemBus());
    if (adapter.isValid()) {
        adapter.asyncCall("RemoveDevice", QDBusObjectPath(path));
    }

    m_pairedDevices.remove(upperMac);
    m_discoveredDevices.remove(upperMac);
    emit deviceRemoved(upperMac);
    emit pairedDevicesChanged();
}

QVariantList BluezBluetoothManager::pairedDevices() const
{
    QVariantList list;
    for (auto it = m_pairedDevices.begin(); it != m_pairedDevices.end(); ++it) {
        if (m_removedMacs.contains(it.key())) {
            continue;
        }
        const auto &dev = it.value();
        if (dev["paired"].toBool() && !dev["isInput"].toBool()) {
            list.append(dev);
        }
    }
    return list;
}

static QVariant unwrap(const QVariant &v)
{
    if (v.canConvert<QDBusVariant>()) {
        return v.value<QDBusVariant>().variant();
    }
    return v;
}

void BluezBluetoothManager::onPropertiesChanged(const QString &interface,
                                                const QVariantMap &changedProperties,
                                                const QStringList &invalidatedProperties,
                                                const QDBusMessage &msg)
{
    Q_UNUSED(invalidatedProperties);
    QString path = msg.path();

    // Adapter property changes
    if (interface == ADAPTER_INTERFACE && path == m_adapterPath) {
        if (changedProperties.contains("Discoverable")) {
            m_isDiscoverable = changedProperties["Discoverable"].toBool();
            emit discoverableChanged(m_isDiscoverable);
            // Restore if disabled while on Add Device screen
            if (!m_isDiscoverable && m_isPowered && m_targetDiscoverable) {
                setDiscoverable(true);
            }
        }
        if (changedProperties.contains("Discovering")) {
            m_isDiscovering = changedProperties["Discovering"].toBool();
            emit discoveryStateChanged(m_isDiscovering);
        }
        if (changedProperties.contains("Powered")) {
            m_isPowered = changedProperties["Powered"].toBool();
            emit powerStateChanged(m_isPowered);
        }
        return;
    }

    // Battery property changes (org.bluez.Battery1)
    if (interface == "org.bluez.Battery1" && path.startsWith(m_adapterPath + "/dev_")) {
        QString mac = macFromObjectPath(path);
        if (changedProperties.contains("Percentage")) {
            int battery = unwrap(changedProperties["Percentage"]).toInt();
            qDebug() << "[BluezManager] Battery percentage for" << mac << "is" << battery << "%";
            m_deviceBatteries[mac] = battery;
            emit batteryLevelChanged(mac, battery);
        }
        return;
    }

    // Device property changes (Requirements 6 & 7)
    if (interface == DEVICE_INTERFACE && path.startsWith(m_adapterPath + "/dev_")) {
        QString mac = macFromObjectPath(path);

        // Requirement 6: Disconnect detection from phone side (Universal across all devices)
        if (changedProperties.contains("Connected")) {
            bool isConnected = unwrap(changedProperties["Connected"]).toBool();
            qDebug() << "[BluezManager] D-Bus Connected property changed for" << mac << "->" << isConnected;

            m_pairedDevices[mac]["mac"] = mac;
            m_pairedDevices[mac]["connected"] = isConnected;
            if (!isConnected) {
                m_pairedDevices[mac]["handsFree"] = false;
                m_pairedDevices[mac]["audio"] = false;
            }
            emit pairedDevicesChanged();

            if (isConnected) {
                queryDeviceBattery(mac);
                emit deviceConnected(mac);
            } else {
                // Instantly emit deviceDisconnected so IVI UI updates from Connected to Disconnected
                emit deviceDisconnected(mac);
            }
        }

        // Requirement 7: Device unpairing detection from phone side
        if (changedProperties.contains("Paired")) {
            bool isPaired = unwrap(changedProperties["Paired"]).toBool();
            qDebug() << "[BluezManager] D-Bus Paired property changed for" << mac << "->" << isPaired;
            refreshAllManagedObjects();
            if (!isPaired) {
                emit deviceRemoved(mac);
            } else {
                // Ensure device is trusted so all profiles are accepted under one single permission
                QString devPath = objectPathFromMac(mac);
                QDBusInterface devProps(BLUEZ_SERVICE, devPath, PROPERTIES_INTERFACE, QDBusConnection::systemBus());
                if (devProps.isValid()) {
                    devProps.asyncCall("Set", DEVICE_INTERFACE, "Trusted", QVariant::fromValue(QDBusVariant(true)));
                }
                emit pairingFinished(mac, true, QString());
            }
            emit pairedDevicesChanged();
        }

        // Update name or alias
        if (changedProperties.contains("Alias") || changedProperties.contains("Name")) {
            QString newName = unwrap(changedProperties.value("Alias", changedProperties.value("Name"))).toString().trimmed();
            if (m_pairedDevices.contains(mac) && !newName.isEmpty()) {
                m_pairedDevices[mac]["name"] = newName;
                emit pairedDevicesChanged();
            }
            if (m_discoveredDevices.contains(mac) && !newName.isEmpty()) {
                m_discoveredDevices[mac]["name"] = newName;
                emit discoveredDevicesChanged();
            }
        }
    }
}

void BluezBluetoothManager::onInterfacesAdded(const QDBusObjectPath &objectPath,
                                              const InterfaceList &interfaces)
{
    QString path = objectPath.path();
    if (interfaces.contains("org.bluez.Battery1") && path.startsWith(m_adapterPath + "/dev_")) {
        QString mac = macFromObjectPath(path);
        const QVariantMap &batProps = interfaces["org.bluez.Battery1"];
        if (batProps.contains("Percentage")) {
            int battery = unwrap(batProps["Percentage"]).toInt();
            qDebug() << "[BluezManager] Battery1 interface added for" << mac << ":" << battery << "%";
            m_deviceBatteries[mac] = battery;
            emit batteryLevelChanged(mac, battery);
        }
    }

    if (!path.startsWith(m_adapterPath + "/dev_") || !interfaces.contains(DEVICE_INTERFACE)) {
        return;
    }

    refreshAllManagedObjects();

    QVariantMap devProps = parseDeviceProperties(path, interfaces[DEVICE_INTERFACE]);
    QString mac = devProps["mac"].toString();
    bool isInput = devProps["isInput"].toBool();

    if (devProps["paired"].toBool()) {
        if (!m_pairedDevices.contains(mac)) {
            m_pairedDevices[mac] = devProps;
            emit pairingFinished(mac, true, QString());
        }
        emit pairedDevicesChanged();
    } else if (m_isDiscovering) {
        if (!isInput && !m_pairedDevices.contains(mac)) {
            m_discoveredDevices[mac] = devProps;
            emit discoveredDevicesChanged();
        }
    }
}

void BluezBluetoothManager::onInterfacesRemoved(const QDBusObjectPath &objectPath,
                                                const QStringList &interfaces)
{
    QString path = objectPath.path();
    if (!path.startsWith(m_adapterPath + "/dev_") || !interfaces.contains(DEVICE_INTERFACE)) {
        return;
    }

    QString mac = macFromObjectPath(path);
    if (mac.isEmpty()) return;
    qDebug() << "[BluezManager] Device object removed from BlueZ:" << mac;

    refreshAllManagedObjects();
    m_discoveredDevices.remove(mac);
    emit deviceRemoved(mac);
    emit pairedDevicesChanged();
    emit discoveredDevicesChanged();
}

// ============================================================================
// Helper Methods
// ============================================================================
void BluezBluetoothManager::refreshAllManagedObjects()
{
    QDBusInterface objManager(BLUEZ_SERVICE, "/", OBJECT_MANAGER_INTERFACE, QDBusConnection::systemBus());
    if (!objManager.isValid()) return;

    QDBusPendingCall pcall = objManager.asyncCall("GetManagedObjects");
    auto *watcher = new QDBusPendingCallWatcher(pcall, this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *w) {
        w->deleteLater();
        QDBusPendingReply<ManagedObjectList> reply = *w;
        if (!reply.isValid()) {
            qWarning() << "[BluezManager] GetManagedObjects async failed:" << reply.error().message();
            return;
        }

        QMap<QString, QVariantMap> newPaired;
        const auto &objects = reply.value();

        for (auto it = objects.begin(); it != objects.end(); ++it) {
            QString path = it.key().path();
            const auto &ifaces = it.value();

            if (path.startsWith(m_adapterPath + "/dev_") && ifaces.contains(DEVICE_INTERFACE)) {
                QVariantMap dev = parseDeviceProperties(path, ifaces[DEVICE_INTERFACE]);
                QString devMac = dev["mac"].toString().trimmed().toUpper();
                if (!m_removedMacs.contains(devMac) && dev["paired"].toBool() && !dev["isInput"].toBool()) {
                    newPaired[devMac] = dev;
                }
            }

            if (path.startsWith(m_adapterPath + "/dev_") && ifaces.contains("org.bluez.Battery1")) {
                QString devMac = macFromObjectPath(path);
                const auto &batProps = ifaces["org.bluez.Battery1"];
                if (batProps.contains("Percentage")) {
                    int pct = unwrap(batProps["Percentage"]).toInt();
                    qDebug() << "[BluezManager] Read initial Battery1 for" << devMac << ":" << pct << "%";
                    m_deviceBatteries[devMac] = pct;
                    emit batteryLevelChanged(devMac, pct);
                }
            }
        }

        if (newPaired != m_pairedDevices) {
            m_pairedDevices = newPaired;
            for (const auto &d : m_pairedDevices) {
                qDebug() << "[BluezManager] Paired device loaded from BlueZ:" << d["name"].toString() << d["mac"].toString() << "Connected:" << d["connected"].toBool();
            }
            emit pairedDevicesChanged();
        }
    });
}

QString BluezBluetoothManager::macFromObjectPath(const QString &path) const
{
    // Path format: /org/bluez/hci0/dev_XX_XX_XX_XX_XX_XX
    QString devPart = path.section('/', -1);
    if (devPart.startsWith("dev_")) {
        QString mac = devPart.mid(4);
        mac.replace('_', ':');
        return mac.toUpper();
    }
    return QString();
}

QString BluezBluetoothManager::objectPathFromMac(const QString &mac) const
{
    QString cleaned = mac.toUpper();
    cleaned.replace(':', '_');
    return m_adapterPath + "/dev_" + cleaned;
}

QVariantMap BluezBluetoothManager::parseDeviceProperties(const QString &path, const QVariantMap &props) const
{
    QVariantMap dev;
    QString mac = unwrap(props.value("Address")).toString().toUpper();
    if (mac.isEmpty()) {
        mac = macFromObjectPath(path);
    }

    QString name = unwrap(props.value("Alias")).toString().trimmed();
    if (name.isEmpty()) {
        name = unwrap(props.value("Name")).toString().trimmed();
    }
    if (name.isEmpty()) {
        name = mac;
    }

    QString icon = unwrap(props.value("Icon")).toString().toLower();
    bool isInput = (icon == "input-mouse" || icon == "input-keyboard" || icon == "input-gaming");

    dev["mac"] = mac;
    dev["name"] = name;
    dev["icon"] = icon;
    dev["paired"] = unwrap(props.value("Paired", false)).toBool();
    dev["connected"] = unwrap(props.value("Connected", false)).toBool();
    dev["trusted"] = unwrap(props.value("Trusted", false)).toBool();
    if (dev["paired"].toBool() && !dev["trusted"].toBool()) {
        QDBusInterface devProps(BLUEZ_SERVICE, objectPathFromMac(mac), "org.freedesktop.DBus.Properties", QDBusConnection::systemBus());
        devProps.asyncCall("Set", DEVICE_INTERFACE, "Trusted", QVariant::fromValue(QDBusVariant(true)));
        dev["trusted"] = true;
    }
    dev["isInput"] = isInput;
    dev["handsFree"] = dev["connected"].toBool();
    dev["audio"] = dev["connected"].toBool();

    return dev;
}

void BluezBluetoothManager::queryDeviceBattery(const QString &mac)
{
    QString devPath = objectPathFromMac(mac);
    QDBusMessage msg = QDBusMessage::createMethodCall(BLUEZ_SERVICE, devPath, "org.freedesktop.DBus.Properties", "Get");
    msg << QString("org.bluez.Battery1") << QString("Percentage");
    auto pcall = QDBusConnection::systemBus().asyncCall(msg);
    auto *watcher = new QDBusPendingCallWatcher(pcall, this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, mac](QDBusPendingCallWatcher *w) {
        w->deleteLater();
        QDBusPendingReply<QDBusVariant> reply = *w;
        if (reply.isValid()) {
            int pct = reply.value().variant().toInt();
            if (pct >= 0 && pct <= 100) {
                if (!m_deviceBatteries.contains(mac) || m_deviceBatteries[mac] != pct) {
                    qDebug() << "[BluezManager] Battery percentage updated for" << mac << "->" << pct << "%";
                    m_deviceBatteries[mac] = pct;
                    emit batteryLevelChanged(mac, pct);
                }
            }
        }
    });
}

int BluezBluetoothManager::getDeviceBattery(const QString &mac) const
{
    if (m_deviceBatteries.contains(mac)) {
        return m_deviceBatteries.value(mac);
    }
    QString devPath = objectPathFromMac(mac);
    QDBusInterface batIf(BLUEZ_SERVICE, devPath, "org.bluez.Battery1", QDBusConnection::systemBus());
    if (batIf.isValid()) {
        QVariant val = batIf.property("Percentage");
        if (val.isValid() && !val.isNull()) {
            return val.toInt();
        }
    }
    return -1;
}

bool BluezBluetoothManager::isInputDevice(const QString &mac) const
{
    QString upperMac = mac.trimmed().toUpper();
    if (m_pairedDevices.contains(upperMac)) {
        return m_pairedDevices[upperMac]["isInput"].toBool();
    }
    // Also check directly via D-Bus Icon or UUIDs
    QString devPath = objectPathFromMac(upperMac);
    QDBusInterface devIf(BLUEZ_SERVICE, devPath, DEVICE_INTERFACE, QDBusConnection::systemBus());
    if (devIf.isValid()) {
        QString icon = devIf.property("Icon").toString().toLower();
        if (icon.contains("mouse") || icon.contains("keyboard") || icon.contains("input")) {
            return true;
        }
        QString name = devIf.property("Alias").toString().toLower();
        if (name.isEmpty()) name = devIf.property("Name").toString().toLower();
        if (name.contains("pebble") || name.contains("mouse") || name.contains("keyboard")) {
            return true;
        }
    }
    return false;
}

