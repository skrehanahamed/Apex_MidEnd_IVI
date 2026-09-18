#pragma once

#include <QObject>
#include <QThread>
#include <QImage>
#include <QString>
#include <atomic>
#include <memory>
#include <thread>

class AndroidAutoH264Decoder;
class AndroidAutoAudioSink;

struct libusb_context;
struct libusb_device;

#ifdef APEX_ENABLE_AASDK
#include <boost/asio/io_service.hpp>

namespace f1x {
namespace aasdk {
namespace common {
class DataConstBuffer;
}
namespace error {
class Error;
}
namespace usb {
class USBWrapper;
class IAOAPDevice;
}
namespace transport {
class USBTransport;
class SSLWrapper;
}
namespace messenger {
class Cryptor;
class MessageInStream;
class MessageOutStream;
class Messenger;
class Timestamp;
}
namespace channel {
namespace control {
class ControlServiceChannel;
class IControlServiceChannelEventHandler;
}
namespace av {
class VideoServiceChannel;
class IVideoServiceChannelEventHandler;
class MediaAudioServiceChannel;
class SpeechAudioServiceChannel;
class SystemAudioServiceChannel;
class IAudioServiceChannelEventHandler;
class AVInputServiceChannel;
class IAVInputServiceChannelEventHandler;
}
namespace input {
class InputServiceChannel;
class IInputServiceChannelEventHandler;
}
namespace sensor {
class SensorServiceChannel;
class ISensorServiceChannelEventHandler;
}
namespace bluetooth {
class BluetoothServiceChannel;
class IBluetoothServiceChannelEventHandler;
}
}
}
}
#endif

class AndroidAutoSession : public QThread
{
    Q_OBJECT
public:
    explicit AndroidAutoSession(QObject *parent = nullptr);
    ~AndroidAutoSession() override;

    bool startSession(void *usbDevicePtr, void *usbContext = nullptr, const QString &btAddress = QString());
    void stopSession();
    bool isRunningSession() const { return m_running.load(); }

    void sendTouch(int action, int x, int y);
    void sendKeyEvent(uint32_t keyCode);
    void requestVideoFocus(bool focused);

    bool isMediaAudioActive() const { return m_mediaAudioActive.load(); }

signals:
    void frameReady(const QImage &frame);
    void sessionStarted();
    void sessionStopped();
    void statusChanged(const QString &status);
    void exitRequested();
    void audioFocusGained();
    void mediaPlaybackStateChanged(bool playing);

protected:
    void run() override;

private:
#ifdef APEX_ENABLE_AASDK
    friend class ControlEventHandler;
    friend class VideoEventHandler;
    friend class InputEventHandler;
    friend class AudioEventHandler;
    friend class SensorEventHandler;
    friend class BluetoothEventHandler;
    friend class MicEventHandler;

    void cleanupSession();
    void onFatalError(const QString &reason);
    void doHandshakeStep();
    void handleHandshakePayload(const f1x::aasdk::common::DataConstBuffer &payload);
    void schedulePing();
    void armServiceChannels();
#endif

    void *m_devicePtr{nullptr};
    libusb_context *m_usbCtx{nullptr};
    QString m_bluetoothAdapterAddress;

    std::atomic<bool> m_running{false};
    std::atomic<bool> m_tlsHandshakeComplete{false};
    std::atomic<bool> m_cleanedUp{false};
    std::atomic<int> m_consecutiveFailedPings{0};
    std::atomic<bool> m_mediaAudioActive{false};
    std::mutex m_cleanupMutex;

    int m_videoWidth{1920};
    int m_videoHeight{1080};
    int m_touchWidth{1920};
    int m_touchHeight{1080};

    AndroidAutoH264Decoder *m_decoder{nullptr};
    AndroidAutoAudioSink *m_audioSink{nullptr};

#ifdef APEX_ENABLE_AASDK
    std::unique_ptr<boost::asio::io_service> m_ioService;
    struct PrivateMembers;
    std::unique_ptr<PrivateMembers> m_priv;
#endif

    std::thread m_usbEventThread;
};

