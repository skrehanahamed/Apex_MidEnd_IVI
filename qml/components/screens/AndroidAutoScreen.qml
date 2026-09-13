/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * File: AndroidAutoScreen.qml
 * Description: Genuine Android Auto Projection Viewport with APEX Menu Badge,
 *              Direct Caller Integration, and Unified Touch/Mouse Event Forwarding
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts
import com.apex.ivi 1.0

Rectangle {
    id: root
    color: "#0A0D12"

    signal backClicked()

    Connections {
        target: systemController
        function onAndroidAutoConnectedChanged() {
            if (!systemController.androidAutoConnected) {
                if (aaVideoView) {
                    aaVideoView.clearVideo();
                }
                if (systemController.currentScreen === "android_auto") {
                    console.log("[AndroidAutoScreen] Phone disconnected -> Returning to Home");
                    systemController.navigateTo("home");
                }
            }
        }
    }

    Item {
        anchors.fill: parent

        // 1. VIDEO RENDER ONLY (no touch logic in C++)
        AndroidAutoVideoItem {
            id: aaVideoView
            anchors.fill: parent
            controller: systemController
            visible: true
            opacity: hasVideo ? 1.0 : 0.0
            z: 10
        }

        // 2. SOLE TOUCH OWNER — MultiPointTouchArea above video, below top pill bar
        //    Captures all touch points (and mouse pointer via mouseEnabled: true)
        //    Maps raw screen coords -> 1280x720 AA canvas -> systemController.sendAndroidAutoTouch
        MultiPointTouchArea {
            id: aaTouchArea
            anchors.fill: parent
            z: 20
            minimumTouchPoints: 1
            maximumTouchPoints: 1
            mouseEnabled: true
            enabled: systemController.androidAutoConnected

            property bool gestureActive: false
            property real lastDragMs: 0

            touchPoints: [ TouchPoint { id: tp0 } ]

            onPressed: (touchPoints) => {
                if (gestureActive) return
                gestureActive = true
                lastDragMs = Date.now()
                var p = (touchPoints && touchPoints.length > 0) ? touchPoints[0] : tp0
                var nx = Math.max(0, Math.min(1279, Math.round((p.x / width) * 1280)))
                var ny = Math.max(0, Math.min(719, Math.round((p.y / height) * 720)))
                console.log("[AndroidAutoScreen] Touch PRESS at raw (" + Math.round(p.x) + "," + Math.round(p.y) + ") -> AA (" + nx + "," + ny + ")")
                systemController.sendAndroidAutoTouch(0, nx, ny)
            }

            onUpdated: (touchPoints) => {
                if (!gestureActive) return
                var now = Date.now()
                // Rate limit DRAG to ~50 events/second (20 ms)
                if (now - lastDragMs < 20) return
                lastDragMs = now
                var p = (touchPoints && touchPoints.length > 0) ? touchPoints[0] : tp0
                var nx = Math.max(0, Math.min(1279, Math.round((p.x / width) * 1280)))
                var ny = Math.max(0, Math.min(719, Math.round((p.y / height) * 720)))
                systemController.sendAndroidAutoTouch(2, nx, ny)
            }

            onReleased: (touchPoints) => {
                if (!gestureActive) return
                gestureActive = false
                var p = (touchPoints && touchPoints.length > 0) ? touchPoints[0] : tp0
                var nx = Math.max(0, Math.min(1279, Math.round((p.x / width) * 1280)))
                var ny = Math.max(0, Math.min(719, Math.round((p.y / height) * 720)))
                console.log("[AndroidAutoScreen] Touch RELEASE at raw (" + Math.round(p.x) + "," + Math.round(p.y) + ") -> AA (" + nx + "," + ny + ")")
                systemController.sendAndroidAutoTouch(1, nx, ny)
            }

            onCanceled: (touchPoints) => {
                if (gestureActive) {
                    gestureActive = false
                    var p = (touchPoints && touchPoints.length > 0) ? touchPoints[0] : tp0
                    var nx = Math.max(0, Math.min(1279, Math.round((p.x / width) * 1280)))
                    var ny = Math.max(0, Math.min(719, Math.round((p.y / height) * 720)))
                    systemController.sendAndroidAutoTouch(1, nx, ny)
                }
            }
        }
    }
}
