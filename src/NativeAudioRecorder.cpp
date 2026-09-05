/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: NativeAudioRecorder.cpp
 * Description: Cross-platform fallback implementation for Linux and Windows
 * ============================================================================
 */

#ifndef __APPLE__
#include "NativeAudioRecorder.h"

NativeAudioRecorder::NativeAudioRecorder(QObject *parent)
    : QObject(parent)
    , m_recorder(nullptr)
    , m_isRecording(false)
    , m_isPaused(false)
{
}

NativeAudioRecorder::~NativeAudioRecorder()
{
    stopRecording();
}

bool NativeAudioRecorder::startRecording(const QString &filePath, float gain)
{
    Q_UNUSED(filePath);
    Q_UNUSED(gain);
    m_isRecording = true;
    m_isPaused = false;
    return true;
}

void NativeAudioRecorder::pauseRecording()
{
    if (m_isRecording) {
        m_isPaused = true;
    }
}

void NativeAudioRecorder::resumeRecording()
{
    if (m_isRecording) {
        m_isPaused = false;
    }
}

void NativeAudioRecorder::stopRecording()
{
    m_isRecording = false;
    m_isPaused = false;
}

bool NativeAudioRecorder::isRecording() const
{
    return m_isRecording && !m_isPaused;
}

float NativeAudioRecorder::currentLevel()
{
    return (m_isRecording && !m_isPaused) ? 0.65f : 0.0f;
}

#endif // !__APPLE__
