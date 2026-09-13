#pragma once

#include <QThread>
#include <QImage>
#include <QByteArray>
#include <QMutex>
#include <QQueue>
#include <QWaitCondition>
#include <atomic>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavutil/imgutils.h>
#include <libswscale/swscale.h>
}

class AndroidAutoH264Decoder : public QThread
{
    Q_OBJECT
public:
    explicit AndroidAutoH264Decoder(QObject *parent = nullptr);
    ~AndroidAutoH264Decoder() override;

    bool init(int width = 1280, int height = 720);
    void reset();
    void stopDecoder();
    void queuePacket(const QByteArray &packet);
    bool decodePacket(const uint8_t *data, int size);

signals:
    void frameReady(const QImage &image);

protected:
    void run() override;

private:
    bool decodePacketInternal(const uint8_t *data, int size);

    const AVCodec *m_codec = nullptr;
    AVCodecContext *m_codecCtx = nullptr;
    AVCodecParserContext *m_parser = nullptr;
    AVFrame *m_frame = nullptr;
    AVPacket *m_packet = nullptr;
    SwsContext *m_swsCtx = nullptr;
    int m_width = 1280;
    int m_height = 720;
    QRecursiveMutex m_codecMutex;
    bool m_initialized = false;

    // Asynchronous Packet Queue
    QQueue<QByteArray> m_packetQueue;
    QMutex m_queueMutex;
    QWaitCondition m_queueCond;
    std::atomic<bool> m_running{false};

    // Pre-allocated triple-buffer pool for zero-allocation frame delivery
    static constexpr int POOL_SIZE = 3;
    QImage m_imagePool[POOL_SIZE];
    int m_poolIndex = 0;
};
