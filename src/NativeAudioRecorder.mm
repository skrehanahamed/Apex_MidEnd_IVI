/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: NativeAudioRecorder.mm
 * ============================================================================
 */

#import "NativeAudioRecorder.h"
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#include <cmath>

NativeAudioRecorder::NativeAudioRecorder(QObject *parent)
    : QObject(parent), m_recorder(nullptr), m_isRecording(false), m_isPaused(false)
{
}

NativeAudioRecorder::~NativeAudioRecorder()
{
    stopRecording();
}

bool NativeAudioRecorder::startRecording(const QString &filePath, float gain)
{
    stopRecording();
    @autoreleasepool {
        NSString *pathStr = filePath.toNSString();
        NSURL *url = [NSURL fileURLWithPath:pathStr];

        NSDictionary *settings = @{
            AVFormatIDKey: @(kAudioFormatLinearPCM),
            AVSampleRateKey: @44100.0,
            AVNumberOfChannelsKey: @1,
            AVLinearPCMBitDepthKey: @16,
            AVLinearPCMIsFloatKey: @NO,
            AVLinearPCMIsBigEndianKey: @NO
        };

        NSError *error = nil;
        AVAudioRecorder *rec = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
        if (!rec || error) {
            NSLog(@"[NativeAudioRecorder] Failed to create AVAudioRecorder: %@", error);
            return false;
        }

        rec.meteringEnabled = YES;
        if (![rec record]) {
            NSLog(@"[NativeAudioRecorder] Failed to start record on URL: %@", url);
            return false;
        }

        m_recorder = (__bridge_retained void*)rec;
        m_isRecording = true;
        m_isPaused = false;
        NSLog(@"[NativeAudioRecorder] Recording started successfully at: %@", pathStr);
        return true;
    }
}

void NativeAudioRecorder::pauseRecording()
{
    if (m_recorder && m_isRecording && !m_isPaused) {
        AVAudioRecorder *rec = (__bridge AVAudioRecorder*)m_recorder;
        [rec pause];
        m_isPaused = true;
        NSLog(@"[NativeAudioRecorder] Recording paused");
    }
}

void NativeAudioRecorder::resumeRecording()
{
    if (m_recorder && m_isRecording && m_isPaused) {
        AVAudioRecorder *rec = (__bridge AVAudioRecorder*)m_recorder;
        [rec record];
        m_isPaused = false;
        NSLog(@"[NativeAudioRecorder] Recording resumed");
    }
}

void NativeAudioRecorder::stopRecording()
{
    if (m_recorder) {
        AVAudioRecorder *rec = (__bridge_transfer AVAudioRecorder*)m_recorder;
        [rec stop];
        m_recorder = nullptr;
        NSLog(@"[NativeAudioRecorder] Recording stopped");
    }
    m_isRecording = false;
    m_isPaused = false;
}

bool NativeAudioRecorder::isRecording() const
{
    return m_isRecording;
}

float NativeAudioRecorder::currentLevel()
{
    if (m_recorder && m_isRecording && !m_isPaused) {
        AVAudioRecorder *rec = (__bridge AVAudioRecorder*)m_recorder;
        [rec updateMeters];
        float avg = [rec averagePowerForChannel:0]; // -160 dB to 0 dB
        if (avg < -60.0f) return 0.05f;
        float norm = (avg + 60.0f) / 60.0f; // 0.0 to 1.0
        return std::max(0.05f, std::min(1.0f, norm));
    }
    return 0.0f;
}
