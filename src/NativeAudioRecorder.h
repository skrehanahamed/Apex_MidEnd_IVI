/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: NativeAudioRecorder.h
 * ============================================================================
 */

#pragma once
#include <QString>
#include <QObject>

class NativeAudioRecorder : public QObject {
    Q_OBJECT
public:
    explicit NativeAudioRecorder(QObject *parent = nullptr);
    ~NativeAudioRecorder();

    bool startRecording(const QString &filePath, float gain = 1.0f);
    void pauseRecording();
    void resumeRecording();
    void stopRecording();
    bool isRecording() const;
    float currentLevel();

private:
    void *m_recorder{nullptr};
    bool m_isRecording{false};
    bool m_isPaused{false};
};
