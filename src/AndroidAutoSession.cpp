#include "AndroidAutoSession.hpp"
#include "AndroidAutoH264Decoder.hpp"
#include "AndroidAutoAudioSink.hpp"

#include <boost/asio.hpp>
#include <boost/asio/steady_timer.hpp>

#include <f1x/aasdk/USB/USBWrapper.hpp>
#include <f1x/aasdk/USB/AOAPDevice.hpp>
#include <f1x/aasdk/Transport/USBTransport.hpp>
#include <f1x/aasdk/Transport/SSLWrapper.hpp>
#include <f1x/aasdk/Messenger/Cryptor.hpp>
#include <f1x/aasdk/Messenger/MessageInStream.hpp>
#include <f1x/aasdk/Messenger/MessageOutStream.hpp>
#include <f1x/aasdk/Messenger/Messenger.hpp>

#include <f1x/aasdk/Channel/Control/ControlServiceChannel.hpp>
#include <f1x/aasdk/Channel/Control/IControlServiceChannelEventHandler.hpp>
#include <f1x/aasdk/Channel/AV/VideoServiceChannel.hpp>
#include <f1x/aasdk/Channel/AV/IVideoServiceChannelEventHandler.hpp>
#include <f1x/aasdk/Channel/Input/InputServiceChannel.hpp>
#include <f1x/aasdk/Channel/Input/IInputServiceChannelEventHandler.hpp>
#include <f1x/aasdk/Channel/AV/MediaAudioServiceChannel.hpp>
#include <f1x/aasdk/Channel/AV/SpeechAudioServiceChannel.hpp>
#include <f1x/aasdk/Channel/AV/SystemAudioServiceChannel.hpp>
#include <f1x/aasdk/Channel/AV/IAudioServiceChannelEventHandler.hpp>
#include <f1x/aasdk/Channel/Sensor/SensorServiceChannel.hpp>
#include <f1x/aasdk/Channel/Sensor/ISensorServiceChannelEventHandler.hpp>
#include <f1x/aasdk/Channel/Bluetooth/BluetoothServiceChannel.hpp>
#include <f1x/aasdk/Channel/Bluetooth/IBluetoothServiceChannelEventHandler.hpp>
#include <f1x/aasdk/Channel/AV/AVInputServiceChannel.hpp>
#include <f1x/aasdk/Channel/AV/IAVInputServiceChannelEventHandler.hpp>

#include <aasdk_proto/VersionResponseStatusEnum.pb.h>
#include <aasdk_proto/ServiceDiscoveryResponseMessage.pb.h>
#include <aasdk_proto/ChannelOpenResponseMessage.pb.h>
#include <aasdk_proto/AVChannelSetupResponseMessage.pb.h>
#include <aasdk_proto/VideoFocusIndicationMessage.pb.h>
#include <aasdk_proto/AVMediaAckIndicationMessage.pb.h>
#include <aasdk_proto/InputEventIndicationMessage.pb.h>
#include <aasdk_proto/BindingResponseMessage.pb.h>
#include <aasdk_proto/SensorStartResponseMessage.pb.h>
#include <aasdk_proto/SensorEventIndicationMessage.pb.h>
#include <aasdk_proto/BluetoothPairingResponseMessage.pb.h>
#include <aasdk_proto/AudioFocusResponseMessage.pb.h>
#include <aasdk_proto/ShutdownResponseMessage.pb.h>
#include <aasdk_proto/NavigationFocusResponseMessage.pb.h>
#include <aasdk_proto/PingRequestMessage.pb.h>
#include <aasdk_proto/PingResponseMessage.pb.h>
#include <aasdk_proto/AuthCompleteIndicationMessage.pb.h>
#include <aasdk_proto/AVInputOpenResponseMessage.pb.h>
#include <aasdk_proto/StatusEnum.pb.h>
#include <aasdk_proto/AVStreamTypeEnum.pb.h>
#include <aasdk_proto/AudioTypeEnum.pb.h>
#include <aasdk_proto/VideoResolutionEnum.pb.h>
#include <aasdk_proto/VideoFPSEnum.pb.h>
#include <aasdk_proto/SensorTypeEnum.pb.h>
#include <aasdk_proto/ButtonCodeEnum.pb.h>
#include <aasdk_proto/TouchActionEnum.pb.h>
#include <aasdk_proto/AudioFocusStateEnum.pb.h>
#include <aasdk_proto/AudioFocusTypeEnum.pb.h>
#include <aasdk_proto/VideoFocusModeEnum.pb.h>
#include <aasdk_proto/AVChannelSetupStatusEnum.pb.h>
#include <aasdk_proto/BluetoothPairingStatusEnum.pb.h>
#include <aasdk_proto/DrivingStatusEnum.pb.h>

#include <libusb-1.0/libusb.h>
#include <QDebug>
#include <chrono>

// ============================================================================
// Forward Declarations of Channel Handlers
// ============================================================================
class ControlEventHandler;
class VideoEventHandler;
class InputEventHandler;
class AudioEventHandler;
class SensorEventHandler;
class BluetoothEventHandler;
class MicEventHandler;

struct AndroidAutoSession::PrivateMembers {
    std::unique_ptr<boost::asio::io_service::work> work;
    std::unique_ptr<boost::asio::io_service::strand> strand;
    std::unique_ptr<boost::asio::steady_timer> pingTimer;

    std::shared_ptr<f1x::aasdk::usb::USBWrapper> usbWrapper;
    f1x::aasdk::usb::IAOAPDevice::Pointer aoapDevice;
    std::shared_ptr<f1x::aasdk::transport::USBTransport> transport;
    std::shared_ptr<f1x::aasdk::transport::SSLWrapper> sslWrapper;
    std::shared_ptr<f1x::aasdk::messenger::Cryptor> cryptor;
    std::shared_ptr<f1x::aasdk::messenger::MessageInStream> inStream;
    std::shared_ptr<f1x::aasdk::messenger::MessageOutStream> outStream;
    std::shared_ptr<f1x::aasdk::messenger::Messenger> messenger;

    std::shared_ptr<f1x::aasdk::channel::control::ControlServiceChannel> controlChannel;
    std::shared_ptr<f1x::aasdk::channel::av::VideoServiceChannel> videoChannel;
    std::shared_ptr<f1x::aasdk::channel::input::InputServiceChannel> inputChannel;
    std::shared_ptr<f1x::aasdk::channel::av::MediaAudioServiceChannel> mediaAudioChannel;
    std::shared_ptr<f1x::aasdk::channel::av::SpeechAudioServiceChannel> speechAudioChannel;
    std::shared_ptr<f1x::aasdk::channel::av::SystemAudioServiceChannel> systemAudioChannel;
    std::shared_ptr<f1x::aasdk::channel::sensor::SensorServiceChannel> sensorChannel;
    std::shared_ptr<f1x::aasdk::channel::bluetooth::BluetoothServiceChannel> bluetoothChannel;
    std::shared_ptr<f1x::aasdk::channel::av::AVInputServiceChannel> micChannel;

    std::shared_ptr<ControlEventHandler> controlHandler;
    std::shared_ptr<VideoEventHandler> videoHandler;
    std::shared_ptr<InputEventHandler> inputHandler;
    std::shared_ptr<AudioEventHandler> mediaAudioHandler;
    std::shared_ptr<AudioEventHandler> speechAudioHandler;
    std::shared_ptr<AudioEventHandler> systemAudioHandler;
    std::shared_ptr<SensorEventHandler> sensorHandler;
    std::shared_ptr<BluetoothEventHandler> bluetoothHandler;
    std::shared_ptr<MicEventHandler> micHandler;
};

static const char* libusbTransferStatusStr(int status) {
    switch (status) {
        case 0: return "LIBUSB_TRANSFER_COMPLETED";
        case 1: return "LIBUSB_TRANSFER_ERROR";
        case 2: return "LIBUSB_TRANSFER_TIMED_OUT";
        case 3: return "LIBUSB_TRANSFER_CANCELLED";
        case 4: return "LIBUSB_TRANSFER_STALL";
        case 5: return "LIBUSB_TRANSFER_NO_DEVICE";
        case 6: return "LIBUSB_TRANSFER_OVERFLOW";
        default: return "UNKNOWN";
    }
}

// ============================================================================
// 1. Control Service Channel Event Handler (Channel 0)
// ============================================================================
class ControlEventHandler : public f1x::aasdk::channel::control::IControlServiceChannelEventHandler,
                            public std::enable_shared_from_this<ControlEventHandler>
{
public:
    explicit ControlEventHandler(AndroidAutoSession *session) : m_session(session) {}

    void onVersionResponse(uint16_t majorCode, uint16_t minorCode, f1x::aasdk::proto::enums::VersionResponseStatus::Enum status) override {
        if (status != f1x::aasdk::proto::enums::VersionResponseStatus::MATCH) {
            qWarning() << "[AA Session] Version mismatch: major=" << majorCode << "minor=" << minorCode;
            m_session->onFatalError("Version mismatch with mobile device");
            return;
        }
        qInfo() << "[AA Session] Phone accepted version (" << majorCode << "." << minorCode << "). Starting SSL Handshake...";
        m_session->doHandshakeStep();
        if (m_session->m_priv && m_session->m_priv->controlChannel) {
            m_session->m_priv->controlChannel->receive(shared_from_this());
        }
    }

    void onHandshake(const f1x::aasdk::common::DataConstBuffer& payload) override {
        m_session->handleHandshakePayload(payload);
        if (m_session->m_priv && m_session->m_priv->controlChannel) {
            m_session->m_priv->controlChannel->receive(shared_from_this());
        }
    }

    void onServiceDiscoveryRequest(const f1x::aasdk::proto::messages::ServiceDiscoveryRequest& request) override {
        Q_UNUSED(request);
        qInfo() << "[AA Session] ServiceDiscoveryRequest received -> building 8 AASDK service channels";

        f1x::aasdk::proto::messages::ServiceDiscoveryResponse response;

        // Channel 7: Microphone (Audio Input)
        auto *chMic = response.add_channels();
        chMic->set_channel_id(7);
        auto *avInput = chMic->mutable_av_input_channel();
        avInput->set_stream_type(f1x::aasdk::proto::enums::AVStreamType::AUDIO);
        auto *inCfg = avInput->mutable_audio_config();
        inCfg->set_sample_rate(16000);
        inCfg->set_bit_depth(16);
        inCfg->set_channel_count(1);

        // Channel 4: Media Audio (48kHz Stereo)
        auto *chMedia = response.add_channels();
        chMedia->set_channel_id(4);
        auto *mediaAv = chMedia->mutable_av_channel();
        mediaAv->set_stream_type(f1x::aasdk::proto::enums::AVStreamType::AUDIO);
        mediaAv->set_audio_type(f1x::aasdk::proto::enums::AudioType::MEDIA);
        mediaAv->set_available_while_in_call(true);
        auto *mediaCfg = mediaAv->add_audio_configs();
        mediaCfg->set_sample_rate(48000);
        mediaCfg->set_bit_depth(16);
        mediaCfg->set_channel_count(2);

        // Channel 5: Speech Audio (16kHz Mono)
        auto *chSpeech = response.add_channels();
        chSpeech->set_channel_id(5);
        auto *speechAv = chSpeech->mutable_av_channel();
        speechAv->set_stream_type(f1x::aasdk::proto::enums::AVStreamType::AUDIO);
        speechAv->set_audio_type(f1x::aasdk::proto::enums::AudioType::SPEECH);
        speechAv->set_available_while_in_call(true);
        auto *speechCfg = speechAv->add_audio_configs();
        speechCfg->set_sample_rate(16000);
        speechCfg->set_bit_depth(16);
        speechCfg->set_channel_count(1);

        // Channel 6: System Audio (16kHz Mono)
        auto *chSys = response.add_channels();
        chSys->set_channel_id(6);
        auto *sysAv = chSys->mutable_av_channel();
        sysAv->set_stream_type(f1x::aasdk::proto::enums::AVStreamType::AUDIO);
        sysAv->set_audio_type(f1x::aasdk::proto::enums::AudioType::SYSTEM);
        sysAv->set_available_while_in_call(true);
        auto *sysCfg = sysAv->add_audio_configs();
        sysCfg->set_sample_rate(16000);
        sysCfg->set_bit_depth(16);
        sysCfg->set_channel_count(1);

        // Channel 2: Sensor Channel (DrivingStatus, NightData)
        auto *chSensor = response.add_channels();
        chSensor->set_channel_id(2);
        auto *sensorChannel = chSensor->mutable_sensor_channel();
        sensorChannel->add_sensors()->set_type(f1x::aasdk::proto::enums::SensorType::DRIVING_STATUS);
        sensorChannel->add_sensors()->set_type(f1x::aasdk::proto::enums::SensorType::NIGHT_DATA);

        // Channel 3: Video Channel (720p 60/30 FPS)
        auto *chVideo = response.add_channels();
        chVideo->set_channel_id(3);
        auto *videoAv = chVideo->mutable_av_channel();
        videoAv->set_stream_type(f1x::aasdk::proto::enums::AVStreamType::VIDEO);
        videoAv->set_available_while_in_call(true);

        auto *vidCfg60 = videoAv->add_video_configs();
        vidCfg60->set_video_resolution(f1x::aasdk::proto::enums::VideoResolution::_720p);
        vidCfg60->set_video_fps(f1x::aasdk::proto::enums::VideoFPS::_60);
        vidCfg60->set_margin_width(0);
        vidCfg60->set_margin_height(0);
        vidCfg60->set_dpi(140);

        auto *vidCfg30 = videoAv->add_video_configs();
        vidCfg30->set_video_resolution(f1x::aasdk::proto::enums::VideoResolution::_720p);
        vidCfg30->set_video_fps(f1x::aasdk::proto::enums::VideoFPS::_30);
        vidCfg30->set_margin_width(0);
        vidCfg30->set_margin_height(0);
        vidCfg30->set_dpi(140);

        // Channel 8: Bluetooth Channel (Real BlueZ adapter address)
        auto *chBt = response.add_channels();
        chBt->set_channel_id(8);
        auto *btChannel = chBt->mutable_bluetooth_channel();
        btChannel->set_adapter_address(m_session->m_bluetoothAdapterAddress.toStdString());

        // Channel 1: Input Channel (Touchscreen + Keycodes)
        auto *chInput = response.add_channels();
        chInput->set_channel_id(1);
        auto *inChannel = chInput->mutable_input_channel();
        inChannel->add_supported_keycodes(f1x::aasdk::proto::enums::ButtonCode::ENTER);
        inChannel->add_supported_keycodes(f1x::aasdk::proto::enums::ButtonCode::BACK);
        inChannel->add_supported_keycodes(f1x::aasdk::proto::enums::ButtonCode::HOME);
        inChannel->add_supported_keycodes(f1x::aasdk::proto::enums::ButtonCode::PHONE);
        inChannel->add_supported_keycodes(f1x::aasdk::proto::enums::ButtonCode::CALL_END);
        inChannel->add_supported_keycodes(f1x::aasdk::proto::enums::ButtonCode::MICROPHONE_1);
        inChannel->add_supported_keycodes(f1x::aasdk::proto::enums::ButtonCode::MICROPHONE_2);
        inChannel->add_supported_keycodes(f1x::aasdk::proto::enums::ButtonCode::PLAY);
        inChannel->add_supported_keycodes(f1x::aasdk::proto::enums::ButtonCode::PAUSE);
        inChannel->add_supported_keycodes(f1x::aasdk::proto::enums::ButtonCode::PREV);
        inChannel->add_supported_keycodes(f1x::aasdk::proto::enums::ButtonCode::NEXT);
        inChannel->add_supported_keycodes(f1x::aasdk::proto::enums::ButtonCode::SCROLL_WHEEL);
        inChannel->add_supported_keycodes(65537); // KEYCODE_MEDIA
        inChannel->add_supported_keycodes(65538); // KEYCODE_NAVIGATION
        inChannel->add_supported_keycodes(65540); // KEYCODE_TEL
        auto *touchConfig = inChannel->mutable_touch_screen_config();
        touchConfig->set_width(1280);
        touchConfig->set_height(720);
        m_session->m_touchWidth = 1280;
        m_session->m_touchHeight = 720;

        // Headunit Metadata
        response.set_head_unit_name("APEX");
        response.set_car_model("Apex Horizon");
        response.set_car_year("2026");
        response.set_car_serial("APEX-2026-RPI5");
        response.set_left_hand_drive_vehicle(true);
        response.set_headunit_manufacturer("APEX");
        response.set_headunit_model("Apex IVI");
        response.set_sw_build("1");
        response.set_sw_version("1.0");
        response.set_can_play_native_media_during_vr(false);
        response.set_hide_clock(false);

        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        promise->then([]() {
            qInfo() << "[AA Session] ServiceDiscoveryResponse successfully dispatched";
        }, [this](const f1x::aasdk::error::Error &e) {
            qWarning() << "[AA Session] Failed to send ServiceDiscoveryResponse:" << static_cast<int>(e.getCode());
            m_session->onFatalError("Service discovery response send failure");
        });

        m_session->m_priv->controlChannel->sendServiceDiscoveryResponse(response, std::move(promise));
        m_session->m_priv->controlChannel->receive(shared_from_this());

        // Arm receive on all registered service channels now that service discovery is complete
        m_session->armServiceChannels();
    }

    void onAudioFocusRequest(const f1x::aasdk::proto::messages::AudioFocusRequest& request) override {
        f1x::aasdk::proto::enums::AudioFocusState::Enum focusState = f1x::aasdk::proto::enums::AudioFocusState::GAIN;
        if (request.audio_focus_type() == f1x::aasdk::proto::enums::AudioFocusType::RELEASE) {
            focusState = f1x::aasdk::proto::enums::AudioFocusState::LOSS;
        }
        qInfo() << "[AA Session] AudioFocusRequest received -> responding with state:" << focusState;

        f1x::aasdk::proto::messages::AudioFocusResponse response;
        response.set_audio_focus_state(focusState);

        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_session->m_priv->controlChannel->sendAudioFocusResponse(response, std::move(promise));
        if (focusState == f1x::aasdk::proto::enums::AudioFocusState::GAIN) {
            emit m_session->audioFocusGained();
        }
        if (m_session->m_priv && m_session->m_priv->controlChannel) {
            m_session->m_priv->controlChannel->receive(shared_from_this());
        }
    }

    void onShutdownRequest(const f1x::aasdk::proto::messages::ShutdownRequest& request) override {
        Q_UNUSED(request);
        qInfo() << "[AA Session] ShutdownRequest received from mobile device (Drawer Home tapped)";
        f1x::aasdk::proto::messages::ShutdownResponse response;
        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_session->m_priv->controlChannel->sendShutdownResponse(response, std::move(promise));

        emit m_session->exitRequested();
        m_session->onFatalError("Session closed by mobile device");
    }

    void onShutdownResponse(const f1x::aasdk::proto::messages::ShutdownResponse& response) override {
        Q_UNUSED(response);
        qInfo() << "[AA Session] ShutdownResponse received";
        m_session->onFatalError("Session shutdown acknowledged");
    }

    void onNavigationFocusRequest(const f1x::aasdk::proto::messages::NavigationFocusRequest& request) override {
        f1x::aasdk::proto::messages::NavigationFocusResponse response;
        response.set_type(request.type());
        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_session->m_priv->controlChannel->sendNavigationFocusResponse(response, std::move(promise));
        if (m_session->m_priv && m_session->m_priv->controlChannel) {
            m_session->m_priv->controlChannel->receive(shared_from_this());
        }
    }

    void onPingResponse(const f1x::aasdk::proto::messages::PingResponse& response) override {
        Q_UNUSED(response);
        m_session->m_consecutiveFailedPings.store(0);
        if (m_session->m_priv && m_session->m_priv->controlChannel) {
            m_session->m_priv->controlChannel->receive(shared_from_this());
        }
    }

    void onChannelError(const f1x::aasdk::error::Error& e) override {
        qWarning() << "[AA Session] Control channel error: code=" << static_cast<int>(e.getCode())
                   << "native=" << e.getNativeCode() << "(" << libusbTransferStatusStr(e.getNativeCode()) << ")";
        // Only fatal if USB device is gone
        if (e.getNativeCode() == 5 /* LIBUSB_TRANSFER_NO_DEVICE */) {
            m_session->onFatalError(QString("Control channel USB device gone: %1").arg(e.getNativeCode()));
        } else {
            qWarning() << "[AA Session] Control channel transient error, re-arming receive...";
            if (m_session->m_priv && m_session->m_priv->controlChannel) {
                m_session->m_priv->controlChannel->receive(shared_from_this());
            }
        }
    }

private:
    AndroidAutoSession *m_session;
};

// ============================================================================
// 2. Video Service Channel Event Handler (Channel 3)
// ============================================================================
class VideoEventHandler : public f1x::aasdk::channel::av::IVideoServiceChannelEventHandler,
                          public std::enable_shared_from_this<VideoEventHandler>
{
public:
    explicit VideoEventHandler(AndroidAutoSession *session) : m_session(session), m_videoSession(0) {}

    void onChannelOpenRequest(const f1x::aasdk::proto::messages::ChannelOpenRequest& request) override {
        Q_UNUSED(request);
        qInfo() << "[AA Session] Video ChannelOpenRequest received";
        f1x::aasdk::proto::messages::ChannelOpenResponse resp;
        resp.set_status(f1x::aasdk::proto::enums::Status::OK);
        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_session->m_priv->videoChannel->sendChannelOpenResponse(resp, std::move(promise));
        m_session->m_priv->videoChannel->receive(shared_from_this());
    }

    void onAVChannelSetupRequest(const f1x::aasdk::proto::messages::AVChannelSetupRequest& request) override {
        Q_UNUSED(request);
        qInfo() << "[AA Session] Video AVChannelSetupRequest received";
        f1x::aasdk::proto::messages::AVChannelSetupResponse resp;
        resp.set_media_status(f1x::aasdk::proto::enums::AVChannelSetupStatus::OK);
        resp.set_max_unacked(1); // Aligned with OpenAuto AASDK reference
        resp.add_configs(0);
        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_session->m_priv->videoChannel->sendAVChannelSetupResponse(resp, std::move(promise));

        // Immediately request video focus
        f1x::aasdk::proto::messages::VideoFocusIndication focusInd;
        focusInd.set_focus_mode(f1x::aasdk::proto::enums::VideoFocusMode::FOCUSED);
        auto focusPromise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_session->m_priv->videoChannel->sendVideoFocusIndication(focusInd, std::move(focusPromise));

        m_session->m_priv->videoChannel->receive(shared_from_this());
    }

    void onAVChannelStartIndication(const f1x::aasdk::proto::messages::AVChannelStartIndication& indication) override {
        m_videoSession = indication.session();
        qInfo() << "[AA Session] Video stream active and flowing, session id:" << m_videoSession;
        m_session->m_priv->videoChannel->receive(shared_from_this());
    }

    void onAVChannelStopIndication(const f1x::aasdk::proto::messages::AVChannelStopIndication& indication) override {
        Q_UNUSED(indication);
        qInfo() << "[AA Session] Video stream paused by phone";
        m_session->m_priv->videoChannel->receive(shared_from_this());
    }

    void onAVMediaWithTimestampIndication(f1x::aasdk::messenger::Timestamp::ValueType, const f1x::aasdk::common::DataConstBuffer& buffer) override {
        if (m_session->m_decoder && buffer.size > 0) {
            m_session->m_decoder->queuePacket(QByteArray(reinterpret_cast<const char*>(buffer.cdata), static_cast<int>(buffer.size)));
        }

        f1x::aasdk::proto::messages::AVMediaAckIndication ack;
        ack.set_session(m_videoSession);
        ack.set_value(1);
        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_session->m_priv->videoChannel->sendAVMediaAckIndication(ack, std::move(promise));

        m_session->m_priv->videoChannel->receive(shared_from_this());
    }

    void onAVMediaIndication(const f1x::aasdk::common::DataConstBuffer& buffer) override {
        if (m_session->m_decoder && buffer.size > 0) {
            m_session->m_decoder->queuePacket(QByteArray(reinterpret_cast<const char*>(buffer.cdata), static_cast<int>(buffer.size)));
        }

        f1x::aasdk::proto::messages::AVMediaAckIndication ack;
        ack.set_session(m_videoSession);
        ack.set_value(1);
        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_session->m_priv->videoChannel->sendAVMediaAckIndication(ack, std::move(promise));

        m_session->m_priv->videoChannel->receive(shared_from_this());
    }

    void onVideoFocusRequest(const f1x::aasdk::proto::messages::VideoFocusRequest& request) override {
        qInfo() << "[AA Session] VideoFocusRequest received: mode=" << static_cast<int>(request.focus_mode())
                << "reason=" << static_cast<int>(request.focus_reason())
                << "disp=" << request.disp_index();

        // Mode 2 = UNFOCUSED (native IVI), Reason 2 = LAUNCH_NATIVE (Exit to car headunit)
        if (request.focus_mode() == f1x::aasdk::proto::enums::VideoFocusMode::UNFOCUSED ||
            request.focus_reason() == f1x::aasdk::proto::enums::VideoFocusReason::UNK_2 ||
            (request.focus_mode() != f1x::aasdk::proto::enums::VideoFocusMode::FOCUSED &&
             request.focus_reason() != f1x::aasdk::proto::enums::VideoFocusReason::NONE))
        {
            qInfo() << "[AA Session] Exit to OEM IVI requested from Android Auto drawer -> Navigating to Home";
            f1x::aasdk::proto::messages::VideoFocusIndication indication;
            indication.set_focus_mode(f1x::aasdk::proto::enums::VideoFocusMode::UNFOCUSED);
            indication.set_unrequested(false);
            auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
            m_session->m_priv->videoChannel->sendVideoFocusIndication(indication, std::move(promise));

            emit m_session->exitRequested();
            m_session->m_priv->videoChannel->receive(shared_from_this());
            return;
        }

        f1x::aasdk::proto::messages::VideoFocusIndication indication;
        indication.set_focus_mode(f1x::aasdk::proto::enums::VideoFocusMode::FOCUSED);
        indication.set_unrequested(false);
        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_session->m_priv->videoChannel->sendVideoFocusIndication(indication, std::move(promise));

        m_session->m_priv->videoChannel->receive(shared_from_this());
    }

    void onChannelError(const f1x::aasdk::error::Error& e) override {
        qWarning() << "[AA Session] Video channel error: code=" << static_cast<int>(e.getCode())
                   << "native=" << e.getNativeCode() << "(" << libusbTransferStatusStr(e.getNativeCode()) << ")";

        // Only kill the session if the USB device is truly gone (LIBUSB_TRANSFER_NO_DEVICE).
        // TIMED_OUT (native=2) and similar errors are caused by phone CPU load and are transient.
        if (e.getNativeCode() == 5 /* LIBUSB_TRANSFER_NO_DEVICE */) {
            m_session->onFatalError(QString("Video channel USB device gone: %1").arg(e.getNativeCode()));
        } else {
            // Transient error: re-arm receive and continue
            qWarning() << "[AA Session] Video channel transient error, re-arming receive...";
            if (m_session->m_priv && m_session->m_priv->videoChannel) {
                m_session->m_priv->videoChannel->receive(shared_from_this());
            }
        }
    }

private:
    AndroidAutoSession *m_session;
    int32_t m_videoSession;
};

// ============================================================================
// 3. Input Service Channel Event Handler (Channel 1)
// ============================================================================
class InputEventHandler : public f1x::aasdk::channel::input::IInputServiceChannelEventHandler,
                          public std::enable_shared_from_this<InputEventHandler>
{
public:
    explicit InputEventHandler(AndroidAutoSession *session) : m_session(session) {}

    void onChannelOpenRequest(const f1x::aasdk::proto::messages::ChannelOpenRequest& request) override {
        Q_UNUSED(request);
        qInfo() << "[AA Session] Input ChannelOpenRequest received";
        f1x::aasdk::proto::messages::ChannelOpenResponse resp;
        resp.set_status(f1x::aasdk::proto::enums::Status::OK);
        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_session->m_priv->inputChannel->sendChannelOpenResponse(resp, std::move(promise));
        m_session->m_priv->inputChannel->receive(shared_from_this());
    }

    void onBindingRequest(const f1x::aasdk::proto::messages::BindingRequest& request) override {
        QStringList scList;
        for (int i = 0; i < request.scan_codes_size(); ++i) {
            scList << QString::number(request.scan_codes(i));
        }
        qInfo() << "[AA Session] Input BindingRequest received with scan codes:" << scList.join(", ");
        f1x::aasdk::proto::messages::BindingResponse resp;
        resp.set_status(f1x::aasdk::proto::enums::Status::OK);
        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_session->m_priv->inputChannel->sendBindingResponse(resp, std::move(promise));
        m_session->m_priv->inputChannel->receive(shared_from_this());
    }

    void onChannelError(const f1x::aasdk::error::Error& e) override {
        qWarning() << "[AA Session] Input channel fatal error: code=" << static_cast<int>(e.getCode())
                   << "native=" << e.getNativeCode() << "(" << libusbTransferStatusStr(e.getNativeCode()) << ")";
        m_session->onFatalError(QString("Input channel error: %1 (native: %2)").arg(static_cast<int>(e.getCode())).arg(e.getNativeCode()));
    }

private:
    AndroidAutoSession *m_session;
};

// ============================================================================
// 4. Audio Service Channel Event Handler (Channels 4, 5, 6)
// ============================================================================
class AudioEventHandler : public f1x::aasdk::channel::av::IAudioServiceChannelEventHandler,
                          public std::enable_shared_from_this<AudioEventHandler>
{
public:
    AudioEventHandler(AndroidAutoSession *session, uint8_t channelId, std::shared_ptr<f1x::aasdk::channel::av::AudioServiceChannel> channel)
        : m_session(session), m_channelId(channelId), m_channel(std::move(channel)), m_audioSession(0) {}

    void onChannelOpenRequest(const f1x::aasdk::proto::messages::ChannelOpenRequest& request) override {
        Q_UNUSED(request);
        qInfo() << "[AA Session] Audio ChannelOpenRequest on channel:" << m_channelId;
        f1x::aasdk::proto::messages::ChannelOpenResponse resp;
        resp.set_status(f1x::aasdk::proto::enums::Status::OK);
        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_channel->sendChannelOpenResponse(resp, std::move(promise));
        m_channel->receive(shared_from_this());
    }

    void onAVChannelSetupRequest(const f1x::aasdk::proto::messages::AVChannelSetupRequest& request) override {
        Q_UNUSED(request);
        qInfo() << "[AA Session] Audio AVChannelSetupRequest on channel:" << m_channelId;
        f1x::aasdk::proto::messages::AVChannelSetupResponse resp;
        resp.set_media_status(f1x::aasdk::proto::enums::AVChannelSetupStatus::OK);
        resp.set_max_unacked(1); // Aligned with OpenAuto AASDK reference
        resp.add_configs(0);
        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_channel->sendAVChannelSetupResponse(resp, std::move(promise));
        m_channel->receive(shared_from_this());
    }

    void onAVChannelStartIndication(const f1x::aasdk::proto::messages::AVChannelStartIndication& indication) override {
        m_audioSession = indication.session();
        qInfo() << "[AA Session] Audio AVChannelStartIndication on channel:" << m_channelId << "session:" << m_audioSession;
        if (m_channelId == 4) {
            m_session->m_mediaAudioActive.store(true);
            emit m_session->audioFocusGained();
        }
        m_channel->receive(shared_from_this());
    }

    void onAVChannelStopIndication(const f1x::aasdk::proto::messages::AVChannelStopIndication& indication) override {
        Q_UNUSED(indication);
        qInfo() << "[AA Session] Audio AVChannelStopIndication on channel:" << m_channelId;
        if (m_channelId == 4) {
            m_session->m_mediaAudioActive.store(false);
        }
        m_channel->receive(shared_from_this());
    }

    void onAVMediaWithTimestampIndication(f1x::aasdk::messenger::Timestamp::ValueType, const f1x::aasdk::common::DataConstBuffer& buffer) override {
        if (m_channelId == 4) {
            if (!m_session->m_mediaAudioActive.exchange(true)) {
                qInfo() << "[AA Session] Media Audio stream active on Channel 4 -> Emitting audioFocusGained";
                emit m_session->audioFocusGained();
            }
        }
        if (m_session->m_audioSink && buffer.size > 0) {
            m_session->m_audioSink->queueAudioPacket(m_channelId, reinterpret_cast<const uint8_t*>(buffer.cdata), static_cast<int>(buffer.size));
        }

        f1x::aasdk::proto::messages::AVMediaAckIndication ack;
        ack.set_session(m_audioSession);
        ack.set_value(1);
        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_channel->sendAVMediaAckIndication(ack, std::move(promise));

        m_channel->receive(shared_from_this());
    }

    void onAVMediaIndication(const f1x::aasdk::common::DataConstBuffer& buffer) override {
        if (m_channelId == 4) {
            if (!m_session->m_mediaAudioActive.exchange(true)) {
                qInfo() << "[AA Session] Media Audio stream active on Channel 4 -> Emitting audioFocusGained";
                emit m_session->audioFocusGained();
            }
        }
        if (m_session->m_audioSink && buffer.size > 0) {
            m_session->m_audioSink->queueAudioPacket(m_channelId, reinterpret_cast<const uint8_t*>(buffer.cdata), static_cast<int>(buffer.size));
        }

        f1x::aasdk::proto::messages::AVMediaAckIndication ack;
        ack.set_session(m_audioSession);
        ack.set_value(1);
        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_channel->sendAVMediaAckIndication(ack, std::move(promise));

        m_channel->receive(shared_from_this());
    }

    void onChannelError(const f1x::aasdk::error::Error& e) override {
        qWarning() << "[AA Session] Audio channel" << m_channelId << "error: code=" << static_cast<int>(e.getCode())
                   << "native=" << e.getNativeCode() << "(" << libusbTransferStatusStr(e.getNativeCode()) << ")";
        if (e.getNativeCode() == 5 /* LIBUSB_TRANSFER_NO_DEVICE */) {
            m_session->onFatalError(QString("Audio channel %1 USB device gone").arg(m_channelId));
        } else {
            qWarning() << "[AA Session] Audio channel" << m_channelId << "transient error, re-arming...";
            if (m_channel) m_channel->receive(shared_from_this());
        }
    }

    void setChannel(std::shared_ptr<f1x::aasdk::channel::av::AudioServiceChannel> channel) {
        m_channel = std::move(channel);
    }

private:
    AndroidAutoSession *m_session;
    uint8_t m_channelId;
    std::shared_ptr<f1x::aasdk::channel::av::AudioServiceChannel> m_channel;
    int32_t m_audioSession{0};
};

// ============================================================================
// 5. Sensor Service Channel Event Handler (Channel 2)
// ============================================================================
class SensorEventHandler : public f1x::aasdk::channel::sensor::ISensorServiceChannelEventHandler,
                           public std::enable_shared_from_this<SensorEventHandler>
{
public:
    explicit SensorEventHandler(AndroidAutoSession *session) : m_session(session) {}

    void onChannelOpenRequest(const f1x::aasdk::proto::messages::ChannelOpenRequest& request) override {
        Q_UNUSED(request);
        qInfo() << "[AA Session] Sensor ChannelOpenRequest received";
        f1x::aasdk::proto::messages::ChannelOpenResponse resp;
        resp.set_status(f1x::aasdk::proto::enums::Status::OK);
        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_session->m_priv->sensorChannel->sendChannelOpenResponse(resp, std::move(promise));
        m_session->m_priv->sensorChannel->receive(shared_from_this());
    }

    void onSensorStartRequest(const f1x::aasdk::proto::messages::SensorStartRequestMessage& request) override {
        Q_UNUSED(request);
        qInfo() << "[AA Session] SensorStartRequest received -> broadcasting driving & night state";
        f1x::aasdk::proto::messages::SensorStartResponseMessage resp;
        resp.set_status(f1x::aasdk::proto::enums::Status::OK);
        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_session->m_priv->sensorChannel->sendSensorStartResponse(resp, std::move(promise));

        // DrivingStatus: UNRESTRICTED
        f1x::aasdk::proto::messages::SensorEventIndication driveInd;
        auto *driveEvent = driveInd.add_driving_status();
        driveEvent->set_status(f1x::aasdk::proto::enums::DrivingStatus::UNRESTRICTED);
        auto p1 = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_session->m_priv->sensorChannel->sendSensorEventIndication(driveInd, std::move(p1));

        // NightMode: DAY
        f1x::aasdk::proto::messages::SensorEventIndication nightInd;
        auto *nightEvent = nightInd.add_night_mode();
        nightEvent->set_is_night(false);
        auto p2 = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_session->m_priv->sensorChannel->sendSensorEventIndication(nightInd, std::move(p2));

        m_session->m_priv->sensorChannel->receive(shared_from_this());
    }

    void onChannelError(const f1x::aasdk::error::Error& e) override {
        qWarning() << "[AA Session] Sensor channel error: code=" << static_cast<int>(e.getCode())
                   << "native=" << e.getNativeCode() << "(" << libusbTransferStatusStr(e.getNativeCode()) << ")";
        if (e.getNativeCode() == 5) {
            m_session->onFatalError(QString("Sensor channel USB device gone"));
        } else {
            if (m_session->m_priv && m_session->m_priv->sensorChannel)
                m_session->m_priv->sensorChannel->receive(shared_from_this());
        }
    }

private:
    AndroidAutoSession *m_session;
};

// ============================================================================
// 6. Bluetooth Service Channel Event Handler (Channel 8)
// ============================================================================
class BluetoothEventHandler : public f1x::aasdk::channel::bluetooth::IBluetoothServiceChannelEventHandler,
                              public std::enable_shared_from_this<BluetoothEventHandler>
{
public:
    explicit BluetoothEventHandler(AndroidAutoSession *session) : m_session(session) {}

    void onChannelOpenRequest(const f1x::aasdk::proto::messages::ChannelOpenRequest& request) override {
        Q_UNUSED(request);
        qInfo() << "[AA Session] Bluetooth ChannelOpenRequest received";
        f1x::aasdk::proto::messages::ChannelOpenResponse resp;
        resp.set_status(f1x::aasdk::proto::enums::Status::OK);
        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_session->m_priv->bluetoothChannel->sendChannelOpenResponse(resp, std::move(promise));
        m_session->m_priv->bluetoothChannel->receive(shared_from_this());
    }

    void onBluetoothPairingRequest(const f1x::aasdk::proto::messages::BluetoothPairingRequest& request) override {
        Q_UNUSED(request);
        qInfo() << "[AA Session] BluetoothPairingRequest received";
        f1x::aasdk::proto::messages::BluetoothPairingResponse resp;
        resp.set_status(f1x::aasdk::proto::enums::BluetoothPairingStatus::OK);
        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_session->m_priv->bluetoothChannel->sendBluetoothPairingResponse(resp, std::move(promise));
        m_session->m_priv->bluetoothChannel->receive(shared_from_this());
    }

    void onChannelError(const f1x::aasdk::error::Error& e) override {
        qWarning() << "[AA Session] Bluetooth channel error: code=" << static_cast<int>(e.getCode())
                   << "native=" << e.getNativeCode() << "(" << libusbTransferStatusStr(e.getNativeCode()) << ")";
        if (e.getNativeCode() == 5) {
            m_session->onFatalError(QString("Bluetooth channel USB device gone"));
        } else {
            if (m_session->m_priv && m_session->m_priv->bluetoothChannel)
                m_session->m_priv->bluetoothChannel->receive(shared_from_this());
        }
    }

private:
    AndroidAutoSession *m_session;
};

// ============================================================================
// 7. Microphone Service Channel Event Handler (Channel 7)
// ============================================================================
class MicEventHandler : public f1x::aasdk::channel::av::IAVInputServiceChannelEventHandler,
                        public std::enable_shared_from_this<MicEventHandler>
{
public:
    explicit MicEventHandler(AndroidAutoSession *session) : m_session(session) {}

    void onChannelOpenRequest(const f1x::aasdk::proto::messages::ChannelOpenRequest& request) override {
        Q_UNUSED(request);
        qInfo() << "[AA Session] Mic ChannelOpenRequest received";
        f1x::aasdk::proto::messages::ChannelOpenResponse resp;
        resp.set_status(f1x::aasdk::proto::enums::Status::OK);
        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_session->m_priv->micChannel->sendChannelOpenResponse(resp, std::move(promise));
        m_session->m_priv->micChannel->receive(shared_from_this());
    }

    void onAVChannelSetupRequest(const f1x::aasdk::proto::messages::AVChannelSetupRequest& request) override {
        Q_UNUSED(request);
        qInfo() << "[AA Session] Mic AVChannelSetupRequest received";
        f1x::aasdk::proto::messages::AVChannelSetupResponse resp;
        resp.set_media_status(f1x::aasdk::proto::enums::AVChannelSetupStatus::OK);
        resp.set_max_unacked(1);
        resp.add_configs(0);
        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_session->m_priv->micChannel->sendAVChannelSetupResponse(resp, std::move(promise));
        m_session->m_priv->micChannel->receive(shared_from_this());
    }

    void onAVInputOpenRequest(const f1x::aasdk::proto::messages::AVInputOpenRequest& request) override {
        Q_UNUSED(request);
        qInfo() << "[AA Session] Mic AVInputOpenRequest received";
        f1x::aasdk::proto::messages::AVInputOpenResponse resp;
        resp.set_session(0);
        resp.set_value(0);
        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_session->m_priv->strand);
        m_session->m_priv->micChannel->sendAVInputOpenResponse(resp, std::move(promise));
        m_session->m_priv->micChannel->receive(shared_from_this());
    }

    void onAVMediaAckIndication(const f1x::aasdk::proto::messages::AVMediaAckIndication& indication) override {
        Q_UNUSED(indication);
        m_session->m_priv->micChannel->receive(shared_from_this());
    }

    void onChannelError(const f1x::aasdk::error::Error& e) override {
        qWarning() << "[AA Session] Mic channel error: code=" << static_cast<int>(e.getCode())
                   << "native=" << e.getNativeCode() << "(" << libusbTransferStatusStr(e.getNativeCode()) << ")";
        if (e.getNativeCode() == 5) {
            m_session->onFatalError(QString("Mic channel USB device gone"));
        } else {
            if (m_session->m_priv && m_session->m_priv->micChannel)
                m_session->m_priv->micChannel->receive(shared_from_this());
        }
    }

private:
    AndroidAutoSession *m_session;
};

// ============================================================================
// AndroidAutoSession Implementation
// ============================================================================

AndroidAutoSession::AndroidAutoSession(QObject *parent)
    : QThread(parent)
{
}

AndroidAutoSession::~AndroidAutoSession()
{
    stopSession();
}

void AndroidAutoSession::armServiceChannels()
{
    if (!m_running.load() || !m_priv) return;
    if (m_priv->videoChannel && m_priv->videoHandler) m_priv->videoChannel->receive(m_priv->videoHandler);
    if (m_priv->inputChannel && m_priv->inputHandler) m_priv->inputChannel->receive(m_priv->inputHandler);
    if (m_priv->mediaAudioChannel && m_priv->mediaAudioHandler) m_priv->mediaAudioChannel->receive(m_priv->mediaAudioHandler);
    if (m_priv->speechAudioChannel && m_priv->speechAudioHandler) m_priv->speechAudioChannel->receive(m_priv->speechAudioHandler);
    if (m_priv->systemAudioChannel && m_priv->systemAudioHandler) m_priv->systemAudioChannel->receive(m_priv->systemAudioHandler);
    if (m_priv->sensorChannel && m_priv->sensorHandler) m_priv->sensorChannel->receive(m_priv->sensorHandler);
    if (m_priv->bluetoothChannel && m_priv->bluetoothHandler) m_priv->bluetoothChannel->receive(m_priv->bluetoothHandler);
    if (m_priv->micChannel && m_priv->micHandler) m_priv->micChannel->receive(m_priv->micHandler);
}

bool AndroidAutoSession::startSession(void *usbDevicePtr, void *usbContext, const QString &btAddress)
{
    if (m_running.load()) {
        qWarning() << "[AA Session] Session is already running";
        return false;
    }

    m_devicePtr = usbDevicePtr;
    m_usbCtx = static_cast<libusb_context*>(usbContext);
    m_bluetoothAdapterAddress = btAddress.isEmpty() ? QStringLiteral("98:FE:54:2B:64:6F") : btAddress;

    m_running.store(true);
    m_tlsHandshakeComplete.store(false);
    m_cleanedUp.store(false);
    m_consecutiveFailedPings.store(0);

    m_ioService = std::make_unique<boost::asio::io_service>();
    m_priv = std::make_unique<PrivateMembers>();

    m_priv->work = std::make_unique<boost::asio::io_service::work>(*m_ioService);
    m_priv->strand = std::make_unique<boost::asio::io_service::strand>(*m_ioService);
    m_priv->pingTimer = std::make_unique<boost::asio::steady_timer>(*m_ioService);

    if (!m_decoder) {
        m_decoder = new AndroidAutoH264Decoder(this);
        connect(m_decoder, &AndroidAutoH264Decoder::frameReady, this, &AndroidAutoSession::frameReady);
        m_decoder->init(1280, 720);
    }

    if (!m_audioSink) {
        m_audioSink = new AndroidAutoAudioSink(this);
        m_audioSink->start();
    }

    qInfo() << "[AA Session] Initializing AASDK USB transport and channels...";

    m_priv->usbWrapper = std::make_shared<f1x::aasdk::usb::USBWrapper>(m_usbCtx);
    f1x::aasdk::usb::DeviceHandle devHandle;
    int openRes = m_priv->usbWrapper->open(static_cast<libusb_device*>(m_devicePtr), devHandle);
    if (openRes != 0 || !devHandle) {
        qWarning() << "[AA Session] Failed to open libusb device:" << openRes;
        m_running.store(false);
        return false;
    }

    try {
        m_priv->aoapDevice = f1x::aasdk::usb::AOAPDevice::create(*m_priv->usbWrapper, *m_ioService, std::move(devHandle));
    } catch (const f1x::aasdk::error::Error &e) {
        qWarning() << "[AA Session] Failed to claim AOAP interface / endpoints:" << static_cast<int>(e.getCode());
        m_running.store(false);
        return false;
    }

    m_priv->transport = std::make_shared<f1x::aasdk::transport::USBTransport>(*m_ioService, m_priv->aoapDevice);
    m_priv->sslWrapper = std::make_shared<f1x::aasdk::transport::SSLWrapper>();
    m_priv->cryptor = std::make_shared<f1x::aasdk::messenger::Cryptor>(m_priv->sslWrapper);

    try {
        m_priv->cryptor->init();
    } catch (const f1x::aasdk::error::Error &e) {
        qWarning() << "[AA Session] Failed to initialize AASDK Cryptor:" << static_cast<int>(e.getCode());
        m_priv->aoapDevice.reset();
        m_running.store(false);
        return false;
    }

    m_priv->inStream = std::make_shared<f1x::aasdk::messenger::MessageInStream>(*m_ioService, m_priv->transport, m_priv->cryptor);
    m_priv->outStream = std::make_shared<f1x::aasdk::messenger::MessageOutStream>(*m_ioService, m_priv->transport, m_priv->cryptor);
    m_priv->messenger = std::make_shared<f1x::aasdk::messenger::Messenger>(*m_ioService, m_priv->inStream, m_priv->outStream);

    // Instantiate all AASDK service channels
    m_priv->controlChannel = std::make_shared<f1x::aasdk::channel::control::ControlServiceChannel>(*m_priv->strand, m_priv->messenger);
    m_priv->videoChannel = std::make_shared<f1x::aasdk::channel::av::VideoServiceChannel>(*m_priv->strand, m_priv->messenger);
    m_priv->inputChannel = std::make_shared<f1x::aasdk::channel::input::InputServiceChannel>(*m_priv->strand, m_priv->messenger);
    m_priv->mediaAudioChannel = std::make_shared<f1x::aasdk::channel::av::MediaAudioServiceChannel>(*m_priv->strand, m_priv->messenger);
    m_priv->speechAudioChannel = std::make_shared<f1x::aasdk::channel::av::SpeechAudioServiceChannel>(*m_priv->strand, m_priv->messenger);
    m_priv->systemAudioChannel = std::make_shared<f1x::aasdk::channel::av::SystemAudioServiceChannel>(*m_priv->strand, m_priv->messenger);
    m_priv->sensorChannel = std::make_shared<f1x::aasdk::channel::sensor::SensorServiceChannel>(*m_priv->strand, m_priv->messenger);
    m_priv->bluetoothChannel = std::make_shared<f1x::aasdk::channel::bluetooth::BluetoothServiceChannel>(*m_priv->strand, m_priv->messenger);
    m_priv->micChannel = std::make_shared<f1x::aasdk::channel::av::AVInputServiceChannel>(*m_priv->strand, m_priv->messenger);

    // Instantiate event handlers
    m_priv->controlHandler = std::make_shared<ControlEventHandler>(this);
    m_priv->videoHandler = std::make_shared<VideoEventHandler>(this);
    m_priv->inputHandler = std::make_shared<InputEventHandler>(this);
    m_priv->mediaAudioHandler = std::make_shared<AudioEventHandler>(this, 4, m_priv->mediaAudioChannel);
    m_priv->speechAudioHandler = std::make_shared<AudioEventHandler>(this, 5, m_priv->speechAudioChannel);
    m_priv->systemAudioHandler = std::make_shared<AudioEventHandler>(this, 6, m_priv->systemAudioChannel);
    m_priv->sensorHandler = std::make_shared<SensorEventHandler>(this);
    m_priv->bluetoothHandler = std::make_shared<BluetoothEventHandler>(this);
    m_priv->micHandler = std::make_shared<MicEventHandler>(this);

    // Arm receive on control channel ONLY (service channels arm after ServiceDiscoveryResponse)
    m_priv->controlChannel->receive(m_priv->controlHandler);

    // Dedicated thread for libusb event polling
    m_usbEventThread = std::thread([this]() {
        struct timeval tv;
        tv.tv_sec = 0;
        tv.tv_usec = 20000;
        while (m_running.load()) {
            libusb_handle_events_timeout_completed(m_usbCtx, &tv, nullptr);
        }
    });

    this->start();
    emit sessionStarted();

    // Send Version Request
    auto promise = f1x::aasdk::channel::SendPromise::defer(*m_priv->strand);
    promise->then([]() {
        qInfo() << "[AA Session] VersionRequest successfully sent to mobile device";
    }, [this](const f1x::aasdk::error::Error &e) {
        qWarning() << "[AA Session] Failed to send VersionRequest: code=" << static_cast<int>(e.getCode())
                   << "native=" << e.getNativeCode() << "(" << libusbTransferStatusStr(e.getNativeCode()) << ")";
        onFatalError("VersionRequest send timeout");
    });
    m_priv->controlChannel->sendVersionRequest(std::move(promise));

    return true;
}

void AndroidAutoSession::run()
{
    qInfo() << "[AA Session] AASDK ASIO event loop running...";
    emit statusChanged("AASDK session active");

    try {
        m_ioService->run();
    } catch (const std::exception &e) {
        qWarning() << "[AA Session] Exception in AASDK ASIO loop:" << e.what();
    } catch (...) {
        qWarning() << "[AA Session] Unknown exception in AASDK ASIO loop";
    }

    qInfo() << "[AA Session] AASDK ASIO event loop exited";
}

void AndroidAutoSession::doHandshakeStep()
{
    if (!m_running.load() || !m_priv || !m_priv->cryptor || !m_priv->controlChannel) return;

    try {
        bool complete = m_priv->cryptor->doHandshake();
        auto handshakeBuffer = m_priv->cryptor->readHandshakeBuffer();
        if (handshakeBuffer.size() > 0) {
            auto promise = f1x::aasdk::channel::SendPromise::defer(*m_priv->strand);
            m_priv->controlChannel->sendHandshake(std::move(handshakeBuffer), std::move(promise));
        }

        if (complete) {
            qInfo() << "[AA Session] TLS Handshake SUCCESS! Disagreeing errors cleared. Sending AuthCompleteIndication...";
            m_tlsHandshakeComplete.store(true);

            f1x::aasdk::proto::messages::AuthCompleteIndication authComplete;
            authComplete.set_status(f1x::aasdk::proto::enums::Status::OK);
            auto promise = f1x::aasdk::channel::SendPromise::defer(*m_priv->strand);
            m_priv->controlChannel->sendAuthComplete(authComplete, std::move(promise));

            // No proactive ping timer needed: OpenAuto reference relies on high-frequency video/audio ACKs
        }
    } catch (const f1x::aasdk::error::Error &e) {
        qWarning() << "[AA Session] Fatal Cryptor handshake error:" << static_cast<int>(e.getCode());
        onFatalError("SSL handshake failed");
    }
}

void AndroidAutoSession::handleHandshakePayload(const f1x::aasdk::common::DataConstBuffer &payload)
{
    if (!m_running.load() || !m_priv || !m_priv->cryptor) return;

    try {
        m_priv->cryptor->writeHandshakeBuffer(payload);
        doHandshakeStep();
    } catch (const f1x::aasdk::error::Error &e) {
        qWarning() << "[AA Session] Cryptor writeHandshakeBuffer error:" << static_cast<int>(e.getCode());
        onFatalError("SSL handshake payload failed");
    }
}

void AndroidAutoSession::schedulePing()
{
    // Proactive ping disabled to prevent USB transfer contention with active video streaming
}

void AndroidAutoSession::onFatalError(const QString &reason)
{
    bool expected = true;
    if (!m_running.compare_exchange_strong(expected, false)) {
        return;
    }

    qWarning() << "[AA Session] FATAL SESSION TERMINATION:" << reason;
    emit statusChanged(QString("Session error: %1").arg(reason));

    // Cancel transfers and stop ASIO immediately to unblock pending operations
    if (m_priv && m_priv->transport) {
        try { m_priv->transport->stop(); } catch (...) {}
    }
    if (m_priv && m_priv->messenger) {
        try { m_priv->messenger->stop(); } catch (...) {}
    }
    if (m_ioService) {
        m_ioService->stop();
    }

    // Execute unified cleanup asynchronously so we don't block or deadlock the caller strand
    std::thread([this]() {
        this->cleanupSession();
    }).detach();
}

void AndroidAutoSession::cleanupSession()
{
    std::lock_guard<std::mutex> lock(m_cleanupMutex);
    if (m_cleanedUp.exchange(true)) {
        return;
    }

    m_running.store(false);
    m_mediaAudioActive.store(false);

    qInfo() << "[AA Session] Executing unified session cleanup...";

    // 1. Cancel AASDK USB transfers
    if (m_priv && m_priv->transport) {
        try {
            m_priv->transport->stop();
        } catch (...) {}
    }

    // 2. Stop messenger / ASIO loop
    if (m_priv && m_priv->pingTimer) {
        boost::system::error_code ec;
        m_priv->pingTimer->cancel(ec);
    }
    if (m_priv && m_priv->work) {
        m_priv->work.reset();
    }
    if (m_priv && m_priv->messenger) {
        try {
            m_priv->messenger->stop();
        } catch (...) {}
    }
    if (m_ioService) {
        m_ioService->stop();
    }

    // 3. Join USB event thread
    if (m_usbEventThread.joinable()) {
        try {
            m_usbEventThread.join();
        } catch (const std::exception &e) {
            qWarning() << "[AA Session] Exception joining USB event thread:" << e.what();
        } catch (...) {
            qWarning() << "[AA Session] Unknown exception joining USB event thread";
        }
    }

    // 4. Wait for AndroidAutoSession thread (if caller is not the session thread itself)
    if (QThread::currentThread() != this) {
        try {
            this->wait(3000);
        } catch (...) {}
    }

    // 5. Release USB interface and AASDK resources
    if (m_priv) {
        try {
            m_priv->controlChannel.reset();
            m_priv->videoChannel.reset();
            m_priv->inputChannel.reset();
            m_priv->mediaAudioChannel.reset();
            m_priv->speechAudioChannel.reset();
            m_priv->systemAudioChannel.reset();
            m_priv->sensorChannel.reset();
            m_priv->bluetoothChannel.reset();
            m_priv->micChannel.reset();

            m_priv->messenger.reset();
            m_priv->inStream.reset();
            m_priv->outStream.reset();
            m_priv->transport.reset();
            m_priv->aoapDevice.reset();

            if (m_priv->cryptor) {
                m_priv->cryptor->deinit();
                m_priv->cryptor.reset();
            }
            m_priv->sslWrapper.reset();
            m_priv->usbWrapper.reset();
            m_priv.reset();
        } catch (const std::exception &e) {
            qWarning() << "[AA Session] Exception destroying AASDK components:" << e.what();
        } catch (...) {
            qWarning() << "[AA Session] Unknown exception destroying AASDK components";
        }
    }

    m_ioService.reset();

    if (m_decoder) {
        m_decoder->stopDecoder();
        delete m_decoder;
        m_decoder = nullptr;
    }

    if (m_audioSink) {
        m_audioSink->stop();
        delete m_audioSink;
        m_audioSink = nullptr;
    }

    qInfo() << "[AA Session] AASDK session cleanup complete and USB interface released";

    // 6. Emit sessionStopped
    emit sessionStopped();
}

void AndroidAutoSession::stopSession()
{
    cleanupSession();
}

void AndroidAutoSession::sendTouch(int action, int x, int y)
{
    if (!m_running.load() || !m_tlsHandshakeComplete.load() || !m_priv || !m_priv->inputChannel) {
        qWarning() << "[AA Session] sendTouch dropped: running=" << m_running.load()
                   << "tls=" << m_tlsHandshakeComplete.load()
                   << "priv=" << (m_priv != nullptr)
                   << "inputChannel=" << (m_priv && m_priv->inputChannel ? "yes" : "no");
        return;
    }

    // Rate-limit DRAG (action == 2) to ~60Hz (16ms) to avoid queue saturation; PRESS and RELEASE always pass
    if (action == 2) {
        static std::atomic<uint64_t> lastDragMs{0};
        uint64_t nowMs = static_cast<uint64_t>(
            std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::steady_clock::now().time_since_epoch()).count());
        uint64_t prev = lastDragMs.load();
        if (nowMs - prev < 16) {
            return;
        }
        lastDragMs.store(nowMs);
    }

    uint64_t timestamp = static_cast<uint64_t>(
        std::chrono::duration_cast<std::chrono::microseconds>(
            std::chrono::high_resolution_clock::now().time_since_epoch()).count());

    int clampedX = qBound(0, x, m_touchWidth - 1);
    int clampedY = qBound(0, y, m_touchHeight - 1);

    if (action != 2) {
        qInfo() << "[AA Session] Sending touch action=" << action
                << (action == 0 ? "(PRESS)" : "(RELEASE)")
                << "at (" << clampedX << "," << clampedY << ")";
    }

    m_priv->strand->post([this, timestamp, action, clampedX, clampedY]() {
        if (!m_running.load() || !m_priv || !m_priv->inputChannel) return;

        f1x::aasdk::proto::messages::InputEventIndication indication;
        indication.set_timestamp(timestamp);

        auto *touch = indication.mutable_touch_event();
        touch->set_touch_action(action == 0 ? f1x::aasdk::proto::enums::TouchAction::PRESS :
                                (action == 1 ? f1x::aasdk::proto::enums::TouchAction::RELEASE :
                                               f1x::aasdk::proto::enums::TouchAction::DRAG));
        touch->set_action_index(0);

        auto *location = touch->add_touch_location();
        location->set_x(clampedX);
        location->set_y(clampedY);
        location->set_pointer_id(0);

        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_priv->strand);
        promise->then([]() {}, [this](const f1x::aasdk::error::Error &e) {
            qWarning() << "[AA Session] Touch send failed: code=" << static_cast<int>(e.getCode())
                       << "native=" << e.getNativeCode() << "(" << libusbTransferStatusStr(e.getNativeCode()) << ")";
            // Do not end Android Auto on one touch-send failure!
            // Terminate only if transport confirmed disconnected (LIBUSB_TRANSFER_NO_DEVICE = 5)
            if (e.getNativeCode() == 5 /* LIBUSB_TRANSFER_NO_DEVICE */) {
                onFatalError("USB device disconnected during touch send");
            }
        });

        m_priv->inputChannel->sendInputEventIndication(indication, std::move(promise));
    });
}

void AndroidAutoSession::sendKeyEvent(uint32_t keyCode)
{
    if (!m_running.load() || !m_tlsHandshakeComplete.load() || !m_priv || !m_priv->inputChannel || !m_priv->strand) return;

    m_priv->strand->post([this, keyCode]() {
        if (!m_running.load() || !m_priv || !m_priv->inputChannel) return;

        qInfo() << "[AA Session] Sending key event keyCode=" << keyCode << "(PRESS)";

        auto sendSingleKey = [this, keyCode](bool pressed) {
            if (!m_running.load() || !m_priv || !m_priv->inputChannel) return;

            uint64_t timestamp = static_cast<uint64_t>(
                std::chrono::duration_cast<std::chrono::microseconds>(
                    std::chrono::high_resolution_clock::now().time_since_epoch()).count());

            f1x::aasdk::proto::messages::InputEventIndication indication;
            indication.set_timestamp(timestamp);
            auto *btnEvents = indication.mutable_button_event();
            auto *btnEvent = btnEvents->add_button_events();
            btnEvent->set_scan_code(keyCode);
            btnEvent->set_is_pressed(pressed);
            btnEvent->set_meta(0);
            btnEvent->set_long_press(false);

            auto promise = f1x::aasdk::channel::SendPromise::defer(*m_priv->strand);
            promise->then([keyCode, pressed]() {
                qDebug() << "[AA Session] Key indication acked: code=" << keyCode << "pressed=" << pressed;
            }, [keyCode, pressed](const f1x::aasdk::error::Error &e) {
                qWarning() << "[AA Session] Key send failed: code=" << keyCode << "pressed=" << pressed
                           << "err=" << static_cast<int>(e.getCode()) << "native=" << e.getNativeCode();
            });
            m_priv->inputChannel->sendInputEventIndication(indication, std::move(promise));
        };

        // Send Key PRESS
        sendSingleKey(true);

        // Schedule Key RELEASE after 60ms
        if (m_ioService) {
            auto timer = std::make_shared<boost::asio::steady_timer>(*m_ioService);
            timer->expires_after(std::chrono::milliseconds(60));
            timer->async_wait(m_priv->strand->wrap([this, sendSingleKey, timer](const boost::system::error_code &ec) {
                if (!ec) {
                    qInfo() << "[AA Session] Sending key event (RELEASE)";
                    sendSingleKey(false);
                }
            }));
        }
    });
}

void AndroidAutoSession::requestVideoFocus(bool focused)
{
    if (!m_running.load() || !m_priv || !m_priv->videoChannel || !m_priv->strand) return;
    m_priv->strand->post([this, focused]() {
        if (!m_running.load() || !m_priv || !m_priv->videoChannel) return;
        qInfo() << "[AA Session] Explicit VideoFocusIndication dispatch:" << (focused ? "FOCUSED" : "UNFOCUSED");
        f1x::aasdk::proto::messages::VideoFocusIndication indication;
        indication.set_focus_mode(focused ? f1x::aasdk::proto::enums::VideoFocusMode::FOCUSED : f1x::aasdk::proto::enums::VideoFocusMode::UNFOCUSED);
        indication.set_unrequested(!focused);
        auto promise = f1x::aasdk::channel::SendPromise::defer(*m_priv->strand);
        m_priv->videoChannel->sendVideoFocusIndication(indication, std::move(promise));
    });
}

