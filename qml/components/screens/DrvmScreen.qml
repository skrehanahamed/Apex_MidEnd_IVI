/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: DrvmScreen.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts

Item {
    id: root
    width: 1280
    height: 720

    signal homeClicked()
    signal settingsClicked()

    // Mode: DRVM (normal driving rear view monitor) vs REVERSE (R gear parking camera with guidelines)
    readonly property bool isReverse: systemController.isReverseGear

    // ====================================================
    // 1. CAMERA BACKGROUND FEED
    // ====================================================
    Image {
        id: cameraFeed
        anchors.fill: parent
        // In DRVM mode: clean camera feed
        // In Reverse mode: camera feed with integrated parking guidelines
        source: root.isReverse
                ? "qrc:/assets/vehicle/drvm_reverse_camera_feed.png"
                : "qrc:/assets/vehicle/drvm_clean_camera_feed.png"
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
    }

    // Subtle dark gradient overlay at top for high text contrast
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 90
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.40) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // ====================================================
    // 3. LEFT ACTION BAR: [ Home ] and [ Settings ]
    // ====================================================
    Column {
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.top: parent.top
        anchors.topMargin: 20
        spacing: 14
        z: 20

        // Home Button (Top Left)
        Rectangle {
            width: 76
            height: 56
            radius: 4
            color: homeMouse.pressed ? "#447CA8" : (homeMouse.containsMouse ? "#366892" : "#285278")
            border.color: homeMouse.pressed ? "#80D8FF" : "#4A78A4"
            border.width: 1.5

            Behavior on color { ColorAnimation { duration: 90 } }

            Image {
                anchors.centerIn: parent
                width: 32
                height: 32
                source: "qrc:/assets/ui/icon_home.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                scale: homeMouse.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 80 } }
            }

            MouseArea {
                id: homeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    console.log("[DRVM] Home clicked -> Exiting camera")
                    if (systemController.isReverseGear) {
                        systemController.isReverseGear = false
                    }
                    root.homeClicked()
                }
            }
        }

        // Settings Button (Below Home)
        Rectangle {
            width: 76
            height: 56
            radius: 4
            color: setMouse.pressed ? "#447CA8" : (setMouse.containsMouse ? "#366892" : "#285278")
            border.color: setMouse.pressed ? "#80D8FF" : "#4A78A4"
            border.width: 1.5

            Behavior on color { ColorAnimation { duration: 90 } }

            Image {
                anchors.centerIn: parent
                width: 30
                height: 30
                source: "qrc:/assets/ui/icon_settings_hdr.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                scale: setMouse.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 80 } }
            }

            MouseArea {
                id: setMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    console.log("[DRVM] Settings clicked -> Opening Display/Camera settings")
                    root.settingsClicked()
                }
            }
        }
    }

    // ====================================================
    // 4. TOP CENTER SAFETY WARNING (Matching Genuine Car Screen)
    // ====================================================
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 22
        text: "Check surroundings for your safety."
        color: "#FFFFFF"
        font.pixelSize: 26
        font.weight: Font.DemiBold
        font.family: "Roboto"
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.85)
        z: 20
    }

    // ====================================================
    // 5. TOP RIGHT CLOCK (Matching Genuine Car Screen - Clean text, no pill)
    // ====================================================
    Text {
        id: topClockText
        anchors.right: parent.right
        anchors.rightMargin: 40
        anchors.top: parent.top
        anchors.topMargin: 24
        text: (systemController.currentTime && systemController.currentTime.length > 0 ? systemController.currentTime : "3:15") + " " +
              (systemController.currentAmPm && systemController.currentAmPm.length > 0 ? systemController.currentAmPm : "PM")
        color: "#FFFFFF"
        font.pixelSize: 22
        font.weight: Font.DemiBold
        font.family: "Roboto"
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.85)
        z: 20
    }

    // ====================================================
    // 6. TOP-DOWN CAR SENSOR GRAPHIC (Inside OEM Dark Square)
    // ====================================================
    Rectangle {
        id: carSensorSquare
        anchors.right: parent.right
        anchors.rightMargin: 165
        anchors.top: parent.top
        anchors.topMargin: 70
        width: 92
        height: 112
        radius: 6
        color: Qt.rgba(0.06, 0.10, 0.16, 0.82)
        border.color: Qt.rgba(1, 1, 1, 0.22)
        border.width: 1
        z: 20
        visible: !root.isReverse

        Image {
            id: carSensorImg
            anchors.centerIn: parent
            width: 76
            height: 96
            source: "qrc:/assets/vehicle/drvm_car_sensor.png"
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
        }
    }
}
