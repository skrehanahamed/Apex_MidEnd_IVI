/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: TopStatusBar.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    height: 64
    color: "#05070B"

    signal menuClicked()
    signal homeClicked()

    property bool isHomeScreen: systemController.currentScreen === "home"
    property bool menuOpen: false

    // Bottom hairline divider
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1.5
        color: "#1E222D"
    }

    // 1. Left Action Button: "Menu" on Home Screen <-> "🏠" Home Icon on Subscreens
    Rectangle {
        id: leftBtn
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        width: 116
        color: (root.isHomeScreen && root.menuOpen)
               ? (btnMouse.pressed ? "#93CFE2" : "#A5D4E6")
               : (btnMouse.pressed ? "#1E88E5" : (btnMouse.containsMouse ? "#3A6C9B" : "#2E5B84"))
        border.color: (root.isHomeScreen && root.menuOpen) ? "#8AC5D7" : (btnMouse.pressed ? "#66D9FF" : "#3F74A3")
        border.width: 1
        radius: 3

        Behavior on color { ColorAnimation { duration: 100 } }

        // Home Screen: "Menu" text
        Text {
            anchors.centerIn: parent
            text: "Menu"
            color: (root.isHomeScreen && root.menuOpen) ? "#1B3B4C" : "#FFFFFF"
            font.pixelSize: 24
            font.bold: true
            font.family: "Roboto"
            visible: root.isHomeScreen
            scale: btnMouse.pressed ? 0.94 : 1.0
            Behavior on scale { NumberAnimation { duration: 100 } }
        }

        // Subscreens: White House Home Icon
        Image {
            anchors.centerIn: parent
            width: 34
            height: 32
            source: "qrc:/assets/ui/icon_home.png"
            fillMode: Image.PreserveAspectFit
            visible: !root.isHomeScreen
            smooth: true
            mipmap: true
            scale: btnMouse.pressed ? 0.92 : 1.0
            Behavior on scale { NumberAnimation { duration: 100 } }
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.isHomeScreen) {
                    root.menuClicked()
                } else {
                    root.homeClicked()
                }
            }
        }
    }

    // 2. Date & Time cluster (STAYS STATIC, NEVER MOVES)
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 170
        anchors.verticalCenter: parent.verticalCenter
        spacing: 16

        // Date: "Fri, 09/04"
        Text {
            id: dateText
            anchors.baseline: timeText.baseline
            text: systemController.currentDate
            color: "#FFFFFF"
            font.pixelSize: 28
            font.weight: Font.DemiBold
            font.family: "Roboto"
        }

        // Divider between Date and Time
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1.5
            height: 30
            color: "#2E3648"
        }

        // Time: "11:07"
        Text {
            id: timeText
            anchors.verticalCenter: parent.verticalCenter
            text: systemController.currentTime
            color: "#FFFFFF"
            font.pixelSize: 32
            font.bold: true
            font.family: "Roboto"
        }

        // AM/PM: "PM"
        Text {
            id: amPmText
            anchors.baseline: timeText.baseline
            text: systemController.currentAmPm
            color: "#D0D6E2"
            font.pixelSize: 16
            font.weight: Font.DemiBold
            font.family: "Roboto"
        }

        // Divider following AM/PM
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1.5
            height: 28
            color: "#242A38"
        }
    }

    // 3. Right side Status Indicators (Quiet Mode, BT Music)
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        spacing: 16

        // Quiet Mode Indicator (Moon Icon in Upper Side)
        Image {
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            height: 28
            source: "qrc:/assets/ui/icon_quiet_mode.png"
            fillMode: Image.PreserveAspectFit
            visible: systemController.quietModeEnabled
            opacity: systemController.quietModeEnabled ? 1.0 : 0.0
            smooth: true
            mipmap: true

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
        }

        // BT Music Indicator
        Image {
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            height: 36
            source: "qrc:/assets/bluetooth/icon_bt_music.png"
            fillMode: Image.PreserveAspectFit
            visible: systemController.isBluetoothConnected
            smooth: true
            mipmap: true
        }
    }
}
