/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: SettingsScreen.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#05070B"

    signal backToHomeClicked()
    signal deviceConnectionClicked()
    signal soundClicked()
    signal displayClicked()
    signal buttonClicked()
    signal generalClicked()
    signal rearrangeIconsClicked()
    signal manualClicked()

    readonly property bool isHindi: (systemController.systemLanguage === "Hindi")
    function tr(en, hi) { return isHindi ? hi : en; }

    property bool menuOpen: false

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ====================================================
        // 1. SUB-HEADER BAR ("Settings" title + 3 Action Buttons)
        // ====================================================
        Rectangle {
            id: headerBar
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            color: "#10141C"
            z: 10

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1.5
                color: "#1E222D"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 16
                spacing: 12

                // Left: Gear icon + "Settings" title
                Row {
                    spacing: 14
                    Layout.alignment: Qt.AlignVCenter

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32
                        source: "qrc:/assets/ui/icon_settings_hdr.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.tr("Settings", "सेटिंग्स")
                        color: "#FFFFFF"
                        font.pixelSize: 24
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }
                }

                Item { Layout.fillWidth: true }

                // Right 3 Blue Buttons: Display Off | Menu | Back (⮌)
                Row {
                    spacing: 12
                    Layout.alignment: Qt.AlignVCenter

                    // 1. Display Off
                    Rectangle {
                        id: dispOffBtn
                        width: 130
                        height: 40
                        color: dispOffMouse.pressed ? "#1E88E5" : (dispOffMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: dispOffMouse.pressed ? "#66D9FF" : "#3F74A3"
                        border.width: 1
                        radius: 3

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: root.tr("Display Off", "डिस्प्ले बंद")
                            color: "#FFFFFF"
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                            scale: dispOffMouse.pressed ? 0.94 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: dispOffMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[Settings] Display Off clicked -> Activating Screensaver")
                                systemController.setDisplayOff(true)
                            }
                        }
                    }

                    // 2. Menu
                    Rectangle {
                        id: menuBtn
                        width: 90
                        height: 40
                        color: root.menuOpen ? "#1E88E5" : (menuMouse.pressed ? "#1E88E5" : (menuMouse.containsMouse ? "#3A6C9B" : "#2E5B84"))
                        border.color: root.menuOpen ? "#66D9FF" : (menuMouse.pressed ? "#66D9FF" : "#3F74A3")
                        border.width: 1
                        radius: 3

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: root.tr("Menu", "मेनू")
                            color: "#FFFFFF"
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                            scale: menuMouse.pressed ? 0.94 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: menuMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.menuOpen = !root.menuOpen
                                console.log("[Settings] Menu clicked -> menuOpen:", root.menuOpen)
                            }
                        }
                    }

                    // 3. Back Arrow Button (⮌)
                    Rectangle {
                        width: 70
                        height: 40
                        color: backMouse.pressed ? "#1E88E5" : (backMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: backMouse.pressed ? "#66D9FF" : "#3F74A3"
                        border.width: 1
                        radius: 3

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Image {
                            anchors.centerIn: parent
                            width: 30
                            height: 26
                            source: "qrc:/assets/ui/icon_back.png"
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            scale: backMouse.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.menuOpen = false
                                root.backToHomeClicked()
                            }
                        }
                    }
                }
            }
        }

        // ====================================================
        // 2. SETTINGS ITEMS GRID (Dynamically ordered by systemController.settingsIconsOrder)
        // ====================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#05070B"

            Grid {
                anchors.fill: parent
                anchors.leftMargin: 60
                anchors.topMargin: 40
                columns: 4
                rowSpacing: 48
                columnSpacing: 60

                Repeater {
                    model: systemController.settingsIconsOrder

                    Loader {
                        sourceComponent: {
                            switch (modelData) {
                                case "sound": return soundCardComponent;
                                case "device_connection": return devConnCardComponent;
                                case "display": return dispCardComponent;
                                case "button": return btnCardComponent;
                                case "general": return genCardComponent;
                                default: return null;
                            }
                        }
                    }
                }
            }
        }
    }

    // ====================================================
    // 3. MENU DROPDOWN (Matching Image 1: Rearrange icons + Manual)
    // ====================================================
    MouseArea {
        id: menuShield
        anchors.fill: parent
        z: 90
        visible: root.menuOpen
        onClicked: root.menuOpen = false
    }

    Rectangle {
        id: menuDropdown
        z: 100
        visible: root.menuOpen
        x: root.width - width - 98 // Aligned under the Menu button area
        y: 60 // Directly beneath the 56px header bar
        width: 230
        height: 98
        color: "#EDF2F7"
        border.color: "#A4B8CD"
        border.width: 1
        radius: 4

        // Soft Drop Shadow Glow
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: 6
            color: Qt.rgba(0, 0, 0, 0.25)
            z: -1
        }

        Column {
            anchors.fill: parent

            // 1. Rearrange icons
            Rectangle {
                width: parent.width
                height: 48
                radius: 4
                color: optRearrangeMouse.pressed ? "#D0E0F0" : (optRearrangeMouse.containsMouse ? "#DEEAF6" : "transparent")

                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.tr("Rearrange icons", "आइकन पुनर्व्यवस्थित करें")
                    color: "#101824"
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                }

                MouseArea {
                    id: optRearrangeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.menuOpen = false
                        console.log("[Settings] Rearrange icons clicked -> Navigating to Rearrange Screen")
                        root.rearrangeIconsClicked()
                    }
                }
            }

            // Divider Line
            Rectangle {
                width: parent.width
                height: 1
                color: "#C8D6E5"
            }

            // 2. Manual
            Rectangle {
                width: parent.width
                height: 48
                radius: 4
                color: optManualMouse.pressed ? "#D0E0F0" : (optManualMouse.containsMouse ? "#DEEAF6" : "transparent")

                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.tr("Manual", "मैनुअल")
                    color: "#101824"
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                }

                MouseArea {
                    id: optManualMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.menuOpen = false
                        console.log("[Settings] Manual clicked -> Navigating to Manual QR Screen")
                        root.manualClicked()
                    }
                }
            }
        }
    }

    // ====================================================
    // 4. ICON COMPONENTS (Sound, Device Conn, Display, Button, General)
    // ====================================================

    // 1. Sound Card Component
    Component {
        id: soundCardComponent

        Rectangle {
            width: 220
            height: 160
            radius: 12
            color: soundMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.25) : (soundMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.08) : "transparent")
            border.color: soundMouse.pressed ? "#66D2FF" : "transparent"
            border.width: 1.5

            Behavior on color { ColorAnimation { duration: 120 } }

            Column {
                anchors.centerIn: parent
                spacing: 16
                scale: soundMouse.pressed ? 0.95 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                }

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 58
                    height: 56

                    // Soft Light Blue Pressed Glow
                    Rectangle {
                        anchors.centerIn: parent
                        width: 84
                        height: 84
                        radius: 42
                        color: "#4DC3FF"
                        opacity: soundMouse.pressed ? 0.55 : 0.0
                        scale: soundMouse.pressed ? 1.15 : 0.6
                        border.color: "#99E5FF"
                        border.width: soundMouse.pressed ? 1.5 : 0

                        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                    }

                    Image {
                        anchors.fill: parent
                        source: "qrc:/assets/apps/icon_sound.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.tr("Sound", "ध्वनि")
                    color: soundMouse.pressed ? "#70D6FF" : "#FFFFFF"
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                }
            }

            MouseArea {
                id: soundMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    console.log("[Settings] Sound selected -> Opening Sound settings")
                    root.soundClicked()
                }
            }
        }
    }

    // 2. Device Connection Card Component
    Component {
        id: devConnCardComponent

        Rectangle {
            width: 220
            height: 160
            radius: 12
            color: devConnMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.25) : (devConnMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.08) : "transparent")
            border.color: devConnMouse.pressed ? "#66D2FF" : "transparent"
            border.width: 1.5

            Behavior on color { ColorAnimation { duration: 120 } }

            Column {
                anchors.centerIn: parent
                spacing: 16
                scale: devConnMouse.pressed ? 0.95 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                }

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 76
                    height: 58

                    // Soft Light Blue Pressed Glow
                    Rectangle {
                        anchors.centerIn: parent
                        width: 96
                        height: 84
                        radius: 42
                        color: "#4DC3FF"
                        opacity: devConnMouse.pressed ? 0.55 : 0.0
                        scale: devConnMouse.pressed ? 1.15 : 0.6
                        border.color: "#99E5FF"
                        border.width: devConnMouse.pressed ? 1.5 : 0

                        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                    }

                    Image {
                        anchors.fill: parent
                        source: "qrc:/assets/bluetooth/icon_device_conn.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: root.tr("Device\nconnection", "डिवाइस\nकनेक्शन")
                    color: devConnMouse.pressed ? "#70D6FF" : "#FFFFFF"
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                }
            }

            MouseArea {
                id: devConnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    console.log("[Settings] Device Connection selected")
                    root.deviceConnectionClicked()
                }
            }
        }
    }

    // 3. Display Card Component
    Component {
        id: dispCardComponent

        Rectangle {
            width: 220
            height: 160
            radius: 12
            color: dispMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.25) : (dispMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.08) : "transparent")
            border.color: dispMouse.pressed ? "#66D2FF" : "transparent"
            border.width: 1.5

            Behavior on color { ColorAnimation { duration: 120 } }

            Column {
                anchors.centerIn: parent
                spacing: 16
                scale: dispMouse.pressed ? 0.95 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                }

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 66
                    height: 58

                    // Soft Light Blue Pressed Glow
                    Rectangle {
                        anchors.centerIn: parent
                        width: 88
                        height: 84
                        radius: 42
                        color: "#4DC3FF"
                        opacity: dispMouse.pressed ? 0.55 : 0.0
                        scale: dispMouse.pressed ? 1.15 : 0.6
                        border.color: "#99E5FF"
                        border.width: dispMouse.pressed ? 1.5 : 0

                        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                    }

                    Image {
                        anchors.fill: parent
                        source: "qrc:/assets/ui/icon_display.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.tr("Display", "डिस्प्ले")
                    color: dispMouse.pressed ? "#70D6FF" : "#FFFFFF"
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                }
            }

            MouseArea {
                id: dispMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    console.log("[Settings] Display selected")
                    root.displayClicked()
                }
            }
        }
    }

    // 4. Button Card Component
    Component {
        id: btnCardComponent

        Rectangle {
            width: 220
            height: 160
            radius: 12
            color: btnMouseArea.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.25) : (btnMouseArea.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.08) : "transparent")
            border.color: btnMouseArea.pressed ? "#66D2FF" : "transparent"
            border.width: 1.5

            Behavior on color { ColorAnimation { duration: 120 } }

            Column {
                anchors.centerIn: parent
                spacing: 16
                scale: btnMouseArea.pressed ? 0.95 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                }

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 58
                    height: 58

                    // Soft Light Blue Pressed Glow
                    Rectangle {
                        anchors.centerIn: parent
                        width: 84
                        height: 84
                        radius: 42
                        color: "#4DC3FF"
                        opacity: btnMouseArea.pressed ? 0.55 : 0.0
                        scale: btnMouseArea.pressed ? 1.15 : 0.6
                        border.color: "#99E5FF"
                        border.width: btnMouseArea.pressed ? 1.5 : 0

                        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                    }

                    Image {
                        anchors.fill: parent
                        source: "qrc:/assets/ui/icon_button.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.tr("Button", "बटन")
                    color: btnMouseArea.pressed ? "#70D6FF" : "#FFFFFF"
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                }
            }

            MouseArea {
                id: btnMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    console.log("[Settings] Button selected -> Sliding into Button settings")
                    root.buttonClicked()
                }
            }
        }
    }

    // 5. General Card Component
    Component {
        id: genCardComponent

        Rectangle {
            width: 220
            height: 160
            radius: 12
            color: genMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.25) : (genMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.08) : "transparent")
            border.color: genMouse.pressed ? "#66D2FF" : "transparent"
            border.width: 1.5

            Behavior on color { ColorAnimation { duration: 120 } }

            Column {
                anchors.centerIn: parent
                spacing: 16
                scale: genMouse.pressed ? 0.95 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                }

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 66
                    height: 58

                    // Soft Light Blue Pressed Glow
                    Rectangle {
                        anchors.centerIn: parent
                        width: 88
                        height: 84
                        radius: 42
                        color: "#4DC3FF"
                        opacity: genMouse.pressed ? 0.55 : 0.0
                        scale: genMouse.pressed ? 1.15 : 0.6
                        border.color: "#99E5FF"
                        border.width: genMouse.pressed ? 1.5 : 0

                        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                    }

                    Image {
                        anchors.fill: parent
                        source: "qrc:/assets/ui/icon_general.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.tr("General", "सामान्य")
                    color: genMouse.pressed ? "#70D6FF" : "#FFFFFF"
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                }
            }

            MouseArea {
                id: genMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    console.log("[Settings] General selected -> Sliding into General settings")
                    root.generalClicked()
                }
            }
        }
    }
}
