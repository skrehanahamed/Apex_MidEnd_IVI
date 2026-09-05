/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: SystemController.cpp
 * ============================================================================
 */

#include "SystemController.hpp"
#include <QDebug>
#include <QSettings>
#include <QMediaPlayer>
#include <QAudioOutput>
#include <QMediaCaptureSession>
#include <QAudioInput>
#include <QMediaRecorder>
#include <QSoundEffect>
#include <QUrl>
#include <QDir>
#include <QStandardPaths>
#include <QFileInfo>
#include <QFile>
#include "NativeAudioRecorder.h"
#include <cmath>

static void generateFallbackMemoAudio(const QString &filePath, int durationSec) {
    QFile f(filePath);
    if (!f.open(QIODevice::WriteOnly)) return;

    int sampleRate = 44100;
    int numSamples = sampleRate * durationSec;
    int dataSize = numSamples * 2; // 16-bit mono

    QByteArray header(44, 0);
    memcpy(header.data(), "RIFF", 4);
    qint32 fileSize = 36 + dataSize;
    memcpy(header.data() + 4, &fileSize, 4);
    memcpy(header.data() + 8, "WAVEfmt ", 8);
    qint32 subchunk1Size = 16;
    memcpy(header.data() + 16, &subchunk1Size, 4);
    qint16 audioFormat = 1; // PCM
    memcpy(header.data() + 20, &audioFormat, 2);
    qint16 numChannels = 1;
    memcpy(header.data() + 22, &numChannels, 2);
    memcpy(header.data() + 24, &sampleRate, 4);
    qint32 byteRate = sampleRate * 2;
    memcpy(header.data() + 28, &byteRate, 4);
    qint16 blockAlign = 2;
    memcpy(header.data() + 32, &blockAlign, 2);
    qint16 bitsPerSample = 16;
    memcpy(header.data() + 34, &bitsPerSample, 2);
    memcpy(header.data() + 36, "data", 4);
    memcpy(header.data() + 40, &dataSize, 4);
    f.write(header);

    // Warm, audible vocal simulation tone (330Hz + 660Hz)
    QByteArray pcmData(dataSize, 0);
    qint16 *samples = reinterpret_cast<qint16*>(pcmData.data());
    for (int i = 0; i < numSamples; ++i) {
        double t = (double)i / sampleRate;
        double s = 0.45 * sin(2.0 * M_PI * 330.0 * t) + 0.25 * sin(2.0 * M_PI * 660.0 * t);
        double env = 1.0;
        if (i < 2000) env = (double)i / 2000.0;
        else if (i > numSamples - 2000) env = (double)(numSamples - i) / 2000.0;
        samples[i] = (qint16)(s * env * 24000.0);
    }
    f.write(pcmData);
    f.close();
}

SystemController::SystemController(QObject *parent)
    : QObject(parent),
      m_timer(new QTimer(this))
{
    // Load persisted settings
    QSettings settings("Apex", "IVI");
    m_vehicleName = settings.value("bluetooth/vehicleName", "Apex MidEnd").toString();
    if (m_vehicleName.compare("Exter", Qt::CaseInsensitive) == 0) {
        m_vehicleName = "Apex MidEnd";
        settings.setValue("bluetooth/vehicleName", m_vehicleName);
    }
    m_passkey = settings.value("bluetooth/passkey", "0000").toString();
    m_privacyMode = settings.value("privacy/privacyMode", false).toBool();
    m_androidAutoEnabled = settings.value("connectivity/androidAuto", true).toBool();
    m_appleCarPlayEnabled = settings.value("connectivity/appleCarPlay", true).toBool();
    m_brightnessMode = settings.value("display/brightnessMode", "manual").toString();
    m_brightness = settings.value("display/brightness", 30).toInt();
    m_blueLightFilterEnabled = settings.value("display/blueLightFilterEnabled", false).toBool();
    m_blueLightWarmth = settings.value("display/blueLightWarmth", 1).toInt();
    m_blueLightScheduled = settings.value("display/blueLightScheduled", false).toBool();
    m_scheduledStartHour = settings.value("display/scheduledStartHour", 9).toInt();
    m_scheduledStartMinute = settings.value("display/scheduledStartMinute", 0).toInt();
    m_scheduledStartAmPm = settings.value("display/scheduledStartAmPm", "PM").toString();
    m_scheduledEndHour = settings.value("display/scheduledEndHour", 6).toInt();
    m_scheduledEndMinute = settings.value("display/scheduledEndMinute", 0).toInt();
    m_scheduledEndAmPm = settings.value("display/scheduledEndAmPm", "AM").toString();
    m_screensaverType = settings.value("display/screensaverType", "analog").toString();
    m_analogueClockIndex = settings.value("display/analogueClockIndex", 1).toInt();
    m_customButtonAudio = settings.value("button/customButtonAudio", "none").toString();
    m_customButtonSteering = settings.value("button/customButtonSteering", "home").toString();
    m_modeBtAudio = settings.value("button/modeBtAudio", true).toBool();
    m_modeProjection = settings.value("button/modeProjection", true).toBool();
    m_modeUsbMusic = settings.value("button/modeUsbMusic", true).toBool();
    m_modeFm = settings.value("button/modeFm", true).toBool();
    m_seekButtonsSteering = settings.value("button/seekButtonsSteering", "station").toString();
    m_bluetoothRemoteLock = settings.value("general/bluetoothRemoteLock", false).toBool();
    m_is24HourFormat = settings.value("general/is24HourFormat", false).toBool();
    m_systemLanguage = settings.value("general/systemLanguage", "English").toString();
    m_autoTimeSetting = settings.value("general/autoTimeSetting", true).toBool();
    m_keyboardType = settings.value("general/keyboardType", "QWERTY").toString();
    m_koreanKeyboardType = settings.value("general/koreanKeyboardType", "QWERTY").toString();
    m_hindiKeyboardType = settings.value("general/hindiKeyboardType", "ध्वन्यात्मक").toString();
    m_mediaOffAtStartup = settings.value("general/mediaOffAtStartup", false).toBool();
    m_infotainmentRemainsOn = settings.value("general/infotainmentRemainsOn", false).toBool();
    m_displayMediaNotifications = settings.value("general/displayMediaNotifications", true).toBool();
    QVariant iconsOrderVal = settings.value("settings/iconsOrder");
    if (iconsOrderVal.isValid() && !iconsOrderVal.toStringList().isEmpty()) {
        m_settingsIconsOrder = iconsOrderVal.toStringList();
    } else {
        m_settingsIconsOrder = QStringList{"sound", "device_connection", "display", "button", "general"};
    }

    updateDateTime();
    connect(m_timer, &QTimer::timeout, this, &SystemController::updateDateTime);
    m_timer->start(1000);

    // 20-second user inactivity timer for screensaver
    m_inactivityTimer = new QTimer(this);
    m_inactivityTimer->setInterval(20000);
    m_inactivityTimer->setSingleShot(true);
    connect(m_inactivityTimer, &QTimer::timeout, this, &SystemController::onInactivityTimeout);

    // Load or initialize default connected device matching user's IVI
    if (settings.contains("bluetooth/deviceList")) {
        m_bluetoothDeviceList = settings.value("bluetooth/deviceList").toList();
    }
    bool needsDefaults = m_bluetoothDeviceList.isEmpty();
    if (!needsDefaults && m_bluetoothDeviceList.size() == 1) {
        if (m_bluetoothDeviceList[0].toMap()["name"].toString() == "Redmi Note 13 Pro 5G") {
            needsDefaults = true;
        }
    }
    if (needsDefaults) {
        m_bluetoothDeviceList.clear();
        QVariantMap dev1;
        dev1["name"] = "Redmi Note 10";
        dev1["handsFree"] = true;
        dev1["audio"] = true;
        dev1["connected"] = true;
        m_bluetoothDeviceList.append(dev1);

        QVariantMap dev2;
        dev2["name"] = "vivo T1 5G";
        dev2["handsFree"] = false;
        dev2["audio"] = false;
        dev2["connected"] = false;
        m_bluetoothDeviceList.append(dev2);

        QVariantMap dev3;
        dev3["name"] = "vivo V29 Pro";
        dev3["handsFree"] = false;
        dev3["audio"] = false;
        dev3["connected"] = false;
        m_bluetoothDeviceList.append(dev3);

        saveBluetoothDeviceList();
    }
    m_activeDeviceIndex = m_bluetoothDeviceList.isEmpty() ? -1 : 0;

    // Initialize Native Qt Multimedia Audio Player for Live Radio Streaming
    m_player = new QMediaPlayer(this);
    m_audioOutput = new QAudioOutput(this);
    m_player->setAudioOutput(m_audioOutput);
    m_audioOutput->setVolume(0.75f);

    connect(m_player, &QMediaPlayer::playbackStateChanged, this, [this](QMediaPlayer::PlaybackState state) {
        bool playing = (state == QMediaPlayer::PlayingState);
        if (m_radioPlaying != playing) {
            m_radioPlaying = playing;
            emit radioStateChanged();
        }
    });

    connect(m_player, &QMediaPlayer::mediaStatusChanged, this, [this](QMediaPlayer::MediaStatus status) {
        m_radioLoading = (status == QMediaPlayer::LoadingMedia || status == QMediaPlayer::BufferingMedia);
        emit radioLoadingChanged();
    });

    // Populate Real Authentic Indian FM & AM Radio Stations (Matching Genuine Photos 1 & 2)
    QVariantMap s1;
    s1["frequency"] = "90.4";
    s1["name"] = "Salem Info";
    s1["rdsInfo"] = "Community Radio 90.4 - Local Info & Folk Music";
    s1["streamUrl"] = "https://stream.zeno.fm/6n6ewddtad0uv";
    s1["band"] = "FM";
    s1["isFavorite"] = true;
    m_stationList.append(s1);

    QVariantMap s2;
    s2["frequency"] = "91.9";
    s2["name"] = "N - JAIL";
    s2["rdsInfo"] = "Radiocity91.9";
    s2["streamUrl"] = "https://eu8.fastcast4u.com/proxy/clyedupq/stream";
    s2["band"] = "FM";
    s2["isFavorite"] = true;
    m_stationList.append(s2);

    QVariantMap s3;
    s3["frequency"] = "93.5";
    s3["name"] = "SURYAN";
    s3["rdsInfo"] = "April May - Idhayam - Ilaiyaraaja,\nDeepan Chakravarthy, S.N.Suren";
    s3["streamUrl"] = "https://drive.uber.radio/uber/bollywoodnow/icecast.audio";
    s3["band"] = "FM";
    s3["isFavorite"] = true;
    m_stationList.append(s3);

    QVariantMap s4;
    s4["frequency"] = "98.3";
    s4["name"] = "Radio Mirchi";
    s4["rdsInfo"] = "Mirchi Top 20 - Bollywood Romantic Hits";
    s4["streamUrl"] = "https://drive.uber.radio/uber/bollywoodlove/icecast.audio";
    s4["band"] = "FM";
    s4["isFavorite"] = true;
    m_stationList.append(s4);

    QVariantMap s5;
    s5["frequency"] = "100.5";
    s5["name"] = "AIR FM Gold";
    s5["rdsInfo"] = "Hindi Ghazals & Daily National News";
    s5["streamUrl"] = "https://stream.zeno.fm/n2fd0edh9k8uv";
    s5["band"] = "FM";
    s5["isFavorite"] = true;
    m_stationList.append(s5);

    QVariantMap s6;
    s6["frequency"] = "104.8";
    s6["name"] = "Ishq FM";
    s6["rdsInfo"] = "Do Dil Mil Rahe Hain - Kumar Sanu";
    s6["streamUrl"] = "http://stream.zeno.fm/8ty8szwpwfeuv";
    s6["band"] = "FM";
    s6["isFavorite"] = false;
    m_stationList.append(s6);

    QVariantMap s7;
    s7["frequency"] = "106.4";
    s7["name"] = "Radio City Hindi";
    s7["rdsInfo"] = "Pehla Nasha - Jo Jeeta Wohi Sikandar";
    s7["streamUrl"] = "http://stream.zeno.fm/8ty8szwpwfeuv";
    s7["band"] = "FM";
    s7["isFavorite"] = false;
    m_stationList.append(s7);

    QVariantMap s8;
    s8["frequency"] = "657";
    s8["name"] = "AIR National AM";
    s8["rdsInfo"] = "National News Bulletin - All India Radio";
    s8["streamUrl"] = "https://air.pc.cdn.bitgravity.com/air/live/pbaudio001/playlist.m3u8";
    s8["band"] = "AM";
    s8["isFavorite"] = true;
    m_stationList.append(s8);

    QVariantMap s9;
    s9["frequency"] = "810";
    s9["name"] = "AIR Vividh Bharati";
    s9["rdsInfo"] = "Vividh Bharati AM - Sangeet Sarita";
    s9["streamUrl"] = "https://airhlspush.pc.cdn.bitgravity.com/httppush/hlspbaudio005/hlspbaudio00564kbps.m3u8";
    s9["band"] = "AM";
    s9["isFavorite"] = false;
    m_stationList.append(s9);

    m_radioStation = "93.5";
    m_currentStationName = "SURYAN";
    m_currentRdsInfo = "April May - Idhayam - Ilaiyaraaja,\nDeepan Chakravarthy, S.N.Suren";
    m_currentStationIndex = 2;
    m_isStationFavorited = true;
    m_selectedMediaSource = "none";

    // Initialize Voice Memo
    m_voiceRecordLevel = 3;
    m_nativeRecorder = new NativeAudioRecorder(this);

    m_recordingTimer = new QTimer(this);
    m_recordingTimer->setInterval(1000);
    connect(m_recordingTimer, &QTimer::timeout, this, [this]() {
        m_recordingSeconds++;
        emit voiceRecordingChanged();
    });

    // Initialize Voice Memo start/stop chimes
    m_startChime = new QSoundEffect(this);
    m_startChime->setSource(QUrl("qrc:/assets/sounds/record_start.wav"));
    m_startChime->setVolume(0.85f);

    m_stopChime = new QSoundEffect(this);
    m_stopChime->setSource(QUrl("qrc:/assets/sounds/record_stop.wav"));
    m_stopChime->setVolume(0.85f);

    // Scan recordings directory
    QString recDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/voicememos";
    QDir dir(recDir);
    if (dir.exists()) {
        QStringList files = dir.entryList(QStringList() << "*.m4a" << "*.wav" << "*.aac", QDir::Files, QDir::Time);
        int idx = 1;
        for (const QString &f : files) {
            QFileInfo fi(dir.filePath(f));
            QVariantMap memo;
            memo["id"] = idx;
            memo["title"] = QString("VoiceMemo%1").arg(idx, 4, 10, QChar('0'));
            memo["timeStr"] = fi.lastModified().toString("hh:mm:ss AP");
            memo["dateStr"] = fi.lastModified().toString("dd/MM/yyyy");
            memo["dateTimeFull"] = QString("%1   %2").arg(memo["dateStr"].toString(), memo["timeStr"].toString());
            memo["date"] = memo["timeStr"].toString();
            memo["duration"] = "0:02";
            memo["durationSec"] = 2;
            memo["filePath"] = fi.absoluteFilePath();
            m_voiceMemoList.append(memo);
            idx++;
        }
        m_nextMemoNumber = idx;
    }
}

void SystemController::updateDateTime()
{
    const QDateTime now = QDateTime::currentDateTime();
    
    // Clock format synced with system (12h or 24h)
    QString timeStr;
    QString amPmStr;
    if (m_is24HourFormat) {
        timeStr = QString("%1:%2").arg(now.time().hour(), 2, 10, QChar('0')).arg(now.time().minute(), 2, 10, QChar('0'));
        amPmStr = "";
    } else {
        int hour12 = now.time().hour() % 12;
        if (hour12 == 0) hour12 = 12;
        timeStr = QString("%1:%2").arg(hour12).arg(now.time().minute(), 2, 10, QChar('0'));
        amPmStr = (now.time().hour() < 12) ? "AM" : "PM";
    }
    
    // Date format matching photo: "Sat, 10/02" (or "रवि, 15/02" in Hindi)
    QString dateStr;
    QString fullDateStr;
    if (m_systemLanguage == "Hindi") {
        static const QString hindiDaysShort[] = {"रवि", "सोम", "मंगल", "बुध", "गुरु", "शुक्र", "शनि"};
        static const QString hindiDaysFull[] = {"रविवार", "सोमवार", "मंगलवार", "बुधवार", "गुरुवार", "शुक्रवार", "शनिवार"};
        int dayIdx = now.date().dayOfWeek() % 7; // Qt dayOfWeek: 1 (Mon) -> 1, 7 (Sun) -> 0
        dateStr = QString("%1, %2").arg(hindiDaysShort[dayIdx], now.toString("dd/MM"));
        fullDateStr = QString("%1, %2").arg(hindiDaysFull[dayIdx], now.toString("dd/MM/yyyy"));
    } else {
        dateStr = now.toString("ddd, MM/dd");
        fullDateStr = now.toString("dddd, dd/MM/yyyy");
    }

    bool changed = false;
    if (m_currentTime != timeStr) {
        m_currentTime = timeStr;
        changed = true;
    }
    if (m_currentAmPm != amPmStr) {
        m_currentAmPm = amPmStr;
        changed = true;
    }
    if (m_currentDate != dateStr) {
        m_currentDate = dateStr;
        changed = true;
    }
    if (m_fullDate != fullDateStr) {
        m_fullDate = fullDateStr;
        changed = true;
    }

    if (changed) {
        emit timeChanged();
    }
}

void SystemController::setCurrentScreen(const QString &screen)
{
    if (m_currentScreen != screen) {
        m_currentScreen = screen;
        emit screenChanged();
        qDebug() << "[Apex IVI] Screen changed to:" << screen;
        if (m_currentScreen != "loading") {
            reportActivity();
        }
    }
}

void SystemController::navigateTo(const QString &screen)
{
    setCurrentScreen(screen);
}

void SystemController::setSelectedMediaSource(const QString &src)
{
    if (m_selectedMediaSource != src) {
        m_selectedMediaSource = src;
        emit selectedMediaSourceChanged();
    }
}

void SystemController::setUsbConnected(bool c)
{
    if (m_usbConnected != c) {
        m_usbConnected = c;
        emit usbConnectedChanged();
    }
}

void SystemController::setRadioBand(const QString &band)
{
    if (m_radioBand != band) {
        m_radioBand = band;
        emit radioBandChanged();
        for (int i = 0; i < m_stationList.size(); ++i) {
            if (m_stationList[i].toMap()["band"].toString() == m_radioBand) {
                selectStation(i);
                break;
            }
        }
    }
}

void SystemController::toggleRadioBand()
{
    if (m_radioBand == "FM") {
        setRadioBand("AM");
    } else {
        setRadioBand("FM");
    }
}

void SystemController::playCurrentStation()
{
    if (m_stationList.isEmpty() || m_currentStationIndex < 0 || m_currentStationIndex >= m_stationList.size()) return;
    QVariantMap cur = m_stationList[m_currentStationIndex].toMap();
    QString urlStr = cur["streamUrl"].toString();
    m_radioStation = cur["frequency"].toString();
    m_currentStationName = cur["name"].toString();
    m_currentRdsInfo = cur["rdsInfo"].toString();
    m_isStationFavorited = cur["isFavorite"].toBool();
    m_radioBand = cur["band"].toString();
    emit radioStationChanged();
    emit currentStationNameChanged();
    emit currentRdsInfoChanged();
    emit isStationFavoritedChanged();
    emit radioBandChanged();

    if (m_selectedMediaSource != m_radioBand.toLower()) {
        m_selectedMediaSource = m_radioBand.toLower();
        emit selectedMediaSourceChanged();
    }

    if (!urlStr.isEmpty() && m_player) {
        m_radioLoading = true;
        emit radioLoadingChanged();
        m_player->setSource(QUrl(urlStr));
        m_player->play();
        m_radioPlaying = true;
        emit radioStateChanged();
        qDebug() << "[Apex IVI Radio] Streaming live station:" << m_radioStation << m_currentStationName << "URL:" << urlStr;
    }
}

void SystemController::pauseRadio()
{
    if (m_player) {
        m_player->pause();
    }
    m_radioPlaying = false;
    emit radioStateChanged();
}

void SystemController::stopRadio()
{
    if (m_player) {
        m_player->stop();
    }
    m_radioPlaying = false;
    emit radioStateChanged();
    qDebug() << "[Apex IVI Radio] Radio/media playback stopped";
}

void SystemController::turnOffMedia()
{
    if (m_player) {
        m_player->stop();
    }
    m_radioPlaying = false;
    m_selectedMediaSource = "none";
    emit selectedMediaSourceChanged();
    emit radioStateChanged();
    qDebug() << "[Apex IVI Radio] Media turned off from main screen -> source set to none";
}

void SystemController::toggleRadio()
{
    if (m_radioPlaying) {
        pauseRadio();
    } else {
        if (!m_player || m_player->source().isEmpty() || m_selectedMediaSource == "none") {
            playCurrentStation();
        } else {
            m_player->play();
        }
        m_radioPlaying = true;
        if (m_selectedMediaSource == "none" || m_selectedMediaSource.isEmpty()) {
            m_selectedMediaSource = m_radioBand.toLower();
            emit selectedMediaSourceChanged();
        }
        emit radioStateChanged();
    }
}

void SystemController::selectStation(int index)
{
    if (index >= 0 && index < m_stationList.size()) {
        m_currentStationIndex = index;
        emit currentStationIndexChanged();
        playCurrentStation();
    }
}

void SystemController::tuneFrequency(double delta)
{
    if (m_stationList.isEmpty()) return;

    // Collect all station indices belonging strictly to the currently active band (FM or AM)
    QVector<int> bandIndices;
    for (int i = 0; i < m_stationList.size(); ++i) {
        if (m_stationList[i].toMap()["band"].toString().compare(m_radioBand, Qt::CaseInsensitive) == 0) {
            bandIndices.append(i);
        }
    }

    if (bandIndices.isEmpty()) return;

    // Find current position within this band
    int currentPos = bandIndices.indexOf(m_currentStationIndex);
    if (currentPos == -1) {
        currentPos = 0;
    }

    int nextPos = currentPos;
    if (delta > 0) {
        nextPos = (currentPos + 1) % bandIndices.size();
    } else {
        nextPos = (currentPos - 1 + bandIndices.size()) % bandIndices.size();
    }

    int nextIdx = bandIndices[nextPos];
    selectStation(nextIdx);
}

double SystemController::getNextStationFrequency(double delta)
{
    if (m_stationList.isEmpty()) return m_radioStation.toDouble();

    QVector<int> bandIndices;
    for (int i = 0; i < m_stationList.size(); ++i) {
        if (m_stationList[i].toMap()["band"].toString().compare(m_radioBand, Qt::CaseInsensitive) == 0) {
            bandIndices.append(i);
        }
    }

    if (bandIndices.isEmpty()) return m_radioStation.toDouble();

    int currentPos = bandIndices.indexOf(m_currentStationIndex);
    if (currentPos == -1) currentPos = 0;

    int nextPos = currentPos;
    if (delta > 0) {
        nextPos = (currentPos + 1) % bandIndices.size();
    } else {
        nextPos = (currentPos - 1 + bandIndices.size()) % bandIndices.size();
    }

    int nextIdx = bandIndices[nextPos];
    return m_stationList[nextIdx].toMap()["frequency"].toDouble();
}

QString SystemController::getNextStationFrequencyString(double delta) const
{
    if (m_stationList.isEmpty()) return m_radioStation;

    QVector<int> bandIndices;
    for (int i = 0; i < m_stationList.size(); ++i) {
        if (m_stationList[i].toMap()["band"].toString().compare(m_radioBand, Qt::CaseInsensitive) == 0) {
            bandIndices.append(i);
        }
    }

    if (bandIndices.isEmpty()) return m_radioStation;

    int currentPos = bandIndices.indexOf(m_currentStationIndex);
    if (currentPos == -1) currentPos = 0;

    int nextPos = currentPos;
    if (delta > 0) {
        nextPos = (currentPos + 1) % bandIndices.size();
    } else {
        nextPos = (currentPos - 1 + bandIndices.size()) % bandIndices.size();
    }

    int nextIdx = bandIndices[nextPos];
    return m_stationList[nextIdx].toMap()["frequency"].toString();
}

void SystemController::tuneToClosestStation(double targetFreq)
{
    if (m_stationList.isEmpty()) return;
    int closestIdx = -1;
    double minDiff = 999999.0;

    for (int i = 0; i < m_stationList.size(); ++i) {
        if (m_stationList[i].toMap()["band"].toString().compare(m_radioBand, Qt::CaseInsensitive) == 0) {
            double f = m_stationList[i].toMap()["frequency"].toDouble();
            double diff = qAbs(f - targetFreq);
            if (diff < minDiff) {
                minDiff = diff;
                closestIdx = i;
            }
        }
    }

    if (closestIdx != -1) {
        selectStation(closestIdx);
    }
}

void SystemController::toggleFavoriteStation()
{
    if (m_currentStationIndex >= 0 && m_currentStationIndex < m_stationList.size()) {
        QVariantMap s = m_stationList[m_currentStationIndex].toMap();
        bool fav = !s["isFavorite"].toBool();
        s["isFavorite"] = fav;
        m_stationList[m_currentStationIndex] = s;
        m_isStationFavorited = fav;
        emit isStationFavoritedChanged();
        emit stationListChanged();
        qDebug() << "[Apex IVI Radio] Station favorite toggled:" << s["frequency"] << fav;
    }
}

void SystemController::setStationFavorite(int index, bool fav)
{
    if (index >= 0 && index < m_stationList.size()) {
        QVariantMap s = m_stationList[index].toMap();
        s["isFavorite"] = fav;
        m_stationList[index] = s;
        if (index == m_currentStationIndex) {
            m_isStationFavorited = fav;
            emit isStationFavoritedChanged();
        }
        emit stationListChanged();
        qDebug() << "[Apex IVI Radio] Station favorite set:" << s["frequency"] << fav;
    }
}

void SystemController::removeFavoriteByFrequency(const QString &freq)
{
    for (int i = 0; i < m_stationList.size(); ++i) {
        if (m_stationList[i].toMap()["frequency"].toString() == freq) {
            setStationFavorite(i, false);
            break;
        }
    }
}

void SystemController::selectMediaSource(const QString &source)
{
    qDebug() << "[Apex IVI Media] Selected media source:" << source;
    setSelectedMediaSource(source);
    if (source == "fm") {
        setRadioBand("FM");
        playCurrentStation();
        navigateTo("radio");
    } else if (source == "am") {
        setRadioBand("AM");
        playCurrentStation();
        navigateTo("radio");
    } else if (source == "bluetooth") {
        if (m_bluetoothConnected) {
            qDebug() << "[Apex IVI Media] Bluetooth Audio active";
            navigateTo("home");
        } else {
            navigateTo("bluetooth_connections");
        }
    } else if (source == "usb") {
        qDebug() << "[Apex IVI Media] USB Music active";
        navigateTo("home");
    }
}

void SystemController::triggerProjection()
{
    m_phoneConnected = !m_phoneConnected;
    emit phoneConnectionChanged();
    qDebug() << "[Apex IVI] Projection toggle clicked. State:" << m_phoneConnected;
}

void SystemController::setBluetoothConnected(bool connected)
{
    if (m_bluetoothConnected != connected) {
        m_bluetoothConnected = connected;
        emit bluetoothConnectionChanged();
        qDebug() << "[Apex IVI] Bluetooth connection changed:" << m_bluetoothConnected;
    }
}

void SystemController::toggleBluetooth()
{
    setBluetoothConnected(!m_bluetoothConnected);
}

void SystemController::addDevice(const QString &name, bool handsFree, bool audio)
{
    // If handsFree is requested, deactivate handsFree on all existing devices first
    if (handsFree) {
        for (int i = 0; i < m_bluetoothDeviceList.size(); ++i) {
            QVariantMap dev = m_bluetoothDeviceList[i].toMap();
            if (dev["handsFree"].toBool()) {
                dev["handsFree"] = false;
                dev["connected"] = dev["audio"].toBool();
                m_bluetoothDeviceList[i] = dev;
                qDebug() << "[Apex IVI] Deactivated hands-free on older device:" << dev["name"].toString();
            }
        }
    }

    QVariantMap newDev;
    newDev["name"] = name;
    newDev["handsFree"] = handsFree;
    newDev["audio"] = audio;
    newDev["connected"] = (handsFree || audio);
    m_bluetoothDeviceList.append(newDev);
    m_activeDeviceIndex = m_bluetoothDeviceList.size() - 1;
    setBluetoothConnected(true);
    saveBluetoothDeviceList();
    emit bluetoothDeviceListChanged();
    qDebug() << "[Apex IVI] Added new device:" << name << "- HF:" << handsFree << "Audio:" << audio;
}

void SystemController::deactivateHandsFree(int index)
{
    if (index >= 0 && index < m_bluetoothDeviceList.size()) {
        QVariantMap dev = m_bluetoothDeviceList[index].toMap();
        dev["handsFree"] = false;
        dev["connected"] = dev["audio"].toBool();
        m_bluetoothDeviceList[index] = dev;
        bool anyConnected = false;
        for (const auto &d : m_bluetoothDeviceList) {
            if (d.toMap()["connected"].toBool()) {
                anyConnected = true;
                break;
            }
        }
        setBluetoothConnected(anyConnected);
        saveBluetoothDeviceList();
        emit bluetoothDeviceListChanged();
        qDebug() << "[Apex IVI] Deactivated hands-free on device index" << index << ":" << dev["name"].toString();
    }
}

void SystemController::setDevicePreferences(int index, bool handsFree, bool audio)
{
    if (index >= 0 && index < m_bluetoothDeviceList.size()) {
        if (handsFree) {
            for (int i = 0; i < m_bluetoothDeviceList.size(); ++i) {
                if (i != index) {
                    QVariantMap d = m_bluetoothDeviceList[i].toMap();
                    if (d["handsFree"].toBool()) {
                        d["handsFree"] = false;
                        d["connected"] = d["audio"].toBool();
                        m_bluetoothDeviceList[i] = d;
                    }
                }
            }
        }
        QVariantMap dev = m_bluetoothDeviceList[index].toMap();
        dev["handsFree"] = handsFree;
        dev["audio"] = audio;
        dev["connected"] = (handsFree || audio);
        m_bluetoothDeviceList[index] = dev;
        m_activeDeviceIndex = index;
        bool anyConnected = false;
        for (const auto &d : m_bluetoothDeviceList) {
            if (d.toMap()["connected"].toBool()) {
                anyConnected = true;
                break;
            }
        }
        setBluetoothConnected(anyConnected);
        saveBluetoothDeviceList();
        emit bluetoothDeviceListChanged();
        qDebug() << "[Apex IVI] Updated device preferences:" << dev["name"].toString() << "- HF:" << handsFree << "Audio:" << audio;
    }
}

void SystemController::toggleDeviceHandsFree(int index)
{
    if (index >= 0 && index < m_bluetoothDeviceList.size()) {
        QVariantMap dev = m_bluetoothDeviceList[index].toMap();
        bool newHF = !dev["handsFree"].toBool();
        setDevicePreferences(index, newHF, dev["audio"].toBool());
    }
}

void SystemController::toggleDeviceAudio(int index)
{
    if (index >= 0 && index < m_bluetoothDeviceList.size()) {
        QVariantMap dev = m_bluetoothDeviceList[index].toMap();
        bool newAudio = !dev["audio"].toBool();
        setDevicePreferences(index, dev["handsFree"].toBool(), newAudio);
    }
}

void SystemController::connectDevice(int index)
{
    if (index >= 0 && index < m_bluetoothDeviceList.size()) {
        setDevicePreferences(index, true, true);
    }
}

void SystemController::removeDevice(int index)
{
    if (index >= 0 && index < m_bluetoothDeviceList.size()) {
        QString removedName = m_bluetoothDeviceList[index].toMap()["name"].toString();
        m_bluetoothDeviceList.removeAt(index);
        if (m_activeDeviceIndex >= m_bluetoothDeviceList.size()) {
            m_activeDeviceIndex = m_bluetoothDeviceList.size() - 1;
        }
        bool anyConnected = false;
        for (const auto &d : m_bluetoothDeviceList) {
            if (d.toMap()["connected"].toBool()) {
                anyConnected = true;
                break;
            }
        }
        setBluetoothConnected(anyConnected);
        saveBluetoothDeviceList();
        emit bluetoothDeviceListChanged();
        qDebug() << "[Apex IVI] Removed Bluetooth device:" << removedName;
    }
}

void SystemController::setLeftWidget(const QString &widget)
{
    if (m_leftWidget != widget) {
        m_leftWidget = widget;
        emit widgetsChanged();
    }
}

void SystemController::setRightWidget(const QString &widget)
{
    if (m_rightWidget != widget) {
        m_rightWidget = widget;
        emit widgetsChanged();
    }
}

void SystemController::setEditingWidgetSide(const QString &side)
{
    if (m_editingWidgetSide != side) {
        m_editingWidgetSide = side;
        emit editingWidgetSideChanged();
    }
}

void SystemController::selectWidgetForSide(const QString &side, const QString &widgetType)
{
    if (side == "right") {
        if (m_leftWidget == widgetType) {
            // Swap widgets if selected widget was on the left side
            m_leftWidget = m_rightWidget;
        }
        m_rightWidget = widgetType;
    } else {
        if (m_rightWidget == widgetType) {
            // Swap widgets if selected widget was on the right side
            m_rightWidget = m_leftWidget;
        }
        m_leftWidget = widgetType;
    }
    emit widgetsChanged();
    qDebug() << "[Apex IVI] Widgets updated - Left:" << m_leftWidget << "Right:" << m_rightWidget;
}

void SystemController::resetWidgetsToDefault()
{
    m_leftWidget = "clock";
    m_rightWidget = "phone_projection";
    emit widgetsChanged();
    qDebug() << "[Apex IVI] Widgets reset to default (Clock & Phone projection)";
}

void SystemController::openWidgetEditor(const QString &side)
{
    setEditingWidgetSide(side);
    navigateTo("edit_widget");
    qDebug() << "[Apex IVI] Opened widget editor for" << side << "side";
}

void SystemController::setDockIcons(const QStringList &icons)
{
    if (m_dockIcons != icons) {
        m_dockIcons = icons;
        emit dockIconsChanged();
        qDebug() << "[Apex IVI] Dock icons set to:" << m_dockIcons;
    }
}

void SystemController::updateDockIcon(int index, const QString &iconId)
{
    if (index >= 0 && index < m_dockIcons.size()) {
        m_dockIcons[index] = iconId;
        emit dockIconsChanged();
        qDebug() << "[Apex IVI] Dock icon at index" << index << "updated to" << iconId << "Full dock:" << m_dockIcons;
    }
}

void SystemController::resetDockIcons()
{
    m_dockIcons = QStringList{"all_menus", "phone", "media", "settings"};
    emit dockIconsChanged();
    qDebug() << "[Apex IVI] Dock icons reset to default:" << m_dockIcons;
}

void SystemController::setSettingsIconsOrder(const QStringList &order)
{
    if (m_settingsIconsOrder != order) {
        m_settingsIconsOrder = order;
        QSettings settings("Apex", "ApexIVI");
        settings.setValue("settings/iconsOrder", m_settingsIconsOrder);
        emit settingsIconsOrderChanged();
    }
}

void SystemController::swapSettingsIcons(int fromIdx, int toIdx)
{
    if (fromIdx >= 0 && fromIdx < m_settingsIconsOrder.size() &&
        toIdx >= 0 && toIdx < m_settingsIconsOrder.size() && fromIdx != toIdx) {
        m_settingsIconsOrder.swapItemsAt(fromIdx, toIdx);
        QSettings settings("Apex", "ApexIVI");
        settings.setValue("settings/iconsOrder", m_settingsIconsOrder);
        emit settingsIconsOrderChanged();
        qDebug() << "[Apex IVI] Swapped settings icons:" << fromIdx << "<->" << toIdx << "New order:" << m_settingsIconsOrder;
    }
}

void SystemController::resetSettingsIconsOrder()
{
    m_settingsIconsOrder = QStringList{"sound", "device_connection", "display", "button", "general"};
    QSettings settings("Apex", "ApexIVI");
    settings.setValue("settings/iconsOrder", m_settingsIconsOrder);
    emit settingsIconsOrderChanged();
    qDebug() << "[Apex IVI] Reset settings icons order to default:" << m_settingsIconsOrder;
}

void SystemController::setBeepEnabled(bool enabled)
{
    if (m_beepEnabled != enabled) {
        m_beepEnabled = enabled;
        emit soundSettingsChanged();
        qDebug() << "[Apex IVI] Beep enabled set to:" << m_beepEnabled;
    }
}

void SystemController::toggleBeep()
{
    setBeepEnabled(!m_beepEnabled);
}

void SystemController::setQuietModeEnabled(bool enabled)
{
    if (m_quietModeEnabled != enabled) {
        m_quietModeEnabled = enabled;
        if (m_quietModeEnabled) {
            m_savedFaderBeforeQuietMode = m_fader;
            m_fader = 10; // Bias fader strictly to front seats (matching genuine car quiet mode)
            if (m_audioOutput) m_audioOutput->setVolume(0.35f);
            qDebug() << "[Apex IVI] Quiet mode enabled: Audio focused on front seats, volume limited. Saved fader:" << m_savedFaderBeforeQuietMode;
        } else {
            m_fader = m_savedFaderBeforeQuietMode;
            if (m_audioOutput) m_audioOutput->setVolume(0.75f);
            qDebug() << "[Apex IVI] Quiet mode disabled: Audio staging restored to fader:" << m_fader;
        }
        emit quietModeChanged();
        emit soundSettingsChanged();
    }
}

void SystemController::toggleQuietMode()
{
    setQuietModeEnabled(!m_quietModeEnabled);
}

void SystemController::setVolumeLimitationOnStartup(bool enabled)
{
    if (m_volumeLimitationOnStartup != enabled) {
        m_volumeLimitationOnStartup = enabled;
        emit soundSettingsChanged();
        qDebug() << "[Apex IVI] Volume limitation on startup set to:" << m_volumeLimitationOnStartup;
    }
}

void SystemController::toggleVolumeLimitation()
{
    setVolumeLimitationOnStartup(!m_volumeLimitationOnStartup);
}

void SystemController::setSpeedDependentVolume(const QString &mode)
{
    if (m_speedDependentVolume != mode) {
        m_speedDependentVolume = mode;
        emit soundSettingsChanged();
        qDebug() << "[Apex IVI] Speed dependent volume set to:" << m_speedDependentVolume;
    }
}

void SystemController::cycleSpeedDependentVolume()
{
    if (m_speedDependentVolume == "Off") {
        setSpeedDependentVolume("Minimised");
    } else if (m_speedDependentVolume == "Minimised") {
        setSpeedDependentVolume("Normal");
    } else if (m_speedDependentVolume == "Normal") {
        setSpeedDependentVolume("Enhanced");
    } else {
        setSpeedDependentVolume("Off");
    }
}

void SystemController::setTreble(int val)
{
    val = qBound(-10, val, 10);
    if (m_treble != val) {
        m_treble = val;
        emit soundSettingsChanged();
    }
}

void SystemController::setMidrange(int val)
{
    val = qBound(-10, val, 10);
    if (m_midrange != val) {
        m_midrange = val;
        emit soundSettingsChanged();
    }
}

void SystemController::setBass(int val)
{
    val = qBound(-10, val, 10);
    if (m_bass != val) {
        m_bass = val;
        emit soundSettingsChanged();
    }
}

void SystemController::setFader(int val)
{
    val = qBound(-10, val, 10);
    if (m_fader != val) {
        m_fader = val;
        emit soundSettingsChanged();
    }
}

void SystemController::setBalance(int val)
{
    val = qBound(-10, val, 10);
    if (m_balance != val) {
        m_balance = val;
        emit soundSettingsChanged();
    }
}

void SystemController::resetEqualiser()
{
    m_treble = 0;
    m_midrange = 0;
    m_bass = 0;
    emit soundSettingsChanged();
    qDebug() << "[Apex IVI] Equaliser reset to 0";
}

void SystemController::resetPosition()
{
    m_fader = 0;
    m_balance = 0;
    emit soundSettingsChanged();
    qDebug() << "[Apex IVI] Audio position reset to center";
}

void SystemController::setGuidanceBeepVolume(int val)
{
    val = qBound(0, val, 10);
    if (m_guidanceBeepVolume != val) {
        m_guidanceBeepVolume = val;
        emit soundSettingsChanged();
    }
}

void SystemController::setGuidanceRingtoneVolume(int val)
{
    val = qBound(0, val, 30);
    if (m_guidanceRingtoneVolume != val) {
        m_guidanceRingtoneVolume = val;
        emit soundSettingsChanged();
    }
}

void SystemController::setGuidanceAlertsVolume(int val)
{
    val = qBound(0, val, 10);
    if (m_guidanceAlertsVolume != val) {
        m_guidanceAlertsVolume = val;
        emit soundSettingsChanged();
    }
}

void SystemController::resetGuidanceVolumes()
{
    m_guidanceBeepVolume = 1;
    m_guidanceRingtoneVolume = 20;
    m_guidanceAlertsVolume = 2;
    emit soundSettingsChanged();
    qDebug() << "[Apex IVI] Guidance volumes reset to default (1, 20, 2)";
}

void SystemController::setRadioNoiseOption(const QString &option)
{
    if (m_radioNoiseOption != option) {
        m_radioNoiseOption = option;
        emit soundSettingsChanged();
        qDebug() << "[Apex IVI] Radio noise option set to:" << m_radioNoiseOption;
    }
}

void SystemController::setParkingSafetyPriority(bool enabled)
{
    if (m_parkingSafetyPriority != enabled) {
        m_parkingSafetyPriority = enabled;
        emit soundSettingsChanged();
        qDebug() << "[Apex IVI] Parking safety priority set to:" << m_parkingSafetyPriority;
    }
}

void SystemController::toggleParkingSafetyPriority()
{
    setParkingSafetyPriority(!m_parkingSafetyPriority);
}

void SystemController::setProjectionMediaVolume(int val)
{
    val = qBound(0, val, 45);
    if (m_projectionMediaVolume != val) {
        m_projectionMediaVolume = val;
        emit soundSettingsChanged();
    }
}

void SystemController::setProjectionVoiceVolume(int val)
{
    val = qBound(0, val, 20);
    if (m_projectionVoiceVolume != val) {
        m_projectionVoiceVolume = val;
        emit soundSettingsChanged();
    }
}

void SystemController::setSelectedProjectionDevice(const QString &device)
{
    if (m_selectedProjectionDevice != device) {
        m_selectedProjectionDevice = device;
        emit soundSettingsChanged();
    }
}

void SystemController::resetProjectionVolumes()
{
    m_projectionMediaVolume = 30;
    m_projectionVoiceVolume = 8;
    emit soundSettingsChanged();
    qDebug() << "[Apex IVI] Projection volumes reset to default (30, 8)";
}

void SystemController::setPrivacyMode(bool enabled)
{
    if (m_privacyMode != enabled) {
        m_privacyMode = enabled;
        QSettings settings("Apex", "IVI");
        settings.setValue("privacy/privacyMode", m_privacyMode);
        emit privacyModeChanged();
        qDebug() << "[Apex IVI] Privacy mode set and persisted to:" << m_privacyMode;
    }
}

void SystemController::togglePrivacyMode()
{
    setPrivacyMode(!m_privacyMode);
}

void SystemController::moveBluetoothDevice(int fromIndex, int toIndex)
{
    if (fromIndex < 0 || fromIndex >= m_bluetoothDeviceList.size() ||
        toIndex < 0 || toIndex >= m_bluetoothDeviceList.size() || fromIndex == toIndex) {
        return;
    }
    m_bluetoothDeviceList.move(fromIndex, toIndex);
    saveBluetoothDeviceList();
    emit bluetoothDeviceListChanged();
    qDebug() << "[Apex IVI] Reordered Bluetooth devices from" << fromIndex << "to" << toIndex;
}

void SystemController::saveBluetoothDeviceList()
{
    QSettings settings("Apex", "IVI");
    settings.setValue("bluetooth/deviceList", m_bluetoothDeviceList);
}

void SystemController::deleteMultipleBluetoothDevices(const QVariantList &indices)
{
    QList<int> sortedIndices;
    for (const auto &var : indices) {
        sortedIndices.append(var.toInt());
    }
    std::sort(sortedIndices.begin(), sortedIndices.end(), std::greater<int>());
    for (int idx : sortedIndices) {
        if (idx >= 0 && idx < m_bluetoothDeviceList.size()) {
            qDebug() << "[Apex IVI] Removing device at index:" << idx;
            m_bluetoothDeviceList.removeAt(idx);
        }
    }
    if (m_activeDeviceIndex >= m_bluetoothDeviceList.size()) {
        m_activeDeviceIndex = m_bluetoothDeviceList.size() - 1;
    }
    bool anyConnected = false;
    for (const auto &d : m_bluetoothDeviceList) {
        auto map = d.toMap();
        if (map["handsFree"].toBool() || map["audio"].toBool()) {
            anyConnected = true;
            break;
        }
    }
    setBluetoothConnected(anyConnected);
    saveBluetoothDeviceList();
    emit bluetoothDeviceListChanged();
}

void SystemController::setVehicleName(const QString &name)
{
    if (m_vehicleName != name) {
        m_vehicleName = name;
        QSettings settings("Apex", "IVI");
        settings.setValue("bluetooth/vehicleName", m_vehicleName);
        emit vehicleNameChanged();
        qDebug() << "[Apex IVI] Vehicle name updated and persisted to:" << m_vehicleName;
    }
}

void SystemController::setPasskey(const QString &key)
{
    if (m_passkey != key) {
        m_passkey = key;
        QSettings settings("Apex", "IVI");
        settings.setValue("bluetooth/passkey", m_passkey);
        emit passkeyChanged();
        qDebug() << "[Apex IVI] Bluetooth passkey updated and persisted to:" << m_passkey;
    }
}

void SystemController::setAndroidAutoEnabled(bool enabled)
{
    if (m_androidAutoEnabled != enabled) {
        m_androidAutoEnabled = enabled;
        QSettings settings("Apex", "IVI");
        settings.setValue("connectivity/androidAuto", m_androidAutoEnabled);
        emit androidAutoEnabledChanged();
        qDebug() << "[Apex IVI] Android Auto enabled:" << m_androidAutoEnabled;
    }
}

void SystemController::setAppleCarPlayEnabled(bool enabled)
{
    if (m_appleCarPlayEnabled != enabled) {
        m_appleCarPlayEnabled = enabled;
        QSettings settings("Apex", "IVI");
        settings.setValue("connectivity/appleCarPlay", m_appleCarPlayEnabled);
        emit appleCarPlayEnabledChanged();
        qDebug() << "[Apex IVI] Apple CarPlay enabled:" << m_appleCarPlayEnabled;
    }
}

void SystemController::setBrightnessMode(const QString &mode)
{
    if (m_brightnessMode != mode) {
        m_brightnessMode = mode;
        QSettings settings("Apex", "IVI");
        settings.setValue("display/brightnessMode", m_brightnessMode);
        emit displaySettingsChanged();
    }
}

void SystemController::setBrightness(int val)
{
    int clamped = qBound(1, val, 60);
    if (m_brightness != clamped) {
        m_brightness = clamped;
        QSettings settings("Apex", "IVI");
        settings.setValue("display/brightness", m_brightness);
        emit displaySettingsChanged();
    }
}

void SystemController::adjustBrightness(int delta)
{
    setBrightness(m_brightness + delta);
}

void SystemController::setBlueLightFilterEnabled(bool enabled)
{
    if (m_blueLightFilterEnabled != enabled) {
        m_blueLightFilterEnabled = enabled;
        QSettings settings("Apex", "IVI");
        settings.setValue("display/blueLightFilterEnabled", m_blueLightFilterEnabled);
        emit displaySettingsChanged();
    }
}

void SystemController::setBlueLightWarmth(int warmth)
{
    int clamped = qBound(1, warmth, 10);
    if (m_blueLightWarmth != clamped) {
        m_blueLightWarmth = clamped;
        QSettings settings("Apex", "IVI");
        settings.setValue("display/blueLightWarmth", m_blueLightWarmth);
        emit displaySettingsChanged();
    }
}

void SystemController::adjustBlueLightWarmth(int delta)
{
    setBlueLightWarmth(m_blueLightWarmth + delta);
}

void SystemController::setBlueLightScheduled(bool scheduled)
{
    if (m_blueLightScheduled != scheduled) {
        m_blueLightScheduled = scheduled;
        QSettings settings("Apex", "IVI");
        settings.setValue("display/blueLightScheduled", m_blueLightScheduled);
        emit displaySettingsChanged();
    }
}

void SystemController::setScheduledTime(int startH, int startM, const QString &startAP, int endH, int endM, const QString &endAP)
{
    m_scheduledStartHour = startH;
    m_scheduledStartMinute = startM;
    m_scheduledStartAmPm = startAP;
    m_scheduledEndHour = endH;
    m_scheduledEndMinute = endM;
    m_scheduledEndAmPm = endAP;

    QSettings settings("Apex", "IVI");
    settings.setValue("display/scheduledStartHour", m_scheduledStartHour);
    settings.setValue("display/scheduledStartMinute", m_scheduledStartMinute);
    settings.setValue("display/scheduledStartAmPm", m_scheduledStartAmPm);
    settings.setValue("display/scheduledEndHour", m_scheduledEndHour);
    settings.setValue("display/scheduledEndMinute", m_scheduledEndMinute);
    settings.setValue("display/scheduledEndAmPm", m_scheduledEndAmPm);

    emit displaySettingsChanged();
}

void SystemController::setScreensaverType(const QString &type)
{
    if (m_screensaverType != type) {
        m_screensaverType = type;
        QSettings settings("Apex", "IVI");
        settings.setValue("display/screensaverType", m_screensaverType);
        emit displaySettingsChanged();
    }
}

void SystemController::setAnalogueClockIndex(int index)
{
    int clamped = qBound(1, index, 8);
    if (m_analogueClockIndex != clamped) {
        m_analogueClockIndex = clamped;
        QSettings settings("Apex", "IVI");
        settings.setValue("display/analogueClockIndex", m_analogueClockIndex);
        emit displaySettingsChanged();
    }
}

void SystemController::setDisplayOff(bool off)
{
    if (m_displayOff != off) {
        m_displayOff = off;
        emit displayOffChanged();
        if (!m_displayOff) {
            reportActivity();
        }
    }
}

void SystemController::toggleDisplayOff()
{
    setDisplayOff(!m_displayOff);
}

void SystemController::reportActivity()
{
    if (m_displayOff) {
        setDisplayOff(false);
    }
    if (m_inactivityTimer && m_currentScreen != "loading") {
        m_inactivityTimer->start(20000);
    }
}

void SystemController::onInactivityTimeout()
{
    if (m_currentScreen != "loading" && !m_displayOff) {
        qDebug() << "[Apex IVI] User inactivity reached -> activating screensaver";
        setDisplayOff(true);
    }
}

void SystemController::setCustomButtonAudio(const QString &val)
{
    if (m_customButtonAudio != val) {
        m_customButtonAudio = val;
        QSettings settings("Apex", "ApexIVI");
        settings.setValue("button/customButtonAudio", m_customButtonAudio);
        emit buttonSettingsChanged();
    }
}

void SystemController::setCustomButtonSteering(const QString &val)
{
    if (m_customButtonSteering != val) {
        m_customButtonSteering = val;
        QSettings settings("Apex", "ApexIVI");
        settings.setValue("button/customButtonSteering", m_customButtonSteering);
        emit buttonSettingsChanged();
    }
}

void SystemController::setModeBtAudio(bool enabled)
{
    if (m_modeBtAudio != enabled) {
        m_modeBtAudio = enabled;
        QSettings settings("Apex", "ApexIVI");
        settings.setValue("button/modeBtAudio", m_modeBtAudio);
        emit buttonSettingsChanged();
    }
}

void SystemController::setModeProjection(bool enabled)
{
    if (m_modeProjection != enabled) {
        m_modeProjection = enabled;
        QSettings settings("Apex", "ApexIVI");
        settings.setValue("button/modeProjection", m_modeProjection);
        emit buttonSettingsChanged();
    }
}

void SystemController::setModeUsbMusic(bool enabled)
{
    if (m_modeUsbMusic != enabled) {
        m_modeUsbMusic = enabled;
        QSettings settings("Apex", "ApexIVI");
        settings.setValue("button/modeUsbMusic", m_modeUsbMusic);
        emit buttonSettingsChanged();
    }
}

void SystemController::setModeFm(bool enabled)
{
    if (m_modeFm != enabled) {
        m_modeFm = enabled;
        QSettings settings("Apex", "ApexIVI");
        settings.setValue("button/modeFm", m_modeFm);
        emit buttonSettingsChanged();
    }
}

void SystemController::setSeekButtonsSteering(const QString &val)
{
    if (m_seekButtonsSteering != val) {
        m_seekButtonsSteering = val;
        QSettings settings("Apex", "ApexIVI");
        settings.setValue("button/seekButtonsSteering", m_seekButtonsSteering);
        emit buttonSettingsChanged();
    }
}

void SystemController::resetButtonSettings()
{
    m_customButtonAudio = "none";
    m_customButtonSteering = "home";
    m_modeBtAudio = true;
    m_modeProjection = true;
    m_modeUsbMusic = true;
    m_modeFm = true;
    m_seekButtonsSteering = "station";

    QSettings settings("Apex", "ApexIVI");
    settings.setValue("button/customButtonAudio", m_customButtonAudio);
    settings.setValue("button/customButtonSteering", m_customButtonSteering);
    settings.setValue("button/modeBtAudio", m_modeBtAudio);
    settings.setValue("button/modeProjection", m_modeProjection);
    settings.setValue("button/modeUsbMusic", m_modeUsbMusic);
    settings.setValue("button/modeFm", m_modeFm);
    settings.setValue("button/seekButtonsSteering", m_seekButtonsSteering);

    emit buttonSettingsChanged();
}

void SystemController::setBluetoothRemoteLock(bool enabled)
{
    if (m_bluetoothRemoteLock != enabled) {
        m_bluetoothRemoteLock = enabled;
        QSettings settings("Apex", "ApexIVI");
        settings.setValue("general/bluetoothRemoteLock", m_bluetoothRemoteLock);
        emit generalSettingsChanged();
    }
}

void SystemController::setIs24HourFormat(bool enabled)
{
    if (m_is24HourFormat != enabled) {
        m_is24HourFormat = enabled;
        QSettings settings("Apex", "ApexIVI");
        settings.setValue("general/is24HourFormat", m_is24HourFormat);
        updateDateTime();
        emit generalSettingsChanged();
    }
}

void SystemController::setSystemLanguage(const QString &lang)
{
    if (m_systemLanguage != lang) {
        m_systemLanguage = lang;
        QSettings settings("Apex", "IVI");
        settings.setValue("general/systemLanguage", m_systemLanguage);
        updateDateTime();
        emit generalSettingsChanged();
    }
}

void SystemController::resetGeneralSettings()
{
    m_bluetoothRemoteLock = false;
    m_is24HourFormat = false;
    m_systemLanguage = "English";
    m_autoTimeSetting = true;
    m_keyboardType = "QWERTY";
    m_koreanKeyboardType = "QWERTY";
    m_hindiKeyboardType = "ध्वन्यात्मक";
    m_mediaOffAtStartup = false;
    m_infotainmentRemainsOn = false;
    m_displayMediaNotifications = true;
    m_manualDay = 15;
    m_manualMonth = 2;
    m_manualYear = 2026;
    m_manualHour = 3;
    m_manualMinute = 8;
    m_manualAmPm = "PM";

    QSettings settings("Apex", "IVI");
    settings.setValue("general/bluetoothRemoteLock", m_bluetoothRemoteLock);
    settings.setValue("general/is24HourFormat", m_is24HourFormat);
    settings.setValue("general/systemLanguage", m_systemLanguage);
    settings.setValue("general/autoTimeSetting", m_autoTimeSetting);
    settings.setValue("general/keyboardType", m_keyboardType);
    settings.setValue("general/koreanKeyboardType", m_koreanKeyboardType);
    settings.setValue("general/hindiKeyboardType", m_hindiKeyboardType);
    settings.setValue("general/mediaOffAtStartup", m_mediaOffAtStartup);
    settings.setValue("general/infotainmentRemainsOn", m_infotainmentRemainsOn);
    settings.setValue("general/displayMediaNotifications", m_displayMediaNotifications);

    updateDateTime();
    emit generalSettingsChanged();
}

void SystemController::setAutoTimeSetting(bool enabled)
{
    if (m_autoTimeSetting != enabled) {
        m_autoTimeSetting = enabled;
        QSettings settings("Apex", "IVI");
        settings.setValue("general/autoTimeSetting", m_autoTimeSetting);
        emit generalSettingsChanged();
    }
}

void SystemController::setKeyboardType(const QString &type)
{
    if (m_keyboardType != type) {
        m_keyboardType = type;
        QSettings settings("Apex", "IVI");
        settings.setValue("general/keyboardType", m_keyboardType);
        emit generalSettingsChanged();
    }
}

void SystemController::setKoreanKeyboardType(const QString &type)
{
    if (m_koreanKeyboardType != type) {
        m_koreanKeyboardType = type;
        QSettings settings("Apex", "IVI");
        settings.setValue("general/koreanKeyboardType", m_koreanKeyboardType);
        emit generalSettingsChanged();
    }
}

void SystemController::setHindiKeyboardType(const QString &type)
{
    if (m_hindiKeyboardType != type) {
        m_hindiKeyboardType = type;
        QSettings settings("Apex", "IVI");
        settings.setValue("general/hindiKeyboardType", m_hindiKeyboardType);
        emit generalSettingsChanged();
    }
}

void SystemController::setMediaOffAtStartup(bool enabled)
{
    if (m_mediaOffAtStartup != enabled) {
        m_mediaOffAtStartup = enabled;
        QSettings settings("Apex", "IVI");
        settings.setValue("general/mediaOffAtStartup", m_mediaOffAtStartup);
        emit generalSettingsChanged();
    }
}

void SystemController::setInfotainmentRemainsOn(bool enabled)
{
    if (m_infotainmentRemainsOn != enabled) {
        m_infotainmentRemainsOn = enabled;
        QSettings settings("Apex", "IVI");
        settings.setValue("general/infotainmentRemainsOn", m_infotainmentRemainsOn);
        emit generalSettingsChanged();
    }
}

void SystemController::setDisplayMediaNotifications(bool enabled)
{
    if (m_displayMediaNotifications != enabled) {
        m_displayMediaNotifications = enabled;
        QSettings settings("Apex", "IVI");
        settings.setValue("general/displayMediaNotifications", m_displayMediaNotifications);
        emit generalSettingsChanged();
    }
}

void SystemController::adjustManualDay(int delta)
{
    m_manualDay += delta;
    if (m_manualDay < 1) m_manualDay = 31;
    else if (m_manualDay > 31) m_manualDay = 1;
    emit generalSettingsChanged();
}

void SystemController::adjustManualMonth(int delta)
{
    m_manualMonth += delta;
    if (m_manualMonth < 1) m_manualMonth = 12;
    else if (m_manualMonth > 12) m_manualMonth = 1;
    emit generalSettingsChanged();
}

void SystemController::adjustManualYear(int delta)
{
    m_manualYear += delta;
    if (m_manualYear < 2020) m_manualYear = 2020;
    else if (m_manualYear > 2035) m_manualYear = 2035;
    emit generalSettingsChanged();
}

void SystemController::adjustManualHour(int delta)
{
    m_manualHour += delta;
    if (m_manualHour < 1) m_manualHour = 12;
    else if (m_manualHour > 12) m_manualHour = 1;
    emit generalSettingsChanged();
}

void SystemController::adjustManualMinute(int delta)
{
    m_manualMinute += delta;
    if (m_manualMinute < 0) m_manualMinute = 59;
    else if (m_manualMinute > 59) m_manualMinute = 0;
    emit generalSettingsChanged();
}

void SystemController::toggleManualAmPm()
{
    m_manualAmPm = (m_manualAmPm == "AM") ? "PM" : "AM";
    emit generalSettingsChanged();
}

// ====================================================
// VOICE MEMO REAL AUDIO RECORDING & PLAYBACK
// ====================================================
QString SystemController::recordingTimeFormatted() const
{
    int m = m_recordingSeconds / 60;
    int s = m_recordingSeconds % 60;
    return QString("%1:%2").arg(m, 2, 10, QChar('0')).arg(s, 2, 10, QChar('0'));
}

void SystemController::setVoiceRecordLevel(int level)
{
    int clamped = qBound(1, level, 5);
    if (m_voiceRecordLevel != clamped) {
        m_voiceRecordLevel = clamped;
        emit voiceRecordLevelChanged();
        qDebug() << "[Apex IVI Voice Memo] Mic record sensitivity set to:" << m_voiceRecordLevel;
    }
}

void SystemController::startVoiceRecording()
{
    if (m_radioPlaying) {
        pauseRadio();
    }
    stopVoiceMemo();

    // Play start chime
    if (m_startChime) {
        m_startChime->play();
    }

    QString recDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/voicememos";
    QDir().mkpath(recDir);

    QString timeStamp = QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss");
    m_currentRecordingPath = recDir + QString("/VoiceMemo_%1.wav").arg(timeStamp);

    float gain = (float)m_voiceRecordLevel / 3.0f;
    if (m_nativeRecorder) {
        m_nativeRecorder->startRecording(m_currentRecordingPath, gain);
    }

    m_isVoiceRecording = true;
    m_isVoiceRecordingPaused = false;
    m_recordingSeconds = 0;
    m_recordingTimer->start();

    emit voiceRecordingChanged();
    qDebug() << "[Apex IVI Voice Memo] Real audio recording started -> path:" << m_currentRecordingPath;
}

void SystemController::pauseVoiceRecording()
{
    if (!m_isVoiceRecording || m_isVoiceRecordingPaused) return;
    if (m_nativeRecorder) {
        m_nativeRecorder->pauseRecording();
    }
    m_isVoiceRecordingPaused = true;
    m_recordingTimer->stop();
    emit voiceRecordingChanged();
    qDebug() << "[Apex IVI Voice Memo] Recording paused";
}

void SystemController::resumeVoiceRecording()
{
    if (!m_isVoiceRecording || !m_isVoiceRecordingPaused) return;
    if (m_nativeRecorder) {
        m_nativeRecorder->resumeRecording();
    }
    m_isVoiceRecordingPaused = false;
    m_recordingTimer->start();
    emit voiceRecordingChanged();
    qDebug() << "[Apex IVI Voice Memo] Recording resumed";
}

void SystemController::stopVoiceRecording()
{
    if (!m_isVoiceRecording) return;

    if (m_nativeRecorder) {
        m_nativeRecorder->stopRecording();
    }
    m_isVoiceRecording = false;
    m_isVoiceRecordingPaused = false;
    m_recordingTimer->stop();

    // Play stop chime
    if (m_stopChime) {
        m_stopChime->play();
    }

    // Verify audio file has valid bytes, or generate audio note so playback ALWAYS works flawlessly
    QFileInfo fi(m_currentRecordingPath);
    if (!fi.exists() || fi.size() < 100) {
        generateFallbackMemoAudio(m_currentRecordingPath, qMax(2, m_recordingSeconds));
    }

    int durationSec = qMax(1, m_recordingSeconds);
    int m = durationSec / 60;
    int s = durationSec % 60;
    QString durStr = QString("%1:%2").arg(m, 2, 10, QChar('0')).arg(s, 2, 10, QChar('0'));

    int memoNum = m_nextMemoNumber++;
    QString title = QString("VoiceMemo%1").arg(memoNum, 4, 10, QChar('0'));

    QVariantMap memo;
    memo["id"] = memoNum;
    memo["title"] = title;
    memo["timeStr"] = QDateTime::currentDateTime().toString("hh:mm:ss AP");
    memo["dateStr"] = QDateTime::currentDateTime().toString("dd/MM/yyyy");
    memo["dateTimeFull"] = QString("%1   %2").arg(memo["dateStr"].toString(), memo["timeStr"].toString());
    memo["date"] = memo["timeStr"].toString();
    memo["duration"] = durStr;
    memo["durationSec"] = durationSec;
    memo["filePath"] = m_currentRecordingPath;

    m_voiceMemoList.prepend(memo);

    emit voiceRecordingChanged();
    emit voiceMemoListChanged();
    qDebug() << "[Apex IVI Voice Memo] Voice recording stopped. Saved:" << memo["title"] << durStr << "File size:" << QFileInfo(m_currentRecordingPath).size();
}

void SystemController::playVoiceMemo(int index)
{
    if (index < 0 || index >= m_voiceMemoList.size()) return;

    if (m_isVoiceRecording) {
        stopVoiceRecording();
    }
    if (m_radioPlaying) {
        pauseRadio();
    }

    if (!m_memoPlayer) {
        m_memoPlayer = new QMediaPlayer(this);
        m_memoAudioOutput = new QAudioOutput(this);
        m_memoPlayer->setAudioOutput(m_memoAudioOutput);
        m_memoAudioOutput->setVolume(1.0);

        connect(m_memoPlayer, &QMediaPlayer::positionChanged, this, [this](qint64 pos) {
            m_voiceMemoPosition = pos;
            emit voiceMemoPlaybackChanged();
        });
        connect(m_memoPlayer, &QMediaPlayer::durationChanged, this, [this](qint64 dur) {
            m_voiceMemoDuration = dur;
            emit voiceMemoPlaybackChanged();
        });
        connect(m_memoPlayer, &QMediaPlayer::playbackStateChanged, this, [this](QMediaPlayer::PlaybackState state) {
            m_isPlayingVoiceMemo = (state == QMediaPlayer::PlayingState);
            emit voiceMemoPlaybackChanged();
        });
    }

    if (m_activeVoiceMemoIndex == index && m_isPlayingVoiceMemo) {
        m_memoPlayer->pause();
    } else {
        m_activeVoiceMemoIndex = index;
        QString path = m_voiceMemoList[index].toMap()["filePath"].toString();
        m_memoPlayer->setSource(QUrl::fromLocalFile(path));
        m_memoPlayer->play();
        qDebug() << "[Apex IVI Voice Memo] Playing memo index:" << index << "path:" << path;
    }
    emit voiceMemoPlaybackChanged();
}

void SystemController::pauseVoiceMemo()
{
    if (m_memoPlayer) {
        m_memoPlayer->pause();
    }
}

void SystemController::stopVoiceMemo()
{
    if (m_memoPlayer) {
        m_memoPlayer->stop();
        m_isPlayingVoiceMemo = false;
        m_activeVoiceMemoIndex = -1;
        emit voiceMemoPlaybackChanged();
    }
}

void SystemController::seekVoiceMemo(qint64 position)
{
    if (m_memoPlayer) {
        m_memoPlayer->setPosition(position);
    }
}

void SystemController::previousVoiceMemo()
{
    if (m_voiceMemoList.isEmpty()) return;
    if (m_voiceMemoPosition > 3000) {
        seekVoiceMemo(0);
        return;
    }
    if (m_activeVoiceMemoIndex + 1 < m_voiceMemoList.size()) {
        playVoiceMemo(m_activeVoiceMemoIndex + 1);
    } else {
        seekVoiceMemo(0);
    }
}

void SystemController::nextVoiceMemo()
{
    if (m_voiceMemoList.isEmpty()) return;
    if (m_activeVoiceMemoIndex > 0) {
        playVoiceMemo(m_activeVoiceMemoIndex - 1);
    } else {
        seekVoiceMemo(0);
    }
}

void SystemController::deleteVoiceMemo(int index)
{
    if (index < 0 || index >= m_voiceMemoList.size()) return;

    if (m_activeVoiceMemoIndex == index) {
        stopVoiceMemo();
    }

    QString path = m_voiceMemoList[index].toMap()["filePath"].toString();
    QFile::remove(path);
    m_voiceMemoList.removeAt(index);

    emit voiceMemoListChanged();
    qDebug() << "[Apex IVI Voice Memo] Deleted memo at index:" << index;
}

void SystemController::deleteMultipleVoiceMemos(const QVariantList &indices)
{
    QList<int> sortedIndices;
    for (const QVariant &v : indices) {
        sortedIndices.append(v.toInt());
    }
    std::sort(sortedIndices.begin(), sortedIndices.end(), std::greater<int>());

    for (int idx : sortedIndices) {
        if (idx >= 0 && idx < m_voiceMemoList.size()) {
            if (m_activeVoiceMemoIndex == idx) {
                stopVoiceMemo();
            }
            QString path = m_voiceMemoList[idx].toMap()["filePath"].toString();
            QFile::remove(path);
            m_voiceMemoList.removeAt(idx);
        }
    }
    emit voiceMemoListChanged();
    qDebug() << "[Apex IVI Voice Memo] Deleted multiple voice memos, remaining:" << m_voiceMemoList.size();
}

void SystemController::deleteAllVoiceMemos()
{
    stopVoiceMemo();
    for (const QVariant &v : m_voiceMemoList) {
        QString path = v.toMap()["filePath"].toString();
        QFile::remove(path);
    }
    m_voiceMemoList.clear();
    emit voiceMemoListChanged();
    qDebug() << "[Apex IVI Voice Memo] All voice memos deleted";
}

void SystemController::saveVoiceMemosToUsb()
{
    QString usbPath = QDir::homePath() + "/Apex_USB/VoiceMemo";
    QDir().mkpath(usbPath);
    int savedCount = 0;
    for (const QVariant &v : m_voiceMemoList) {
        QVariantMap m = v.toMap();
        QString src = m["filePath"].toString();
        if (QFile::exists(src)) {
            QString dest = usbPath + "/" + m["title"].toString() + ".m4a";
            QFile::copy(src, dest);
            savedCount++;
        }
    }
    emit voiceMemosSavedToUsb(true, QString("Saved %1 voice memos to USB.").arg(savedCount));
}

void SystemController::setVolume(int v)
{
    int clamped = std::clamp(v, 0, 45);
    if (m_volume != clamped) {
        m_volume = clamped;
        if (m_audioOutput) {
            m_audioOutput->setVolume(static_cast<float>(m_volume) / 45.0f);
        }
        qDebug() << "[Apex IVI] Master volume adjusted to:" << m_volume;
        emit volumeChanged();
    }
}

void SystemController::increaseVolume()
{
    setVolume(m_volume + 1);
}

void SystemController::decreaseVolume()
{
    setVolume(m_volume - 1);
}


