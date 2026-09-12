/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: BluetoothAudioScreen.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#0B1422"

    signal backClicked()
    signal switchDeviceClicked()

    property bool menuOpen: false

    // Genuine OEM Wallpaper for Bluetooth Audio Player - illuminated and vibrant
    Image {
        anchors.fill: parent
        source: systemController.currentScenicBlurBackground
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        opacity: 0.62
        z: 0
    }

    // Soft illumination gradient overlay
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.06, 0.12, 0.20, 0.35) }
            GradientStop { position: 0.5; color: Qt.rgba(0.04, 0.08, 0.15, 0.25) }
            GradientStop { position: 1.0; color: Qt.rgba(0.02, 0.05, 0.10, 0.50) }
        }
        z: 1
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        z: 10

        // ====================================================
        // 1. SUB-HEADER BAR ("Bluetooth Audio" | Device Switch | Menu | Back)
        // Matching RadioScreen.qml layout and reference photo media_1789229471260.png
        // ====================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            color: "#101622"
            z: 30

            // Hairline bottom divider
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1.5
                color: "#1E2736"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 16
                spacing: 12

                // Left: Bluetooth Audio Badge Icon + Title
                Row {
                    spacing: 12
                    Layout.alignment: Qt.AlignVCenter

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32
                        source: "qrc:/assets/media/icon_media_bluetooth.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Bluetooth Audio"
                        color: "#FFFFFF"
                        font.pixelSize: 24
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }
                }

                Item { Layout.fillWidth: true }

                // Right Action Buttons: [ 📱⇆📱 ]  [ Menu ]  [ ↩ ]
                Row {
                    spacing: 10
                    Layout.alignment: Qt.AlignVCenter

                    // 1. Device Switch Button: [ 📱⇆📱 ]
                    Rectangle {
                        width: 64
                        height: 40
                        color: switchMouse.pressed ? "#389BFF" : (switchMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: switchMouse.pressed ? "#80D8FF" : "#3F74A3"
                        border.width: 1
                        radius: 3

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Image {
                            anchors.centerIn: parent
                            width: 26
                            height: 26
                            source: "qrc:/assets/phone/icon_phone_device_switch.png"
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            scale: switchMouse.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                        }

                        MouseArea {
                            id: switchMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[BluetoothAudio] Device switch clicked -> Opening Change connection modal")
                                root.menuOpen = false
                                changeConnScrim.visible = true
                            }
                        }
                    }

                    // 2. Menu Button: [ Menu ]
                    Rectangle {
                        width: 90
                        height: 40
                        color: (root.menuOpen || menuMouse.pressed) ? "#389BFF" : (menuMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: (root.menuOpen || menuMouse.pressed) ? "#80D8FF" : "#3F74A3"
                        border.width: 1
                        radius: 3

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Menu"
                            color: "#FFFFFF"
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                            scale: menuMouse.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                        }

                        MouseArea {
                            id: menuMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.menuOpen = !root.menuOpen
                            }
                        }
                    }

                    // 3. Back Button: [ ↩ ]
                    Rectangle {
                        width: 70
                        height: 40
                        color: backMouse.pressed ? "#389BFF" : (backMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: backMouse.pressed ? "#80D8FF" : "#3F74A3"
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
                            Behavior on scale { NumberAnimation { duration: 80 } }
                        }

                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[BluetoothAudio] Back clicked")
                                root.menuOpen = false
                                root.backClicked()
                            }
                        }
                    }
                }
            }
        }

        // ====================================================
        // 2. MAIN PLAYER BODY (Left: Track Details & Controls | Right: Album Art Photo Box)
        // Matching Reference Photo media_1789229471260.png
        // ====================================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 48
                anchors.rightMargin: 48
                anchors.topMargin: 16
                anchors.bottomMargin: 16
                spacing: 40

                // ----------------------------------------------------
                // LEFT COLUMN: Track Info, Playback Controls, & Helper Prompt
                // ----------------------------------------------------
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 6

                    // Connected Device Name
                    Text {
                        text: systemController.activeHandsFreeDeviceName || systemController.detectedBluetoothName || (systemController.bluetoothConnected ? "Connected Phone" : "No Device Connected")
                        color: "#CAD8E6"
                        font.pixelSize: 22
                        font.weight: Font.Medium
                        font.family: "Roboto"
                    }

                    Item { height: 4 }

                    // Track Title
                    Text {
                        Layout.fillWidth: true
                        text: (systemController.bluetoothTrackTitle.length > 0) ? systemController.bluetoothTrackTitle : (systemController.bluetoothConnected ? "No Media Playing" : "Bluetooth Audio")
                        color: "#FFFFFF"
                        font.pixelSize: 36
                        font.weight: Font.Bold
                        font.family: "Roboto"
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    // Artist Name
                    Text {
                        Layout.fillWidth: true
                        text: (systemController.bluetoothTrackArtist.length > 0) ? systemController.bluetoothTrackArtist : (systemController.bluetoothConnected ? "Press Play on phone or tap ▶ to start" : "Connect your phone via Bluetooth")
                        color: "#CAD8E6"
                        font.pixelSize: 22
                        font.weight: Font.Medium
                        font.family: "Roboto"
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    // Album Name
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24

                        Text {
                            anchors.fill: parent
                            text: systemController.bluetoothTrackAlbum
                            color: "#95A8BC"
                            font.pixelSize: 20
                            font.weight: Font.Normal
                            font.family: "Roboto"
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            opacity: (text.length > 0) ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }

                    Item { height: 26 }

                    // Playback Controls Row: [ |◀◀ ]   [ ▶ / ❚❚ ]   [ ▶▶| ]
                    // USER REQUIREMENT: NO circle borders, NO background circles, clean white icons, zero layout jump
                    Row {
                        spacing: 48
                        Layout.alignment: Qt.AlignLeft

                        // 1. Previous Track Button [ |◀◀ ]
                        Item {
                            width: 64
                            height: 52

                            Text {
                                anchors.centerIn: parent
                                text: "|◀◀"
                                color: prevMouse.pressed ? "#70D6FF" : (prevMouse.containsMouse ? "#B0E2FF" : "#FFFFFF")
                                font.pixelSize: 28
                                font.weight: Font.Bold
                                Behavior on color { ColorAnimation { duration: 80 } }
                            }

                            MouseArea {
                                id: prevMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                preventStealing: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    console.log("[BluetoothAudio] Prev track clicked")
                                    systemController.bluetoothMediaPrevious()
                                }
                            }
                        }

                        // 2. Play / Pause Button [ ▶ / ❚❚ ]
                        Item {
                            width: 64
                            height: 52

                            Text {
                                anchors.centerIn: parent
                                text: (systemController.bluetoothPlaybackStatus === "playing") ? "❚❚" : "▶"
                                color: playMouse.pressed ? "#70D6FF" : (playMouse.containsMouse ? "#B0E2FF" : "#FFFFFF")
                                font.pixelSize: 34
                                font.weight: Font.Bold
                                Behavior on color { ColorAnimation { duration: 80 } }
                            }

                            MouseArea {
                                id: playMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                preventStealing: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    console.log("[BluetoothAudio] Play/Pause clicked -> current:", systemController.bluetoothPlaybackStatus)
                                    systemController.toggleBluetoothMediaPlayback()
                                }
                            }
                        }

                        // 3. Next Track Button [ ▶▶| ]
                        Item {
                            width: 64
                            height: 52

                            Text {
                                anchors.centerIn: parent
                                text: "▶▶|"
                                color: nextMouse.pressed ? "#70D6FF" : (nextMouse.containsMouse ? "#B0E2FF" : "#FFFFFF")
                                font.pixelSize: 28
                                font.weight: Font.Bold
                                Behavior on color { ColorAnimation { duration: 80 } }
                            }

                            MouseArea {
                                id: nextMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                preventStealing: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    console.log("[BluetoothAudio] Next track clicked")
                                    systemController.bluetoothMediaNext()
                                }
                            }
                        }
                    }

                    Item { height: 18 }

                    // OEM Helper Prompt below controls (Fixed container so layout never jumps/shifts)
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "The music app may have to be started from the mobile device."
                            color: "#CAD8E6"
                            font.pixelSize: 18
                            font.weight: Font.Normal
                            font.family: "Roboto"
                            opacity: (systemController.bluetoothTrackTitle.length === 0 || systemController.bluetoothPlaybackStatus !== "playing") ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 250 } }
                        }
                    }
                }

                // ----------------------------------------------------
                // RIGHT COLUMN: Song Artwork Photo Box (Matching Reference Photo)
                // ----------------------------------------------------
                Item {
                    Layout.preferredWidth: 300
                    Layout.preferredHeight: 300
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: "#080F1B"
                        border.color: "#2C3E55"
                        border.width: 1.5
                        clip: true

                        // Scenic Landscape Artwork Graphic (Randomized scenic photo matching genuine OEM UI)
                        Image {
                            id: fallbackArtwork
                            anchors.fill: parent
                            source: systemController.currentScenicArtwork
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            mipmap: true
                            visible: !albumArtImg.visible || albumArtImg.status !== Image.Ready
                        }

                        // Live Fetched Album Cover Art (Fetched via Song Title & Artist)
                        Image {
                            id: albumArtImg
                            anchors.fill: parent
                            source: systemController.bluetoothAlbumArtUrl
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            mipmap: true
                            cache: false
                            visible: (source != "" && status === Image.Ready)
                        }

                        // Subtle inner gloss border overlay
                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            color: "transparent"
                            border.color: "#3F5876"
                            border.width: 1
                            opacity: 0.35
                        }
                    }
                }
            }
        }

        // ====================================================
        // 3. BOTTOM SLEEK LIVE PROGRESS BAR
        // Matching Genuine IVI OEM Design
        // ====================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            color: "#0A101C"

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 1
                color: "#162030"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 16

                // Elapsed time (e.g. "0:00" or "0:41")
                Text {
                    text: systemController.bluetoothTrackPositionStr
                    color: "#A0B2C6"
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                }

                // Interactive Progress Bar Track
                Item {
                    id: progressTrack
                    Layout.fillWidth: true
                    height: 16

                    // Background Track
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 4
                        radius: 2
                        color: "#1C2838"

                        // Active Blue Fill
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.max(0, Math.min(parent.width, parent.width * (systemController.bluetoothTrackPositionMs / Math.max(1, systemController.bluetoothTrackDurationMs))))
                            radius: 2
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#0072E5" }
                                GradientStop { position: 1.0; color: "#38B6FF" }
                            }
                        }
                    }

                    // Seek gesture area
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) {
                            if (systemController.bluetoothTrackDurationMs > 0) {
                                var ratio = Math.max(0.0, Math.min(1.0, mouse.x / progressTrack.width))
                                var seekMs = Math.round(ratio * systemController.bluetoothTrackDurationMs)
                                systemController.seekBluetoothTrackPosition(seekMs)
                            }
                        }
                    }
                }

                // Total Duration (e.g. "5:20")
                Text {
                    text: (systemController.bluetoothTrackDurationMs > 0) ? systemController.bluetoothTrackDurationStr : ""
                    color: "#A0B2C6"
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                }
            }
        }
    }

    // Dropdown menu for [ Menu ] button
    Rectangle {
        id: btMenuPopup
        visible: root.menuOpen
        width: 220
        height: 120
        radius: 6
        color: "#121C2B"
        border.color: "#2C4362"
        border.width: 1
        anchors.top: parent.top
        anchors.topMargin: 54
        anchors.right: parent.right
        anchors.rightMargin: 80
        z: 99

        Column {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 4

            Rectangle {
                width: parent.width
                height: 50
                radius: 4
                color: item1Mouse.pressed ? "#234166" : (item1Mouse.containsMouse ? "#182C45" : "transparent")

                Text {
                    anchors.centerIn: parent
                    text: "Change connection"
                    color: "#FFFFFF"
                    font.pixelSize: 16
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: item1Mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.menuOpen = false
                        changeConnScrim.visible = true
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 50
                radius: 4
                color: item2Mouse.pressed ? "#234166" : (item2Mouse.containsMouse ? "#182C45" : "transparent")

                Text {
                    anchors.centerIn: parent
                    text: "Sound Settings"
                    color: "#FFFFFF"
                    font.pixelSize: 16
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: item2Mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.menuOpen = false
                        systemController.navigateTo("sound_settings")
                    }
                }
            }
        }
    }

    // ====================================================
    // CHANGE CONNECTION MODAL WINDOW (Matching PhoneScreen)
    // ====================================================
    Rectangle {
        id: changeConnScrim
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.65)
        visible: false
        z: 95

        MouseArea {
            anchors.fill: parent
            onClicked: changeConnScrim.visible = false
        }

        Rectangle {
            id: changeConnDialog
            anchors.centerIn: parent
            width: 760
            height: 440
            color: "#131C2A"
            border.color: "#3B6994"
            border.width: 1.5
            radius: 6
            clip: true

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            // Top Header Bar: "Change connection"
            Rectangle {
                id: modalHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 54
                color: "#2C5177"

                Text {
                    anchors.centerIn: parent
                    text: "Change connection"
                    color: "#FFFFFF"
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                }
            }

            // Subtitle: "Press [Settings] to add mobile devices."
            Text {
                id: modalSubtitle
                anchors.top: modalHeader.bottom
                anchors.topMargin: 20
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Press [Settings] to add mobile devices."
                color: "#B4C8DE"
                font.pixelSize: 20
                font.weight: Font.Normal
                font.family: "Roboto"
            }

            // Paired Mobile Devices List
            ListView {
                id: modalDeviceList
                anchors.top: modalSubtitle.bottom
                anchors.topMargin: 18
                anchors.left: parent.left
                anchors.leftMargin: 36
                anchors.right: parent.right
                anchors.rightMargin: 36
                anchors.bottom: modalBtnRow.top
                anchors.bottomMargin: 16
                clip: true
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds

                model: systemController.bluetoothDeviceList

                delegate: Rectangle {
                    id: deviceRowDelegate
                    width: modalDeviceList.width
                    height: 54
                    radius: 4
                    color: itemRowMouse.pressed ? "#223E62" : (itemRowMouse.containsMouse ? "#1A2E46" : "transparent")

                    Behavior on color { ColorAnimation { duration: 90 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            color: modelData.connected ? "#7CE8FF" : "#FFFFFF"
                            font.pixelSize: 24
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        // Connected indicator badge
                        Text {
                            text: modelData.connected ? "Connected" : ""
                            color: "#7CE8FF"
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                            visible: modelData.connected
                        }
                    }

                    MouseArea {
                        id: itemRowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            console.log("[Change Connection] Selected device:", modelData.name)
                            systemController.connectDevice(index)
                            changeConnScrim.visible = false
                        }
                    }
                }
            }

            // Bottom Action Buttons: [ Settings ]  [ Cancel ]
            Row {
                id: modalBtnRow
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 20
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.right: parent.right
                anchors.rightMargin: 20
                spacing: 18

                // Settings Button
                Rectangle {
                    width: (parent.width - 18) / 2
                    height: 52
                    radius: 4
                    color: settingsBtnMouse.pressed ? "#1E4166" : (settingsBtnMouse.containsMouse ? "#3D6F9F" : "#2E557F")
                    border.color: settingsBtnMouse.pressed ? "#66D9FF" : "#4A7CA9"
                    border.width: 1.5

                    Behavior on color { ColorAnimation { duration: 90 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Settings"
                        color: "#FFFFFF"
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }

                    MouseArea {
                        id: settingsBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            console.log("[Change Connection] Settings clicked -> Opening Bluetooth connections")
                            changeConnScrim.visible = false
                            systemController.navigateTo("bluetooth_connections")
                        }
                    }
                }

                // Cancel Button
                Rectangle {
                    width: (parent.width - 18) / 2
                    height: 52
                    radius: 4
                    color: cancelBtnMouse.pressed ? "#1E4166" : (cancelBtnMouse.containsMouse ? "#3D6F9F" : "#2E557F")
                    border.color: cancelBtnMouse.pressed ? "#66D9FF" : "#4A7CA9"
                    border.width: 1.5

                    Behavior on color { ColorAnimation { duration: 90 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: "#FFFFFF"
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }

                    MouseArea {
                        id: cancelBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            console.log("[Change Connection] Cancel clicked")
                            changeConnScrim.visible = false
                        }
                    }
                }
            }
        }
    }
}
