/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: ApexLoadingScreen.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Effects

Rectangle {
    id: root
    color: "#000000"

    signal finished()

    // Pure black screen, centered metallic APEX logo, NO shapes behind it, NO words
    Item {
        id: logoWrapper
        anchors.centerIn: parent
        width: 480
        height: width * (204.0 / 1024.0)

        // 1. Base Metallic Logo
        Image {
            id: baseLogo
            anchors.fill: parent
            source: "qrc:/assets/branding/apex_logo.png"
            fillMode: Image.PreserveAspectFit
            sourceSize.width: 480
            smooth: true
        }

        // 2. Offscreen Pure White Shine Strip with soft feathered edges
        Item {
            id: shineStripContainer
            anchors.fill: parent
            visible: false

            Rectangle {
                id: shineStripe
                width: 120
                height: parent.height * 2.6
                anchors.verticalCenter: parent.verticalCenter
                rotation: 22

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.20; color: "transparent" }
                    GradientStop { position: 0.40; color: "#45FFFFFF" }
                    GradientStop { position: 0.50; color: "#FFFFFFFF" }
                    GradientStop { position: 0.60; color: "#45FFFFFF" }
                    GradientStop { position: 0.80; color: "transparent" }
                    GradientStop { position: 1.0; color: "transparent" }
                }

                // Slow, graceful pure white shine animation across the logo
                NumberAnimation on x {
                    id: shineAnim
                    from: -160
                    to: logoWrapper.width + 160
                    duration: 3200
                    loops: Animation.Infinite
                    easing.type: Easing.InOutQuad
                }
            }
        }

        // 3. Masked Effect: Locks the pure white specular shine exclusively to the APEX metallic letters
        MultiEffect {
            anchors.fill: baseLogo
            source: shineStripContainer
            maskEnabled: true
            maskSource: baseLogo
            maskThresholdMin: 0.3
            maskSpreadAtMin: 0.2
        }
    }

    // Splash duration & graceful fade out
    SequentialAnimation {
        id: splashTimer
        running: true

        PauseAnimation { duration: 3200 }

        NumberAnimation {
            target: root
            property: "opacity"
            to: 0.0
            duration: 600
            easing.type: Easing.InOutQuad
        }

        ScriptAction {
            script: {
                root.visible = false
                root.finished()
            }
        }
    }

    // Absorb clicks during bootup without interrupting the animation
    MouseArea {
        anchors.fill: parent
        onClicked: {
            // Do not stop the animation - let it complete gracefully as requested
        }
    }
}
