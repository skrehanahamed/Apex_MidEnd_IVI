#ifndef PBAPSYNCMANAGER_HPP
#define PBAPSYNCMANAGER_HPP

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusObjectPath>
#include <QTimer>

class PbapSyncManager : public QObject
{
    Q_OBJECT

public:
    explicit PbapSyncManager(QObject *parent = nullptr);
    ~PbapSyncManager() override;

    bool isSyncing() const { return m_isSyncing; }
    void syncPhone(const QString &mac);

signals:
    void syncStarted();
    void syncFinished(bool success, const QString &message);
    void contactsUpdated(const QVariantList &contacts);
    void callHistoryUpdated(const QVariantList &calls);

private slots:
    void onTransferPropertiesChanged(const QString &interface, const QVariantMap &changedProps, const QStringList &invalidatedProps);
    void onSyncTimeout();
    void pollTransferStatus();

private:
    void startContactsSync();
    void startCallHistorySync();
    void syncNextCallFolder();
    void cleanupSession();
    void parseContactsFile(const QString &filePath);
    void parseCallHistoryFile(const QString &filePath);
    void parseVCardCalls(const QString &filePath, const QString &defaultType);
    QString lookupContactName(const QString &rawNumber) const;
    void finishSync(bool success, const QString &message = QString());

    bool m_isSyncing{false};
    QString m_currentMac;
    QString m_sessionPath;
    QString m_transferPath;
    QString m_currentStage; // "contacts", "calls_cch", "calls_ich", "calls_och", "calls_mch"

    enum class CallHistoryMode {
        Combined,       // Try telecom/cch.vcf (PBAP 1.1 / flat stack)
        SplitFolders    // Mandatory PBAP 1.2+ fallback: ich -> och -> mch
    };
    CallHistoryMode m_callHistoryMode{CallHistoryMode::Combined};
    int m_splitFolderStep{0}; // 0: ich, 1: och, 2: mch
    int m_folderSelectRetryCount{0};
    bool m_isPbap12{false};
    
    QTimer *m_syncTimeoutTimer{nullptr};
    QTimer *m_pollTimer{nullptr};
    int m_pollCounter{0};

    QVariantList m_syncedContacts;
    QVariantList m_syncedCalls;

    QString m_contactsFilePath{"/root/.cache/obex/contacts.vcf"};
    QString m_callsFilePath{"/root/.cache/obex/calls.vcf"};
    QString m_tempCallFolderFilePath{"/root/.cache/obex/temp_folder.vcf"};
};

#endif // PBAPSYNCMANAGER_HPP
