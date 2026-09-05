/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: SoundSettingsScreen.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#05070B"

    signal backClicked()
    signal manualClicked()

    property string currentView: "main" // "main" | "speed_volume" | "guidance_volumes" | "projection_volume"
    property string selectedTab: "premium_sound" // "premium_sound" | "position" | "equaliser" | "guidance" | "radio_noise" | "driver_assist" | "connected_devices"
    property string selectedSeatArea: "none" // "none" | "top-left" | "top-right" | "bottom-left" | "bottom-right"
    property bool menuOpen: false

    function resetToDefault() {
        currentView = "main"
        selectedTab = "premium_sound"
        selectedSeatArea = "none"
        menuOpen = false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ====================================================
        // 1. SUB-HEADER BAR
        // ====================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            color: "#10141C"
            z: 30

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

                // Left: Gear icon + Dynamic Title
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
                        text: {
                            if (root.currentView === "speed_volume") return "Speed dependent volume control"
                            if (root.currentView === "guidance_volumes") return "Guidance volumes"
                            if (root.currentView === "projection_volume") return "Phone projection"
                            return "Sound settings"
                        }
                        color: "#FFFFFF"
                        font.pixelSize: 24
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }
                }

                Item { Layout.fillWidth: true }

                // Right Action Buttons:
                Row {
                    spacing: 12
                    Layout.alignment: Qt.AlignVCenter

                    // 1. [| Beep] Button (Visible in Main, Guidance Volumes, & Projection Volume)
                    Rectangle {
                        width: 106
                        height: 40
                        color: beepMouse.pressed ? "#1E88E5" : (beepMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: beepMouse.pressed ? "#66D9FF" : "#3F74A3"
                        border.width: 1
                        radius: 3
                        visible: root.currentView !== "speed_volume"

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3.5
                                height: 20
                                radius: 1.5
                                color: systemController.beepEnabled ? "#38B6FF" : "#6E8296"
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Beep"
                                color: "#FFFFFF"
                                font.pixelSize: 18
                                font.weight: Font.DemiBold
                                font.family: "Roboto"
                                scale: beepMouse.pressed ? 0.94 : 1.0
                                Behavior on scale { NumberAnimation { duration: 100 } }
                            }
                        }

                        MouseArea {
                            id: beepMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: systemController.toggleBeep()
                        }
                    }

                    // 2. Menu Button (Visible in Main view)
                    Rectangle {
                        width: 90
                        height: 40
                        color: root.menuOpen ? "#1E88E5" : (menuMouse.pressed ? "#1E88E5" : (menuMouse.containsMouse ? "#3A6C9B" : "#2E5B84"))
                        border.color: root.menuOpen ? "#66D9FF" : (menuMouse.pressed ? "#66D9FF" : "#3F74A3")
                        border.width: 1
                        radius: 3
                        visible: root.currentView === "main"

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Menu"
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
                            onClicked: root.menuOpen = !root.menuOpen
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
                                if (root.currentView !== "main") {
                                    root.currentView = "main"
                                } else {
                                    root.backClicked()
                                }
                            }
                        }
                    }
                }
            }

            // Sub-header Dropdown Menu
            Rectangle {
                id: soundDropdownMenu
                anchors.top: parent.bottom
                anchors.topMargin: 4
                anchors.right: parent.right
                anchors.rightMargin: 96
                width: 260
                height: 144
                color: "#EDF2F7"
                border.color: "#A4B8CD"
                border.width: 1
                radius: 4
                visible: root.menuOpen && root.currentView === "main"
                z: 50

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: 6
                    color: Qt.rgba(0, 0, 0, 0.25)
                    z: -1
                }

                Column {
                    anchors.fill: parent

                    // 1. Reset sound settings
                    Rectangle {
                        width: parent.width
                        height: 48
                        radius: 4
                        color: resetSoundMouse.pressed ? "#D0E0F0" : (resetSoundMouse.containsMouse ? "#DEEAF6" : "transparent")
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            text: "Reset sound settings"
                            color: "#101824"
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }
                        MouseArea {
                            id: resetSoundMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.menuOpen = false
                                root.selectedSeatArea = "none"
                                systemController.resetEqualiser()
                                systemController.resetPosition()
                                systemController.resetGuidanceVolumes()
                                systemController.resetProjectionVolumes()
                                systemController.setSpeedDependentVolume("Normal")
                                systemController.setVolumeLimitationOnStartup(false)
                                systemController.setRadioNoiseOption("original")
                                systemController.setParkingSafetyPriority(true)
                            }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: "#C8D6E5" }

                    // 2. Manual
                    Rectangle {
                        width: parent.width
                        height: 48
                        radius: 4
                        color: manualMenuMouse.pressed ? "#D0E0F0" : (manualMenuMouse.containsMouse ? "#DEEAF6" : "transparent")
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            text: "Manual"
                            color: "#101824"
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }
                        MouseArea {
                            id: manualMenuMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.menuOpen = false
                                root.manualClicked()
                            }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: "#C8D6E5" }

                    // 3. Beep
                    Rectangle {
                        width: parent.width
                        height: 47
                        radius: 4
                        color: beepMenuMouse.pressed ? "#D0E0F0" : (beepMenuMouse.containsMouse ? "#DEEAF6" : "transparent")
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            text: systemController.beepEnabled ? "Disable beep" : "Enable beep"
                            color: "#101824"
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }
                        MouseArea {
                            id: beepMenuMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.menuOpen = false
                                systemController.toggleBeep()
                            }
                        }
                    }
                }
            }
        }

        // ====================================================
        // 2. MAIN CONTAINER AREA
        // ====================================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Click to close menu if open
            MouseArea {
                anchors.fill: parent
                enabled: root.menuOpen
                onClicked: root.menuOpen = false
                z: 40
            }

            // ====================================================
            // VIEW A: MAIN SOUND SETTINGS (Sidebar Tabs + Content)
            // ====================================================
            RowLayout {
                anchors.fill: parent
                spacing: 0
                visible: root.currentView === "main"

                // ------------------------------------------------
                // LEFT SIDEBAR TABS (7 TABS TOTAL)
                // ------------------------------------------------
                Rectangle {
                    Layout.preferredWidth: 320
                    Layout.fillHeight: true
                    color: "#080B12"

                    Rectangle {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        width: 1.5
                        color: "#1A2230"
                    }

                    Flickable {
                        anchors.fill: parent
                        contentHeight: sidebarCol.height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: sidebarCol
                            width: parent.width

                            // 1. Premium sound
                            SoundTabItem {
                                title: "Premium sound"
                                isActive: root.selectedTab === "premium_sound"
                                onClicked: root.selectedTab = "premium_sound"
                            }

                            // 2. Position
                            SoundTabItem {
                                title: "Position"
                                isActive: root.selectedTab === "position"
                                onClicked: root.selectedTab = "position"
                            }

                            // 3. Equaliser
                            SoundTabItem {
                                title: "Equaliser"
                                isActive: root.selectedTab === "equaliser"
                                onClicked: root.selectedTab = "equaliser"
                            }

                            // 4. Guidance
                            SoundTabItem {
                                title: "Guidance"
                                isActive: root.selectedTab === "guidance"
                                onClicked: root.selectedTab = "guidance"
                            }

                            // 5. Radio noise control
                            SoundTabItem {
                                title: "Radio noise control"
                                isActive: root.selectedTab === "radio_noise"
                                onClicked: root.selectedTab = "radio_noise"
                            }

                            // 6. Driver assistance warning
                            SoundTabItem {
                                title: "Driver assistance warning"
                                isActive: root.selectedTab === "driver_assist"
                                onClicked: root.selectedTab = "driver_assist"
                            }

                            // 7. Connected devices
                            SoundTabItem {
                                title: "Connected devices"
                                isActive: root.selectedTab === "connected_devices"
                                onClicked: root.selectedTab = "connected_devices"
                            }
                        }
                    }
                }

                // ------------------------------------------------
                // RIGHT CONTENT PANE
                // ------------------------------------------------
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#05070B"

                    // ============================================
                    // TAB 1: PREMIUM SOUND (Matching Photo 1 intro)
                    // ============================================
                    Column {
                        anchors.fill: parent
                        anchors.leftMargin: 48
                        anchors.rightMargin: 48
                        anchors.topMargin: 38
                        spacing: 0
                        visible: root.selectedTab === "premium_sound"

                        // Item 1: Speed dependent volume control -> opens sub-screen
                        Rectangle {
                            width: parent.width
                            height: 94
                            color: speedMouse.containsMouse ? "#0E1522" : "transparent"
                            radius: 4

                            Behavior on color { ColorAnimation { duration: 100 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 16

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        text: "Speed dependent volume control"
                                        color: "#FFFFFF"
                                        font.pixelSize: 24
                                        font.weight: Font.DemiBold
                                        font.family: "Roboto"
                                    }

                                    Text {
                                        text: systemController.speedDependentVolume
                                        color: "#96B2CE"
                                        font.pixelSize: 19
                                        font.weight: Font.Normal
                                        font.family: "Roboto"
                                    }
                                }

                                Text {
                                    text: "▶"
                                    color: "#BACDDF"
                                    font.pixelSize: 18
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            MouseArea {
                                id: speedMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.currentView = "speed_volume"
                            }
                        }

                        // Divider Line
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#1B2332"
                            anchors.topMargin: 18
                            anchors.bottomMargin: 24
                        }

                        Item { width: 1; height: 18 }

                        // Item 2: Volume limitation on start-up
                        Rectangle {
                            width: parent.width
                            height: 160
                            color: volLimMouse.containsMouse ? "#0E1522" : "transparent"
                            radius: 4

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Column {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 14

                                Row {
                                    spacing: 18
                                    anchors.left: parent.left
                                    anchors.right: parent.right

                                    Rectangle {
                                        width: 28
                                        height: 28
                                        radius: 3
                                        color: systemController.volumeLimitationOnStartup ? "#389BFF" : "#101622"
                                        border.color: systemController.volumeLimitationOnStartup ? "#80D8FF" : "#556A82"
                                        border.width: 1.5

                                        Behavior on color { ColorAnimation { duration: 120 } }
                                        Behavior on border.color { ColorAnimation { duration: 120 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "✓"
                                            color: "#FFFFFF"
                                            font.pixelSize: 20
                                            font.weight: Font.Bold
                                            visible: systemController.volumeLimitationOnStartup
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Volume limitation on start-up"
                                        color: "#FFFFFF"
                                        font.pixelSize: 23
                                        font.weight: Font.DemiBold
                                        font.family: "Roboto"
                                    }
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 46
                                    anchors.right: parent.right
                                    text: "Automatic lowering of audio volumes when starting the system, if they are higher than the defined maximum. Only applies, if the vehicle was Off for a certain period of time"
                                    color: "#A4BCD0"
                                    font.pixelSize: 18
                                    font.weight: Font.Normal
                                    font.family: "Roboto"
                                    wrapMode: Text.WordWrap
                                    lineHeight: 1.35
                                }
                            }

                            MouseArea {
                                id: volLimMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: systemController.toggleVolumeLimitation()
                            }
                        }
                    }

                    // ============================================
                    // TAB 2: POSITION (Exact Photos 2 & 3 Match!)
                    // ============================================
                    Item {
                        anchors.fill: parent
                        anchors.leftMargin: 36
                        anchors.rightMargin: 36
                        anchors.topMargin: 24
                        anchors.bottomMargin: 24
                        visible: root.selectedTab === "position"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 16

                            // Top instruction
                            Text {
                                Layout.fillWidth: true
                                text: "Touch the point in the vehicle diagram, in which you wish to focus the sound. Use the arrow keys to fine-tune the position."
                                color: "#B8CBDD"
                                font.pixelSize: 19
                                font.weight: Font.Normal
                                font.family: "Roboto"
                                wrapMode: Text.WordWrap
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 40

                                // Left Area: Car Cabin Diagram with 4 Selectable Quadrants & Target Reticle
                                Column {
                                    Layout.preferredWidth: 440
                                    Layout.fillHeight: true
                                    spacing: 12

                                    Rectangle {
                                        id: carBox
                                        width: 440
                                        height: parent.height - 56
                                        color: "transparent"
                                        clip: true

                                        readonly property real cx: carBox.width / 2
                                        readonly property real cy: carBox.height / 2
                                        readonly property real leftBound: carBox.width * 0.16
                                        readonly property real rightBound: carBox.width * 0.84
                                        readonly property real topBound: carBox.height * 0.12
                                        readonly property real bottomBound: carBox.height * 0.88

                                        // 1. Vehicle Cabin Wireframe / Pillar Image
                                        Image {
                                            anchors.centerIn: parent
                                            width: parent.width * 0.82
                                            height: parent.height * 0.88
                                            source: "qrc:/assets/vehicle/car_cabin.png"
                                            fillMode: Image.PreserveAspectFit
                                            smooth: true
                                            mipmap: true
                                            opacity: 0.85
                                        }

                                        // 2. The Four Selectable Quadrants (Touch highlights the area with focus color, reticle remains at its place)
                                        // A. Top-Left Quadrant (Focus on passenger seat - RHD specification)
                                        QuadrantZone {
                                            x: carBox.leftBound
                                            y: carBox.topBound
                                            width: carBox.cx - carBox.leftBound
                                            height: carBox.cy - carBox.topBound
                                            corner: "top-left"
                                            isActive: root.selectedSeatArea === "top-left"
                                            onSelected: {
                                                console.log("[SoundPosition] Top-Left tapped -> Select passenger seat area")
                                                root.selectedSeatArea = (root.selectedSeatArea === "top-left" ? "none" : "top-left")
                                            }
                                        }

                                        // B. Top-Right Quadrant (Focus on driver's seat)
                                        QuadrantZone {
                                            x: carBox.cx
                                            y: carBox.topBound
                                            width: carBox.rightBound - carBox.cx
                                            height: carBox.cy - carBox.topBound
                                            corner: "top-right"
                                            isActive: root.selectedSeatArea === "top-right"
                                            onSelected: {
                                                console.log("[SoundPosition] Top-Right tapped -> Select driver seat area")
                                                root.selectedSeatArea = (root.selectedSeatArea === "top-right" ? "none" : "top-right")
                                            }
                                        }

                                        // C. Bottom-Left Quadrant (Focus on rear left seat)
                                        QuadrantZone {
                                            x: carBox.leftBound
                                            y: carBox.cy
                                            width: carBox.cx - carBox.leftBound
                                            height: carBox.bottomBound - carBox.cy
                                            corner: "bottom-left"
                                            isActive: root.selectedSeatArea === "bottom-left"
                                            onSelected: {
                                                console.log("[SoundPosition] Bottom-Left tapped -> Select rear left seat area")
                                                root.selectedSeatArea = (root.selectedSeatArea === "bottom-left" ? "none" : "bottom-left")
                                            }
                                        }

                                        // D. Bottom-Right Quadrant (Focus on rear right seat)
                                        QuadrantZone {
                                            x: carBox.cx
                                            y: carBox.cy
                                            width: carBox.rightBound - carBox.cx
                                            height: carBox.bottomBound - carBox.cy
                                            corner: "bottom-right"
                                            isActive: root.selectedSeatArea === "bottom-right"
                                            onSelected: {
                                                console.log("[SoundPosition] Bottom-Right tapped -> Select rear right seat area")
                                                root.selectedSeatArea = (root.selectedSeatArea === "bottom-right" ? "none" : "bottom-right")
                                            }
                                        }

                                        // 3. Dynamic Target Reticle Coordinates
                                        readonly property real targetPxX: carBox.cx + (systemController.balance * ((carBox.rightBound - carBox.cx) * 0.78 / 10))
                                        readonly property real targetPxY: carBox.cy - (systemController.fader * ((carBox.cy - carBox.topBound) * 0.78 / 10))

                                        // 4. Crosshair Lines (Silky-smooth following)
                                        Rectangle {
                                            x: carBox.leftBound - 12
                                            y: carBox.targetPxY - 0.75
                                            width: (carBox.rightBound - carBox.leftBound) + 24
                                            height: 1.5
                                            color: "#38B6FF"
                                            opacity: 0.8
                                            z: 14

                                            Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                        }

                                        Rectangle {
                                            x: carBox.targetPxX - 0.75
                                            y: carBox.topBound - 12
                                            width: 1.5
                                            height: (carBox.bottomBound - carBox.topBound) + 24
                                            color: "#38B6FF"
                                            opacity: 0.8
                                            z: 14

                                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                        }

                                        // 5. Sound Focus Target Reticle Marker (Circle with ticks - shrinks to small when centered)
                                        Item {
                                            id: focusReticle
                                            x: carBox.targetPxX - width / 2
                                            y: carBox.targetPxY - height / 2
                                            width: 44
                                            height: 44
                                            z: 15
                                            transformOrigin: Item.Center

                                            readonly property bool isCentered: systemController.fader === 0 && systemController.balance === 0
                                            scale: isCentered ? 0.55 : 1.0

                                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                            Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: 38
                                                height: 38
                                                radius: 19
                                                color: Qt.rgba(10/255, 20/255, 35/255, 0.55)
                                                border.color: "#80D8FF"
                                                border.width: 2
                                            }

                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: 8
                                                height: 8
                                                radius: 4
                                                color: "#38B6FF"
                                            }

                                            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.top; anchors.bottomMargin: -6; width: 1.5; height: 6; color: "#80D8FF" }
                                            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.bottom; anchors.topMargin: -6; width: 1.5; height: 6; color: "#80D8FF" }
                                            Rectangle { anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.left; anchors.rightMargin: -6; width: 6; height: 1.5; color: "#80D8FF" }
                                            Rectangle { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.right; anchors.leftMargin: -6; width: 6; height: 1.5; color: "#80D8FF" }
                                        }

                                        // 6. Center Reset Tap Target
                                        MouseArea {
                                            x: carBox.cx - 36
                                            y: carBox.cy - 36
                                            width: 72
                                            height: 72
                                            z: 20
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                console.log("[SoundPosition] Center tapped -> Reset to center")
                                                root.selectedSeatArea = "none"
                                                systemController.resetPosition()
                                            }
                                        }
                                    }

                                    // Helper function for dynamic OEM seat focus names
                                    function getFocusName() {
                                        if (root.selectedSeatArea === "top-left") return "Focus on passenger seat"
                                        if (root.selectedSeatArea === "top-right") return "Focus on driver's seat"
                                        if (root.selectedSeatArea === "bottom-left") return "Focus on rear left seat"
                                        if (root.selectedSeatArea === "bottom-right") return "Focus on rear right seat"

                                        var b = systemController.balance
                                        var f = systemController.fader
                                        if (b === 0 && f === 0) return "Focus on all seats"
                                        if (f > 0 && b < 0) return "Focus on passenger seat"
                                        if (f > 0 && b > 0) return "Focus on driver's seat"
                                        if (f < 0 && b < 0) return "Focus on rear left seat"
                                        if (f < 0 && b > 0) return "Focus on rear right seat"
                                        if (f > 0 && b === 0) return "Focus on front seats"
                                        if (f < 0 && b === 0) return "Focus on rear seats"
                                        if (f === 0 && b < 0) return "Focus on left side"
                                        if (f === 0 && b > 0) return "Focus on right side"
                                        return "Focus on all seats"
                                    }

                                    // Bottom Status Row (Exact Match to Genuine Screen Photo!)
                                    RowLayout {
                                        width: parent.width

                                        Text {
                                            Layout.preferredWidth: 220
                                            text: parent.parent.getFocusName()
                                            color: "#AEC5DC"
                                            font.pixelSize: 18
                                            font.weight: Font.Medium
                                            font.family: "Roboto"
                                        }

                                        Item { Layout.fillWidth: true }

                                        Column {
                                            Layout.preferredWidth: 90
                                            spacing: 2
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: "Fader"
                                                color: "#7E9AB5"
                                                font.pixelSize: 16
                                                font.family: "Roboto"
                                            }
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: systemController.fader === 0 ? "0" : (systemController.fader > 0 ? "F=" + systemController.fader : "R=" + (-systemController.fader))
                                                color: "#FFFFFF"
                                                font.pixelSize: 19
                                                font.weight: Font.DemiBold
                                                font.family: "Roboto"
                                            }
                                        }

                                        Column {
                                            Layout.preferredWidth: 90
                                            spacing: 2
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: "Balance"
                                                color: "#7E9AB5"
                                                font.pixelSize: 16
                                                font.family: "Roboto"
                                            }
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: systemController.balance === 0 ? "0" : (systemController.balance > 0 ? "R=" + systemController.balance : "L=" + (-systemController.balance))
                                                color: "#FFFFFF"
                                                font.pixelSize: 19
                                                font.weight: Font.DemiBold
                                                font.family: "Roboto"
                                            }
                                        }
                                    }
                                }

                                // Right Area: Directional D-Pad Controller (Up, Down, Left, Right & Center Reset)
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 12

                                        // Top Arrow [ ^ ]
                                        Item {
                                            width: 300
                                            height: 60
                                            PositionKeyButton {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                arrowType: "up"
                                                onTriggered: systemController.setFader(Math.min(10, systemController.fader + 1))
                                            }
                                        }

                                        // Middle Row [ < ] [ ⌖ ] [ > ]
                                        Row {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            spacing: 12

                                            // Left Arrow [ < ]
                                            PositionKeyButton {
                                                arrowType: "left"
                                                onTriggered: systemController.setBalance(Math.max(-10, systemController.balance - 1))
                                            }

                                            // Center Crosshair Button [ ⌖ ] -> Resets Position to Center!
                                            Rectangle {
                                                width: 88
                                                height: 60
                                                color: centerBtnM.pressed ? "#1E88E5" : (centerBtnM.containsMouse ? "#3A6C9B" : "#2E5B84")
                                                border.color: centerBtnM.pressed ? "#80D8FF" : "#3F74A3"
                                                border.width: 1.5
                                                radius: 4

                                                Behavior on color { ColorAnimation { duration: 100 } }

                                                Item {
                                                    anchors.centerIn: parent
                                                    width: 32; height: 32

                                                    Rectangle {
                                                        anchors.centerIn: parent
                                                        width: 22; height: 22; radius: 11
                                                        color: "transparent"
                                                        border.color: "#FFFFFF"
                                                        border.width: 2
                                                    }

                                                    Rectangle {
                                                        anchors.centerIn: parent
                                                        width: 6; height: 6; radius: 3
                                                        color: "#FFFFFF"
                                                    }

                                                    Rectangle { anchors.centerIn: parent; width: 30; height: 2; color: "#FFFFFF" }
                                                    Rectangle { anchors.centerIn: parent; width: 2; height: 30; color: "#FFFFFF" }
                                                }

                                                MouseArea {
                                                    id: centerBtnM
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        console.log("[SoundSettings] Controller center reset clicked")
                                                        root.selectedSeatArea = "none"
                                                        systemController.resetPosition()
                                                    }
                                                }
                                            }

                                            // Right Arrow [ > ]
                                            PositionKeyButton {
                                                arrowType: "right"
                                                onTriggered: systemController.setBalance(Math.min(10, systemController.balance + 1))
                                            }
                                        }

                                        // Bottom Arrow [ v ]
                                        Item {
                                            width: 300
                                            height: 60
                                            PositionKeyButton {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                arrowType: "down"
                                                onTriggered: systemController.setFader(Math.max(-10, systemController.fader - 1))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ============================================
                    // TAB 3: EQUALISER (Exact Photo 4 Match!)
                    // ============================================
                    Column {
                        anchors.fill: parent
                        anchors.leftMargin: 48
                        anchors.rightMargin: 48
                        anchors.topMargin: 32
                        anchors.bottomMargin: 24
                        spacing: 24
                        visible: root.selectedTab === "equaliser"

                        EqualiserTrackRow {
                            label: "Treble"
                            value: systemController.treble
                            onMinus: systemController.setTreble(systemController.treble - 1)
                            onPlus: systemController.setTreble(systemController.treble + 1)
                        }

                        EqualiserTrackRow {
                            label: "Midrange"
                            value: systemController.midrange
                            onMinus: systemController.setMidrange(systemController.midrange - 1)
                            onPlus: systemController.setMidrange(systemController.midrange + 1)
                        }

                        EqualiserTrackRow {
                            label: "Bass"
                            value: systemController.bass
                            onMinus: systemController.setBass(systemController.bass - 1)
                            onPlus: systemController.setBass(systemController.bass + 1)
                        }

                        Item { Layout.fillHeight: true }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 480
                            height: 52
                            color: centreEqM.pressed ? "#1E88E5" : (centreEqM.containsMouse ? "#3A6C9B" : "#2E5B84")
                            border.color: centreEqM.pressed ? "#80D8FF" : "#3F74A3"
                            border.width: 1.5
                            radius: 4

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: "Centre"
                                color: "#FFFFFF"
                                font.pixelSize: 21
                                font.weight: Font.DemiBold
                                font.family: "Roboto"
                            }

                            MouseArea {
                                id: centreEqM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: systemController.resetEqualiser()
                            }
                        }
                    }

                    // ============================================
                    // TAB 4: GUIDANCE (Photo 5 Match!)
                    // ============================================
                    Column {
                        anchors.fill: parent
                        anchors.leftMargin: 48
                        anchors.rightMargin: 48
                        anchors.topMargin: 38
                        spacing: 0
                        visible: root.selectedTab === "guidance"

                        Rectangle {
                            width: parent.width
                            height: 80
                            color: guidRowM.containsMouse ? "#0E1522" : "transparent"
                            radius: 4

                            Behavior on color { ColorAnimation { duration: 100 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 16

                                Text {
                                    Layout.fillWidth: true
                                    text: "Guidance volumes"
                                    color: "#FFFFFF"
                                    font.pixelSize: 24
                                    font.weight: Font.DemiBold
                                    font.family: "Roboto"
                                }

                                Text {
                                    text: "▶"
                                    color: "#BACDDF"
                                    font.pixelSize: 18
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            MouseArea {
                                id: guidRowM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.currentView = "guidance_volumes"
                            }
                        }
                    }

                    // ============================================
                    // TAB 5: RADIO NOISE CONTROL (Exact Photo 2 Match!)
                    // ============================================
                    Column {
                        anchors.fill: parent
                        anchors.leftMargin: 48
                        anchors.rightMargin: 48
                        anchors.topMargin: 32
                        spacing: 12
                        visible: root.selectedTab === "radio_noise"

                        RadioChoiceRow {
                            title: "Original sound"
                            description: "Unaltered sound without reduction of noise in areas with weak reception"
                            isSelected: systemController.radioNoiseOption === "original"
                            onClicked: systemController.setRadioNoiseOption("original")
                        }

                        RadioChoiceRow {
                            title: "Mild noise reduction"
                            description: "A sound with reduced noise in areas with weak reception, but still true to the original sound"
                            isSelected: systemController.radioNoiseOption === "mild"
                            onClicked: systemController.setRadioNoiseOption("mild")
                        }

                        RadioChoiceRow {
                            title: "Strong noise reduction"
                            description: "Maximised noise reduction in areas with weak reception"
                            isSelected: systemController.radioNoiseOption === "strong"
                            onClicked: systemController.setRadioNoiseOption("strong")
                        }
                    }

                    // ============================================
                    // TAB 6: DRIVER ASSISTANCE WARNING (Photo 3 Match!)
                    // ============================================
                    Column {
                        anchors.fill: parent
                        anchors.leftMargin: 48
                        anchors.rightMargin: 48
                        anchors.topMargin: 38
                        spacing: 0
                        visible: root.selectedTab === "driver_assist"

                        Rectangle {
                            width: parent.width
                            height: 140
                            color: parkM.containsMouse ? "#0E1522" : "transparent"
                            radius: 4

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Column {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 14

                                Row {
                                    spacing: 18
                                    anchors.left: parent.left
                                    anchors.right: parent.right

                                    Rectangle {
                                        width: 28
                                        height: 28
                                        radius: 3
                                        color: systemController.parkingSafetyPriority ? "#389BFF" : "#101622"
                                        border.color: systemController.parkingSafetyPriority ? "#80D8FF" : "#556A82"
                                        border.width: 1.5

                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "✓"
                                            color: "#FFFFFF"
                                            font.pixelSize: 20
                                            font.weight: Font.Bold
                                            visible: systemController.parkingSafetyPriority
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Parking safety priority"
                                        color: "#FFFFFF"
                                        font.pixelSize: 24
                                        font.weight: Font.DemiBold
                                        font.family: "Roboto"
                                    }
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 46
                                    anchors.right: parent.right
                                    text: "Lowers all other audio volumes when a parking assist view is active."
                                    color: "#A4BCD0"
                                    font.pixelSize: 19
                                    font.weight: Font.Normal
                                    font.family: "Roboto"
                                }
                            }

                            MouseArea {
                                id: parkM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: systemController.toggleParkingSafetyPriority()
                            }
                        }
                    }

                    // ============================================
                    // TAB 7: CONNECTED DEVICES (Photo 4 Match!)
                    // ============================================
                    Column {
                        anchors.fill: parent
                        anchors.leftMargin: 48
                        anchors.rightMargin: 48
                        anchors.topMargin: 38
                        spacing: 20
                        visible: root.selectedTab === "connected_devices"

                        // Row 1: Android Auto
                        Rectangle {
                            width: parent.width
                            height: 70
                            color: aaM.containsMouse ? "#0E1522" : "transparent"
                            radius: 4

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 16

                                Text {
                                    Layout.fillWidth: true
                                    text: "Android Auto"
                                    color: "#FFFFFF"
                                    font.pixelSize: 24
                                    font.weight: Font.DemiBold
                                    font.family: "Roboto"
                                }

                                Text {
                                    text: "▶"
                                    color: "#BACDDF"
                                    font.pixelSize: 18
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            MouseArea {
                                id: aaM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    systemController.setSelectedProjectionDevice("Android Auto")
                                    root.currentView = "projection_volume"
                                }
                            }
                        }

                        // Row 2: Apple CarPlay
                        Rectangle {
                            width: parent.width
                            height: 70
                            color: cpM.containsMouse ? "#0E1522" : "transparent"
                            radius: 4

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 16

                                Text {
                                    Layout.fillWidth: true
                                    text: "Apple CarPlay"
                                    color: "#FFFFFF"
                                    font.pixelSize: 24
                                    font.weight: Font.DemiBold
                                    font.family: "Roboto"
                                }

                                Text {
                                    text: "▶"
                                    color: "#BACDDF"
                                    font.pixelSize: 18
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            MouseArea {
                                id: cpM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    systemController.setSelectedProjectionDevice("Apple CarPlay")
                                    root.currentView = "projection_volume"
                                }
                            }
                        }
                    }
                }
            }

            // ====================================================
            // VIEW B: SPEED DEPENDENT VOLUME CONTROL SUB-SCREEN
            // (Exact Photo 1 Match!)
            // ====================================================
            Rectangle {
                anchors.fill: parent
                color: "#05070B"
                visible: root.currentView === "speed_volume"

                Column {
                    anchors.fill: parent
                    anchors.leftMargin: 48
                    anchors.rightMargin: 48
                    anchors.topMargin: 32
                    spacing: 16

                    Text {
                        text: "Volume is automatically adjusted to vehicle speed."
                        color: "#C2D4E6"
                        font.pixelSize: 22
                        font.weight: Font.Normal
                        font.family: "Roboto"
                    }

                    Item { width: 1; height: 16 }

                    SpeedSelectRow {
                        title: "Enhanced"
                        isSelected: systemController.speedDependentVolume === "Enhanced"
                        onClicked: systemController.setSpeedDependentVolume("Enhanced")
                    }

                    SpeedSelectRow {
                        title: "Normal"
                        isSelected: systemController.speedDependentVolume === "Normal"
                        onClicked: systemController.setSpeedDependentVolume("Normal")
                    }

                    SpeedSelectRow {
                        title: "Minimised"
                        isSelected: systemController.speedDependentVolume === "Minimised"
                        onClicked: systemController.setSpeedDependentVolume("Minimised")
                    }

                    SpeedSelectRow {
                        title: "Off"
                        isSelected: systemController.speedDependentVolume === "Off"
                        onClicked: systemController.setSpeedDependentVolume("Off")
                    }
                }
            }

            // ====================================================
            // VIEW C: GUIDANCE VOLUMES SUB-SCREEN (New Photo 1 Match!)
            // ====================================================
            Rectangle {
                anchors.fill: parent
                color: "#05070B"
                visible: root.currentView === "guidance_volumes"

                Column {
                    anchors.fill: parent
                    anchors.leftMargin: 48
                    anchors.rightMargin: 48
                    anchors.topMargin: 32
                    anchors.bottomMargin: 24
                    spacing: 24

                    // 1. Beep (1..10)
                    ContinuousVolumeRow {
                        label: "Beep"
                        value: systemController.guidanceBeepVolume
                        maxVal: 10
                        onMinus: systemController.setGuidanceBeepVolume(Math.max(0, systemController.guidanceBeepVolume - 1))
                        onPlus: systemController.setGuidanceBeepVolume(Math.min(10, systemController.guidanceBeepVolume + 1))
                    }

                    // 2. Ringtone (1..30)
                    ContinuousVolumeRow {
                        label: "Ringtone"
                        value: systemController.guidanceRingtoneVolume
                        maxVal: 30
                        onMinus: systemController.setGuidanceRingtoneVolume(Math.max(0, systemController.guidanceRingtoneVolume - 1))
                        onPlus: systemController.setGuidanceRingtoneVolume(Math.min(30, systemController.guidanceRingtoneVolume + 1))
                    }

                    // 3. Alerts (1..10)
                    ContinuousVolumeRow {
                        label: "Alerts"
                        value: systemController.guidanceAlertsVolume
                        maxVal: 10
                        onMinus: systemController.setGuidanceAlertsVolume(Math.max(0, systemController.guidanceAlertsVolume - 1))
                        onPlus: systemController.setGuidanceAlertsVolume(Math.min(10, systemController.guidanceAlertsVolume + 1))
                    }

                    Item { Layout.fillHeight: true }

                    // Bottom Wide [ Default ] Button (Photo 1 Match!)
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 480
                        height: 52
                        color: defGuidM.pressed ? "#1E88E5" : (defGuidM.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: defGuidM.pressed ? "#80D8FF" : "#3F74A3"
                        border.width: 1.5
                        radius: 4

                        Text {
                            anchors.centerIn: parent
                            text: "Default"
                            color: "#FFFFFF"
                            font.pixelSize: 21
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        MouseArea {
                            id: defGuidM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: systemController.resetGuidanceVolumes()
                        }
                    }
                }
            }

            // ====================================================
            // VIEW D: PHONE PROJECTION VOLUMES (New Photo 5 Match!)
            // ====================================================
            Rectangle {
                anchors.fill: parent
                color: "#05070B"
                visible: root.currentView === "projection_volume"

                Column {
                    anchors.fill: parent
                    anchors.leftMargin: 48
                    anchors.rightMargin: 48
                    anchors.topMargin: 24
                    anchors.bottomMargin: 24
                    spacing: 20

                    // Subtitle: "Adjustment of the Android Auto volume."
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Adjustment of the " + systemController.selectedProjectionDevice + " volume."
                        color: "#C2D4E6"
                        font.pixelSize: 20
                    }

                    // Section Title + Top-Right Default Button (Photo 5 Match!)
                    RowLayout {
                        width: parent.width

                        Text {
                            text: systemController.selectedProjectionDevice
                            color: "#FFFFFF"
                            font.pixelSize: 26
                            font.weight: Font.DemiBold
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: 190
                            height: 48
                            color: defProjM.pressed ? "#1E88E5" : (defProjM.containsMouse ? "#3A6C9B" : "#2E5B84")
                            border.color: defProjM.pressed ? "#80D8FF" : "#3F74A3"
                            border.width: 1.5
                            radius: 4

                            Text {
                                anchors.centerIn: parent
                                text: "Default"
                                color: "#FFFFFF"
                                font.pixelSize: 20
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                id: defProjM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: systemController.resetProjectionVolumes()
                            }
                        }
                    }

                    Item { width: 1; height: 8 }

                    // 1. Media Volume (30)
                    ContinuousVolumeRow {
                        label: "Media"
                        value: systemController.projectionMediaVolume
                        maxVal: 45
                        onMinus: systemController.setProjectionMediaVolume(Math.max(0, systemController.projectionMediaVolume - 1))
                        onPlus: systemController.setProjectionMediaVolume(Math.min(45, systemController.projectionMediaVolume + 1))
                    }

                    // 2. Voice guidance (8)
                    ContinuousVolumeRow {
                        label: "Voice guidance"
                        value: systemController.projectionVoiceVolume
                        maxVal: 20
                        onMinus: systemController.setProjectionVoiceVolume(Math.max(0, systemController.projectionVoiceVolume - 1))
                        onPlus: systemController.setProjectionVoiceVolume(Math.min(20, systemController.projectionVoiceVolume + 1))
                    }
                }
            }
        }
    }

    // ========================================================
    // COMPONENT: Speed Selection Row (Photo 1 Match!)
    // ========================================================
    component SpeedSelectRow: Rectangle {
        property string title: ""
        property bool isSelected: false
        signal clicked()

        width: parent.width
        height: 68
        radius: 3
        color: rowM.pressed ? "#16202E" : (rowM.containsMouse ? "#0E1522" : "transparent")

        Behavior on color { ColorAnimation { duration: 120 } }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 20
            spacing: 22

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                radius: 14
                color: "transparent"
                border.color: isSelected ? "#389BFF" : "#9FB4C8"
                border.width: 2

                Rectangle {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    radius: 6
                    color: "#1888F5"
                    visible: isSelected
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: title
                color: isSelected ? "#389BFF" : "#FFFFFF"
                font.pixelSize: 24
                font.weight: isSelected ? Font.DemiBold : Font.Normal
                font.family: "Roboto"
            }
        }

        MouseArea {
            id: rowM
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    // ========================================================
    // COMPONENT: Radio Choice Row (New Photo 2 Match!)
    // ========================================================
    component RadioChoiceRow: Rectangle {
        property string title: ""
        property string description: ""
        property bool isSelected: false
        signal clicked()

        width: parent.width
        height: 84
        radius: 3
        color: choiceM.pressed ? "#16202E" : (choiceM.containsMouse ? "#0E1522" : "transparent")

        Behavior on color { ColorAnimation { duration: 120 } }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 20
            spacing: 22

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                radius: 14
                color: "transparent"
                border.color: isSelected ? "#389BFF" : "#9FB4C8"
                border.width: 2

                Rectangle {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    radius: 6
                    color: "#1888F5"
                    visible: isSelected
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 50
                spacing: 4

                Text {
                    text: title
                    color: isSelected ? "#389BFF" : "#FFFFFF"
                    font.pixelSize: 23
                    font.weight: isSelected ? Font.DemiBold : Font.Normal
                    font.family: "Roboto"
                }

                Text {
                    text: description
                    color: "#8FA9C2"
                    font.pixelSize: 16
                    font.family: "Roboto"
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
            }
        }

        MouseArea {
            id: choiceM
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    // ========================================================
    // COMPONENT: Continuous Volume Slider Row (New Photos 1 & 5 Match!)
    // ========================================================
    component ContinuousVolumeRow: Column {
        id: volRow
        property string label: ""
        property int value: 0
        property int maxVal: 10
        signal minus()
        signal plus()

        width: parent.width
        spacing: 6

        RowLayout {
            width: parent.width
            spacing: 20

            // Left [ - ]
            Rectangle {
                width: 68
                height: 48
                color: minusBtnM.pressed ? "#1E88E5" : (minusBtnM.containsMouse ? "#3A6C9B" : "#2E5B84")
                border.color: minusBtnM.pressed ? "#80D8FF" : "#3F74A3"
                border.width: 1.5
                radius: 4

                Text {
                    anchors.centerIn: parent
                    text: "−"
                    color: "#FFFFFF"
                    font.pixelSize: 26
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: minusBtnM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: volRow.minus()
                }
            }

            // Slider Line with Dynamic Floating Value Badge
            Rectangle {
                id: sliderTrack
                Layout.fillWidth: true
                height: 40
                color: "transparent"

                // Base Track Line
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    color: "#1F2F44"
                    radius: 2
                }

                // Active Cyan Fill Line up to value
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    width: Math.min(parent.width, Math.max(0, parent.width * (volRow.value / volRow.maxVal)))
                    height: 4
                    color: "#38B6FF"
                    radius: 2
                }

                // White Number Badge
                Rectangle {
                    x: Math.max(0, Math.min(sliderTrack.width - width, (sliderTrack.width * (volRow.value / volRow.maxVal)) - width / 2))
                    anchors.verticalCenter: parent.verticalCenter
                    width: 64
                    height: 36
                    color: "#FFFFFF"
                    radius: 3

                    Text {
                        anchors.centerIn: parent
                        text: volRow.value.toString()
                        color: "#1A2534"
                        font.pixelSize: 20
                        font.weight: Font.Bold
                    }
                }

                // Allow clicking track directly to adjust
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        var newVal = Math.round((mouse.x / width) * volRow.maxVal)
                        if (newVal < volRow.value) volRow.minus()
                        else if (newVal > volRow.value) volRow.plus()
                    }
                }
            }

            // Right [ + ]
            Rectangle {
                width: 68
                height: 48
                color: plusBtnM.pressed ? "#1E88E5" : (plusBtnM.containsMouse ? "#3A6C9B" : "#2E5B84")
                border.color: plusBtnM.pressed ? "#80D8FF" : "#3F74A3"
                border.width: 1.5
                radius: 4

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    color: "#FFFFFF"
                    font.pixelSize: 26
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: plusBtnM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: parent.parent.parent.plus()
                }
            }
        }

        // Centered label underneath
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: label
            color: "#FFFFFF"
            font.pixelSize: 20
            font.weight: Font.DemiBold
            font.family: "Roboto"
        }
    }

    // ========================================================
    // COMPONENT: Sidebar Tab Item
    // ========================================================
    component SoundTabItem: Rectangle {
        property string title: ""
        property bool isActive: false
        signal clicked()

        width: parent.width
        height: 68
        color: isActive ? "#C4E2FE" : (tabMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.25) : (tabMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.08) : "transparent"))

        Behavior on color { ColorAnimation { duration: 120 } }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 3.5
            color: "#00B8FF"
            visible: isActive
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 26
            anchors.right: parent.right
            anchors.rightMargin: 16
            text: title
            color: isActive ? "#0A1428" : "#FFFFFF"
            font.pixelSize: 21
            font.weight: isActive ? Font.DemiBold : Font.Normal
            font.family: "Roboto"
            wrapMode: Text.WordWrap
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: "#151C26"
            visible: !isActive
        }

        MouseArea {
            id: tabMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    // ========================================================
    // COMPONENT: Equaliser Track Row with Segmented Ticks (Photo 4 Match!)
    // ========================================================
    component EqualiserTrackRow: Column {
        property string label: ""
        property int value: 0
        signal minus()
        signal plus()

        width: parent.width
        spacing: 8

        RowLayout {
            width: parent.width
            spacing: 20

            // Left [ - ] Button
            Rectangle {
                width: 68
                height: 48
                color: minusBtnM.pressed ? "#1E88E5" : (minusBtnM.containsMouse ? "#3A6C9B" : "#2E5B84")
                border.color: minusBtnM.pressed ? "#80D8FF" : "#3F74A3"
                border.width: 1.5
                radius: 4

                Text {
                    anchors.centerIn: parent
                    text: "−"
                    color: "#FFFFFF"
                    font.pixelSize: 26
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: minusBtnM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: parent.parent.parent.minus()
                }
            }

            // Segmented Level Bar (21 discrete tick marks)
            Rectangle {
                Layout.fillWidth: true
                height: 16
                color: "transparent"

                Row {
                    anchors.fill: parent
                    spacing: 4

                    Repeater {
                        model: 21

                        Rectangle {
                            width: (parent.width - (parent.spacing * 20)) / 21
                            height: 10
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 2

                            readonly property int stepVal: index - 10
                            readonly property bool isLit: {
                                if (value >= 0) {
                                    return stepVal >= 0 && stepVal <= value
                                } else {
                                    return stepVal <= 0 && stepVal >= value
                                }
                            }

                            color: isLit ? "#38B6FF" : "#1B2A3E"
                        }
                    }
                }
            }

            // White Value Badge Rectangle
            Rectangle {
                width: 68
                height: 40
                color: "#FFFFFF"
                radius: 3

                Text {
                    anchors.centerIn: parent
                    text: value > 0 ? "+" + value : value
                    color: "#0B1522"
                    font.pixelSize: 21
                    font.weight: Font.Bold
                    font.family: "Roboto"
                }
            }

            // Right [ + ] Button
            Rectangle {
                width: 68
                height: 48
                color: plusBtnM.pressed ? "#1E88E5" : (plusBtnM.containsMouse ? "#3A6C9B" : "#2E5B84")
                border.color: plusBtnM.pressed ? "#80D8FF" : "#3F74A3"
                border.width: 1.5
                radius: 4

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    color: "#FFFFFF"
                    font.pixelSize: 26
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: plusBtnM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: parent.parent.parent.plus()
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: label
            color: "#FFFFFF"
            font.pixelSize: 20
            font.weight: Font.DemiBold
            font.family: "Roboto"
        }
    }

    // ========================================================
    // ========================================================
    // COMPONENT: Sound Position Quadrant Zone (Acoustic Wave Arcs)
    // ========================================================
    component QuadrantZone: Rectangle {
        id: qZoneRoot
        property bool isActive: false
        property string corner: "top-left" // "top-left" | "top-right" | "bottom-left" | "bottom-right"
        signal selected()

        color: isActive ? Qt.rgba(20/255, 105/255, 235/255, 0.45) : "transparent"
        border.color: isActive ? "#38B6FF" : "transparent"
        border.width: 1.5

        Behavior on color { ColorAnimation { duration: 150 } }

        Canvas {
            id: rippleCanvas
            anchors.fill: parent
            visible: qZoneRoot.isActive
            opacity: rippleAnim.opacityVal

            onVisibleChanged: {
                if (visible) requestPaint()
            }

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = "rgba(110, 215, 255, 0.85)"
                ctx.lineWidth = 2.2
                ctx.lineCap = "round"

                var ox = 0
                var oy = 0
                var sa = 0
                var ea = Math.PI / 2

                if (qZoneRoot.corner === "top-left") {
                    ox = 0; oy = 0
                    sa = 0; ea = Math.PI / 2
                } else if (qZoneRoot.corner === "top-right") {
                    ox = width; oy = 0
                    sa = Math.PI / 2; ea = Math.PI
                } else if (qZoneRoot.corner === "bottom-left") {
                    ox = 0; oy = height
                    sa = 3 * Math.PI / 2; ea = 2 * Math.PI
                } else if (qZoneRoot.corner === "bottom-right") {
                    ox = width; oy = height
                    sa = Math.PI; ea = 3 * Math.PI / 2
                }

                var radii = [22, 38, 54]
                for (var i = 0; i < radii.length; i++) {
                    ctx.beginPath()
                    ctx.arc(ox, oy, radii[i], sa, ea)
                    ctx.stroke()
                }
            }

            Connections {
                target: qZoneRoot
                function onIsActiveChanged() {
                    if (qZoneRoot.isActive) {
                        rippleCanvas.requestPaint()
                    }
                }
            }
        }

        Item {
            id: rippleAnim
            property real opacityVal: 0.85
            SequentialAnimation on opacityVal {
                loops: Animation.Infinite
                running: qZoneRoot.isActive
                NumberAnimation { to: 0.50; duration: 1100; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 0.95; duration: 1100; easing.type: Easing.InOutQuad }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: qZoneRoot.selected()
        }
    }

    // ========================================================
    // COMPONENT: Position D-Pad Key Button with Auto-Repeat & Chevrons
    // ========================================================
    component PositionKeyButton: Rectangle {
        id: pKeyRoot
        property string arrowType: "up" // "up" | "down" | "left" | "right"
        signal clicked()
        signal triggered()

        width: 88
        height: 60
        color: arrowBtnM.pressed ? "#1E88E5" : (arrowBtnM.containsMouse ? "#3A6C9B" : "#2E5B84")
        border.color: arrowBtnM.pressed ? "#80D8FF" : "#3F74A3"
        border.width: 1.5
        radius: 4

        Behavior on color { ColorAnimation { duration: 100 } }

        Timer {
            id: repeatTimer
            interval: 100
            repeat: true
            onTriggered: {
                pKeyRoot.clicked()
                pKeyRoot.triggered()
            }
        }

        Timer {
            id: initialDelayTimer
            interval: 350
            repeat: false
            onTriggered: repeatTimer.start()
        }

        Canvas {
            anchors.centerIn: parent
            width: 28
            height: 28
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = "#FFFFFF"
                ctx.lineWidth = 3.2
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                ctx.beginPath()
                if (pKeyRoot.arrowType === "up") {
                    ctx.moveTo(5, 18); ctx.lineTo(14, 9); ctx.lineTo(23, 18)
                } else if (pKeyRoot.arrowType === "down") {
                    ctx.moveTo(5, 10); ctx.lineTo(14, 19); ctx.lineTo(23, 10)
                } else if (pKeyRoot.arrowType === "left") {
                    ctx.moveTo(18, 5); ctx.lineTo(9, 14); ctx.lineTo(18, 23)
                } else if (pKeyRoot.arrowType === "right") {
                    ctx.moveTo(10, 5); ctx.lineTo(19, 14); ctx.lineTo(10, 23)
                }
                ctx.stroke()
            }
        }

        MouseArea {
            id: arrowBtnM
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: {
                pKeyRoot.clicked()
                pKeyRoot.triggered()
                initialDelayTimer.start()
            }
            onReleased: {
                initialDelayTimer.stop()
                repeatTimer.stop()
            }
            onCanceled: {
                initialDelayTimer.stop()
                repeatTimer.stop()
            }
        }
    }
}
