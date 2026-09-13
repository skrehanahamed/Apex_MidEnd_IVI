#include "AndroidAutoAudioSink.hpp"
#include <QDebug>

AndroidAutoAudioSink::AndroidAutoAudioSink(QObject *parent)
    : QObject(parent)
{
    start();
}

AndroidAutoAudioSink::~AndroidAutoAudioSink()
{
    stop();
}

void AndroidAutoAudioSink::start()
{
    QMutexLocker locker(&m_mutex);
    if (m_running) return;

    m_running = true;
    m_thread = QThread::create([this]() {
        workerLoop();
    });
    m_thread->setObjectName("AAAudioWorker");
    m_thread->start(QThread::HighPriority);
}

void AndroidAutoAudioSink::stop()
{
    {
        QMutexLocker locker(&m_mutex);
        if (!m_running) return;
        m_running = false;
        m_cond.wakeAll();
    }

    if (m_thread) {
        m_thread->quit();
        m_thread->wait();
        delete m_thread;
        m_thread = nullptr;
    }

    reset();
}

void AndroidAutoAudioSink::reset()
{
    QMutexLocker locker(&m_mutex);
    m_queue.clear();

#ifdef HAVE_ALSA
    closeDevice(&m_mediaHandle);
    closeDevice(&m_speechHandle);
#endif
}

void AndroidAutoAudioSink::queueAudioPacket(uint8_t channel, const uint8_t *data, int size)
{
    if (!data || size <= 0) return;

    QMutexLocker locker(&m_mutex);
    if (!m_running) return;

    // Bound queue size to ~250ms of audio to prevent latency buildup
    if (m_queue.size() > 40) {
        m_queue.dequeue();
    }

    AudioPacket pkt;
    pkt.channel = channel;
    pkt.data = QByteArray(reinterpret_cast<const char*>(data), size);
    m_queue.enqueue(pkt);
    m_cond.wakeOne();
}

#ifdef HAVE_ALSA
bool AndroidAutoAudioSink::openDevice(snd_pcm_t **handle, unsigned int rate, unsigned int channels, const char *streamName)
{
    if (*handle) return true;

    int err = snd_pcm_open(handle, "pipewire", SND_PCM_STREAM_PLAYBACK, 0);
    if (err < 0) {
        err = snd_pcm_open(handle, "default", SND_PCM_STREAM_PLAYBACK, 0);
        if (err < 0) {
            qWarning() << "[AA Audio] Failed to open ALSA playback for" << streamName << ":" << snd_strerror(err);
            *handle = nullptr;
            return false;
        }
    }

    err = snd_pcm_set_params(*handle,
                             SND_PCM_FORMAT_S16_LE,
                             SND_PCM_ACCESS_RW_INTERLEAVED,
                             channels,
                             rate,
                             1, /* soft_resample */
                             50000 /* 50ms buffer latency */);
    if (err < 0) {
        qWarning() << "[AA Audio] Failed to set ALSA parameters for" << streamName << ":" << snd_strerror(err);
        snd_pcm_close(*handle);
        *handle = nullptr;
        return false;
    }

    qInfo() << "[AA Audio] Successfully opened ALSA PipeWire playback for" << streamName
            << "at" << rate << "Hz," << channels << "ch";
    return true;
}

void AndroidAutoAudioSink::closeDevice(snd_pcm_t **handle)
{
    if (*handle) {
        snd_pcm_drop(*handle);
        snd_pcm_close(*handle);
        *handle = nullptr;
    }
}
#endif

void AndroidAutoAudioSink::workerLoop()
{
    while (true) {
        AudioPacket pkt;
        {
            QMutexLocker locker(&m_mutex);
            while (m_running && m_queue.isEmpty()) {
                m_cond.wait(&m_mutex);
            }
            if (!m_running) break;
            pkt = m_queue.dequeue();
        }

#ifdef HAVE_ALSA
        if (pkt.channel == 4) {
            // Media audio: 48000 Hz, 2 channels, S16_LE (4 bytes per frame)
            if (!m_mediaHandle) {
                openDevice(&m_mediaHandle, 48000, 2, "Media");
            }
            if (m_mediaHandle) {
                snd_pcm_uframes_t frames = pkt.data.size() / 4;
                snd_pcm_sframes_t written = snd_pcm_writei(m_mediaHandle, pkt.data.constData(), frames);
                if (written < 0) {
                    snd_pcm_recover(m_mediaHandle, written, 0);
                }
            }
        } else if (pkt.channel == 5 || pkt.channel == 6) {
            // Speech / Guidance / System audio: 16000 Hz, 1 channel, S16_LE (2 bytes per frame)
            if (!m_speechHandle) {
                openDevice(&m_speechHandle, 16000, 1, (pkt.channel == 5 ? "Speech" : "System"));
            }
            if (m_speechHandle) {
                snd_pcm_uframes_t frames = pkt.data.size() / 2;
                snd_pcm_sframes_t written = snd_pcm_writei(m_speechHandle, pkt.data.constData(), frames);
                if (written < 0) {
                    snd_pcm_recover(m_speechHandle, written, 0);
                }
            }
        }
#endif
    }

#ifdef HAVE_ALSA
    closeDevice(&m_mediaHandle);
    closeDevice(&m_speechHandle);
#endif
}
