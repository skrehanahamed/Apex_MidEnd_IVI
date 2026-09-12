/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: SystemController.hpp
 * ============================================================================
 */

#pragma once

#include <QObject>
#include <QString>
#include <QTimer>
#include <QDateTime>
#include <QThread>
#include <QSet>
#include <QProcess>
#include <QRandomGenerator>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QFile>
#include <QDir>
#include <QStandardPaths>

class QMediaPlayer;
class QAudioOutput;
class QMediaCaptureSession;
class QAudioInput;
class QMediaRecorder;
class QSoundEffect;
class NativeAudioRecorder;
class BluezBluetoothManager;
class PbapSyncManager;

class RadioStreamWorker : public QObject {
    Q_OBJECT
public:
    explicit RadioStreamWorker(QObject *parent = nullptr);
    ~RadioStreamWorker() override;

public slots:
    void init();
    void playStream(const QString &urlStr);
    void pause();
    void resume();
    void stop();
    void setVolume(float volume);
    void cleanup();

signals:
    void playbackStateChanged(bool playing);
    void mediaStatusChanged(bool loading);

private:
    QProcess *m_process{nullptr};
    QString m_currentUrl;
    float m_volume{0.65f};
};


class SystemController : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isVoiceRecording READ isVoiceRecording NOTIFY voiceRecordingChanged)
    Q_PROPERTY(bool isVoiceRecordingPaused READ isVoiceRecordingPaused NOTIFY voiceRecordingChanged)
    Q_PROPERTY(int recordingSeconds READ recordingSeconds NOTIFY voiceRecordingChanged)
    Q_PROPERTY(QString recordingTimeFormatted READ recordingTimeFormatted NOTIFY voiceRecordingChanged)
    Q_PROPERTY(int voiceRecordLevel READ voiceRecordLevel WRITE setVoiceRecordLevel NOTIFY voiceRecordLevelChanged)
    Q_PROPERTY(QVariantList voiceMemoList READ voiceMemoList NOTIFY voiceMemoListChanged)
    Q_PROPERTY(bool isPlayingVoiceMemo READ isPlayingVoiceMemo NOTIFY voiceMemoPlaybackChanged)
    Q_PROPERTY(int activeVoiceMemoIndex READ activeVoiceMemoIndex NOTIFY voiceMemoPlaybackChanged)
    Q_PROPERTY(qint64 voiceMemoPosition READ voiceMemoPosition NOTIFY voiceMemoPlaybackChanged)
    Q_PROPERTY(qint64 voiceMemoDuration READ voiceMemoDuration NOTIFY voiceMemoPlaybackChanged)
    Q_PROPERTY(QString currentTime READ currentTime NOTIFY timeChanged)
    Q_PROPERTY(QString currentAmPm READ currentAmPm NOTIFY timeChanged)
    Q_PROPERTY(QString currentDate READ currentDate NOTIFY timeChanged)
    Q_PROPERTY(QString fullDate READ fullDate NOTIFY timeChanged)
    Q_PROPERTY(int volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(int maxVolume READ maxVolume CONSTANT)
    Q_PROPERTY(QString currentScreen READ currentScreen WRITE setCurrentScreen NOTIFY screenChanged)
    Q_PROPERTY(bool radioPlaying READ isRadioPlaying NOTIFY radioStateChanged)
    Q_PROPERTY(QString radioStation READ radioStation NOTIFY radioStationChanged)
    Q_PROPERTY(QString previousStationFrequency READ previousStationFrequency NOTIFY radioStationChanged)
    Q_PROPERTY(QString nextStationFrequency READ nextStationFrequency NOTIFY radioStationChanged)
    Q_PROPERTY(QString selectedMediaSource READ selectedMediaSource WRITE setSelectedMediaSource NOTIFY selectedMediaSourceChanged)
    Q_PROPERTY(QString radioBand READ radioBand WRITE setRadioBand NOTIFY radioBandChanged)
    Q_PROPERTY(QString currentStationName READ currentStationName NOTIFY currentStationNameChanged)
    Q_PROPERTY(QString currentRdsInfo READ currentRdsInfo NOTIFY currentRdsInfoChanged)
    Q_PROPERTY(bool isStationFavorited READ isStationFavorited NOTIFY isStationFavoritedChanged)
    Q_PROPERTY(QVariantList stationList READ stationList NOTIFY stationListChanged)
    Q_PROPERTY(QString radioServerUrl READ radioServerUrl WRITE setRadioServerUrl NOTIFY radioServerUrlChanged)
    Q_PROPERTY(bool radioServerOnline READ radioServerOnline NOTIFY radioServerOnlineChanged)
    Q_PROPERTY(bool radioLoading READ radioLoading NOTIFY radioLoadingChanged)
    Q_PROPERTY(bool usbConnected READ usbConnected WRITE setUsbConnected NOTIFY usbConnectedChanged)
    Q_PROPERTY(int currentStationIndex READ currentStationIndex NOTIFY currentStationIndexChanged)
    Q_PROPERTY(bool phoneConnected READ isPhoneConnected NOTIFY phoneConnectionChanged)
    Q_PROPERTY(bool isBluetoothConnected READ isBluetoothConnected WRITE setBluetoothConnected NOTIFY bluetoothConnectionChanged)
    Q_PROPERTY(QString leftWidget READ leftWidget WRITE setLeftWidget NOTIFY widgetsChanged)
    Q_PROPERTY(QString rightWidget READ rightWidget WRITE setRightWidget NOTIFY widgetsChanged)
    Q_PROPERTY(QString editingWidgetSide READ editingWidgetSide WRITE setEditingWidgetSide NOTIFY editingWidgetSideChanged)
    Q_PROPERTY(QStringList dockIcons READ dockIcons WRITE setDockIcons NOTIFY dockIconsChanged)
    Q_PROPERTY(bool beepEnabled READ beepEnabled WRITE setBeepEnabled NOTIFY soundSettingsChanged)
    Q_PROPERTY(bool quietModeEnabled READ quietModeEnabled WRITE setQuietModeEnabled NOTIFY quietModeChanged)
    Q_PROPERTY(bool volumeLimitationOnStartup READ volumeLimitationOnStartup WRITE setVolumeLimitationOnStartup NOTIFY soundSettingsChanged)
    Q_PROPERTY(QString speedDependentVolume READ speedDependentVolume WRITE setSpeedDependentVolume NOTIFY soundSettingsChanged)
    Q_PROPERTY(int treble READ treble WRITE setTreble NOTIFY soundSettingsChanged)
    Q_PROPERTY(int midrange READ midrange WRITE setMidrange NOTIFY soundSettingsChanged)
    Q_PROPERTY(int bass READ bass WRITE setBass NOTIFY soundSettingsChanged)
    Q_PROPERTY(int fader READ fader WRITE setFader NOTIFY soundSettingsChanged)
    Q_PROPERTY(int balance READ balance WRITE setBalance NOTIFY soundSettingsChanged)
    Q_PROPERTY(int guidanceBeepVolume READ guidanceBeepVolume WRITE setGuidanceBeepVolume NOTIFY soundSettingsChanged)
    Q_PROPERTY(int guidanceRingtoneVolume READ guidanceRingtoneVolume WRITE setGuidanceRingtoneVolume NOTIFY soundSettingsChanged)
    Q_PROPERTY(int guidanceAlertsVolume READ guidanceAlertsVolume WRITE setGuidanceAlertsVolume NOTIFY soundSettingsChanged)
    Q_PROPERTY(QString radioNoiseOption READ radioNoiseOption WRITE setRadioNoiseOption NOTIFY soundSettingsChanged)
    Q_PROPERTY(bool parkingSafetyPriority READ parkingSafetyPriority WRITE setParkingSafetyPriority NOTIFY soundSettingsChanged)
    Q_PROPERTY(int projectionMediaVolume READ projectionMediaVolume WRITE setProjectionMediaVolume NOTIFY soundSettingsChanged)
    Q_PROPERTY(int projectionVoiceVolume READ projectionVoiceVolume WRITE setProjectionVoiceVolume NOTIFY soundSettingsChanged)
    Q_PROPERTY(QString selectedProjectionDevice READ selectedProjectionDevice WRITE setSelectedProjectionDevice NOTIFY soundSettingsChanged)
    Q_PROPERTY(QVariantList bluetoothDeviceList READ bluetoothDeviceList NOTIFY bluetoothDeviceListChanged)
    Q_PROPERTY(int activeDeviceIndex READ activeDeviceIndex NOTIFY bluetoothDeviceListChanged)
    Q_PROPERTY(bool hasHandsFreeDevice READ hasHandsFreeDevice NOTIFY bluetoothDeviceListChanged)
    Q_PROPERTY(QString activeHandsFreeDeviceName READ activeHandsFreeDeviceName NOTIFY bluetoothDeviceListChanged)
    Q_PROPERTY(QVariantList callHistory READ callHistory NOTIFY callHistoryChanged)
    Q_PROPERTY(QVariantList contactsList READ contactsList NOTIFY contactsListChanged)
    Q_PROPERTY(int contactsCount READ contactsCount NOTIFY contactsCountChanged)
    Q_PROPERTY(int callHistoryCount READ callHistoryCount NOTIFY callHistoryCountChanged)
    Q_PROPERTY(bool isSyncingContacts READ isSyncingContacts NOTIFY isSyncingContactsChanged)
    Q_PROPERTY(int phoneBatteryLevel READ phoneBatteryLevel NOTIFY phoneBatteryLevelChanged)
    Q_PROPERTY(int phoneSignalLevel READ phoneSignalLevel NOTIFY phoneSignalLevelChanged)
    Q_PROPERTY(QString cellularCarrierName READ cellularCarrierName NOTIFY cellularCarrierNameChanged)
    Q_PROPERTY(QString detectedBluetoothName READ detectedBluetoothName NOTIFY detectedBluetoothNameChanged)
    Q_PROPERTY(bool bluetoothCallActive READ bluetoothCallActive NOTIFY bluetoothCallActiveChanged)
    Q_PROPERTY(QString bluetoothCallStatus READ bluetoothCallStatus NOTIFY bluetoothCallStatusChanged)
    Q_PROPERTY(QString bluetoothCallNumber READ bluetoothCallNumber NOTIFY bluetoothCallNumberChanged)
    Q_PROPERTY(QString bluetoothCallName READ bluetoothCallName NOTIFY bluetoothCallNameChanged)

    // Bluetooth Media Playback & Track Metadata
    Q_PROPERTY(QString bluetoothTrackTitle READ bluetoothTrackTitle NOTIFY bluetoothTrackChanged)
    Q_PROPERTY(QString bluetoothTrackArtist READ bluetoothTrackArtist NOTIFY bluetoothTrackChanged)
    Q_PROPERTY(QString bluetoothTrackAlbum READ bluetoothTrackAlbum NOTIFY bluetoothTrackChanged)
    Q_PROPERTY(int bluetoothTrackDurationMs READ bluetoothTrackDurationMs NOTIFY bluetoothTrackChanged)
    Q_PROPERTY(int bluetoothTrackPositionMs READ bluetoothTrackPositionMs NOTIFY bluetoothTrackPositionChanged)
    Q_PROPERTY(QString bluetoothTrackDurationStr READ bluetoothTrackDurationStr NOTIFY bluetoothTrackChanged)
    Q_PROPERTY(QString bluetoothTrackPositionStr READ bluetoothTrackPositionStr NOTIFY bluetoothTrackPositionChanged)
    Q_PROPERTY(QString bluetoothPlaybackStatus READ bluetoothPlaybackStatus NOTIFY bluetoothPlaybackStatusChanged)
    Q_PROPERTY(QString bluetoothAlbumArtUrl READ bluetoothAlbumArtUrl NOTIFY bluetoothAlbumArtUrlChanged)
    Q_PROPERTY(QString bluetoothRepeatMode READ bluetoothRepeatMode NOTIFY bluetoothRepeatModeChanged)
    Q_PROPERTY(bool bluetoothShuffleMode READ bluetoothShuffleMode NOTIFY bluetoothShuffleModeChanged)
    Q_PROPERTY(QString currentScenicBackground READ currentScenicBackground NOTIFY scenicBackgroundChanged)
    Q_PROPERTY(QString currentScenicBlurBackground READ currentScenicBlurBackground NOTIFY scenicBackgroundChanged)
    Q_PROPERTY(QString currentScenicArtwork READ currentScenicArtwork NOTIFY scenicBackgroundChanged)
    Q_PROPERTY(QVariantList discoveredDeviceList READ discoveredDeviceList NOTIFY discoveredDeviceListChanged)
    Q_PROPERTY(bool isDiscovering READ isDiscovering NOTIFY discoveryStateChanged)
    Q_PROPERTY(QString vehicleName READ vehicleName WRITE setVehicleName NOTIFY vehicleNameChanged)
    Q_PROPERTY(QString passkey READ passkey WRITE setPasskey NOTIFY passkeyChanged)
    Q_PROPERTY(bool isPairingPromptActive READ isPairingPromptActive NOTIFY pairingPromptChanged)
    Q_PROPERTY(QString incomingPairingDeviceName READ incomingPairingDeviceName NOTIFY pairingPromptChanged)
    Q_PROPERTY(QString incomingPairingPasskey READ incomingPairingPasskey NOTIFY pairingPromptChanged)
    Q_PROPERTY(QString incomingPairingDeviceMac READ incomingPairingDeviceMac NOTIFY pairingPromptChanged)
    Q_PROPERTY(bool isConnectingDevice READ isConnectingDevice NOTIFY connectingDeviceChanged)
    Q_PROPERTY(QString connectingDeviceName READ connectingDeviceName NOTIFY connectingDeviceChanged)
    Q_PROPERTY(bool isPairingAuthWaiting READ isPairingAuthWaiting NOTIFY pairingAuthWaitingChanged)
    Q_PROPERTY(bool privacyMode READ privacyMode WRITE setPrivacyMode NOTIFY privacyModeChanged)
    Q_PROPERTY(bool androidAutoEnabled READ androidAutoEnabled WRITE setAndroidAutoEnabled NOTIFY androidAutoEnabledChanged)
    Q_PROPERTY(bool appleCarPlayEnabled READ appleCarPlayEnabled WRITE setAppleCarPlayEnabled NOTIFY appleCarPlayEnabledChanged)
    Q_PROPERTY(QString brightnessMode READ brightnessMode WRITE setBrightnessMode NOTIFY displaySettingsChanged)
    Q_PROPERTY(int brightness READ brightness WRITE setBrightness NOTIFY displaySettingsChanged)
    Q_PROPERTY(bool blueLightFilterEnabled READ blueLightFilterEnabled WRITE setBlueLightFilterEnabled NOTIFY displaySettingsChanged)
    Q_PROPERTY(int blueLightWarmth READ blueLightWarmth WRITE setBlueLightWarmth NOTIFY displaySettingsChanged)
    Q_PROPERTY(bool blueLightScheduled READ blueLightScheduled WRITE setBlueLightScheduled NOTIFY displaySettingsChanged)
    Q_PROPERTY(int scheduledStartHour READ scheduledStartHour NOTIFY displaySettingsChanged)
    Q_PROPERTY(int scheduledStartMinute READ scheduledStartMinute NOTIFY displaySettingsChanged)
    Q_PROPERTY(QString scheduledStartAmPm READ scheduledStartAmPm NOTIFY displaySettingsChanged)
    Q_PROPERTY(int scheduledEndHour READ scheduledEndHour NOTIFY displaySettingsChanged)
    Q_PROPERTY(int scheduledEndMinute READ scheduledEndMinute NOTIFY displaySettingsChanged)
    Q_PROPERTY(QString scheduledEndAmPm READ scheduledEndAmPm NOTIFY displaySettingsChanged)
    Q_PROPERTY(QString screensaverType READ screensaverType WRITE setScreensaverType NOTIFY displaySettingsChanged)
    Q_PROPERTY(int analogueClockIndex READ analogueClockIndex WRITE setAnalogueClockIndex NOTIFY displaySettingsChanged)
    Q_PROPERTY(bool displayOff READ displayOff WRITE setDisplayOff NOTIFY displayOffChanged)
    Q_PROPERTY(QString customButtonAudio READ customButtonAudio WRITE setCustomButtonAudio NOTIFY buttonSettingsChanged)
    Q_PROPERTY(QString customButtonSteering READ customButtonSteering WRITE setCustomButtonSteering NOTIFY buttonSettingsChanged)
    Q_PROPERTY(bool modeBtAudio READ modeBtAudio WRITE setModeBtAudio NOTIFY buttonSettingsChanged)
    Q_PROPERTY(bool modeProjection READ modeProjection WRITE setModeProjection NOTIFY buttonSettingsChanged)
    Q_PROPERTY(bool modeUsbMusic READ modeUsbMusic WRITE setModeUsbMusic NOTIFY buttonSettingsChanged)
    Q_PROPERTY(bool modeFm READ modeFm WRITE setModeFm NOTIFY buttonSettingsChanged)
    Q_PROPERTY(QString seekButtonsSteering READ seekButtonsSteering WRITE setSeekButtonsSteering NOTIFY buttonSettingsChanged)
    Q_PROPERTY(QString systemModel READ systemModel CONSTANT)
    Q_PROPERTY(QString appVersion READ appVersion CONSTANT)
    Q_PROPERTY(QString softwareVersion READ softwareVersion CONSTANT)
    Q_PROPERTY(QString firmwareVersion READ firmwareVersion CONSTANT)
    Q_PROPERTY(bool bluetoothRemoteLock READ bluetoothRemoteLock WRITE setBluetoothRemoteLock NOTIFY generalSettingsChanged)
    Q_PROPERTY(int memoryCapacityMB READ memoryCapacityMB CONSTANT)
    Q_PROPERTY(int memoryUsedVoiceMB READ memoryUsedVoiceMB NOTIFY voiceMemoListChanged)
    Q_PROPERTY(int memoryAvailableMB READ memoryAvailableMB NOTIFY voiceMemoListChanged)
    Q_PROPERTY(bool is24HourFormat READ is24HourFormat WRITE setIs24HourFormat NOTIFY generalSettingsChanged)
    Q_PROPERTY(QString systemLanguage READ systemLanguage WRITE setSystemLanguage NOTIFY generalSettingsChanged)
    Q_PROPERTY(bool autoTimeSetting READ autoTimeSetting WRITE setAutoTimeSetting NOTIFY generalSettingsChanged)
    Q_PROPERTY(QString keyboardType READ keyboardType WRITE setKeyboardType NOTIFY generalSettingsChanged)
    Q_PROPERTY(QString koreanKeyboardType READ koreanKeyboardType WRITE setKoreanKeyboardType NOTIFY generalSettingsChanged)
    Q_PROPERTY(QString hindiKeyboardType READ hindiKeyboardType WRITE setHindiKeyboardType NOTIFY generalSettingsChanged)
    Q_PROPERTY(bool mediaOffAtStartup READ mediaOffAtStartup WRITE setMediaOffAtStartup NOTIFY generalSettingsChanged)
    Q_PROPERTY(bool infotainmentRemainsOn READ infotainmentRemainsOn WRITE setInfotainmentRemainsOn NOTIFY generalSettingsChanged)
    Q_PROPERTY(bool displayMediaNotifications READ displayMediaNotifications WRITE setDisplayMediaNotifications NOTIFY generalSettingsChanged)
    Q_PROPERTY(int manualDay READ manualDay NOTIFY generalSettingsChanged)
    Q_PROPERTY(int manualMonth READ manualMonth NOTIFY generalSettingsChanged)
    Q_PROPERTY(int manualYear READ manualYear NOTIFY generalSettingsChanged)
    Q_PROPERTY(int manualHour READ manualHour NOTIFY generalSettingsChanged)
    Q_PROPERTY(int manualMinute READ manualMinute NOTIFY generalSettingsChanged)
    Q_PROPERTY(QString manualAmPm READ manualAmPm NOTIFY generalSettingsChanged)
    Q_PROPERTY(QStringList settingsIconsOrder READ settingsIconsOrder WRITE setSettingsIconsOrder NOTIFY settingsIconsOrderChanged)
    Q_PROPERTY(bool isReverseGear READ isReverseGear WRITE setIsReverseGear NOTIFY reverseGearChanged)

public:
    explicit SystemController(QObject *parent = nullptr);
    ~SystemController() override;

    bool privacyMode() const { return m_privacyMode; }
    Q_INVOKABLE void setPrivacyMode(bool enabled);
    Q_INVOKABLE void togglePrivacyMode();
    QString vehicleName() const { return m_vehicleName; }
    Q_INVOKABLE void setVehicleName(const QString &name);
    QString passkey() const { return m_passkey; }
    Q_INVOKABLE void setPasskey(const QString &key);
    bool androidAutoEnabled() const { return m_androidAutoEnabled; }
    Q_INVOKABLE void setAndroidAutoEnabled(bool enabled);
    bool appleCarPlayEnabled() const { return m_appleCarPlayEnabled; }
    Q_INVOKABLE void setAppleCarPlayEnabled(bool enabled);
    Q_INVOKABLE void moveBluetoothDevice(int fromIndex, int toIndex);
    Q_INVOKABLE void deleteMultipleBluetoothDevices(const QVariantList &items);
    Q_INVOKABLE void deleteDeviceByMac(const QString &mac);

    // Display Settings
    QString brightnessMode() const { return m_brightnessMode; }
    Q_INVOKABLE void setBrightnessMode(const QString &mode);
    int brightness() const { return m_brightness; }
    Q_INVOKABLE void setBrightness(int val);
    Q_INVOKABLE void adjustBrightness(int delta);
    bool blueLightFilterEnabled() const { return m_blueLightFilterEnabled; }
    Q_INVOKABLE void setBlueLightFilterEnabled(bool enabled);
    int blueLightWarmth() const { return m_blueLightWarmth; }
    Q_INVOKABLE void setBlueLightWarmth(int warmth);
    Q_INVOKABLE void adjustBlueLightWarmth(int delta);
    bool blueLightScheduled() const { return m_blueLightScheduled; }
    Q_INVOKABLE void setBlueLightScheduled(bool scheduled);
    int scheduledStartHour() const { return m_scheduledStartHour; }
    int scheduledStartMinute() const { return m_scheduledStartMinute; }
    QString scheduledStartAmPm() const { return m_scheduledStartAmPm; }
    int scheduledEndHour() const { return m_scheduledEndHour; }
    int scheduledEndMinute() const { return m_scheduledEndMinute; }
    QString scheduledEndAmPm() const { return m_scheduledEndAmPm; }
    Q_INVOKABLE void setScheduledTime(int startH, int startM, const QString &startAP, int endH, int endM, const QString &endAP);
    QString screensaverType() const { return m_screensaverType; }
    Q_INVOKABLE void setScreensaverType(const QString &type);
    int analogueClockIndex() const { return m_analogueClockIndex; }
    Q_INVOKABLE void setAnalogueClockIndex(int index);
    bool displayOff() const { return m_displayOff; }
    Q_INVOKABLE void setDisplayOff(bool off);
    Q_INVOKABLE void toggleDisplayOff();
    Q_INVOKABLE void reportActivity();

    // Button Settings
    QString customButtonAudio() const { return m_customButtonAudio; }
    Q_INVOKABLE void setCustomButtonAudio(const QString &val);
    QString customButtonSteering() const { return m_customButtonSteering; }
    Q_INVOKABLE void setCustomButtonSteering(const QString &val);
    bool modeBtAudio() const { return m_modeBtAudio; }
    Q_INVOKABLE void setModeBtAudio(bool enabled);
    bool modeProjection() const { return m_modeProjection; }
    Q_INVOKABLE void setModeProjection(bool enabled);
    bool modeUsbMusic() const { return m_modeUsbMusic; }
    Q_INVOKABLE void setModeUsbMusic(bool enabled);
    bool modeFm() const { return m_modeFm; }
    Q_INVOKABLE void setModeFm(bool enabled);
    QString seekButtonsSteering() const { return m_seekButtonsSteering; }
    Q_INVOKABLE void setSeekButtonsSteering(const QString &val);
    Q_INVOKABLE void resetButtonSettings();

    // General Settings
    QString systemModel() const { return m_systemModel; }
    QString appVersion() const { return m_appVersion; }
    QString softwareVersion() const { return m_softwareVersion; }
    QString firmwareVersion() const { return m_firmwareVersion; }
    Q_INVOKABLE void setAppVersion(const QString &ver) { m_appVersion = ver; }
    Q_INVOKABLE void setSoftwareVersion(const QString &ver) { m_softwareVersion = ver; }
    Q_INVOKABLE void setFirmwareVersion(const QString &ver) { m_firmwareVersion = ver; }
    bool bluetoothRemoteLock() const { return m_bluetoothRemoteLock; }
    Q_INVOKABLE void setBluetoothRemoteLock(bool enabled);
    int memoryCapacityMB() const { return 128; }
    int memoryUsedVoiceMB() const { return qMax(0, (int)(m_voiceMemoList.size() * 1.2)); }
    int memoryAvailableMB() const { return qMax(0, 128 - memoryUsedVoiceMB()); }
    bool is24HourFormat() const { return m_is24HourFormat; }
    Q_INVOKABLE void setIs24HourFormat(bool enabled);
    QString systemLanguage() const { return m_systemLanguage; }
    Q_INVOKABLE void setSystemLanguage(const QString &lang);
    bool autoTimeSetting() const { return m_autoTimeSetting; }
    Q_INVOKABLE void setAutoTimeSetting(bool enabled);
    QString keyboardType() const { return m_keyboardType; }
    Q_INVOKABLE void setKeyboardType(const QString &type);
    QString koreanKeyboardType() const { return m_koreanKeyboardType; }
    Q_INVOKABLE void setKoreanKeyboardType(const QString &type);
    QString hindiKeyboardType() const { return m_hindiKeyboardType; }
    Q_INVOKABLE void setHindiKeyboardType(const QString &type);
    bool mediaOffAtStartup() const { return m_mediaOffAtStartup; }
    Q_INVOKABLE void setMediaOffAtStartup(bool enabled);
    bool infotainmentRemainsOn() const { return m_infotainmentRemainsOn; }
    Q_INVOKABLE void setInfotainmentRemainsOn(bool enabled);
    bool displayMediaNotifications() const { return m_displayMediaNotifications; }
    Q_INVOKABLE void setDisplayMediaNotifications(bool enabled);

    int manualDay() const { return m_manualDay; }
    int manualMonth() const { return m_manualMonth; }
    int manualYear() const { return m_manualYear; }
    int manualHour() const { return m_manualHour; }
    int manualMinute() const { return m_manualMinute; }
    QString manualAmPm() const { return m_manualAmPm; }

    Q_INVOKABLE void adjustManualDay(int delta);
    Q_INVOKABLE void adjustManualMonth(int delta);
    Q_INVOKABLE void adjustManualYear(int delta);
    Q_INVOKABLE void adjustManualHour(int delta);
    Q_INVOKABLE void adjustManualMinute(int delta);
    Q_INVOKABLE void toggleManualAmPm();

    Q_INVOKABLE void resetGeneralSettings();

    QString currentTime() const { return m_currentTime; }
    QString currentAmPm() const { return m_currentAmPm; }
    QString currentDate() const { return m_currentDate; }
    QString fullDate() const { return m_fullDate; }
    QString currentScreen() const { return m_currentScreen; }
    bool isReverseGear() const { return m_isReverseGear; }
    void setIsReverseGear(bool rev) {
        if (m_isReverseGear != rev) {
            m_isReverseGear = rev;
            emit reverseGearChanged();
        }
    }
    Q_INVOKABLE void toggleReverseGear() {
        setIsReverseGear(!m_isReverseGear);
    }
    int volume() const { return m_volume; }
    int maxVolume() const { return 45; }
    Q_INVOKABLE void setVolume(int v);
    Q_INVOKABLE void increaseVolume();
    Q_INVOKABLE void decreaseVolume();
    bool isRadioPlaying() const { return m_radioPlaying; }
    QString radioStation() const { return m_radioStation; }
    QString previousStationFrequency() const { return getNextStationFrequencyString(-1); }
    QString nextStationFrequency() const { return getNextStationFrequencyString(1); }
    QString selectedMediaSource() const { return m_selectedMediaSource; }
    void setSelectedMediaSource(const QString &src);
    QString radioBand() const { return m_radioBand; }
    void setRadioBand(const QString &band);
    QString currentStationName() const { return m_currentStationName; }
    QString currentRdsInfo() const { return m_currentRdsInfo; }
    bool isStationFavorited() const { return m_isStationFavorited; }
    QVariantList stationList() const { return m_stationList; }
    QString radioServerUrl() const { return m_radioServerUrl; }
    void setRadioServerUrl(const QString &url);
    bool radioServerOnline() const { return m_radioServerOnline; }
    Q_INVOKABLE void fetchRadioStations();
    bool radioLoading() const { return m_radioLoading; }
    bool usbConnected() const { return m_usbConnected; }
    void setUsbConnected(bool c);
    int currentStationIndex() const { return m_currentStationIndex; }
    bool isPhoneConnected() const { return m_phoneConnected; }
    bool isBluetoothConnected() const { return m_bluetoothConnected; }
    QString leftWidget() const { return m_leftWidget; }
    QString rightWidget() const { return m_rightWidget; }
    QString editingWidgetSide() const { return m_editingWidgetSide; }
    QStringList dockIcons() const { return m_dockIcons; }
    QStringList settingsIconsOrder() const { return m_settingsIconsOrder; }
    bool beepEnabled() const { return m_beepEnabled; }
    bool quietModeEnabled() const { return m_quietModeEnabled; }
    bool volumeLimitationOnStartup() const { return m_volumeLimitationOnStartup; }
    QString speedDependentVolume() const { return m_speedDependentVolume; }
    int treble() const { return m_treble; }
    int midrange() const { return m_midrange; }
    int bass() const { return m_bass; }
    int fader() const { return m_fader; }
    int balance() const { return m_balance; }
    int guidanceBeepVolume() const { return m_guidanceBeepVolume; }
    int guidanceRingtoneVolume() const { return m_guidanceRingtoneVolume; }
    int guidanceAlertsVolume() const { return m_guidanceAlertsVolume; }
    QString radioNoiseOption() const { return m_radioNoiseOption; }
    bool parkingSafetyPriority() const { return m_parkingSafetyPriority; }
    int projectionMediaVolume() const { return m_projectionMediaVolume; }
    int projectionVoiceVolume() const { return m_projectionVoiceVolume; }
    QString selectedProjectionDevice() const { return m_selectedProjectionDevice; }
    QVariantList bluetoothDeviceList() const { return m_bluetoothDeviceList; }
    int activeDeviceIndex() const { return m_activeDeviceIndex; }
    int phoneBatteryLevel() const { return m_phoneBatteryLevel; }
    int phoneSignalLevel() const { return m_phoneSignalLevel; }
    QString cellularCarrierName() const { return m_cellularCarrierName; }
    Q_INVOKABLE void setPhoneBatteryLevel(int level);
    Q_INVOKABLE void setPhoneSignalLevel(int level);
    bool hasHandsFreeDevice() const {
        for (const auto &d : m_bluetoothDeviceList) {
            auto map = d.toMap();
            if (map["connected"].toBool()) {
                if (!map.contains("handsFree") || map["handsFree"].toBool()) return true;
            }
        }
        return false;
    }
    QString activeHandsFreeDeviceName() const {
        // The dialer header must describe the same phone that call control,
        // PBAP and telemetry use.  Do not use list order when multiple
        // Bluetooth devices are connected.
        if (m_activeDeviceIndex >= 0 && m_activeDeviceIndex < m_bluetoothDeviceList.size()) {
            auto active = m_bluetoothDeviceList[m_activeDeviceIndex].toMap();
            if (active["connected"].toBool() && !active["isInput"].toBool()
                && (!active.contains("handsFree") || active["handsFree"].toBool())) {
                return active["name"].toString();
            }
        }
        for (const auto &d : m_bluetoothDeviceList) {
            auto map = d.toMap();
            if (map["connected"].toBool() && !map["isInput"].toBool()) {
                if (!map.contains("handsFree") || map["handsFree"].toBool()) return map["name"].toString();
            }
        }
        return m_detectedBluetoothName;
    }
    QVariantList callHistory() const { return m_callHistory; }
    QVariantList contactsList() const { return m_contactsList; }
    int contactsCount() const { return m_contactsCount; }
    int callHistoryCount() const { return m_callHistoryCount; }
    bool isSyncingContacts() const { return m_isSyncingContacts; }
    QString detectedBluetoothName() const { return m_detectedBluetoothName; }
    bool bluetoothCallActive() const { return m_bluetoothCallActive; }
    QString bluetoothCallStatus() const { return m_bluetoothCallStatus; }
    QString bluetoothCallNumber() const { return m_bluetoothCallNumber; }
    QString bluetoothCallName() const { return m_bluetoothCallName; }
    Q_INVOKABLE void pollBluetoothCallState();
    Q_INVOKABLE void refreshBluetoothDevices();
    Q_INVOKABLE void refreshPhonebookData();
    Q_INVOKABLE int getFirstContactIndexForLetter(const QString &letter);
    Q_INVOKABLE void dialNumber(const QString &number);
    Q_INVOKABLE void hangUpCall();
    Q_INVOKABLE void answerCall();
    Q_INVOKABLE void sendQuickReply(const QString &number, const QString &message);
    Q_INVOKABLE void sendDtmf(const QString &digit);
    Q_INVOKABLE void setCallMuted(bool mute);
    Q_INVOKABLE void syncBluetoothContacts();
    Q_INVOKABLE void syncRecentCallHistory();
    Q_INVOKABLE void recordCallToHistory(const QString &number, const QString &name = QString(), bool isIncoming = false);

    // Bluetooth Media Playback & Track Metadata
    QString bluetoothTrackTitle() const { return m_bluetoothTrackTitle; }
    QString bluetoothTrackArtist() const { return m_bluetoothTrackArtist; }
    QString bluetoothTrackAlbum() const { return m_bluetoothTrackAlbum; }
    int bluetoothTrackDurationMs() const { return m_bluetoothTrackDurationMs; }
    int bluetoothTrackPositionMs() const { return m_bluetoothTrackPositionMs; }
    QString bluetoothTrackDurationStr() const {
        int sec = m_bluetoothTrackDurationMs / 1000;
        return QString("%1:%2").arg(sec / 60).arg(sec % 60, 2, 10, QChar('0'));
    }
    QString bluetoothTrackPositionStr() const {
        int sec = m_bluetoothTrackPositionMs / 1000;
        return QString("%1:%2").arg(sec / 60).arg(sec % 60, 2, 10, QChar('0'));
    }
    QString bluetoothPlaybackStatus() const { return m_bluetoothPlaybackStatus; }
    QString bluetoothAlbumArtUrl() const { return m_bluetoothAlbumArtUrl; }
    QString bluetoothRepeatMode() const { return m_bluetoothRepeatMode; }
    bool bluetoothShuffleMode() const { return m_bluetoothShuffleMode; }
    QString currentScenicBackground() const {
        static const QStringList bgs = {
            "qrc:/assets/media/scenic_city.jpg",
            "qrc:/assets/media/scenic_beach.jpg",
            "qrc:/assets/media/scenic_mountain.jpg"
        };
        return bgs.value(qAbs(m_scenicIndex) % bgs.size(), bgs[0]);
    }
    QString currentScenicBlurBackground() const {
        static const QStringList blurBgs = {
            "qrc:/assets/media/scenic_city_blur.jpg",
            "qrc:/assets/media/scenic_beach_blur.jpg",
            "qrc:/assets/media/scenic_mountain_blur.jpg"
        };
        return blurBgs.value(qAbs(m_scenicIndex) % blurBgs.size(), blurBgs[0]);
    }
    QString currentScenicArtwork() const {
        return currentScenicBackground();
    }
    Q_INVOKABLE void cycleRandomScenicBackground() {
        int next = (m_scenicIndex + 1 + (QRandomGenerator::global()->generate() % 2)) % 3;
        if (next == m_scenicIndex) next = (m_scenicIndex + 1) % 3;
        m_scenicIndex = next;
        emit scenicBackgroundChanged();
    }

    Q_INVOKABLE void bluetoothMediaPlay();
    Q_INVOKABLE void bluetoothMediaPause();
    Q_INVOKABLE void toggleBluetoothMediaPlayback();
    Q_INVOKABLE void bluetoothMediaNext();
    Q_INVOKABLE void bluetoothMediaPrevious();
    Q_INVOKABLE void toggleBluetoothRepeat();
    Q_INVOKABLE void toggleBluetoothShuffle();
    Q_INVOKABLE void seekBluetoothTrackPosition(int positionMs);
    Q_INVOKABLE void fetchAlbumArt(const QString &title, const QString &artist);

    void setCurrentScreen(const QString &screen);
    void setBluetoothConnected(bool connected);
    void setLeftWidget(const QString &widget);
    void setRightWidget(const QString &widget);
    void setEditingWidgetSide(const QString &side);
    void setDockIcons(const QStringList &icons);
    Q_INVOKABLE void setBeepEnabled(bool enabled);
    Q_INVOKABLE void setVolumeLimitationOnStartup(bool enabled);
    Q_INVOKABLE void setSpeedDependentVolume(const QString &mode);
    Q_INVOKABLE void setTreble(int val);
    Q_INVOKABLE void setMidrange(int val);
    Q_INVOKABLE void setBass(int val);
    Q_INVOKABLE void setFader(int val);
    Q_INVOKABLE void setBalance(int val);
    Q_INVOKABLE void setGuidanceBeepVolume(int val);
    Q_INVOKABLE void setGuidanceRingtoneVolume(int val);
    Q_INVOKABLE void setGuidanceAlertsVolume(int val);
    Q_INVOKABLE void setRadioNoiseOption(const QString &option);
    Q_INVOKABLE void setParkingSafetyPriority(bool enabled);
    Q_INVOKABLE void setProjectionMediaVolume(int val);
    Q_INVOKABLE void setProjectionVoiceVolume(int val);
    Q_INVOKABLE void setSelectedProjectionDevice(const QString &device);

    Q_INVOKABLE void navigateTo(const QString &screen);
    Q_INVOKABLE void toggleRadio();
    Q_INVOKABLE void triggerProjection();
    Q_INVOKABLE void toggleBluetooth();
    Q_INVOKABLE void addDevice(const QString &name, bool handsFree, bool audio);
    Q_INVOKABLE void deactivateHandsFree(int index);
    Q_INVOKABLE void setDevicePreferences(int index, bool handsFree, bool audio);
    Q_INVOKABLE void setDevicePreferencesForMac(const QString &mac, bool handsFree, bool audio);
    Q_INVOKABLE void toggleDeviceHandsFree(int index);
    Q_INVOKABLE void toggleDeviceAudio(int index);
    Q_INVOKABLE void removeDevice(int index);
    Q_INVOKABLE void connectDevice(int index);
    Q_INVOKABLE void disconnectDevice(int index);

    // Bluetooth Discovery & Add Device Methods
    QVariantList discoveredDeviceList() const;
    bool isDiscovering() const;
    Q_INVOKABLE void startDiscovery();
    Q_INVOKABLE void stopDiscovery();
    Q_INVOKABLE void pairAndConnectDevice(const QString &mac);
    Q_INVOKABLE QString primaryConnectedPhoneMac() const;
    Q_INVOKABLE void updatePrimaryPhoneTelemetry(bool forceSync = false);

    bool isPairingPromptActive() const { return m_isPairingPromptActive; }
    QString incomingPairingDeviceName() const { return m_incomingPairingDeviceName; }
    QString incomingPairingPasskey() const { return m_incomingPairingPasskey; }
    QString incomingPairingDeviceMac() const { return m_incomingPairingDeviceMac; }
    bool isConnectingDevice() const { return m_isConnectingDevice; }
    QString connectingDeviceName() const { return m_connectingDeviceName; }
    bool isPairingAuthWaiting() const { return m_isPairingAuthWaiting; }
    Q_INVOKABLE void confirmPairing();
    Q_INVOKABLE void rejectPairing();
    Q_INVOKABLE void cancelPairing();
    Q_INVOKABLE void setBluetoothDiscoverable(bool discoverable);
    Q_INVOKABLE void cancelConnectingDevice();
    Q_INVOKABLE void selectWidgetForSide(const QString &side, const QString &widgetType);
    Q_INVOKABLE void resetWidgetsToDefault();
    Q_INVOKABLE void openWidgetEditor(const QString &side);
    Q_INVOKABLE void updateDockIcon(int index, const QString &iconId);
    Q_INVOKABLE void resetDockIcons();
    Q_INVOKABLE void setSettingsIconsOrder(const QStringList &order);
    Q_INVOKABLE void swapSettingsIcons(int fromIdx, int toIdx);
    Q_INVOKABLE void resetSettingsIconsOrder();
    Q_INVOKABLE void toggleBeep();
    Q_INVOKABLE void toggleQuietMode();
    void setQuietModeEnabled(bool enabled);
    Q_INVOKABLE void toggleVolumeLimitation();
    Q_INVOKABLE void cycleSpeedDependentVolume();
    Q_INVOKABLE void resetEqualiser();
    Q_INVOKABLE void resetPosition();
    Q_INVOKABLE void resetGuidanceVolumes();
    Q_INVOKABLE void resetProjectionVolumes();
    Q_INVOKABLE void toggleParkingSafetyPriority();
    Q_INVOKABLE void selectStation(int index);
    Q_INVOKABLE void tuneFrequency(double delta);
    Q_INVOKABLE void tuneToClosestStation(double targetFreq);
    Q_INVOKABLE double getNextStationFrequency(double delta);
    Q_INVOKABLE QString getNextStationFrequencyString(double delta) const;
    Q_INVOKABLE void toggleRadioBand();
    Q_INVOKABLE void toggleFavoriteStation();
    Q_INVOKABLE void setStationFavorite(int index, bool fav);
    Q_INVOKABLE void removeFavoriteByFrequency(const QString &freq);
    Q_INVOKABLE void selectMediaSource(const QString &source);
    Q_INVOKABLE void playCurrentStation();
    Q_INVOKABLE void pauseRadio();
    Q_INVOKABLE void stopRadio();
    Q_INVOKABLE void turnOffMedia();

    // Voice Memo Methods
    bool isVoiceRecording() const { return m_isVoiceRecording; }
    bool isVoiceRecordingPaused() const { return m_isVoiceRecordingPaused; }
    int recordingSeconds() const { return m_recordingSeconds; }
    QString recordingTimeFormatted() const;
    int voiceRecordLevel() const { return m_voiceRecordLevel; }
    QVariantList voiceMemoList() const { return m_voiceMemoList; }
    bool isPlayingVoiceMemo() const { return m_isPlayingVoiceMemo; }
    int activeVoiceMemoIndex() const { return m_activeVoiceMemoIndex; }
    qint64 voiceMemoPosition() const { return m_voiceMemoPosition; }
    qint64 voiceMemoDuration() const { return m_voiceMemoDuration; }

    Q_INVOKABLE void setVoiceRecordLevel(int level);
    Q_INVOKABLE void startVoiceRecording();
    Q_INVOKABLE void pauseVoiceRecording();
    Q_INVOKABLE void resumeVoiceRecording();
    Q_INVOKABLE void stopVoiceRecording();
    Q_INVOKABLE void playVoiceMemo(int index);
    Q_INVOKABLE void pauseVoiceMemo();
    Q_INVOKABLE void stopVoiceMemo();
    Q_INVOKABLE void seekVoiceMemo(qint64 position);
    Q_INVOKABLE void previousVoiceMemo();
    Q_INVOKABLE void nextVoiceMemo();
    Q_INVOKABLE void deleteVoiceMemo(int index);
    Q_INVOKABLE void deleteMultipleVoiceMemos(const QVariantList &indices);
    Q_INVOKABLE void deleteAllVoiceMemos();
    Q_INVOKABLE void saveVoiceMemosToUsb();

signals:
    void voiceMemosSavedToUsb(bool success, const QString &message);
    void timeChanged();
    void screenChanged();
    void radioStateChanged();
    void radioStationChanged();
    void phoneConnectionChanged();
    void bluetoothConnectionChanged();
    void bluetoothDeviceListChanged();
    void devicePairedSuccessfully(const QString &mac, const QString &name);
    void deviceConnecting(const QString &name, const QString &mac);
    void deviceDisconnected(const QString &mac, const QString &name);
    void connectingDeviceChanged();
    void pairingAuthWaitingChanged();
    void pairingAuthenticationWaiting(const QString &name, const QString &passkey);
    void callHistoryChanged();
    void contactsListChanged();
    void contactsCountChanged();
    void callHistoryCountChanged();
    void isSyncingContactsChanged();
    void phoneBatteryLevelChanged();
    void phoneSignalLevelChanged();
    void cellularCarrierNameChanged();
    void detectedBluetoothNameChanged();
    void bluetoothCallActiveChanged();
    void bluetoothCallStatusChanged();
    void bluetoothCallNumberChanged();
    void bluetoothCallNameChanged();
    void bluetoothTrackChanged();
    void bluetoothTrackPositionChanged();
    void bluetoothPlaybackStatusChanged();
    void bluetoothAlbumArtUrlChanged();
    void bluetoothRepeatModeChanged();
    void bluetoothShuffleModeChanged();
    void scenicBackgroundChanged();
    void remoteCallStarted(const QString &name, const QString &number, const QString &status);
    void remoteCallStatusChanged(const QString &status);
    void remoteCallEnded();
    void quickReplyFinished(bool success, const QString &message);
    void widgetsChanged();
    void editingWidgetSideChanged();
    void dockIconsChanged();
    void soundSettingsChanged();
    void privacyModeChanged();
    void vehicleNameChanged();
    void passkeyChanged();
    void voiceRecordingChanged();
    void voiceRecordLevelChanged();
    void voiceMemoListChanged();
    void voiceMemoPlaybackChanged();
    void androidAutoEnabledChanged();
    void appleCarPlayEnabledChanged();
    void displaySettingsChanged();
    void displayOffChanged();
    void buttonSettingsChanged();
    void generalSettingsChanged();
    void settingsIconsOrderChanged();
    void quietModeChanged();
    void selectedMediaSourceChanged();
    void radioBandChanged();
    void currentStationNameChanged();
    void currentRdsInfoChanged();
    void isStationFavoritedChanged();
    void stationListChanged();
    void radioServerUrlChanged();
    void radioServerOnlineChanged();
    void radioLoadingChanged();
    void usbConnectedChanged();
    void currentStationIndexChanged();
    void reverseGearChanged();
    void volumeChanged();
    void pairingPromptChanged();
    void discoveredDeviceListChanged();
    void discoveryStateChanged();

private slots:
    void updateDateTime();
    void onInactivityTimeout();
    void startRadioStream();
    void onBtAgentOutput();

private:
    void saveBluetoothDeviceList();
    QString getMacForDeviceName(const QString &name);
    void acquireCallAudioFocus();
    void releaseCallAudioFocus();
    void setBluetoothMediaPlayback(bool play);
    BluezBluetoothManager *m_bluezManager{nullptr};
    bool m_isPairingPromptActive{false};
    bool m_isPairingAuthWaiting{false};
    QString m_incomingPairingDeviceName;
    QString m_incomingPairingPasskey;
    QString m_incomingPairingDeviceMac;
    bool m_isConnectingDevice{false};
    QString m_connectingDeviceName;
    QString m_connectingDeviceMac;
    QString m_lastPairedSuccessMac;
    qint64 m_lastPairedSuccessTime{0};
    QSet<QString> m_recentlyRemovedMacs;
    QString m_lastSyncedPhoneMac;
    QString m_signalTelemetryPhoneMac;
    QProcess *m_btAgentProc{nullptr};

#ifdef APEX_IVI_VERSION_STRING
    QString m_appVersion{APEX_IVI_VERSION_STRING};
#else
    QString m_appVersion{"v1.0.0"};
#endif
    QString m_systemModel{"AI3_PE_SUVP23S.DVAMN.S2IN"};
    QString m_softwareVersion{"AI3_PE_SUV.IND.D2V.001.001.230606"};
    QString m_firmwareVersion{"AI3_PE_SUV.IND.V257.230223"};
    bool m_isReverseGear{false};
    bool m_bluetoothRemoteLock{false};
    bool m_is24HourFormat{false};
    QString m_systemLanguage{"English"};
    bool m_autoTimeSetting{true};
    QString m_keyboardType{"QWERTY"};
    QString m_koreanKeyboardType{"QWERTY"};
    QString m_hindiKeyboardType{"ध्वन्यात्मक"};
    bool m_mediaOffAtStartup{false};
    bool m_infotainmentRemainsOn{false};
    bool m_displayMediaNotifications{true};
    int m_manualDay{15};
    int m_manualMonth{2};
    int m_manualYear{2026};
    int m_manualHour{3};
    int m_manualMinute{8};
    QString m_manualAmPm{"PM"};

    QString m_customButtonAudio{"none"};
    QString m_customButtonSteering{"home"};
    bool m_modeBtAudio{true};
    bool m_modeProjection{true};
    bool m_modeUsbMusic{true};
    bool m_modeFm{true};
    QString m_seekButtonsSteering{"station"};

    bool m_privacyMode{false};
    QString m_vehicleName{"Apex MidEnd"};
    QString m_passkey{"0000"};
    bool m_androidAutoEnabled{true};
    bool m_appleCarPlayEnabled{true};
    QString m_brightnessMode{"manual"};
    int m_brightness{30};
    bool m_blueLightFilterEnabled{false};
    int m_blueLightWarmth{1};
    bool m_blueLightScheduled{false};
    int m_scheduledStartHour{9};
    int m_scheduledStartMinute{0};
    QString m_scheduledStartAmPm{"PM"};
    int m_scheduledEndHour{6};
    int m_scheduledEndMinute{0};
    QString m_scheduledEndAmPm{"AM"};
    QString m_screensaverType{"analog"};
    int m_analogueClockIndex{1};
    bool m_displayOff{false};
    QString m_currentTime;
    QString m_currentAmPm;
    QString m_currentDate;
    QString m_fullDate;
    QString m_currentScreen{"loading"};
    bool m_radioPlaying{false};
    QString m_radioStation{"93.5"};
    bool m_phoneConnected{false};
    bool m_bluetoothConnected{false};
    QVariantList m_bluetoothDeviceList;
    int m_activeDeviceIndex{0};
    QVariantList m_callHistory;
    QVariantList m_contactsList;
    int m_contactsCount{0};
    int m_callHistoryCount{0};
    bool m_isSyncingContacts{false};
    PbapSyncManager *m_pbapManager{nullptr};
    QString m_detectedBluetoothName{""};
    bool m_bluetoothCallActive{false};
    QString m_bluetoothCallStatus{"idle"};
    QString m_bluetoothCallNumber{""};
    QString m_bluetoothCallName{""};
    QTimer *m_callMonitorTimer{nullptr};
    QTimer *m_callHistoryAutoRefreshTimer{nullptr};
    bool m_isCheckingCallState{false};
    bool m_hangupInProgress{false};
    qint64 m_lastHangupTimestamp{0};
    bool m_currentCallWasIncoming{false};
    bool m_currentCallWasAnswered{false};
    QString m_currentTrackedCallNumber;
    QVariantList m_localCallHistoryPending;
    qint64 m_dialStartedTimestamp{0};
    int m_noCallCount{0};
    bool m_callAudioFocusActive{false};
    bool m_resumeRadioAfterCall{false};
    bool m_resumeVoiceMemoAfterCall{false};
    bool m_resumeBluetoothMediaAfterCall{false};
    QString m_bluetoothTrackTitle{""};
    QString m_bluetoothTrackArtist{""};
    QString m_bluetoothTrackAlbum{""};
    int m_bluetoothTrackDurationMs{0};
    int m_bluetoothTrackPositionMs{0};
    QString m_bluetoothPlaybackStatus{"stopped"};
    QString m_bluetoothAlbumArtUrl{""};
    QString m_bluetoothRepeatMode{"off"};
    bool m_bluetoothShuffleMode{false};
    int m_scenicIndex{0};
    mutable QString m_cachedPlayerPath{""};
    QTimer *m_bluetoothMediaProgressTimer{nullptr};
    QTimer *m_bluetoothMediaMonitorTimer{nullptr};
    bool m_btPollProcActive{false};
    int m_albumArtFlip{0};
    bool m_bluetoothAutoPlayInhibited{true};
    // Timestamp (ms since epoch) of the last Play/Pause/Next/Previous command.
    // The media poll skips status overwrite for 3 s after a command so the
    // AVRCP round-trip (200–800 ms on Bluetooth) cannot flip the optimistic UI
    // state back before the phone has processed the command.
    qint64 m_lastMediaCommandMs{0};
    QString resolveBluetoothPlayerPath() const;
    void pollBluetoothMediaPlayer();
    void updateBluetoothAlbumArt(const QString &title, const QString &artist);
    void parseCallStateOutput(const QString &output);
    void finalizeTrackedCallHistory();
    void scheduleCallHistoryRefresh();
    QString m_leftWidget{"clock"};
    QString m_rightWidget{"phone_projection"};
    QString m_editingWidgetSide{"right"};
    QStringList m_dockIcons{"all_menus", "phone", "media", "settings"};
    QStringList m_settingsIconsOrder{"sound", "device_connection", "display", "button", "general"};
    bool m_beepEnabled{true};
    bool m_quietModeEnabled{false};
    int m_savedFaderBeforeQuietMode{0};
    bool m_volumeLimitationOnStartup{false};
    QString m_speedDependentVolume{"Normal"};
    int m_treble{0};
    int m_midrange{0};
    int m_bass{0};
    int m_fader{0};
    int m_balance{0};
    int m_guidanceBeepVolume{1};
    int m_guidanceRingtoneVolume{20};
    int m_guidanceAlertsVolume{2};
    QString m_radioNoiseOption{"original"};
    bool m_parkingSafetyPriority{true};
    int m_projectionMediaVolume{30};
    int m_projectionVoiceVolume{8};
    int m_volume{29};
    QString m_selectedProjectionDevice{"Android Auto"};
    QTimer *m_timer{nullptr};
    QTimer *m_inactivityTimer{nullptr};
    QTimer *m_radioTuneTimer{nullptr};
    QTimer *m_btMonitorTimer{nullptr};
    QThread *m_radioThread{nullptr};
    RadioStreamWorker *m_radioWorker{nullptr};
    QString m_selectedMediaSource{"none"};
    QString m_radioBand{"FM"};
    QString m_currentStationName{"SURYAN"};
    QString m_currentRdsInfo{"April May - Idhayam - Ilaiyaraaja,\nDeepan Chakravarthy, S.N.Suren"};
    bool m_isStationFavorited{true};
    bool m_radioLoading{false};
    bool m_usbConnected{false};
    int m_currentStationIndex{2};
    QVariantList m_stationList;
    QNetworkAccessManager *m_networkManager{nullptr};
    QString m_radioServerUrl{"http://127.0.0.1:8080/radio/stations.json"};
    bool m_radioServerOnline{false};
    QTimer *m_radioServerPollTimer{nullptr};
    void parseRadioStationsJson(const QByteArray &jsonData);
    void loadCachedRadioStations();
    void saveCachedRadioStations(const QByteArray &jsonData);
    bool m_isVoiceRecording{false};
    bool m_isVoiceRecordingPaused{false};
    int m_recordingSeconds{0};
    int m_voiceRecordLevel{3};
    int m_nextMemoNumber{1};
    QVariantList m_voiceMemoList;
    bool m_isPlayingVoiceMemo{false};
    int m_activeVoiceMemoIndex{-1};
    qint64 m_voiceMemoPosition{0};
    qint64 m_voiceMemoDuration{0};
    QString m_currentRecordingPath;
    QTimer *m_recordingTimer{nullptr};
    QTimer *m_levelTimer{nullptr};
    QMediaCaptureSession *m_captureSession{nullptr};
    QAudioInput *m_audioInput{nullptr};
    QMediaRecorder *m_recorder{nullptr};
    QMediaPlayer *m_memoPlayer{nullptr};
    QAudioOutput *m_memoAudioOutput{nullptr};
    QSoundEffect *m_startChime{nullptr};
    QSoundEffect *m_stopChime{nullptr};
    NativeAudioRecorder *m_nativeRecorder{nullptr};
    int m_phoneBatteryLevel{0};
    int m_phoneSignalLevel{0};
    QString m_cellularCarrierName;
};
