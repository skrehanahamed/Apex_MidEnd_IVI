/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: RadioScreen.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#070C14"

    signal backClicked()
    signal manualClicked()
    signal mediaSelectClicked()
    signal soundSettingsClicked()
    signal radioNoiseClicked()

    property bool menuOpen: false
    property bool infoActive: true
    property bool isScanning: false
    property bool showStationListModal: false
    property bool showDeleteFavoritesModal: false

    property string displayFrequency: systemController.radioStation
    property bool isHoldSeeking: false
    property real currentFreqValue: parseFloat(systemController.radioStation)
    property real targetFreqValue: currentFreqValue
    property int seekDir: 1

    Connections {
        target: systemController
        function onRadioStationChanged() {
            if (!root.isHoldSeeking) {
                root.displayFrequency = systemController.radioStation
                root.currentFreqValue = parseFloat(systemController.radioStation)
            }
        }
    }

    SequentialAnimation {
        id: freqRollAnim
        NumberAnimation {
            target: freqText
            property: "scale"
            to: 1.05
            duration: 18
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: freqText
            property: "scale"
            to: 1.0
            duration: 20
            easing.type: Easing.InQuad
        }
    }

    SequentialAnimation {
        id: lockInAnim
        NumberAnimation {
            target: freqText
            property: "scale"
            to: 1.15
            duration: 120
            easing.type: Easing.OutBack
        }
        NumberAnimation {
            target: freqText
            property: "scale"
            to: 1.0
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: holdSeekStepTimer
        interval: (systemController.radioBand === "FM") ? 38 : 50
        repeat: true
        running: false
        onTriggered: {
            if (systemController.radioBand === "FM") {
                if (root.seekDir > 0) {
                    root.currentFreqValue = Math.round((root.currentFreqValue + 0.1) * 10) / 10
                    if (root.currentFreqValue > 108.0) root.currentFreqValue = 87.5
                } else {
                    root.currentFreqValue = Math.round((root.currentFreqValue - 0.1) * 10) / 10
                    if (root.currentFreqValue < 87.5) root.currentFreqValue = 108.0
                }
                root.displayFrequency = root.currentFreqValue.toFixed(1)
            } else {
                if (root.seekDir > 0) {
                    root.currentFreqValue += 9
                    if (root.currentFreqValue > 1602) root.currentFreqValue = 531
                } else {
                    root.currentFreqValue -= 9
                    if (root.currentFreqValue < 531) root.currentFreqValue = 1602
                }
                root.displayFrequency = Math.round(root.currentFreqValue).toString()
            }

            freqRollAnim.restart()

            var diff = Math.abs(root.currentFreqValue - root.targetFreqValue)
            var reached = (systemController.radioBand === "FM") ? (diff < 0.05) : (diff < 5)

            if (reached) {
                holdSeekStepTimer.stop()
                systemController.tuneToClosestStation(root.targetFreqValue)
                lockInAnim.restart()
                if (seekUpMouse.pressed || seekDownMouse.pressed) {
                    continueHoldTimer.restart()
                } else {
                    root.isHoldSeeking = false
                }
            }
        }
    }

    Timer {
        id: continueHoldTimer
        interval: 450
        repeat: false
        onTriggered: {
            if (seekUpMouse.pressed || seekDownMouse.pressed) {
                root.isHoldSeeking = true
                root.currentFreqValue = parseFloat(systemController.radioStation)
                root.targetFreqValue = systemController.getNextStationFrequency(root.seekDir)
                holdSeekStepTimer.start()
            }
        }
    }

    function resetToDefault() {
        menuOpen = false
        isScanning = false
        scanTimer.stop()
        isHoldSeeking = false
        holdSeekStepTimer.stop()
        continueHoldTimer.stop()
        showStationListModal = false
        showDeleteFavoritesModal = false
    }

    function toggleScanning() {
        if (isScanning) {
            isScanning = false
            scanTimer.stop()
        } else {
            isScanning = true
            scanTimer.restart()
        }
    }

    Timer {
        id: scanTimer
        interval: 5000
        repeat: true
        running: root.isScanning
        onTriggered: {
            console.log("[Apex IVI Radio] Scan timer triggered -> Tuning to next station")
            systemController.tuneFrequency(+1)
        }
    }

    // Genuine OEM Wallpaper for FM/AM Radio Player - flows seamlessly across entire screen
    Image {
        anchors.fill: parent
        source: "qrc:/assets/media/media_player_bg.png"
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        opacity: 0.42
        z: 0
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        z: 10

        // ====================================================
        // 1. SUB-HEADER BAR (Radio + FM/AM + Info + Menu + Back)
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

                // Left: Radio Icon + Title
                Row {
                    spacing: 12
                    Layout.alignment: Qt.AlignVCenter

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32
                        source: (systemController.selectedMediaSource === "bluetooth")
                                ? "qrc:/assets/media/icon_media_bluetooth.png"
                                : ((systemController.selectedMediaSource === "usb")
                                   ? "qrc:/assets/media/icon_media_usb.png"
                                   : "qrc:/assets/apps/icon_all_radio.png")
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (systemController.selectedMediaSource === "bluetooth")
                              ? "Bluetooth Audio"
                              : ((systemController.selectedMediaSource === "usb")
                                 ? "USB Music"
                                 : "Radio")
                        color: "#FFFFFF"
                        font.pixelSize: 24
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }
                }

                Item { Layout.fillWidth: true }

                // Right Action Buttons (FM/AM | Info | Menu | Back)
                Row {
                    spacing: 10
                    Layout.alignment: Qt.AlignVCenter

                    // 1. [FM/AM] Band Switch Button (Visible on FM/AM)
                    Rectangle {
                        width: 100
                        height: 40
                        visible: (systemController.selectedMediaSource !== "bluetooth" && systemController.selectedMediaSource !== "usb")
                        color: bandMouse.pressed ? "#389BFF" : (bandMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: bandMouse.pressed ? "#80D8FF" : "#3F74A3"
                        border.width: 1
                        radius: 3

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 1

                            Text {
                                text: "FM"
                                color: (systemController.radioBand === "FM") ? "#00E5FF" : "#CAD8E6"
                                font.pixelSize: 18
                                font.bold: true
                                font.family: "Roboto"
                            }

                            Text {
                                text: "/"
                                color: "#8AA2BA"
                                font.pixelSize: 18
                                font.family: "Roboto"
                            }

                            Text {
                                text: "AM"
                                color: (systemController.radioBand === "AM") ? "#00E5FF" : "#CAD8E6"
                                font.pixelSize: 18
                                font.bold: true
                                font.family: "Roboto"
                            }
                        }

                        MouseArea {
                            id: bandMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.isScanning) root.toggleScanning()
                                systemController.toggleRadioBand()
                            }
                        }
                    }

                    // 1B. [Media] Switch Button (Visible on Bluetooth/USB)
                    Rectangle {
                        width: 90
                        height: 40
                        visible: (systemController.selectedMediaSource === "bluetooth" || systemController.selectedMediaSource === "usb")
                        color: mediaChangeMouse.pressed ? "#389BFF" : (mediaChangeMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: mediaChangeMouse.pressed ? "#80D8FF" : "#3F74A3"
                        border.width: 1
                        radius: 3

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Media"
                            color: "#FFFFFF"
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        MouseArea {
                            id: mediaChangeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.mediaSelectClicked()
                        }
                    }

                    // 2. [| Info] Button with cyan indicator bar (Matching Photo 1 & 2)
                    Rectangle {
                        width: 88
                        height: 40
                        color: infoMouse.pressed ? "#389BFF" : (infoMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: infoMouse.pressed ? "#80D8FF" : "#3F74A3"
                        border.width: 1
                        radius: 3

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            // Vertical indicator bar: Cyan when Info is active, grey when off
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3.5
                                height: 20
                                radius: 1.5
                                color: root.infoActive ? "#00E5FF" : "#5A6E82"
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Info"
                                color: "#FFFFFF"
                                font.pixelSize: 18
                                font.weight: Font.DemiBold
                                font.family: "Roboto"
                            }
                        }

                        MouseArea {
                            id: infoMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.infoActive = !root.infoActive
                        }
                    }

                    // 3. Menu Button
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
                        }

                        MouseArea {
                            id: menuMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.menuOpen = !root.menuOpen
                        }
                    }

                    // 4. Back Button (⮌)
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
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.menuOpen = false
                                if (root.isScanning) root.toggleScanning()
                                root.backClicked()
                            }
                        }
                    }
                }
            }
        }

        // ====================================================
        // 2. MAIN BODY (Sidebar List + Right Radio Tuner)
        // ====================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // ----------------------------------------------------
            // A. LEFT PRESET SIDEBAR LIST (Transparent over wallpaper)
            // ----------------------------------------------------
            Rectangle {
                Layout.preferredWidth: (systemController.selectedMediaSource !== "bluetooth" && systemController.selectedMediaSource !== "usb") ? 320 : 0
                visible: (systemController.selectedMediaSource !== "bluetooth" && systemController.selectedMediaSource !== "usb")
                Layout.fillHeight: true
                color: "transparent"

                ListView {
                    id: stationListView
                    anchors.fill: parent
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    model: systemController.stationList

                    delegate: Rectangle {
                        id: stationDelegate
                        width: stationListView.width
                        property bool isCurrent: (modelData.frequency === systemController.radioStation)
                        property bool isSameBand: (modelData.band === systemController.radioBand)

                        visible: isSameBand
                        height: isSameBand ? 64 : 0

                        // Active highlighted background (Matching Photo 1 & 2 mint/cyan box)
                        color: isCurrent
                               ? "#D4F0EB"
                               : (itemMouse.pressed ? Qt.rgba(1, 1, 1, 0.08) : (itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"))

                        Behavior on color { ColorAnimation { duration: 100 } }

                        // White right indicator bar when active (Matching Photo 1 & 2)
                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 5
                            height: parent.height - 12
                            radius: 2
                            color: "#FFFFFF"
                            visible: stationDelegate.isCurrent
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            Text {
                                text: modelData.band
                                color: stationDelegate.isCurrent ? "#0C332A" : "#38B6FF"
                                font.pixelSize: 26
                                font.weight: stationDelegate.isCurrent ? Font.Bold : Font.DemiBold
                                font.family: "Roboto"
                            }

                            Text {
                                text: modelData.frequency
                                color: stationDelegate.isCurrent ? "#0C332A" : "#FFFFFF"
                                font.pixelSize: 26
                                font.weight: stationDelegate.isCurrent ? Font.Bold : Font.DemiBold
                                font.family: "Roboto"
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.isScanning) root.toggleScanning()
                                systemController.selectStation(index)
                            }
                        }
                    }
                }

                // Vertical divider line between FM numbers sidebar and main player area (as in photo)
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1.5
                    color: Qt.rgba(1, 1, 1, 0.18)
                }
            }

            // ----------------------------------------------------
            // B. RIGHT MAIN TUNER & MEDIA DISPLAY (Transparent over wallpaper)
            // ----------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                color: "transparent"

                // Scanning active indicator banner
                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: 16
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 240
                    height: 38
                    radius: 19
                    color: "#0F2840"
                    border.color: "#389BFF"
                    border.width: 1.5
                    visible: root.isScanning
                    z: 50

                    Row {
                        anchors.centerIn: parent
                        spacing: 12

                        Text {
                            text: "Scanning " + systemController.radioBand + "..."
                            color: "#00E5FF"
                            font.pixelSize: 17
                            font.bold: true
                            font.family: "Roboto"
                        }

                        Rectangle {
                            width: 60
                            height: 26
                            radius: 13
                            color: "#C62828"
                            Text {
                                anchors.centerIn: parent
                                text: "Stop"
                                color: "#FFFFFF"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.toggleScanning()
                            }
                        }
                    }
                }

                // 1. Radio Tuner Display (FM / AM)
                Column {
                    anchors.centerIn: parent
                    spacing: 12
                    width: parent.width - 60
                    visible: (systemController.selectedMediaSource !== "bluetooth" && systemController.selectedMediaSource !== "usb")

                    // Band Label: "FM" (Matching Photo 1 & 2 cyan text above frequency)
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: systemController.radioBand
                        color: "#38B6FF"
                        font.pixelSize: 26
                        font.weight: Font.Bold
                        font.family: "Roboto"
                    }

                    // 2. Huge Frequency Display with Seek Arrows & Star
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 36
                        Layout.alignment: Qt.AlignVCenter

                        // Seek Down (◀)
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 54
                            height: 54
                            radius: 27
                            color: seekDownMouse.pressed ? "#2A4E72" : (seekDownMouse.containsMouse ? "#18324E" : "transparent")

                            Text {
                                anchors.centerIn: parent
                                text: "◀"
                                color: "#FFFFFF"
                                font.pixelSize: 28
                                scale: seekDownMouse.pressed ? 0.9 : 1.0
                                Behavior on scale { NumberAnimation { duration: 80 } }
                            }

                            MouseArea {
                                id: seekDownMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                pressAndHoldInterval: 1000
                                preventStealing: true

                                onPressAndHold: {
                                    if (root.isScanning) root.toggleScanning()
                                    root.isHoldSeeking = true
                                    root.seekDir = -1
                                    root.currentFreqValue = parseFloat(systemController.radioStation)
                                    root.targetFreqValue = systemController.getNextStationFrequency(-1)
                                    holdSeekStepTimer.start()
                                }

                                onReleased: {
                                    if (root.isHoldSeeking) {
                                        holdSeekStepTimer.stop()
                                        continueHoldTimer.stop()
                                        root.isHoldSeeking = false
                                        systemController.tuneToClosestStation(root.currentFreqValue)
                                    } else {
                                        if (root.isScanning) root.toggleScanning()
                                        systemController.tuneFrequency(-1)
                                    }
                                }
                            }
                        }

                        // Giant Frequency Numbers: "91.9" or "93.5" (with rolling step animation on hold)
                        Text {
                            id: freqText
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.displayFrequency
                            color: root.isHoldSeeking ? "#00E5FF" : "#FFFFFF"
                            font.pixelSize: 88
                            font.weight: Font.Bold
                            font.family: "Roboto"
                            scale: 1.0

                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        // Star Favorite Button (★) - Solid Blue when favorited (Photo 1 & 2)
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 54
                            height: 54
                            radius: 27
                            color: starMouse.pressed ? "#1E3B5C" : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "★"
                                color: systemController.isStationFavorited ? "#5DC2F8" : "#506882"
                                font.pixelSize: 40
                                scale: starMouse.pressed ? 0.9 : 1.0
                                Behavior on scale { NumberAnimation { duration: 80 } }
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            MouseArea {
                                id: starMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: systemController.toggleFavoriteStation()
                            }
                        }

                        // Seek Up (▶)
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 54
                            height: 54
                            radius: 27
                            color: seekUpMouse.pressed ? "#2A4E72" : (seekUpMouse.containsMouse ? "#18324E" : "transparent")

                            Text {
                                anchors.centerIn: parent
                                text: "▶"
                                color: "#FFFFFF"
                                font.pixelSize: 28
                                scale: seekUpMouse.pressed ? 0.9 : 1.0
                                Behavior on scale { NumberAnimation { duration: 80 } }
                            }

                            MouseArea {
                                id: seekUpMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                pressAndHoldInterval: 1000
                                preventStealing: true

                                onPressAndHold: {
                                    if (root.isScanning) root.toggleScanning()
                                    root.isHoldSeeking = true
                                    root.seekDir = +1
                                    root.currentFreqValue = parseFloat(systemController.radioStation)
                                    root.targetFreqValue = systemController.getNextStationFrequency(+1)
                                    holdSeekStepTimer.start()
                                }

                                onReleased: {
                                    if (root.isHoldSeeking) {
                                        holdSeekStepTimer.stop()
                                        continueHoldTimer.stop()
                                        root.isHoldSeeking = false
                                        systemController.tuneToClosestStation(root.currentFreqValue)
                                    } else {
                                        if (root.isScanning) root.toggleScanning()
                                        systemController.tuneFrequency(+1)
                                    }
                                }
                            }
                        }
                    }

                    // 3. Station Name / RDS program name (Matching Photo 1: "N - JAIL", Photo 2: "SURYAN")
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.isHoldSeeking ? ("Seeking " + root.displayFrequency + " MHz...") : systemController.currentStationName
                        color: root.isHoldSeeking ? "#38B6FF" : "#FFFFFF"
                        font.pixelSize: 26
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }

                    // 4. Detailed RDS Info (Song / Artist / Station info) - Controlled by Info Button
                    // Photo 1: "Radiocity91.9"
                    // Photo 2: "April May - Idhayam - Ilaiyaraaja,\nDeepan Chakravarthy, S.N.Suren"
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: systemController.currentRdsInfo
                        color: "#FFFFFF"
                        font.pixelSize: 21
                        font.weight: Font.Normal
                        font.family: "Roboto"
                        horizontalAlignment: Text.AlignHCenter
                        lineHeight: 1.25
                        visible: root.infoActive && systemController.currentRdsInfo !== ""
                    }
                }

                // 2. Bluetooth Audio / USB Music Display
                Column {
                    anchors.centerIn: parent
                    spacing: 18
                    width: parent.width - 80
                    visible: (systemController.selectedMediaSource === "bluetooth" || systemController.selectedMediaSource === "usb")

                    // Source Title Badge
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: (systemController.selectedMediaSource === "bluetooth") ? "Bluetooth Audio" : "USB Music"
                        color: "#38B6FF"
                        font.pixelSize: 26
                        font.weight: Font.Bold
                        font.family: "Roboto"
                    }

                    // Main Device / Media Title
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: (systemController.selectedMediaSource === "bluetooth")
                              ? (systemController.hasHandsFreeDevice ? systemController.activeHandsFreeDeviceName : "Connected Device")
                              : (systemController.usbConnected ? "USB Media Storage" : "No USB Device")
                        color: "#FFFFFF"
                        font.pixelSize: 42
                        font.weight: Font.Bold
                        font.family: "Roboto"
                    }

                    // Subtitle / Status
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: (systemController.selectedMediaSource === "bluetooth")
                              ? "Ready for audio playback"
                              : (systemController.usbConnected ? "Audio Files Ready" : "Insert USB drive to play media")
                        color: "#BAC8D8"
                        font.pixelSize: 20
                        font.family: "Roboto"
                    }

                    Item { width: 1; height: 10 }

                    // Seek & Play/Pause Controls
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 36

                        // Previous Track [ ⏮ ]
                        Rectangle {
                            width: 58
                            height: 58
                            radius: 29
                            color: prevMediaMouse.pressed ? "#2A4E72" : (prevMediaMouse.containsMouse ? "#18324E" : "#132235")
                            border.color: "#389BFF"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "⏮"
                                color: "#FFFFFF"
                                font.pixelSize: 24
                            }

                            MouseArea {
                                id: prevMediaMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: systemController.tuneFrequency(-1)
                            }
                        }

                        // Play/Pause Button
                        Rectangle {
                            width: 58
                            height: 58
                            radius: 29
                            color: playPauseBtMouse.pressed ? "#2A4E72" : (playPauseBtMouse.containsMouse ? "#18324E" : "#132235")
                            border.color: "#389BFF"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: systemController.isRadioPlaying ? "⏸" : "▶"
                                color: "#FFFFFF"
                                font.pixelSize: 26
                            }

                            MouseArea {
                                id: playPauseBtMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: systemController.toggleRadio()
                            }
                        }

                        // Next Track [ ⏭ ]
                        Rectangle {
                            width: 58
                            height: 58
                            radius: 29
                            color: nextMediaMouse.pressed ? "#2A4E72" : (nextMediaMouse.containsMouse ? "#18324E" : "#132235")
                            border.color: "#389BFF"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "⏭"
                                color: "#FFFFFF"
                                font.pixelSize: 24
                            }

                            MouseArea {
                                id: nextMediaMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: systemController.tuneFrequency(1)
                            }
                        }
                    }
                }
            }
        }
    }

    // ====================================================
    // 3. DROPDOWN MENU FOR "MENU" BUTTON (Matching Photos 3 & 4)
    // ====================================================
    MouseArea {
        anchors.fill: parent
        z: 90
        visible: root.menuOpen
        onClicked: root.menuOpen = false
    }

    Rectangle {
        id: radioMenuDropdown
        z: 100
        visible: root.menuOpen
        anchors.right: parent.right
        anchors.rightMargin: 80
        anchors.top: parent.top
        anchors.topMargin: 56
        width: 320
        height: 7 * 54
        color: "#F8FAFC"
        border.color: "#94A3B8"
        border.width: 1
        radius: 4

        // Soft drop shadow
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: 6
            color: Qt.rgba(0, 0, 0, 0.35)
            z: -1
        }

        Column {
            anchors.fill: parent

            // 1. Display Off (Photo 3)
            Rectangle {
                width: parent.width
                height: 53
                color: itemMouse1.pressed ? "#CBD5E1" : (itemMouse1.containsMouse ? "#E2E8F0" : "transparent")
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Display Off"
                    color: "#0F172A"
                    font.pixelSize: 21
                    font.weight: Font.Normal
                    font.family: "Roboto"
                }
                MouseArea {
                    id: itemMouse1
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.menuOpen = false
                        systemController.setDisplayOff(true)
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#CBD5E1" }

            // 2. Station list (Photo 3)
            Rectangle {
                width: parent.width
                height: 53
                color: itemMouse2.pressed ? "#CBD5E1" : (itemMouse2.containsMouse ? "#E2E8F0" : "transparent")
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Station list"
                    color: "#0F172A"
                    font.pixelSize: 21
                    font.weight: Font.Normal
                    font.family: "Roboto"
                }
                MouseArea {
                    id: itemMouse2
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.menuOpen = false
                        root.showStationListModal = true
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#CBD5E1" }

            // 3. Scan FM / Scan AM (Photo 3 & 4)
            Rectangle {
                width: parent.width
                height: 53
                color: itemMouse3.pressed ? "#CBD5E1" : (itemMouse3.containsMouse ? "#E2E8F0" : "transparent")
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.isScanning ? "Stop Scan" : ((systemController.radioBand === "FM") ? "Scan FM" : "Scan AM")
                    color: root.isScanning ? "#D32F2F" : "#0F172A"
                    font.pixelSize: 21
                    font.weight: Font.Normal
                    font.family: "Roboto"
                }
                MouseArea {
                    id: itemMouse3
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.menuOpen = false
                        root.toggleScanning()
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#CBD5E1" }

            // 4. Delete favourites (Photo 3 & 4)
            Rectangle {
                width: parent.width
                height: 53
                color: itemMouse4.pressed ? "#CBD5E1" : (itemMouse4.containsMouse ? "#E2E8F0" : "transparent")
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Delete favourites"
                    color: "#0F172A"
                    font.pixelSize: 21
                    font.weight: Font.Normal
                    font.family: "Roboto"
                }
                MouseArea {
                    id: itemMouse4
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.menuOpen = false
                        root.showDeleteFavoritesModal = true
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#CBD5E1" }

            // 5. Radio noise control (Photo 3 & 4)
            Rectangle {
                width: parent.width
                height: 53
                color: itemMouse5.pressed ? "#CBD5E1" : (itemMouse5.containsMouse ? "#E2E8F0" : "transparent")
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Radio noise control"
                    color: "#0F172A"
                    font.pixelSize: 21
                    font.weight: Font.Normal
                    font.family: "Roboto"
                }
                MouseArea {
                    id: itemMouse5
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.menuOpen = false
                        root.radioNoiseClicked()
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#CBD5E1" }

            // 6. Sound settings (Photo 4)
            Rectangle {
                width: parent.width
                height: 53
                color: itemMouse6.pressed ? "#CBD5E1" : (itemMouse6.containsMouse ? "#E2E8F0" : "transparent")
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Sound settings"
                    color: "#0F172A"
                    font.pixelSize: 21
                    font.weight: Font.Normal
                    font.family: "Roboto"
                }
                MouseArea {
                    id: itemMouse6
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.menuOpen = false
                        root.soundSettingsClicked()
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#CBD5E1" }

            // 7. Manual (Photo 4)
            Rectangle {
                width: parent.width
                height: 53
                color: itemMouse7.pressed ? "#CBD5E1" : (itemMouse7.containsMouse ? "#E2E8F0" : "transparent")
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Manual"
                    color: "#0F172A"
                    font.pixelSize: 21
                    font.weight: Font.Normal
                    font.family: "Roboto"
                }
                MouseArea {
                    id: itemMouse7
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.menuOpen = false
                        root.manualClicked()
                    }
                }
            }
        }
    }

    // ====================================================
    // MODAL 1: STATION LIST (Full band station browser)
    // ====================================================
    Rectangle {
        id: stationListModal
        anchors.fill: parent
        z: 110
        visible: root.showStationListModal
        color: Qt.rgba(0, 0, 0, 0.75)

        MouseArea { anchors.fill: parent } // Prevent clicks through

        Rectangle {
            anchors.centerIn: parent
            width: 720
            height: 480
            radius: 8
            color: "#0F1724"
            border.color: "#253A52"
            border.width: 1.5

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // Modal Header
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Station List (" + systemController.radioBand + ")"
                        color: "#FFFFFF"
                        font.pixelSize: 24
                        font.bold: true
                        font.family: "Roboto"
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: closeListMouse.pressed ? "#389BFF" : "#1A283C"
                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: "#FFFFFF"
                            font.pixelSize: 18
                            font.bold: true
                        }
                        MouseArea {
                            id: closeListMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showStationListModal = false
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#253A52" }

                // List of stations
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: systemController.stationList

                    delegate: Rectangle {
                        width: parent.width
                        property bool isSameBand: (modelData.band === systemController.radioBand)
                        property bool isCurrent: (modelData.frequency === systemController.radioStation)
                        visible: isSameBand
                        height: isSameBand ? 60 : 0
                        color: isCurrent ? "#1E3B5C" : (rowMouse.containsMouse ? "#142438" : "transparent")
                        radius: 4

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 16

                            Row {
                                spacing: 8
                                Layout.preferredWidth: 140

                                Text {
                                    text: modelData.band
                                    color: "#38B6FF"
                                    font.pixelSize: 22
                                    font.bold: true
                                }

                                Text {
                                    text: modelData.frequency
                                    color: isCurrent ? "#00E5FF" : "#FFFFFF"
                                    font.pixelSize: 22
                                    font.bold: true
                                }
                            }

                            Text {
                                text: modelData.name
                                color: "#FFFFFF"
                                font.pixelSize: 20
                                font.weight: Font.DemiBold
                                Layout.preferredWidth: 200
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.rdsInfo ? modelData.rdsInfo.replace("\n", " ") : ""
                                color: "#94A3B8"
                                font.pixelSize: 16
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.isFavorite ? "★" : "☆"
                                color: modelData.isFavorite ? "#2979FF" : "#64748B"
                                font.pixelSize: 26
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                systemController.selectStation(index)
                                root.showStationListModal = false
                            }
                        }
                    }
                }
            }
        }
    }

    // ====================================================
    // MODAL 2: DELETE FAVOURITES (Select and remove favourites)
    // ====================================================
    Rectangle {
        id: deleteFavoritesModal
        anchors.fill: parent
        z: 110
        visible: root.showDeleteFavoritesModal
        color: Qt.rgba(0, 0, 0, 0.75)

        property var selectedFreqs: ({})

        onVisibleChanged: {
            if (visible) {
                selectedFreqs = {}
            }
        }

        MouseArea { anchors.fill: parent }

        Rectangle {
            anchors.centerIn: parent
            width: 680
            height: 480
            radius: 8
            color: "#0F1724"
            border.color: "#253A52"
            border.width: 1.5

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // Modal Header
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Delete favourites"
                        color: "#FFFFFF"
                        font.pixelSize: 24
                        font.bold: true
                        font.family: "Roboto"
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: closeFavMouse.pressed ? "#389BFF" : "#1A283C"
                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: "#FFFFFF"
                            font.pixelSize: 18
                            font.bold: true
                        }
                        MouseArea {
                            id: closeFavMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showDeleteFavoritesModal = false
                        }
                    }
                }

                Text {
                    text: "Select the favourites you want to remove from your preset list."
                    color: "#94A3B8"
                    font.pixelSize: 17
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#253A52" }

                // List of favorite stations
                ListView {
                    id: favListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: systemController.stationList

                    delegate: Rectangle {
                        width: parent.width
                        property bool isFav: modelData.isFavorite
                        property bool isChecked: !!deleteFavoritesModal.selectedFreqs[modelData.frequency]
                        visible: isFav
                        height: isFav ? 52 : 0
                        color: favCheckMouse.containsMouse ? "#142438" : "transparent"
                        radius: 4

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 16

                            // Checkbox
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 4
                                color: isChecked ? "#2979FF" : "transparent"
                                border.color: isChecked ? "#2979FF" : "#64748B"
                                border.width: 2
                                Text {
                                    anchors.centerIn: parent
                                    text: "✓"
                                    color: "#FFFFFF"
                                    font.pixelSize: 16
                                    font.bold: true
                                    visible: isChecked
                                }
                            }

                            Row {
                                spacing: 8
                                Layout.preferredWidth: 120

                                Text {
                                    text: modelData.band
                                    color: "#38B6FF"
                                    font.pixelSize: 20
                                    font.bold: true
                                }

                                Text {
                                    text: modelData.frequency
                                    color: "#FFFFFF"
                                    font.pixelSize: 20
                                    font.bold: true
                                }
                            }

                            Text {
                                text: modelData.name
                                color: "#FFFFFF"
                                font.pixelSize: 19
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: favCheckMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var copy = Object.assign({}, deleteFavoritesModal.selectedFreqs)
                                if (copy[modelData.frequency]) {
                                    delete copy[modelData.frequency]
                                } else {
                                    copy[modelData.frequency] = true
                                }
                                deleteFavoritesModal.selectedFreqs = copy
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#253A52" }

                // Action buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Rectangle {
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 44
                        radius: 4
                        color: "#1E2A3B"
                        Text {
                            anchors.centerIn: parent
                            text: "Select all"
                            color: "#FFFFFF"
                            font.pixelSize: 18
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                var all = {}
                                for (var i = 0; i < systemController.stationList.length; ++i) {
                                    if (systemController.stationList[i].isFavorite) {
                                        all[systemController.stationList[i].frequency] = true
                                    }
                                }
                                deleteFavoritesModal.selectedFreqs = all
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 44
                        radius: 4
                        color: "#253A52"
                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: "#FFFFFF"
                            font.pixelSize: 18
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.showDeleteFavoritesModal = false
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 44
                        radius: 4
                        color: Object.keys(deleteFavoritesModal.selectedFreqs).length > 0 ? "#DC2626" : "#475569"
                        Text {
                            anchors.centerIn: parent
                            text: "Delete"
                            color: "#FFFFFF"
                            font.pixelSize: 18
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: Object.keys(deleteFavoritesModal.selectedFreqs).length > 0
                            onClicked: {
                                for (var freq in deleteFavoritesModal.selectedFreqs) {
                                    systemController.removeFavoriteByFrequency(freq)
                                }
                                root.showDeleteFavoritesModal = false
                            }
                        }
                    }
                }
            }
        }
    }

}
