#include "PbapSyncManager.hpp"
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTextStream>
#include <QDateTime>
#include <algorithm>
#include <QRegularExpression>
#include <QDBusPendingCall>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDBusVariant>
#include <QDBusInterface>

PbapSyncManager::PbapSyncManager(QObject *parent)
    : QObject(parent)
{
    m_syncTimeoutTimer = new QTimer(this);
    m_syncTimeoutTimer->setSingleShot(true);
    m_syncTimeoutTimer->setInterval(120000); // 120-second global sync timeout
    connect(m_syncTimeoutTimer, &QTimer::timeout, this, &PbapSyncManager::onSyncTimeout);

    m_pollTimer = new QTimer(this);
    m_pollTimer->setInterval(800); // Lightweight async status check
    connect(m_pollTimer, &QTimer::timeout, this, &PbapSyncManager::pollTransferStatus);

    // Ensure cache directory exists
    QDir().mkpath("/root/.cache/obex");
}

PbapSyncManager::~PbapSyncManager()
{
    cleanupSession();
}

static int resolvePbapChannel(const QString &mac)
{
    QString cleanMac = mac.trimmed().toUpper();
    QDir btDir("/var/lib/bluetooth");
    for (const QString &adapter : btDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        QString cachePath = QString("/var/lib/bluetooth/%1/cache/%2").arg(adapter, cleanMac);
        QFile file(cachePath);
        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QTextStream in(&file);
            while (!in.atEnd()) {
                QString line = in.readLine();
                if (line.contains("112f", Qt::CaseInsensitive) || line.contains("4F4245582050686F6E65626F6F6B", Qt::CaseInsensitive)) {
                    int idx = line.indexOf("19000308", 0, Qt::CaseInsensitive);
                    if (idx != -1) {
                        bool ok = false;
                        int ch = line.mid(idx + 8, 2).toInt(&ok, 16);
                        if (ok && ch > 0 && ch <= 30) {
                            return ch;
                        }
                    }
                }
            }
        }
    }
    return 19; // Standard Phonebook Access Profile (PBAP) RFCOMM channel
}

void PbapSyncManager::syncPhone(const QString &mac)
{
    if (mac.isEmpty()) {
        qWarning() << "[PBAP] Cannot sync: MAC address is empty.";
        return;
    }

    if (m_isSyncing) {
        if (m_currentMac.compare(mac, Qt::CaseInsensitive) == 0) {
            qDebug() << "[PBAP] Sync already in progress for" << m_currentMac << ", ignoring duplicate request.";
            return;
        } else {
            qDebug() << "[PBAP] Aborting active sync for" << m_currentMac << "to switch to new priority phone:" << mac;
            cleanupSession();
            m_isSyncing = false;
        }
    }

    m_isSyncing = true;
    m_currentMac = mac;
    m_sessionPath.clear();
    m_transferPath.clear();
    m_currentStage.clear();
    m_pollCounter = 0;
    m_splitFolderStep = 0;
    m_folderSelectRetryCount = 0;
    m_callHistoryMode = CallHistoryMode::Combined;
    m_syncedCalls.clear();

    QString cleanMac = mac;
    cleanMac.replace(':', '_');
    m_contactsFilePath = QString("/root/.cache/obex/contacts_%1.vcf").arg(cleanMac);
    m_callsFilePath = QString("/root/.cache/obex/calls_%1.vcf").arg(cleanMac);
    m_tempCallFolderFilePath = QString("/root/.cache/obex/temp_folder_%1.vcf").arg(cleanMac);

    // If we have cached contacts/calls for this specific phone, load them immediately for instant UI display
    if (QFile::exists(m_contactsFilePath)) {
        parseContactsFile(m_contactsFilePath);
    }
    if (QFile::exists(m_callsFilePath)) {
        parseCallHistoryFile(m_callsFilePath);
    }

    emit syncStarted();
    m_syncTimeoutTimer->start();

    int ch = resolvePbapChannel(mac);
    qDebug() << "[PBAP] Starting background Phonebook & Call History sync for phone:" << mac << "resolved PBAP channel:" << ch;

    // Call org.bluez.obex.Client1.CreateSession(mac, {"Target": "pbap", "Channel": ch}) asynchronously (non-blocking)
    QDBusMessage msg = QDBusMessage::createMethodCall(
        "org.bluez.obex",
        "/org/bluez/obex",
        "org.bluez.obex.Client1",
        "CreateSession"
    );

    QVariantMap args;
    args["Target"] = QString("pbap");
    if (ch > 0) {
        args["Channel"] = (uchar)ch;
    }
    msg << mac << args;

    QDBusPendingCall asyncCall = QDBusConnection::systemBus().asyncCall(msg);
    QDBusPendingCallWatcher *watcher = new QDBusPendingCallWatcher(asyncCall, this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *callWatcher) {
        QDBusPendingReply<QDBusObjectPath> reply = *callWatcher;
        callWatcher->deleteLater();
        if (!m_isSyncing) return;

        if (reply.isError()) {
            qWarning() << "[PBAP] Failed to create OBEX PBAP session:" << reply.error().message();
            finishSync(false, reply.error().message());
            return;
        }

        QDBusObjectPath path = reply.value();
        m_sessionPath = path.path();
        qDebug() << "[PBAP] Session created successfully at:" << m_sessionPath;

        // Inspect version / capabilities on PhonebookAccess1 interface
        QDBusInterface pbapIf("org.bluez.obex", m_sessionPath, "org.bluez.obex.PhonebookAccess1", QDBusConnection::systemBus());
        if (pbapIf.isValid()) {
            QVariant dbId = pbapIf.property("DatabaseIdentifier");
            if (dbId.isValid() && !dbId.toString().isEmpty()) {
                m_isPbap12 = true;
                qDebug() << "[PBAP] Remote device supports PBAP 1.2+ (DatabaseIdentifier:" << dbId.toString() << ")";
            } else {
                m_isPbap12 = false;
                qDebug() << "[PBAP] Remote device is standard PBAP 1.1 / Legacy profile.";
            }
        }

        // Start Step 1: Sync Contacts
        startContactsSync();
    });
}

void PbapSyncManager::startContactsSync()
{
    if (m_sessionPath.isEmpty()) {
        finishSync(false, "No active session");
        return;
    }

    m_currentStage = "contacts";
    m_pollCounter = 0;
    qDebug() << "[PBAP] Step 1: Selecting internal phonebook (pb) asynchronously...";

    QDBusMessage selMsg = QDBusMessage::createMethodCall(
        "org.bluez.obex",
        m_sessionPath,
        "org.bluez.obex.PhonebookAccess1",
        "Select"
    );
    selMsg << QString("int") << QString("pb");

    auto selCall = QDBusConnection::systemBus().asyncCall(selMsg);
    auto *selWatcher = new QDBusPendingCallWatcher(selCall, this);
    connect(selWatcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *sw) {
        sw->deleteLater();
        if (!m_isSyncing || m_sessionPath.isEmpty()) return;

        QFile::remove(m_contactsFilePath);

        QDBusMessage pullMsg = QDBusMessage::createMethodCall(
            "org.bluez.obex",
            m_sessionPath,
            "org.bluez.obex.PhonebookAccess1",
            "PullAll"
        );
        QVariantMap filters;
        pullMsg << m_contactsFilePath << filters;

        auto pullCall = QDBusConnection::systemBus().asyncCall(pullMsg);
        auto *pullWatcher = new QDBusPendingCallWatcher(pullCall, this);
        connect(pullWatcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *pw) {
            pw->deleteLater();
            if (!m_isSyncing || m_sessionPath.isEmpty()) return;

            QDBusPendingReply<QDBusObjectPath> pullReply = *pw;
            if (pullReply.isError()) {
                qWarning() << "[PBAP] PullAll (contacts) failed:" << pullReply.error().message();
                startCallHistorySync();
                return;
            }

            m_transferPath = pullReply.value().path();
            qDebug() << "[PBAP] Contacts transfer initiated at:" << m_transferPath;

            QDBusConnection::systemBus().connect(
                "org.bluez.obex",
                m_transferPath,
                "org.freedesktop.DBus.Properties",
                "PropertiesChanged",
                this,
                SLOT(onTransferPropertiesChanged(QString,QVariantMap,QStringList))
            );

            m_pollTimer->start();
        });
    });
}

void PbapSyncManager::startCallHistorySync()
{
    if (m_sessionPath.isEmpty()) {
        finishSync(false, "No active session");
        return;
    }

    if (!m_transferPath.isEmpty()) {
        QDBusMessage cancelMsg = QDBusMessage::createMethodCall(
            "org.bluez.obex",
            m_transferPath,
            "org.bluez.obex.Transfer1",
            "Cancel"
        );
        QDBusConnection::systemBus().call(cancelMsg);
        QDBusConnection::systemBus().disconnect(
            "org.bluez.obex",
            m_transferPath,
            "org.freedesktop.DBus.Properties",
            "PropertiesChanged",
            this,
            SLOT(onTransferPropertiesChanged(QString,QVariantMap,QStringList))
        );
        m_transferPath.clear();
    }

    m_pollCounter = 0;
    m_splitFolderStep = 0;
    m_syncedCalls.clear();
    m_syncTimeoutTimer->start(90000); // 90-second stage timeout for call history

    // If remote device supports PBAP 1.2+ (modern Android 10-15 / iOS), 'cch' is optional and unsupported by modern Bluetooth stacks (Fluoride/Gabeldorsche)!
    // Directly use mandatory PBAP folders (ich, och, mch) to avoid RFCOMM transport disconnect or 25-second hangs.
    if (m_isPbap12) {
        qDebug() << "[PBAP] Modern PBAP 1.2+ device detected -> skipping optional 'cch', syncing mandatory folders directly.";
        m_callHistoryMode = CallHistoryMode::SplitFolders;
        m_splitFolderStep = 0;
        syncNextCallFolder();
        return;
    }

    m_currentStage = "calls_cch";
    m_callHistoryMode = CallHistoryMode::Combined;
    qDebug() << "[PBAP] Step 2: Preparing Call History sync (testing legacy combined 'cch')...";

    QTimer::singleShot(350, this, [this]() {
        if (!m_isSyncing || m_sessionPath.isEmpty()) return;

        qDebug() << "[PBAP] Selecting combined call history (cch) asynchronously...";
        QDBusMessage selMsg = QDBusMessage::createMethodCall(
            "org.bluez.obex",
            m_sessionPath,
            "org.bluez.obex.PhonebookAccess1",
            "Select"
        );
        selMsg << QString("int") << QString("cch");

        auto selCall = QDBusConnection::systemBus().asyncCall(selMsg);
        auto *selWatcher = new QDBusPendingCallWatcher(selCall, this);
        connect(selWatcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *sw) {
            sw->deleteLater();
            if (!m_isSyncing || m_sessionPath.isEmpty()) return;

            QDBusPendingReply<> selReply = *sw;
            if (selReply.isError()) {
                qDebug() << "[PBAP] 'cch' not supported by remote device (" << selReply.error().message() 
                         << "). Falling back to mandatory PBAP folders (ich, och, mch)...";
                m_callHistoryMode = CallHistoryMode::SplitFolders;
                m_splitFolderStep = 0;
                syncNextCallFolder();
                return;
            }

            QFile::remove(m_callsFilePath);

            QDBusMessage pullMsg = QDBusMessage::createMethodCall(
                "org.bluez.obex",
                m_sessionPath,
                "org.bluez.obex.PhonebookAccess1",
                "PullAll"
            );
            QVariantMap filters;
            pullMsg << m_callsFilePath << filters;

            auto pullCall = QDBusConnection::systemBus().asyncCall(pullMsg);
            auto *pullWatcher = new QDBusPendingCallWatcher(pullCall, this);
            connect(pullWatcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *pw) {
                pw->deleteLater();
                if (!m_isSyncing || m_sessionPath.isEmpty()) return;

                QDBusPendingReply<QDBusObjectPath> pullReply = *pw;
                if (pullReply.isError()) {
                    qDebug() << "[PBAP] PullAll on 'cch' failed (" << pullReply.error().message()
                             << "). Falling back to mandatory PBAP folders (ich, och, mch)...";
                    m_callHistoryMode = CallHistoryMode::SplitFolders;
                    m_splitFolderStep = 0;
                    syncNextCallFolder();
                    return;
                }

                m_transferPath = pullReply.value().path();
                qDebug() << "[PBAP] 'cch' transfer initiated at:" << m_transferPath;

                QDBusConnection::systemBus().connect(
                    "org.bluez.obex",
                    m_transferPath,
                    "org.freedesktop.DBus.Properties",
                    "PropertiesChanged",
                    this,
                    SLOT(onTransferPropertiesChanged(QString,QVariantMap,QStringList))
                );

                m_pollTimer->start();
            });
        });
    });
}

void PbapSyncManager::syncNextCallFolder()
{
    if (!m_isSyncing || m_sessionPath.isEmpty()) return;

    if (!m_transferPath.isEmpty()) {
        QDBusMessage cancelMsg = QDBusMessage::createMethodCall(
            "org.bluez.obex",
            m_transferPath,
            "org.bluez.obex.Transfer1",
            "Cancel"
        );
        QDBusConnection::systemBus().call(cancelMsg);
        QDBusConnection::systemBus().disconnect(
            "org.bluez.obex",
            m_transferPath,
            "org.freedesktop.DBus.Properties",
            "PropertiesChanged",
            this,
            SLOT(onTransferPropertiesChanged(QString,QVariantMap,QStringList))
        );
        m_transferPath.clear();
    }

    if (m_splitFolderStep >= 3) {
        qDebug() << "[PBAP] All mandatory call history folders (ich, och, mch) synced. Total records:" << m_syncedCalls.size();

        // Sort all aggregated calls newest first
        std::sort(m_syncedCalls.begin(), m_syncedCalls.end(), [](const QVariant &a, const QVariant &b) {
            qint64 tA = a.toMap().value("timestamp", 0).toLongLong();
            qint64 tB = b.toMap().value("timestamp", 0).toLongLong();
            return tA > tB;
        });

        if (!m_syncedCalls.isEmpty()) {
            emit callHistoryUpdated(m_syncedCalls);
        }

        finishSync(true);
        return;
    }

    QString folderName;
    QString defaultType;
    if (m_splitFolderStep == 0) {
        folderName = "ich"; // Incoming calls (Mandatory in PBAP)
        m_currentStage = "calls_ich";
        defaultType = "RECEIVED";
    } else if (m_splitFolderStep == 1) {
        folderName = "och"; // Outgoing / Dialed calls (Mandatory in PBAP)
        m_currentStage = "calls_och";
        defaultType = "DIALED";
    } else if (m_splitFolderStep == 2) {
        folderName = "mch"; // Missed calls (Mandatory in PBAP)
        m_currentStage = "calls_mch";
        defaultType = "MISSED";
    }

    m_pollCounter = 0;
    qDebug() << "[PBAP] Syncing mandatory PBAP folder:" << folderName << "(step" << m_splitFolderStep << "/ 3)...";

    QTimer::singleShot(250, this, [this, folderName, defaultType]() {
        if (!m_isSyncing || m_sessionPath.isEmpty()) return;

        QDBusMessage selMsg = QDBusMessage::createMethodCall(
            "org.bluez.obex",
            m_sessionPath,
            "org.bluez.obex.PhonebookAccess1",
            "Select"
        );
        selMsg << QString("int") << folderName;

        auto selCall = QDBusConnection::systemBus().asyncCall(selMsg);
        auto *selWatcher = new QDBusPendingCallWatcher(selCall, this);
        connect(selWatcher, &QDBusPendingCallWatcher::finished, this, [this, folderName, defaultType](QDBusPendingCallWatcher *sw) {
            sw->deleteLater();
            if (!m_isSyncing || m_sessionPath.isEmpty()) return;

            QDBusPendingReply<> selReply = *sw;
            if (selReply.isError()) {
                // Some Android PBAP implementations reply "Continue" while
                // their phonebook transfer is being finalized.  It is a
                // transient OBEX state, not an unsupported call-history
                // folder.  Retrying preserves incoming/outgoing/missed IDs.
                if (selReply.error().message().compare("Continue", Qt::CaseInsensitive) == 0
                    && m_folderSelectRetryCount < 5) {
                    ++m_folderSelectRetryCount;
                    qDebug() << "[PBAP] Folder" << folderName << "is still busy; retry"
                             << m_folderSelectRetryCount << "of 5";
                    QTimer::singleShot(1000, this, [this]() { syncNextCallFolder(); });
                    return;
                }
                qWarning() << "[PBAP] Select failed for folder" << folderName << ":" << selReply.error().message() << "- skipping to next folder";
                m_folderSelectRetryCount = 0;
                m_splitFolderStep++;
                syncNextCallFolder();
                return;
            }

            m_folderSelectRetryCount = 0;

            QFile::remove(m_tempCallFolderFilePath);

            QDBusMessage pullMsg = QDBusMessage::createMethodCall(
                "org.bluez.obex",
                m_sessionPath,
                "org.bluez.obex.PhonebookAccess1",
                "PullAll"
            );
            QVariantMap filters;
            pullMsg << m_tempCallFolderFilePath << filters;

            auto pullCall = QDBusConnection::systemBus().asyncCall(pullMsg);
            auto *pullWatcher = new QDBusPendingCallWatcher(pullCall, this);
            connect(pullWatcher, &QDBusPendingCallWatcher::finished, this, [this, folderName, defaultType](QDBusPendingCallWatcher *pw) {
                pw->deleteLater();
                if (!m_isSyncing || m_sessionPath.isEmpty()) return;

                QDBusPendingReply<QDBusObjectPath> pullReply = *pw;
                if (pullReply.isError()) {
                    qWarning() << "[PBAP] PullAll failed for folder" << folderName << ":" << pullReply.error().message() << "- skipping to next folder";
                    m_splitFolderStep++;
                    syncNextCallFolder();
                    return;
                }

                m_transferPath = pullReply.value().path();
                qDebug() << "[PBAP] Folder" << folderName << "transfer initiated at:" << m_transferPath;

                QDBusConnection::systemBus().connect(
                    "org.bluez.obex",
                    m_transferPath,
                    "org.freedesktop.DBus.Properties",
                    "PropertiesChanged",
                    this,
                    SLOT(onTransferPropertiesChanged(QString,QVariantMap,QStringList))
                );

                m_pollTimer->start();
            });
        });
    });
}

void PbapSyncManager::onTransferPropertiesChanged(const QString &interface, const QVariantMap &changedProps, const QStringList &invalidatedProps)
{
    Q_UNUSED(interface);
    Q_UNUSED(invalidatedProps);

    if (changedProps.contains("Status")) {
        QString status = changedProps.value("Status").toString();
        qDebug() << "[PBAP] Transfer status changed to:" << status << "for stage:" << m_currentStage;

        if (status == "complete") {
            m_pollTimer->stop();
            if (m_currentStage == "contacts") {
                m_currentStage = "transitioning";
                parseContactsFile(m_contactsFilePath);
                startCallHistorySync();
            } else if (m_currentStage == "calls_cch") {
                QFileInfo fi(m_callsFilePath);
                if (fi.exists() && fi.size() > 50) {
                    parseCallHistoryFile(m_callsFilePath);
                    if (!m_syncedCalls.isEmpty()) {
                        finishSync(true);
                        return;
                    }
                }
                // Fallback to split folders if cch returned 0 records
                qDebug() << "[PBAP] 'cch' transfer produced 0 records. Falling back to mandatory folders...";
                m_callHistoryMode = CallHistoryMode::SplitFolders;
                m_splitFolderStep = 0;
                syncNextCallFolder();
            } else if (m_currentStage == "calls_ich") {
                parseVCardCalls(m_tempCallFolderFilePath, "RECEIVED");
                m_splitFolderStep = 1;
                syncNextCallFolder();
            } else if (m_currentStage == "calls_och") {
                parseVCardCalls(m_tempCallFolderFilePath, "DIALED");
                m_splitFolderStep = 2;
                syncNextCallFolder();
            } else if (m_currentStage == "calls_mch") {
                parseVCardCalls(m_tempCallFolderFilePath, "MISSED");
                m_splitFolderStep = 3;
                syncNextCallFolder();
            }
        } else if (status == "error") {
            qWarning() << "[PBAP] Transfer reported error status for stage:" << m_currentStage;
            m_pollTimer->stop();
            if (m_currentStage == "contacts") {
                m_currentStage = "transitioning";
                startCallHistorySync();
            } else if (m_currentStage == "calls_cch") {
                m_callHistoryMode = CallHistoryMode::SplitFolders;
                m_splitFolderStep = 0;
                syncNextCallFolder();
            } else if (m_currentStage.startsWith("calls_")) {
                // Non-fatal: advance to next folder
                m_splitFolderStep++;
                syncNextCallFolder();
            } else {
                finishSync(false, "Transfer error");
            }
        }
    }
}

void PbapSyncManager::pollTransferStatus()
{
    m_pollCounter++;

    // Safety fallback: if status signal was dropped and transfer file exists
    if (m_pollCounter >= 25) {
        if (m_currentStage == "contacts") {
            QFileInfo fi(m_contactsFilePath);
            if (fi.exists() && fi.size() > 100) {
                m_pollTimer->stop();
                m_currentStage = "transitioning";
                parseContactsFile(m_contactsFilePath);
                startCallHistorySync();
                return;
            }
        } else if (m_currentStage == "calls_cch") {
            QFileInfo fi(m_callsFilePath);
            if (fi.exists() && fi.size() > 50) {
                m_pollTimer->stop();
                parseCallHistoryFile(m_callsFilePath);
                if (!m_syncedCalls.isEmpty()) {
                    finishSync(true);
                    return;
                }
            }
            m_pollTimer->stop();
            m_callHistoryMode = CallHistoryMode::SplitFolders;
            m_splitFolderStep = 0;
            syncNextCallFolder();
            return;
        } else if (m_currentStage == "calls_ich") {
            m_pollTimer->stop();
            parseVCardCalls(m_tempCallFolderFilePath, "RECEIVED");
            m_splitFolderStep = 1;
            syncNextCallFolder();
            return;
        } else if (m_currentStage == "calls_och") {
            m_pollTimer->stop();
            parseVCardCalls(m_tempCallFolderFilePath, "DIALED");
            m_splitFolderStep = 2;
            syncNextCallFolder();
            return;
        } else if (m_currentStage == "calls_mch") {
            m_pollTimer->stop();
            parseVCardCalls(m_tempCallFolderFilePath, "MISSED");
            m_splitFolderStep = 3;
            syncNextCallFolder();
            return;
        }
    }

    // Lightweight async query if transfer path exists
    if (!m_transferPath.isEmpty()) {
        QDBusMessage getStatus = QDBusMessage::createMethodCall("org.bluez.obex", m_transferPath, "org.freedesktop.DBus.Properties", "Get");
        getStatus << QString("org.bluez.obex.Transfer1") << QString("Status");
        auto call = QDBusConnection::systemBus().asyncCall(getStatus);
        auto *watcher = new QDBusPendingCallWatcher(call, this);
        connect(watcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *w) {
            w->deleteLater();
            if (!m_isSyncing) return;
            QDBusPendingReply<QDBusVariant> reply = *w;
            if (reply.isValid()) {
                QString status = reply.value().variant().toString();
                if (status == "complete") {
                    m_pollTimer->stop();
                    if (m_currentStage == "contacts") {
                        m_currentStage = "transitioning";
                        parseContactsFile(m_contactsFilePath);
                        startCallHistorySync();
                    } else if (m_currentStage == "calls_cch") {
                        QFileInfo fi(m_callsFilePath);
                        if (fi.exists() && fi.size() > 50) {
                            parseCallHistoryFile(m_callsFilePath);
                            if (!m_syncedCalls.isEmpty()) {
                                finishSync(true);
                                return;
                            }
                        }
                        m_callHistoryMode = CallHistoryMode::SplitFolders;
                        m_splitFolderStep = 0;
                        syncNextCallFolder();
                    } else if (m_currentStage == "calls_ich") {
                        parseVCardCalls(m_tempCallFolderFilePath, "RECEIVED");
                        m_splitFolderStep = 1;
                        syncNextCallFolder();
                    } else if (m_currentStage == "calls_och") {
                        parseVCardCalls(m_tempCallFolderFilePath, "DIALED");
                        m_splitFolderStep = 2;
                        syncNextCallFolder();
                    } else if (m_currentStage == "calls_mch") {
                        parseVCardCalls(m_tempCallFolderFilePath, "MISSED");
                        m_splitFolderStep = 3;
                        syncNextCallFolder();
                    }
                } else if (status == "error") {
                    m_pollTimer->stop();
                    if (m_currentStage == "contacts") {
                        m_currentStage = "transitioning";
                        startCallHistorySync();
                    } else if (m_currentStage == "calls_cch") {
                        m_callHistoryMode = CallHistoryMode::SplitFolders;
                        m_splitFolderStep = 0;
                        syncNextCallFolder();
                    } else if (m_currentStage.startsWith("calls_")) {
                        m_splitFolderStep++;
                        syncNextCallFolder();
                    } else {
                        finishSync(false, "Transfer error");
                    }
                }
            }
        });
    }

    // Timeout after ~90 seconds per stage for very large phonebooks
    if (m_pollCounter >= 120) {
        qDebug() << "[PBAP] Stage" << m_currentStage << "poll timeout, moving forward...";
        m_pollTimer->stop();
        if (!m_transferPath.isEmpty()) {
            QDBusMessage cancelMsg = QDBusMessage::createMethodCall(
                "org.bluez.obex",
                m_transferPath,
                "org.bluez.obex.Transfer1",
                "Cancel"
            );
            QDBusConnection::systemBus().call(cancelMsg);
            m_transferPath.clear();
        }
        if (m_currentStage == "contacts") {
            m_currentStage = "transitioning";
            parseContactsFile(m_contactsFilePath);
            startCallHistorySync();
        } else if (m_currentStage == "calls_cch") {
            m_callHistoryMode = CallHistoryMode::SplitFolders;
            m_splitFolderStep = 0;
            syncNextCallFolder();
        } else if (m_currentStage.startsWith("calls_")) {
            m_splitFolderStep++;
            syncNextCallFolder();
        }
    }
}

QString PbapSyncManager::lookupContactName(const QString &rawNumber) const
{
    if (rawNumber.isEmpty()) return QString();
    QString cleanNum = rawNumber;
    cleanNum.remove(QRegularExpression("[^0-9+]"));

    for (const auto &c : m_syncedContacts) {
        auto map = c.toMap();
        QString cNum = map["number"].toString();
        cNum.remove(QRegularExpression("[^0-9+]"));
        if (!cNum.isEmpty() && (cNum == cleanNum || (cleanNum.length() >= 7 && cNum.endsWith(cleanNum.right(7))))) {
            return map["name"].toString();
        }
    }
    return QString();
}

void PbapSyncManager::parseContactsFile(const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "[PBAP] Cannot open contacts file:" << filePath;
        return;
    }

    QVariantList parsedList;
    QTextStream in(&file);
    QString currentName;
    QString currentTel;

    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        if (line.startsWith("FN:", Qt::CaseInsensitive)) {
            currentName = line.mid(3).trimmed();
        } else if (line.startsWith("FN;", Qt::CaseInsensitive)) {
            int colonIdx = line.indexOf(':');
            if (colonIdx != -1) {
                currentName = line.mid(colonIdx + 1).trimmed();
            }
        } else if (line.startsWith("N:", Qt::CaseInsensitive) && currentName.isEmpty()) {
            QString nParts = line.mid(2).trimmed();
            QStringList parts = nParts.split(';');
            QString last = parts.value(0).trimmed();
            QString first = parts.value(1).trimmed();
            if (!first.isEmpty() && !last.isEmpty()) {
                currentName = first + " " + last;
            } else if (!first.isEmpty()) {
                currentName = first;
            } else if (!last.isEmpty()) {
                currentName = last;
            }
        } else if (line.startsWith("N;", Qt::CaseInsensitive) && currentName.isEmpty()) {
            int colonIdx = line.indexOf(':');
            if (colonIdx != -1) {
                QString nParts = line.mid(colonIdx + 1).trimmed();
                QStringList parts = nParts.split(';');
                QString last = parts.value(0).trimmed();
                QString first = parts.value(1).trimmed();
                if (!first.isEmpty() && !last.isEmpty()) {
                    currentName = first + " " + last;
                } else if (!first.isEmpty()) {
                    currentName = first;
                } else if (!last.isEmpty()) {
                    currentName = last;
                }
            }
        } else if (line.startsWith("TEL", Qt::CaseInsensitive)) {
            int colonIdx = line.indexOf(':');
            if (colonIdx != -1) {
                QString number = line.mid(colonIdx + 1).trimmed();
                if (!number.isEmpty()) {
                    currentTel = number;
                }
            }
        } else if (line.compare("END:VCARD", Qt::CaseInsensitive) == 0) {
            if (!currentName.isEmpty() || !currentTel.isEmpty()) {
                if (currentName.isEmpty()) currentName = currentTel;
                QString initial = currentName.left(1).toUpper();
                if (initial.isEmpty() || !initial.at(0).isLetter()) initial = "#";

                QVariantMap cMap;
                cMap["name"] = currentName;
                cMap["number"] = currentTel;
                cMap["initial"] = initial;
                parsedList.append(cMap);
            }
            currentName.clear();
            currentTel.clear();
        }
    }
    file.close();

    // Sort contacts alphabetically
    std::sort(parsedList.begin(), parsedList.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap()["name"].toString().localeAwareCompare(b.toMap()["name"].toString()) < 0;
    });

    if (!parsedList.isEmpty()) {
        m_syncedContacts = parsedList;
        // Also update standard contacts.vcf cache
        QFile::remove("/root/.cache/obex/contacts.vcf");
        QFile::copy(filePath, "/root/.cache/obex/contacts.vcf");

        qDebug() << "[PBAP] Successfully parsed" << m_syncedContacts.size() << "contacts from phone!";
        emit contactsUpdated(m_syncedContacts);
    }
}

void PbapSyncManager::parseVCardCalls(const QString &filePath, const QString &defaultType)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "[PBAP] Cannot open calls vcard file:" << filePath;
        return;
    }

    QTextStream in(&file);
    QString currentName;
    QString currentTel;
    QString currentDate;
    qint64 currentTimestamp = 0;
    QString callType = defaultType;

    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        if (line.startsWith("FN:", Qt::CaseInsensitive)) {
            currentName = line.mid(3).trimmed();
        } else if (line.startsWith("FN;", Qt::CaseInsensitive)) {
            int colonIdx = line.indexOf(':');
            if (colonIdx != -1) {
                currentName = line.mid(colonIdx + 1).trimmed();
            }
        } else if (line.startsWith("N:", Qt::CaseInsensitive) && currentName.isEmpty()) {
            QString nParts = line.mid(2).trimmed();
            QStringList parts = nParts.split(';');
            QString last = parts.value(0).trimmed();
            QString first = parts.value(1).trimmed();
            if (!first.isEmpty() && !last.isEmpty()) {
                currentName = first + " " + last;
            } else if (!first.isEmpty()) {
                currentName = first;
            } else if (!last.isEmpty()) {
                currentName = last;
            }
        } else if (line.startsWith("N;", Qt::CaseInsensitive) && currentName.isEmpty()) {
            int colonIdx = line.indexOf(':');
            if (colonIdx != -1) {
                QString nParts = line.mid(colonIdx + 1).trimmed();
                QStringList parts = nParts.split(';');
                QString last = parts.value(0).trimmed();
                QString first = parts.value(1).trimmed();
                if (!first.isEmpty() && !last.isEmpty()) {
                    currentName = first + " " + last;
                } else if (!first.isEmpty()) {
                    currentName = first;
                } else if (!last.isEmpty()) {
                    currentName = last;
                }
            }
        } else if (line.startsWith("TEL", Qt::CaseInsensitive)) {
            int colonIdx = line.indexOf(':');
            if (colonIdx != -1) {
                currentTel = line.mid(colonIdx + 1).trimmed();
            }
        } else if (line.startsWith("X-IRMC-CALL-DATETIME", Qt::CaseInsensitive) || line.startsWith("DATETIME", Qt::CaseInsensitive)) {
            if (line.contains("MISSED", Qt::CaseInsensitive)) callType = "MISSED";
            else if (line.contains("RECEIVED", Qt::CaseInsensitive) || line.contains("INCOMING", Qt::CaseInsensitive)) callType = "RECEIVED";
            else if (line.contains("DIALED", Qt::CaseInsensitive) || line.contains("OUTGOING", Qt::CaseInsensitive)) callType = "DIALED";

            int colonIdx = line.indexOf(':');
            if (colonIdx != -1) {
                QString dtStr = line.mid(colonIdx + 1).trimmed();
                QDateTime dt;
                if (dtStr.contains("-")) {
                    dt = QDateTime::fromString(dtStr.left(19), Qt::ISODate);
                } else {
                    // Standard IRMC 24-hour timestamp format: YYYYMMDDTHHmmss
                    dt = QDateTime::fromString(dtStr.left(15), "yyyyMMddTHHmmss");
                }

                if (dt.isValid()) {
                    currentTimestamp = dt.toSecsSinceEpoch();
                    if (dt.date() == QDate::currentDate()) {
                        currentDate = dt.toString("h:mm AP");
                    } else {
                        currentDate = dt.toString("MM-dd-yyyy");
                    }
                } else {
                    currentDate = "Recent";
                }
            }
        } else if (line.compare("END:VCARD", Qt::CaseInsensitive) == 0) {
            if (!currentName.isEmpty() || !currentTel.isEmpty()) {
                if (currentName.isEmpty()) {
                    currentName = lookupContactName(currentTel);
                }
                if (currentName.isEmpty()) {
                    currentName = currentTel;
                }
                if (currentDate.isEmpty()) currentDate = "Recent";

                QVariantMap cMap;
                cMap["name"] = currentName;
                cMap["number"] = currentTel;
                cMap["date"] = currentDate;
                cMap["type"] = callType;
                cMap["isMissed"] = (callType == "MISSED");
                cMap["isIncoming"] = (callType == "RECEIVED");
                cMap["timestamp"] = currentTimestamp;
                m_syncedCalls.append(cMap);
            }
            currentName.clear();
            currentTel.clear();
            currentDate.clear();
            currentTimestamp = 0;
            callType = defaultType;
        }
    }
    file.close();
    qDebug() << "[PBAP] Parsed" << filePath << "with default type:" << defaultType 
             << "Total accumulated calls so far:" << m_syncedCalls.size();
}

void PbapSyncManager::parseCallHistoryFile(const QString &filePath)
{
    m_syncedCalls.clear();
    parseVCardCalls(filePath, "MISSED");

    if (!m_syncedCalls.isEmpty()) {
        std::sort(m_syncedCalls.begin(), m_syncedCalls.end(), [](const QVariant &a, const QVariant &b) {
            return a.toMap().value("timestamp", 0).toLongLong() > b.toMap().value("timestamp", 0).toLongLong();
        });

        // Keep newest call records, skip older ones per user requirement
        if (m_syncedCalls.size() > 25) {
            m_syncedCalls = m_syncedCalls.mid(0, 25);
        }

        QFile::remove("/root/.cache/obex/calls.vcf");
        QFile::copy(filePath, "/root/.cache/obex/calls.vcf");

        qDebug() << "[PBAP] Successfully parsed and kept newest" << m_syncedCalls.size() << "call history records from phone!";
        emit callHistoryUpdated(m_syncedCalls);
    }
}

void PbapSyncManager::finishSync(bool success, const QString &message)
{
    qDebug() << "[PBAP] Sync finished. Success:" << success << "Message:" << message;
    cleanupSession();
    m_isSyncing = false;
    emit syncFinished(success, message);
}

void PbapSyncManager::cleanupSession()
{
    m_pollTimer->stop();
    m_syncTimeoutTimer->stop();

    if (!m_transferPath.isEmpty()) {
        QDBusConnection::systemBus().disconnect(
            "org.bluez.obex",
            m_transferPath,
            "org.freedesktop.DBus.Properties",
            "PropertiesChanged",
            this,
            SLOT(onTransferPropertiesChanged(QString,QVariantMap,QStringList))
        );
        m_transferPath.clear();
    }

    if (!m_sessionPath.isEmpty()) {
        qDebug() << "[PBAP] Cleaning up OBEX session asynchronously:" << m_sessionPath;
        QDBusMessage remMsg = QDBusMessage::createMethodCall(
            "org.bluez.obex",
            "/org/bluez/obex",
            "org.bluez.obex.Client1",
            "RemoveSession"
        );
        remMsg << QDBusObjectPath(m_sessionPath);
        QDBusConnection::systemBus().asyncCall(remMsg);
        m_sessionPath.clear();
    }
}

void PbapSyncManager::onSyncTimeout()
{
    qWarning() << "[PBAP] Global sync timeout reached.";
    m_pollTimer->stop();

    QFileInfo cFi(m_contactsFilePath);
    if (cFi.exists() && cFi.size() > 0 && m_syncedContacts.isEmpty()) {
        parseContactsFile(m_contactsFilePath);
    }

    QFileInfo clFi(m_callsFilePath);
    if (clFi.exists() && clFi.size() > 0 && m_syncedCalls.isEmpty()) {
        parseCallHistoryFile(m_callsFilePath);
    }

    finishSync(!m_syncedContacts.isEmpty() || !m_syncedCalls.isEmpty(), "Timeout completed");
}
