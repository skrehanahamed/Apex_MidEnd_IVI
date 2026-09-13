#pragma once

#include <QObject>
#include <QByteArray>
#include <QThread>
#include <QMutex>
#include <QWaitCondition>
#include <QQueue>
#include <cstdint>

#ifndef Q_OS_MACOS
#include <alsa/asoundlib.h>
#endif

class AndroidAutoAudioSink : public QObject
{
    Q_OBJECT
public:
    explicit AndroidAutoAudioSink(QObject *parent = nullptr);
    ~AndroidAutoAudioSink() override;

    void start();
    void stop();
    void reset();

    // Channel 4 = Media (48kHz Stereo), Channel 5 = Speech (16kHz Mono), Channel 6 = System (16kHz Mono)
    void queueAudioPacket(uint8_t channel, const uint8_t *data, int size);

private:
    struct AudioPacket {
        uint8_t channel;
        QByteArray data;
    };

    void workerLoop();

    QThread *m_thread = nullptr;
    QMutex m_mutex;
    QWaitCondition m_cond;
    QQueue<AudioPacket> m_queue;
    bool m_running = false;

#ifndef Q_OS_MACOS
    snd_pcm_t *m_mediaHandle = nullptr;  // Channel 4: 48000 Hz, 2 ch
    snd_pcm_t *m_speechHandle = nullptr; // Channels 5 & 6: 16000 Hz, 1 ch

    bool openDevice(snd_pcm_t **handle, unsigned int rate, unsigned int channels, const char *streamName);
    void closeDevice(snd_pcm_t **handle);
#endif
};
