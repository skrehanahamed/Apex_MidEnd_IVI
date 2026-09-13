#include "AndroidAutoH264Decoder.hpp"
#include <QDebug>

AndroidAutoH264Decoder::AndroidAutoH264Decoder(QObject *parent)
    : QThread(parent)
{
}

AndroidAutoH264Decoder::~AndroidAutoH264Decoder()
{
    stopDecoder();
    reset();
}

void AndroidAutoH264Decoder::stopDecoder()
{
    if (m_running) {
        m_running = false;
        {
            QMutexLocker qLocker(&m_queueMutex);
            m_packetQueue.clear();
        }
        m_queueCond.wakeAll();
        wait(300);
    }
}

void AndroidAutoH264Decoder::reset()
{
    stopDecoder();

    QMutexLocker locker(&m_codecMutex);
    m_initialized = false;

    {
        QMutexLocker qLocker(&m_queueMutex);
        m_packetQueue.clear();
    }

#ifdef APEX_ENABLE_AASDK
    if (m_swsCtx) {
        sws_freeContext(m_swsCtx);
        m_swsCtx = nullptr;
    }
    for (int i = 0; i < POOL_SIZE; ++i) {
        m_imagePool[i] = QImage();
    }
    if (m_frame) {
        av_frame_free(&m_frame);
        m_frame = nullptr;
    }
    if (m_packet) {
        av_packet_free(&m_packet);
        m_packet = nullptr;
    }
    if (m_parser) {
        av_parser_close(m_parser);
        m_parser = nullptr;
    }
    if (m_codecCtx) {
        avcodec_free_context(&m_codecCtx);
        m_codecCtx = nullptr;
    }
#else
    for (int i = 0; i < POOL_SIZE; ++i) {
        m_imagePool[i] = QImage();
    }
#endif
}

bool AndroidAutoH264Decoder::init(int width, int height)
{
    // 1. Stop any previously running worker thread first
    stopDecoder();

    QMutexLocker locker(&m_codecMutex);
    m_initialized = false;

#ifdef APEX_ENABLE_AASDK
    // 2. Clean up previous context safely
    if (m_swsCtx) {
        sws_freeContext(m_swsCtx);
        m_swsCtx = nullptr;
    }
    if (m_frame) {
        av_frame_free(&m_frame);
        m_frame = nullptr;
    }
    if (m_packet) {
        av_packet_free(&m_packet);
        m_packet = nullptr;
    }
    if (m_parser) {
        av_parser_close(m_parser);
        m_parser = nullptr;
    }
    if (m_codecCtx) {
        avcodec_free_context(&m_codecCtx);
        m_codecCtx = nullptr;
    }

    m_width = width;
    m_height = height;

    m_codec = avcodec_find_decoder(AV_CODEC_ID_H264);
    if (!m_codec) {
        qWarning() << "[AA H264] H.264 decoder not found in FFmpeg!";
        return false;
    }

    m_codecCtx = avcodec_alloc_context3(m_codec);
    if (!m_codecCtx) {
        qWarning() << "[AA H264] Failed to allocate codec context";
        return false;
    }

    m_codecCtx->width = m_width;
    m_codecCtx->height = m_height;
    m_codecCtx->pix_fmt = AV_PIX_FMT_YUV420P;

    // Multi-threaded decoding on all 4 Cortex-A76 cores
    m_codecCtx->thread_count = 4;
    m_codecCtx->thread_type = FF_THREAD_SLICE | FF_THREAD_FRAME;
    m_codecCtx->flags |= AV_CODEC_FLAG_LOW_DELAY;
    m_codecCtx->flags2 |= AV_CODEC_FLAG2_FAST;
    m_codecCtx->delay = 0;

    m_parser = av_parser_init(AV_CODEC_ID_H264);
    if (!m_parser) {
        qWarning() << "[AA H264] Failed to init H264 parser";
    }

    AVDictionary *opts = nullptr;
    av_dict_set(&opts, "tune", "zerolatency", 0);
    av_dict_set(&opts, "threads", "4", 0);

    if (avcodec_open2(m_codecCtx, m_codec, &opts) < 0) {
        qWarning() << "[AA H264] Failed to open codec context";
        if (opts) av_dict_free(&opts);
        return false;
    }
    if (opts) av_dict_free(&opts);

    m_frame = av_frame_alloc();
    m_packet = av_packet_alloc();

    // Pre-allocate triple buffer pool for zero-allocation frame delivery
    for (int i = 0; i < POOL_SIZE; ++i) {
        m_imagePool[i] = QImage(m_width, m_height, QImage::Format_RGBA8888);
    }
    m_poolIndex = 0;

    m_swsCtx = sws_getContext(m_width, m_height, AV_PIX_FMT_YUV420P,
                              m_width, m_height, AV_PIX_FMT_RGBA,
                              SWS_FAST_BILINEAR, nullptr, nullptr, nullptr);

    m_initialized = true;
    m_running = true;

    // Start dedicated decoder worker thread
    start(QThread::HighPriority);

    qInfo() << "[AA H264] Initialized 4-thread low-latency decoder worker successfully at" << m_width << "x" << m_height;
    return true;
#else
    Q_UNUSED(width);
    Q_UNUSED(height);
    return false;
#endif
}

void AndroidAutoH264Decoder::queuePacket(const QByteArray &packet)
{
    if (!m_running || packet.isEmpty()) return;

    {
        QMutexLocker locker(&m_queueMutex);
        // Keep queue small to guarantee real-time latency (< 33ms)
        while (m_packetQueue.size() >= 2) {
            m_packetQueue.dequeue();
        }
        m_packetQueue.enqueue(packet);
    }
    m_queueCond.wakeOne();
}

void AndroidAutoH264Decoder::run()
{
    while (m_running) {
        QByteArray packet;
        {
            QMutexLocker locker(&m_queueMutex);
            while (m_running && m_packetQueue.isEmpty()) {
                m_queueCond.wait(&m_queueMutex, 30);
            }
            if (!m_running) break;
            if (!m_packetQueue.isEmpty()) {
                packet = m_packetQueue.dequeue();
            }
        }

        if (!packet.isEmpty()) {
            decodePacketInternal(reinterpret_cast<const uint8_t*>(packet.constData()), packet.size());
        }
    }
}

bool AndroidAutoH264Decoder::decodePacket(const uint8_t *data, int size)
{
    return decodePacketInternal(data, size);
}

bool AndroidAutoH264Decoder::decodePacketInternal(const uint8_t *data, int size)
{
#ifdef APEX_ENABLE_AASDK
    QMutexLocker locker(&m_codecMutex);
    if (!m_initialized || !data || size <= 0) {
        return false;
    }

    uint8_t *pData = const_cast<uint8_t *>(data);
    int remaining = size;

    while (remaining > 0) {
        int parsed = remaining;
        if (m_parser) {
            uint8_t *outData = nullptr;
            int outSize = 0;
            parsed = av_parser_parse2(m_parser, m_codecCtx, &outData, &outSize,
                                      pData, remaining, AV_NOPTS_VALUE, AV_NOPTS_VALUE, 0);
            pData += parsed;
            remaining -= parsed;

            if (outSize <= 0) continue;

            m_packet->data = outData;
            m_packet->size = outSize;
        } else {
            m_packet->data = pData;
            m_packet->size = remaining;
            remaining = 0;
        }

        int ret = avcodec_send_packet(m_codecCtx, m_packet);
        if (ret < 0) {
            continue;
        }

        while (ret >= 0) {
            ret = avcodec_receive_frame(m_codecCtx, m_frame);
            if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF || ret < 0) {
                break;
            }

            // Check if resolution changed
            if (m_frame->width != m_width || m_frame->height != m_height) {
                m_width = m_frame->width;
                m_height = m_frame->height;
                if (m_swsCtx) sws_freeContext(m_swsCtx);
                m_swsCtx = sws_getContext(m_width, m_height, (AVPixelFormat)m_frame->format,
                                          m_width, m_height, AV_PIX_FMT_RGBA,
                                          SWS_FAST_BILINEAR, nullptr, nullptr, nullptr);
                for (int i = 0; i < POOL_SIZE; ++i) {
                    m_imagePool[i] = QImage(m_width, m_height, QImage::Format_RGBA8888);
                }
            }

            if (m_swsCtx) {
                int curIdx = m_poolIndex;
                m_poolIndex = (m_poolIndex + 1) % POOL_SIZE;
                QImage &targetImg = m_imagePool[curIdx];

                uint8_t *dstData[4] = { targetImg.bits(), nullptr, nullptr, nullptr };
                int dstLinesize[4] = { static_cast<int>(targetImg.bytesPerLine()), 0, 0, 0 };

                sws_scale(m_swsCtx, m_frame->data, m_frame->linesize, 0, m_height,
                          dstData, dstLinesize);

                emit frameReady(targetImg);
            }
        }
    }

    return true;
#else
    Q_UNUSED(data);
    Q_UNUSED(size);
    return false;
#endif
}
