/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: DisplaySettingsScreen.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#05070B"

    signal backClicked()

    property string currentView: "main" // "main" | "scheduled_time" | "analogue_clock"
    property string selectedTab: "brightness" // "brightness" | "blue_light" | "screensaver"
    property bool menuOpen: false

    function resetToDefault() {
        currentView = "main"
        selectedTab = "brightness"
        menuOpen = false
    }

    // Temporary local state for time picker
    property int tempStartHour: systemController.scheduledStartHour
    property int tempStartMin: systemController.scheduledStartMinute
    property string tempStartAmPm: systemController.scheduledStartAmPm
    property int tempEndHour: systemController.scheduledEndHour
    property int tempEndMin: systemController.scheduledEndMinute
    property string tempEndAmPm: systemController.scheduledEndAmPm

    onCurrentViewChanged: {
        if (currentView === "scheduled_time") {
            tempStartHour = systemController.scheduledStartHour
            tempStartMin = systemController.scheduledStartMinute
            tempStartAmPm = systemController.scheduledStartAmPm
            tempEndHour = systemController.scheduledEndHour
            tempEndMin = systemController.scheduledEndMinute
            tempEndAmPm = systemController.scheduledEndAmPm
        }
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
                            if (root.currentView === "scheduled_time") return "Scheduled Time"
                            if (root.currentView === "analogue_clock") return "Analogue clock"
                            return "Display settings"
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

                    // 1. [Display Off] Button (visible in main view)
                    Rectangle {
                        width: 130
                        height: 40
                        color: dispOffMouse.pressed ? "#1E88E5" : (dispOffMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: dispOffMouse.pressed ? "#66D9FF" : "#3F74A3"
                        border.width: 1
                        radius: 3
                        visible: root.currentView === "main"

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Display Off"
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
                            onClicked: systemController.setDisplayOff(true)
                        }
                    }

                    // 2. [Menu] Button (visible in main view)
                    Rectangle {
                        width: 90
                        height: 40
                        color: menuMouse.pressed || root.menuOpen ? "#1E88E5" : (menuMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: menuMouse.pressed || root.menuOpen ? "#66D9FF" : "#3F74A3"
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

                    // 3. Back Arrow Button (↶)
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
                                if (root.currentView === "scheduled_time") {
                                    systemController.setScheduledTime(root.tempStartHour, root.tempStartMin, root.tempStartAmPm,
                                                                     root.tempEndHour, root.tempEndMin, root.tempEndAmPm)
                                    root.currentView = "main"
                                } else if (root.currentView === "analogue_clock") {
                                    root.currentView = "main"
                                } else {
                                    root.backClicked()
                                }
                            }
                        }
                    }
                }
            }
        }

        // ====================================================
        // 2. MAIN BODY AREA
        // ====================================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ------------------------------------------------
            // VIEW A: MAIN DISPLAY SETTINGS (Tabs + Panels)
            // ------------------------------------------------
            RowLayout {
                anchors.fill: parent
                spacing: 0
                visible: root.currentView === "main"

                // A1. LEFT SIDEBAR TABS (Width ~260px)
                Rectangle {
                    Layout.preferredWidth: 260
                    Layout.fillHeight: true
                    color: "#0B0E14"

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 1.5
                        color: "#1E222D"
                    }

                    Column {
                        anchors.fill: parent

                        // TAB 1: Brightness
                        Rectangle {
                            width: parent.width
                            height: 72
                            color: root.selectedTab === "brightness" ? "#C4E2FE" : (tab1Mouse.pressed ? Qt.rgba(1, 1, 1, 0.08) : (tab1Mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"))

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 24
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Brightness"
                                color: root.selectedTab === "brightness" ? "#0A1428" : "#FFFFFF"
                                font.pixelSize: 22
                                font.weight: root.selectedTab === "brightness" ? Font.Bold : Font.Normal
                                font.family: "Roboto"
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 1
                                color: "#1E222D"
                            }

                            MouseArea {
                                id: tab1Mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedTab = "brightness"
                            }
                        }

                        // TAB 2: Blue light
                        Rectangle {
                            width: parent.width
                            height: 72
                            color: root.selectedTab === "blue_light" ? "#C4E2FE" : (tab2Mouse.pressed ? Qt.rgba(1, 1, 1, 0.08) : (tab2Mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"))

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 24
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Blue light"
                                color: root.selectedTab === "blue_light" ? "#0A1428" : "#FFFFFF"
                                font.pixelSize: 22
                                font.weight: root.selectedTab === "blue_light" ? Font.Bold : Font.Normal
                                font.family: "Roboto"
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 1
                                color: "#1E222D"
                            }

                            MouseArea {
                                id: tab2Mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedTab = "blue_light"
                            }
                        }

                        // TAB 3: Screensaver
                        Rectangle {
                            width: parent.width
                            height: 72
                            color: root.selectedTab === "screensaver" ? "#C4E2FE" : (tab3Mouse.pressed ? Qt.rgba(1, 1, 1, 0.08) : (tab3Mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"))

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 24
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Screensaver"
                                color: root.selectedTab === "screensaver" ? "#0A1428" : "#FFFFFF"
                                font.pixelSize: 22
                                font.weight: root.selectedTab === "screensaver" ? Font.Bold : Font.Normal
                                font.family: "Roboto"
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 1
                                color: "#1E222D"
                            }

                            MouseArea {
                                id: tab3Mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedTab = "screensaver"
                            }
                        }
                    }
                }

                // A2. RIGHT CONTENT PANEL
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // ============================================
                    // PANEL 1: BRIGHTNESS (Matching Photo 1)
                    // ============================================
                    Item {
                        anchors.fill: parent
                        anchors.margins: 24
                        visible: root.selectedTab === "brightness"

                        Column {
                            anchors.fill: parent
                            spacing: 16

                            // Option 1: Automatic
                            Rectangle {
                                width: parent.width
                                height: 104
                                radius: 8
                                color: (systemController.brightnessMode === "automatic") ? "#EAF2FA" : "transparent"
                                border.color: (systemController.brightnessMode === "automatic") ? "#A4C6E5" : "#252E3E"
                                border.width: 1.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 20
                                    anchors.rightMargin: 20
                                    spacing: 16

                                    // Radio circle
                                    Rectangle {
                                        width: 26
                                        height: 26
                                        radius: 13
                                        color: "transparent"
                                        border.color: (systemController.brightnessMode === "automatic") ? "#1E88E5" : "#FFFFFF"
                                        border.width: 2

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 14
                                            height: 14
                                            radius: 7
                                            color: "#1E88E5"
                                            visible: (systemController.brightnessMode === "automatic")
                                        }
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: "Automatic"
                                            color: (systemController.brightnessMode === "automatic") ? "#0A1428" : "#FFFFFF"
                                            font.pixelSize: 22
                                            font.weight: Font.DemiBold
                                            font.family: "Roboto"
                                        }

                                        Text {
                                            width: 600
                                            wrapMode: Text.WordWrap
                                            text: "Adjusting the level of display illumination automatically, depending on whether the headlights are on or off."
                                            color: (systemController.brightnessMode === "automatic") ? "#3D5066" : "#A6B4C4"
                                            font.pixelSize: 15
                                            font.family: "Roboto"
                                        }
                                    }

                                    // Decorative watermarked light icon on right
                                    Rectangle {
                                        width: 48
                                        height: 48
                                        radius: 6
                                        color: Qt.rgba(0.2, 0.4, 0.6, 0.15)
                                        border.color: Qt.rgba(0.4, 0.6, 0.8, 0.25)
                                        border.width: 1

                                        Image {
                                            anchors.centerIn: parent
                                            width: 28
                                            height: 28
                                            source: "qrc:/assets/ui/icon_display.png"
                                            fillMode: Image.PreserveAspectFit
                                            opacity: 0.6
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: systemController.setBrightnessMode("automatic")
                                }
                            }

                            // Option 2: Manual (Highlighted Card in Photo 1)
                            Rectangle {
                                width: parent.width
                                height: 104
                                radius: 8
                                color: (systemController.brightnessMode === "manual") ? "#EAF2FA" : "transparent"
                                border.color: (systemController.brightnessMode === "manual") ? "#A4C6E5" : "#252E3E"
                                border.width: 1.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 20
                                    anchors.rightMargin: 20
                                    spacing: 16

                                    // Radio circle
                                    Rectangle {
                                        width: 26
                                        height: 26
                                        radius: 13
                                        color: "transparent"
                                        border.color: (systemController.brightnessMode === "manual") ? "#1E88E5" : "#FFFFFF"
                                        border.width: 2

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 14
                                            height: 14
                                            radius: 7
                                            color: "#1E88E5"
                                            visible: (systemController.brightnessMode === "manual")
                                        }
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: "Manual"
                                            color: (systemController.brightnessMode === "manual") ? "#0A1428" : "#FFFFFF"
                                            font.pixelSize: 22
                                            font.weight: Font.DemiBold
                                            font.family: "Roboto"
                                        }

                                        Text {
                                            width: 600
                                            wrapMode: Text.WordWrap
                                            text: "The screen brightness set by the user is maintained regardless of outside brightness."
                                            color: (systemController.brightnessMode === "manual") ? "#006699" : "#A6B4C4"
                                            font.pixelSize: 15
                                            font.family: "Roboto"
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: systemController.setBrightnessMode("manual")
                                }
                            }

                            Item { height: 16; width: 1 }

                            // Slider Row [ - ] -------- [ 30 ] -------- [ + ]
                            RowLayout {
                                width: parent.width
                                spacing: 16

                                // [ - ] Button
                                Rectangle {
                                    width: 72
                                    height: 44
                                    radius: 3
                                    color: bMinusMouse.pressed ? "#1E88E5" : (bMinusMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                                    border.color: bMinusMouse.pressed ? "#66D9FF" : "#3F74A3"
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "−"
                                        color: "#FFFFFF"
                                        font.pixelSize: 26
                                        font.weight: Font.Bold
                                    }

                                    MouseArea {
                                        id: bMinusMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: systemController.adjustBrightness(-1)
                                    }
                                }

                                // Interactive Slider Bar with movable Value Box
                                Item {
                                    id: brightSliderTrack
                                    Layout.fillWidth: true
                                    height: 44

                                    // Background Track
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: 4
                                        color: "#2C3B4E"
                                        radius: 2
                                    }

                                    // Active cyan/blue progress fill
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        width: (brightThumb.x + brightThumb.width / 2)
                                        height: 4
                                        color: "#389BFF"
                                        radius: 2
                                    }

                                    // Movable Value Box (e.g., [ 30 ])
                                    Rectangle {
                                        id: brightThumb
                                        width: 58
                                        height: 34
                                        radius: 3
                                        color: "#FFFFFF"
                                        border.color: "#B4C8D8"
                                        border.width: 1
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: {
                                            var pct = (systemController.brightness - 1) / (60 - 1)
                                            return Math.max(0, Math.min(brightSliderTrack.width - width, pct * (brightSliderTrack.width - width)))
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: systemController.brightness
                                            color: "#0A1428"
                                            font.pixelSize: 20
                                            font.weight: Font.Bold
                                            font.family: "Roboto"
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        function updatePos(mouse) {
                                            var ratio = Math.max(0, Math.min(1, mouse.x / brightSliderTrack.width))
                                            var val = Math.round(1 + ratio * (60 - 1))
                                            systemController.setBrightness(val)
                                        }
                                        onPressed: mouse => updatePos(mouse)
                                        onPositionChanged: mouse => { if (pressed) updatePos(mouse) }
                                    }
                                }

                                // [ + ] Button
                                Rectangle {
                                    width: 72
                                    height: 44
                                    radius: 3
                                    color: bPlusMouse.pressed ? "#1E88E5" : (bPlusMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                                    border.color: bPlusMouse.pressed ? "#66D9FF" : "#3F74A3"
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "+"
                                        color: "#FFFFFF"
                                        font.pixelSize: 26
                                        font.weight: Font.Bold
                                    }

                                    MouseArea {
                                        id: bPlusMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: systemController.adjustBrightness(1)
                                    }
                                }
                            }
                        }
                    }

                    // ============================================
                    // PANEL 2: BLUE LIGHT (Matching Photos 2, 3, 4)
                    // ============================================
                    Item {
                        anchors.fill: parent
                        anchors.margins: 24
                        visible: root.selectedTab === "blue_light"

                        Column {
                            anchors.fill: parent
                            spacing: 18

                            // 1. Blue light filter Checkbox Row
                            Rectangle {
                                width: parent.width
                                height: 76
                                color: "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 16

                                    // Square Checkbox
                                    Rectangle {
                                        width: 26
                                        height: 26
                                        radius: 3
                                        color: systemController.blueLightFilterEnabled ? "#389BFF" : "transparent"
                                        border.color: systemController.blueLightFilterEnabled ? "#389BFF" : "#8BA0B2"
                                        border.width: 2

                                        Text {
                                            anchors.centerIn: parent
                                            text: "✓"
                                            color: "#FFFFFF"
                                            font.pixelSize: 18
                                            font.weight: Font.Bold
                                            visible: systemController.blueLightFilterEnabled
                                        }
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        Text {
                                            text: "Blue light filter"
                                            color: "#FFFFFF"
                                            font.pixelSize: 22
                                            font.weight: Font.DemiBold
                                            font.family: "Roboto"
                                        }

                                        Text {
                                            width: 620
                                            wrapMode: Text.WordWrap
                                            text: "Reduce eye strain by limiting the amount of blue light emitted when outside brightness is low."
                                            color: "#A6B4C4"
                                            font.pixelSize: 15
                                            font.family: "Roboto"
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: systemController.setBlueLightFilterEnabled(!systemController.blueLightFilterEnabled)
                                }
                            }

                            // 2. Warmth Slider (Photos 2 & 3: [ - ] === [ 1 / 9 ] === [ + ] with Less warm / More warm)
                            Item {
                                width: parent.width
                                height: 76
                                opacity: systemController.blueLightFilterEnabled ? 1.0 : 0.45

                                Column {
                                    anchors.fill: parent
                                    spacing: 6

                                    RowLayout {
                                        width: parent.width
                                        spacing: 16

                                        // [ - ] Button
                                        Rectangle {
                                            width: 72
                                            height: 44
                                            radius: 3
                                            color: wMinusMouse.pressed ? "#1E88E5" : (wMinusMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                                            border.color: wMinusMouse.pressed ? "#66D9FF" : "#3F74A3"
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: "−"
                                                color: "#FFFFFF"
                                                font.pixelSize: 26
                                                font.weight: Font.Bold
                                            }

                                            MouseArea {
                                                id: wMinusMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: systemController.adjustBlueLightWarmth(-1)
                                            }
                                        }

                                        // Warmth Slider Track
                                        Item {
                                            id: warmthTrack
                                            Layout.fillWidth: true
                                            height: 44

                                            // Background bar
                                            Rectangle {
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                height: 4
                                                color: "#2C3B4E"
                                                radius: 2
                                            }

                                            // 10 subtle tick marks
                                            Row {
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                layoutDirection: Qt.LeftToRight

                                                Repeater {
                                                    model: 10
                                                    Item {
                                                        width: warmthTrack.width / 9
                                                        height: 8
                                                        Rectangle {
                                                            anchors.centerIn: parent
                                                            width: 2
                                                            height: 8
                                                            color: "#3A4B5D"
                                                        }
                                                    }
                                                }
                                            }

                                            // Active filled bar
                                            Rectangle {
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.left: parent.left
                                                width: (warmthThumb.x + warmthThumb.width / 2)
                                                height: 4
                                                color: "#389BFF"
                                                radius: 2
                                            }

                                            // Thumb Value Box
                                            Rectangle {
                                                id: warmthThumb
                                                width: 58
                                                height: 34
                                                radius: 3
                                                color: "#FFFFFF"
                                                border.color: "#B4C8D8"
                                                border.width: 1
                                                anchors.verticalCenter: parent.verticalCenter
                                                x: {
                                                    var pct = (systemController.blueLightWarmth - 1) / (10 - 1)
                                                    return Math.max(0, Math.min(warmthTrack.width - width, pct * (warmthTrack.width - width)))
                                                }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: systemController.blueLightWarmth
                                                    color: "#389BFF"
                                                    font.pixelSize: 20
                                                    font.weight: Font.Bold
                                                    font.family: "Roboto"
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                function updateWarmth(mouse) {
                                                    var ratio = Math.max(0, Math.min(1, mouse.x / warmthTrack.width))
                                                    var val = Math.round(1 + ratio * (10 - 1))
                                                    systemController.setBlueLightWarmth(val)
                                                }
                                                onPressed: mouse => updateWarmth(mouse)
                                                onPositionChanged: mouse => { if (pressed) updateWarmth(mouse) }
                                            }
                                        }

                                        // [ + ] Button
                                        Rectangle {
                                            width: 72
                                            height: 44
                                            radius: 3
                                            color: wPlusMouse.pressed ? "#1E88E5" : (wPlusMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                                            border.color: wPlusMouse.pressed ? "#66D9FF" : "#3F74A3"
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: "+"
                                                color: "#FFFFFF"
                                                font.pixelSize: 26
                                                font.weight: Font.Bold
                                            }

                                            MouseArea {
                                                id: wPlusMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: systemController.adjustBlueLightWarmth(1)
                                            }
                                        }
                                    }

                                    // Less warm / More warm Labels
                                    Item {
                                        width: parent.width
                                        height: 24

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 88
                                            text: "Less warm"
                                            color: "#A6B4C4"
                                            font.pixelSize: 17
                                            font.family: "Roboto"
                                        }

                                        Text {
                                            anchors.right: parent.right
                                            anchors.rightMargin: 88
                                            text: "More warm"
                                            color: "#A6B4C4"
                                            font.pixelSize: 17
                                            font.family: "Roboto"
                                        }
                                    }
                                }
                            }

                            // 3. Section: Set time
                            Item {
                                width: parent.width
                                height: 28
                                Text {
                                    text: "Set time"
                                    color: "#FFFFFF"
                                    font.pixelSize: 22
                                    font.weight: Font.DemiBold
                                    font.family: "Roboto"
                                }
                            }

                            // 4. Checkbox: Scheduled Time
                            Rectangle {
                                width: parent.width
                                height: 60
                                color: "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 16

                                    Rectangle {
                                        width: 26
                                        height: 26
                                        radius: 3
                                        color: systemController.blueLightScheduled ? "#389BFF" : "transparent"
                                        border.color: systemController.blueLightScheduled ? "#389BFF" : "#8BA0B2"
                                        border.width: 2

                                        Text {
                                            anchors.centerIn: parent
                                            text: "✓"
                                            color: "#FFFFFF"
                                            font.pixelSize: 18
                                            font.weight: Font.Bold
                                            visible: systemController.blueLightScheduled
                                        }
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        Text {
                                            text: "Scheduled Time"
                                            color: "#FFFFFF"
                                            font.pixelSize: 22
                                            font.weight: Font.DemiBold
                                            font.family: "Roboto"
                                        }

                                        Text {
                                            text: "Activate blue light filter during custom time set."
                                            color: "#A6B4C4"
                                            font.pixelSize: 15
                                            font.family: "Roboto"
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: systemController.setBlueLightScheduled(!systemController.blueLightScheduled)
                                }
                            }

                            // 5. Time Summary Row with Right Arrow (Photo 4)
                            Rectangle {
                                width: parent.width
                                height: 80
                                radius: 6
                                visible: systemController.blueLightScheduled
                                color: schedRowMouse.pressed ? Qt.rgba(1, 1, 1, 0.08) : (schedRowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 42
                                    anchors.rightMargin: 16
                                    spacing: 24

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Row {
                                            spacing: 24
                                            Text {
                                                width: 140
                                                text: "Set start time"
                                                color: "#FFFFFF"
                                                font.pixelSize: 19
                                                font.family: "Roboto"
                                            }
                                            Text {
                                                text: systemController.scheduledStartHour + ":" + (systemController.scheduledStartMinute < 10 ? "0" : "") + systemController.scheduledStartMinute + " " + systemController.scheduledStartAmPm
                                                color: "#FFFFFF"
                                                font.pixelSize: 19
                                                font.weight: Font.DemiBold
                                                font.family: "Roboto"
                                            }
                                        }

                                        Row {
                                            spacing: 24
                                            Text {
                                                width: 140
                                                text: "Set end time"
                                                color: "#FFFFFF"
                                                font.pixelSize: 19
                                                font.family: "Roboto"
                                            }
                                            Text {
                                                text: systemController.scheduledEndHour + ":" + (systemController.scheduledEndMinute < 10 ? "0" : "") + systemController.scheduledEndMinute + " " + systemController.scheduledEndAmPm
                                                color: "#FFFFFF"
                                                font.pixelSize: 19
                                                font.weight: Font.DemiBold
                                                font.family: "Roboto"
                                            }
                                        }
                                    }

                                    // Right triangle arrow (▶)
                                    Text {
                                        text: "▶"
                                        color: "#FFFFFF"
                                        font.pixelSize: 22
                                    }
                                }

                                MouseArea {
                                    id: schedRowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.currentView = "scheduled_time"
                                }
                            }
                        }
                    }

                    // ============================================
                    // ============================================
                    // PANEL 3: SCREENSAVER (Matching Photos 1 & 2)
                    // ============================================
                    Item {
                        anchors.fill: parent
                        anchors.margins: 24
                        visible: root.selectedTab === "screensaver"

                        Column {
                            anchors.fill: parent
                            spacing: 16

                            // Option 1: Analogue clock (Photo 2)
                            Rectangle {
                                width: parent.width
                                height: 76
                                radius: 8
                                color: (systemController.screensaverType === "analog") ? "#EAF2FA" : "transparent"
                                border.color: (systemController.screensaverType === "analog") ? "#A4C6E5" : "#252E3E"
                                border.width: 1.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 20
                                    anchors.rightMargin: 16
                                    spacing: 16

                                    Rectangle {
                                        width: 26
                                        height: 26
                                        radius: 13
                                        color: "transparent"
                                        border.color: (systemController.screensaverType === "analog") ? "#1E88E5" : "#FFFFFF"
                                        border.width: 2

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 14
                                            height: 14
                                            radius: 7
                                            color: "#1E88E5"
                                            visible: (systemController.screensaverType === "analog")
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Analogue clock"
                                        color: (systemController.screensaverType === "analog") ? "#0A1428" : "#FFFFFF"
                                        font.pixelSize: 22
                                        font.weight: Font.DemiBold
                                        font.family: "Roboto"
                                    }

                                    // Dedicated Gear Button [ ⚙ ] (Photo 2)
                                    Rectangle {
                                        width: 48
                                        height: 48
                                        radius: 4
                                        visible: (systemController.screensaverType === "analog")
                                        color: gearMouse.pressed ? "#1E88E5" : (gearMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                                        border.color: gearMouse.pressed ? "#66D9FF" : "#3F74A3"
                                        border.width: 1

                                        Image {
                                            anchors.centerIn: parent
                                            width: 26
                                            height: 26
                                            source: "qrc:/assets/ui/icon_settings_hdr.png"
                                            fillMode: Image.PreserveAspectFit
                                            smooth: true
                                            mipmap: true
                                        }

                                        MouseArea {
                                            id: gearMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.currentView = "analogue_clock"
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.rightMargin: (systemController.screensaverType === "analog") ? 70 : 0
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: systemController.setScreensaverType("analog")
                                }
                            }

                            // Option 2: Digital clock (Photo 1)
                            Rectangle {
                                width: parent.width
                                height: 76
                                radius: 8
                                color: (systemController.screensaverType === "digital") ? "#EAF2FA" : "transparent"
                                border.color: (systemController.screensaverType === "digital") ? "#A4C6E5" : "#252E3E"
                                border.width: 1.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 20
                                    anchors.rightMargin: 16
                                    spacing: 16

                                    Rectangle {
                                        width: 26
                                        height: 26
                                        radius: 13
                                        color: "transparent"
                                        border.color: (systemController.screensaverType === "digital") ? "#1E88E5" : "#FFFFFF"
                                        border.width: 2

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 14
                                            height: 14
                                            radius: 7
                                            color: "#1E88E5"
                                            visible: (systemController.screensaverType === "digital")
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Digital clock"
                                        color: (systemController.screensaverType === "digital") ? "#0A1428" : "#FFFFFF"
                                        font.pixelSize: 22
                                        font.weight: Font.DemiBold
                                        font.family: "Roboto"
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: systemController.setScreensaverType("digital")
                                }
                            }

                            // Option 3: None
                            Rectangle {
                                width: parent.width
                                height: 76
                                radius: 8
                                color: (systemController.screensaverType === "none") ? "#EAF2FA" : "transparent"
                                border.color: (systemController.screensaverType === "none") ? "#A4C6E5" : "#252E3E"
                                border.width: 1.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 20
                                    anchors.rightMargin: 16
                                    spacing: 16

                                    Rectangle {
                                        width: 26
                                        height: 26
                                        radius: 13
                                        color: "transparent"
                                        border.color: (systemController.screensaverType === "none") ? "#1E88E5" : "#FFFFFF"
                                        border.width: 2

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 14
                                            height: 14
                                            radius: 7
                                            color: "#1E88E5"
                                            visible: (systemController.screensaverType === "none")
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: "None"
                                        color: (systemController.screensaverType === "none") ? "#0A1428" : "#FFFFFF"
                                        font.pixelSize: 22
                                        font.weight: Font.DemiBold
                                        font.family: "Roboto"
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: systemController.setScreensaverType("none")
                                }
                            }

                            Item { height: 24; width: 1 }

                            // Verbatim Description below options (Photos 1 & 2)
                            Text {
                                width: parent.width
                                wrapMode: Text.WordWrap
                                font.pixelSize: 18
                                font.family: "Roboto"
                                color: "#A6B4C4"
                                text: {
                                    if (systemController.screensaverType === "analog")
                                        return "When the screen or power is turned off, the analogue clock and date are displayed."
                                    if (systemController.screensaverType === "digital")
                                        return "When the screen or power is turned off, the digital clock and date are displayed."
                                    return "When the screen or power is turned off, the screen remains blank."
                                }
                            }
                        }
                    }
                }
            }

            // ------------------------------------------------
            // VIEW B: SCHEDULED TIME PICKER (Matching Photo 5)
            // ------------------------------------------------
            Item {
                anchors.fill: parent
                visible: root.currentView === "scheduled_time"

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 60

                    // ========================================
                    // 1. LEFT COLUMN: Set start time
                    // ========================================
                    Column {
                        spacing: 20
                        Layout.alignment: Qt.AlignHCenter

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Set start time"
                            color: "#FFFFFF"
                            font.pixelSize: 24
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        Row {
                            spacing: 8
                            anchors.horizontalCenter: parent.horizontalCenter

                            // Spinner 1: Hour
                            Column {
                                spacing: 6
                                Rectangle {
                                    width: 86; height: 46; radius: 3
                                    color: sHUpMouse.pressed ? "#1E88E5" : (sHUpMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                                    border.color: sHUpMouse.pressed ? "#66D9FF" : "#3F74A3"; border.width: 1
                                    Text { anchors.centerIn: parent; text: "▲"; color: "#FFFFFF"; font.pixelSize: 18 }
                                    MouseArea {
                                        id: sHUpMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.tempStartHour = (root.tempStartHour % 12) + 1
                                    }
                                }
                                Rectangle {
                                    width: 86; height: 56; radius: 3; color: "#FFFFFF"
                                    Column {
                                        anchors.centerIn: parent
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Hour"; color: "#1D5482"; font.pixelSize: 13 }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.tempStartHour; color: "#0A1428"; font.pixelSize: 24; font.weight: Font.Bold }
                                    }
                                }
                                Rectangle {
                                    width: 86; height: 46; radius: 3
                                    color: sHDnMouse.pressed ? "#1E88E5" : (sHDnMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                                    border.color: sHDnMouse.pressed ? "#66D9FF" : "#3F74A3"; border.width: 1
                                    Text { anchors.centerIn: parent; text: "▼"; color: "#FFFFFF"; font.pixelSize: 18 }
                                    MouseArea {
                                        id: sHDnMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.tempStartHour = (root.tempStartHour === 1) ? 12 : (root.tempStartHour - 1)
                                    }
                                }
                            }

                            // Separator Colon
                            Item {
                                width: 14; height: 160
                                Text {
                                    anchors.centerIn: parent
                                    text: ":"
                                    color: "#FFFFFF"
                                    font.pixelSize: 28
                                    font.weight: Font.Bold
                                }
                            }

                            // Spinner 2: Minute
                            Column {
                                spacing: 6
                                Rectangle {
                                    width: 86; height: 46; radius: 3
                                    color: sMUpMouse.pressed ? "#1E88E5" : (sMUpMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                                    border.color: sMUpMouse.pressed ? "#66D9FF" : "#3F74A3"; border.width: 1
                                    Text { anchors.centerIn: parent; text: "▲"; color: "#FFFFFF"; font.pixelSize: 18 }
                                    MouseArea {
                                        id: sMUpMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.tempStartMin = (root.tempStartMin + 5) % 60
                                    }
                                }
                                Rectangle {
                                    width: 86; height: 56; radius: 3; color: "#FFFFFF"
                                    Column {
                                        anchors.centerIn: parent
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "min"; color: "#1D5482"; font.pixelSize: 13 }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: (root.tempStartMin < 10 ? "0" : "") + root.tempStartMin; color: "#0A1428"; font.pixelSize: 24; font.weight: Font.Bold }
                                    }
                                }
                                Rectangle {
                                    width: 86; height: 46; radius: 3
                                    color: sMDnMouse.pressed ? "#1E88E5" : (sMDnMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                                    border.color: sMDnMouse.pressed ? "#66D9FF" : "#3F74A3"; border.width: 1
                                    Text { anchors.centerIn: parent; text: "▼"; color: "#FFFFFF"; font.pixelSize: 18 }
                                    MouseArea {
                                        id: sMDnMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.tempStartMin = (root.tempStartMin === 0) ? 55 : (root.tempStartMin - 5)
                                    }
                                }
                            }

                            // Spinner 3: AM / PM
                            Column {
                                spacing: 6
                                Rectangle {
                                    width: 86; height: 46; radius: 3
                                    color: sAPUpMouse.pressed ? "#1E88E5" : (sAPUpMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                                    border.color: sAPUpMouse.pressed ? "#66D9FF" : "#3F74A3"; border.width: 1
                                    Text { anchors.centerIn: parent; text: "▲"; color: "#FFFFFF"; font.pixelSize: 18 }
                                    MouseArea {
                                        id: sAPUpMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.tempStartAmPm = (root.tempStartAmPm === "AM") ? "PM" : "AM"
                                    }
                                }
                                Rectangle {
                                    width: 86; height: 56; radius: 3; color: "#FFFFFF"
                                    Text {
                                        anchors.centerIn: parent
                                        text: root.tempStartAmPm
                                        color: "#0A1428"
                                        font.pixelSize: 24
                                        font.weight: Font.Bold
                                    }
                                }
                                Rectangle {
                                    width: 86; height: 46; radius: 3
                                    color: sAPDnMouse.pressed ? "#1E88E5" : (sAPDnMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                                    border.color: sAPDnMouse.pressed ? "#66D9FF" : "#3F74A3"; border.width: 1
                                    Text { anchors.centerIn: parent; text: "▼"; color: "#FFFFFF"; font.pixelSize: 18 }
                                    MouseArea {
                                        id: sAPDnMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.tempStartAmPm = (root.tempStartAmPm === "AM") ? "PM" : "AM"
                                    }
                                }
                            }
                        }
                    }

                    // ========================================
                    // 2. RIGHT COLUMN: Set end time
                    // ========================================
                    Column {
                        spacing: 20
                        Layout.alignment: Qt.AlignHCenter

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Set end time"
                            color: "#FFFFFF"
                            font.pixelSize: 24
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        Row {
                            spacing: 8
                            anchors.horizontalCenter: parent.horizontalCenter

                            // Spinner 1: Hour
                            Column {
                                spacing: 6
                                Rectangle {
                                    width: 86; height: 46; radius: 3
                                    color: eHUpMouse.pressed ? "#1E88E5" : (eHUpMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                                    border.color: eHUpMouse.pressed ? "#66D9FF" : "#3F74A3"; border.width: 1
                                    Text { anchors.centerIn: parent; text: "▲"; color: "#FFFFFF"; font.pixelSize: 18 }
                                    MouseArea {
                                        id: eHUpMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.tempEndHour = (root.tempEndHour % 12) + 1
                                    }
                                }
                                Rectangle {
                                    width: 86; height: 56; radius: 3; color: "#FFFFFF"
                                    Column {
                                        anchors.centerIn: parent
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Hour"; color: "#1D5482"; font.pixelSize: 13 }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.tempEndHour; color: "#0A1428"; font.pixelSize: 24; font.weight: Font.Bold }
                                    }
                                }
                                Rectangle {
                                    width: 86; height: 46; radius: 3
                                    color: eHDnMouse.pressed ? "#1E88E5" : (eHDnMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                                    border.color: eHDnMouse.pressed ? "#66D9FF" : "#3F74A3"; border.width: 1
                                    Text { anchors.centerIn: parent; text: "▼"; color: "#FFFFFF"; font.pixelSize: 18 }
                                    MouseArea {
                                        id: eHDnMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.tempEndHour = (root.tempEndHour === 1) ? 12 : (root.tempEndHour - 1)
                                    }
                                }
                            }

                            // Separator Colon
                            Item {
                                width: 14; height: 160
                                Text {
                                    anchors.centerIn: parent
                                    text: ":"
                                    color: "#FFFFFF"
                                    font.pixelSize: 28
                                    font.weight: Font.Bold
                                }
                            }

                            // Spinner 2: Minute
                            Column {
                                spacing: 6
                                Rectangle {
                                    width: 86; height: 46; radius: 3
                                    color: eMUpMouse.pressed ? "#1E88E5" : (eMUpMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                                    border.color: eMUpMouse.pressed ? "#66D9FF" : "#3F74A3"; border.width: 1
                                    Text { anchors.centerIn: parent; text: "▲"; color: "#FFFFFF"; font.pixelSize: 18 }
                                    MouseArea {
                                        id: eMUpMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.tempEndMin = (root.tempEndMin + 5) % 60
                                    }
                                }
                                Rectangle {
                                    width: 86; height: 56; radius: 3; color: "#FFFFFF"
                                    Column {
                                        anchors.centerIn: parent
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "min"; color: "#1D5482"; font.pixelSize: 13 }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: (root.tempEndMin < 10 ? "0" : "") + root.tempEndMin; color: "#0A1428"; font.pixelSize: 24; font.weight: Font.Bold }
                                    }
                                }
                                Rectangle {
                                    width: 86; height: 46; radius: 3
                                    color: eMDnMouse.pressed ? "#1E88E5" : (eMDnMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                                    border.color: eMDnMouse.pressed ? "#66D9FF" : "#3F74A3"; border.width: 1
                                    Text { anchors.centerIn: parent; text: "▼"; color: "#FFFFFF"; font.pixelSize: 18 }
                                    MouseArea {
                                        id: eMDnMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.tempEndMin = (root.tempEndMin === 0) ? 55 : (root.tempEndMin - 5)
                                    }
                                }
                            }

                            // Spinner 3: AM / PM
                            Column {
                                spacing: 6
                                Rectangle {
                                    width: 86; height: 46; radius: 3
                                    color: eAPUpMouse.pressed ? "#1E88E5" : (eAPUpMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                                    border.color: eAPUpMouse.pressed ? "#66D9FF" : "#3F74A3"; border.width: 1
                                    Text { anchors.centerIn: parent; text: "▲"; color: "#FFFFFF"; font.pixelSize: 18 }
                                    MouseArea {
                                        id: eAPUpMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.tempEndAmPm = (root.tempEndAmPm === "AM") ? "PM" : "AM"
                                    }
                                }
                                Rectangle {
                                    width: 86; height: 56; radius: 3; color: "#FFFFFF"
                                    Text {
                                        anchors.centerIn: parent
                                        text: root.tempEndAmPm
                                        color: "#0A1428"
                                        font.pixelSize: 24
                                        font.weight: Font.Bold
                                    }
                                }
                                Rectangle {
                                    width: 86; height: 46; radius: 3
                                    color: eAPDnMouse.pressed ? "#1E88E5" : (eAPDnMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                                    border.color: eAPDnMouse.pressed ? "#66D9FF" : "#3F74A3"; border.width: 1
                                    Text { anchors.centerIn: parent; text: "▼"; color: "#FFFFFF"; font.pixelSize: 18 }
                                    MouseArea {
                                        id: eAPDnMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.tempEndAmPm = (root.tempEndAmPm === "AM") ? "PM" : "AM"
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ------------------------------------------------
            // VIEW C: ANALOGUE CLOCK SELECTOR (Matching Photos 3 & 4)
            // ------------------------------------------------
            Item {
                id: clockSelectorView
                anchors.fill: parent
                visible: root.currentView === "analogue_clock"

                property int clockPage: (systemController.analogueClockIndex <= 4) ? 0 : 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: 20
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    anchors.bottomMargin: 16
                    spacing: 16

                    // 4 Clock Cards in a Row (Page 1: 1..4, Page 2: 5..8)
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 310
                        spacing: 16

                        Repeater {
                            model: 4
                            Rectangle {
                                id: cardRect
                                readonly property int clockNum: clockSelectorView.clockPage * 4 + index + 1
                                readonly property bool isSelected: systemController.analogueClockIndex === clockNum

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 4
                                color: isSelected ? "#EAF2FA" : "#14202E"
                                border.color: isSelected ? "#389BFF" : "#243447"
                                border.width: isSelected ? 2 : 1

                                Behavior on color { ColorAnimation { duration: 150 } }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.topMargin: 24
                                    anchors.bottomMargin: 16
                                    spacing: 16

                                    // Clock Face Preview
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        AnalogueClockFace {
                                            anchors.centerIn: parent
                                            width: 155
                                            height: 155
                                            clockStyle: cardRect.clockNum
                                        }
                                    }

                                    // Bottom Label & Radio Circle (Matching Photos 3 & 4)
                                    Row {
                                        Layout.alignment: Qt.AlignHCenter
                                        spacing: 12

                                        // Radio Circle
                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 24
                                            height: 24
                                            radius: 12
                                            color: cardRect.isSelected ? "#FFFFFF" : "transparent"
                                            border.color: cardRect.isSelected ? "#1E88E5" : "#FFFFFF"
                                            border.width: 2

                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: 12
                                                height: 12
                                                radius: 6
                                                color: "#1E88E5"
                                                visible: cardRect.isSelected
                                            }
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "Clock " + cardRect.clockNum
                                            color: cardRect.isSelected ? "#0A1428" : "#FFFFFF"
                                            font.pixelSize: 20
                                            font.weight: cardRect.isSelected ? Font.Bold : Font.DemiBold
                                            font.family: "Roboto"
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    property real startX: 0
                                    onPressed: function(mouse) { startX = mouse.x }
                                    onReleased: function(mouse) {
                                        var diff = mouse.x - startX
                                        if (diff < -35 && clockSelectorView.clockPage === 0) {
                                            clockSelectorView.clockPage = 1
                                        } else if (diff > 35 && clockSelectorView.clockPage === 1) {
                                            clockSelectorView.clockPage = 0
                                        } else if (Math.abs(diff) <= 8) {
                                            systemController.setAnalogueClockIndex(cardRect.clockNum)
                                            systemController.setScreensaverType("analog")
                                        }
                                    }
                                    onWheel: function(wheel) {
                                        if (wheel.angleDelta.x < -20 || wheel.angleDelta.y < -20) {
                                            clockSelectorView.clockPage = 1
                                        } else if (wheel.angleDelta.x > 20 || wheel.angleDelta.y > 20) {
                                            clockSelectorView.clockPage = 0
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Bottom Page Indicators (__  --) matching Photos 3 & 4
                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 10

                        // Page 1 Indicator
                        Rectangle {
                            width: (clockSelectorView.clockPage === 0) ? 32 : 16
                            height: 4
                            radius: 2
                            color: (clockSelectorView.clockPage === 0) ? "#FFFFFF" : "#324458"
                            Behavior on width { NumberAnimation { duration: 150 } }
                            Behavior on color { ColorAnimation { duration: 150 } }

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -10
                                cursorShape: Qt.PointingHandCursor
                                onClicked: clockSelectorView.clockPage = 0
                            }
                        }

                        // Page 2 Indicator
                        Rectangle {
                            width: (clockSelectorView.clockPage === 1) ? 32 : 16
                            height: 4
                            radius: 2
                            color: (clockSelectorView.clockPage === 1) ? "#FFFFFF" : "#324458"
                            Behavior on width { NumberAnimation { duration: 150 } }
                            Behavior on color { ColorAnimation { duration: 150 } }

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -10
                                cursorShape: Qt.PointingHandCursor
                                onClicked: clockSelectorView.clockPage = 1
                            }
                        }
                    }
                }

                // Left chevron for clock selector
                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 56
                    radius: 18
                    color: clkPrevMouse.pressed ? "#33FFFFFF" : (clkPrevMouse.containsMouse ? "#22FFFFFF" : "#12FFFFFF")
                    visible: clockSelectorView.clockPage === 1
                    z: 10
                    Text { anchors.centerIn: parent; text: "❮"; color: "#FFFFFF"; font.pixelSize: 18 }
                    MouseArea {
                        id: clkPrevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: clockSelectorView.clockPage = 0
                    }
                }

                // Right chevron for clock selector
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 56
                    radius: 18
                    color: clkNextMouse.pressed ? "#33FFFFFF" : (clkNextMouse.containsMouse ? "#22FFFFFF" : "#12FFFFFF")
                    visible: clockSelectorView.clockPage === 0
                    z: 10
                    Text { anchors.centerIn: parent; text: "❯"; color: "#FFFFFF"; font.pixelSize: 18 }
                    MouseArea {
                        id: clkNextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: clockSelectorView.clockPage = 1
                    }
                }
            }
        }
    }

    // ========================================================
    // MENU DROPDOWN
    // ========================================================
    Rectangle {
        id: menuPopup
        anchors.top: parent.top
        anchors.topMargin: 56
        anchors.right: parent.right
        anchors.rightMargin: 90
        width: 220
        height: 110
        color: "#182230"
        border.color: "#3F74A3"
        border.width: 1
        radius: 4
        z: 40
        visible: root.menuOpen

        Column {
            anchors.fill: parent
            anchors.margins: 4

            // Item 1: Reset
            Rectangle {
                width: parent.width
                height: 50
                color: rstMouse.pressed ? "#1E88E5" : (rstMouse.containsMouse ? "#2A3A50" : "transparent")
                radius: 3
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Reset"
                    color: "#FFFFFF"
                    font.pixelSize: 18
                    font.family: "Roboto"
                }
                MouseArea {
                    id: rstMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        systemController.setBrightnessMode("manual")
                        systemController.setBrightness(30)
                        systemController.setBlueLightFilterEnabled(false)
                        systemController.setBlueLightWarmth(1)
                        systemController.setBlueLightScheduled(false)
                        systemController.setScheduledTime(9, 0, "PM", 6, 0, "AM")
                        systemController.setScreensaverType("analog")
                        root.menuOpen = false
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#2C3E54"
            }

            // Item 2: Web manual
            Rectangle {
                width: parent.width
                height: 50
                color: manMouse.pressed ? "#1E88E5" : (manMouse.containsMouse ? "#2A3A50" : "transparent")
                radius: 3
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Web manual"
                    color: "#FFFFFF"
                    font.pixelSize: 18
                    font.family: "Roboto"
                }
                MouseArea {
                    id: manMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.menuOpen = false
                        systemController.navigateTo("manual")
                    }
                }
            }
        }
    }

    // Dismiss menu popup on tap outside
    MouseArea {
        anchors.fill: parent
        z: 35
        visible: root.menuOpen
        onClicked: root.menuOpen = false
    }
}
