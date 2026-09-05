/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: ButtonSettingsScreen.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#05070B"

    signal backClicked()
    signal manualClicked()

    property string selectedTab: "custom_audio" // "custom_audio" | "custom_steering" | "mode_steering" | "seek_steering"
    property bool menuOpen: false

    function resetToDefault() {
        selectedTab = "custom_audio"
        menuOpen = false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ====================================================
        // 1. SUB-HEADER BAR ("Button settings" + Menu + Back)
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

                // Left: Gear icon + Title
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
                        text: "Button settings"
                        color: "#FFFFFF"
                        font.pixelSize: 24
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }
                }

                Item { Layout.fillWidth: true }

                // Right: Menu button + Back button
                Row {
                    spacing: 12
                    Layout.alignment: Qt.AlignVCenter

                    // Menu Button
                    Rectangle {
                        width: 90
                        height: 40
                        color: menuMouse.pressed ? "#389BFF" : (menuMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: menuMouse.pressed ? "#80D8FF" : "#3F74A3"
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

                    // Back Arrow Button (⮌)
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
                                root.backClicked()
                            }
                        }
                    }
                }
            }
        }

        // ====================================================
        // 2. MAIN BODY: LEFT SIDEBAR + RIGHT CONTENT
        // ====================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // ------------------------------------------------
            // A. LEFT SIDEBAR (4 Button Tabs)
            // ------------------------------------------------
            Rectangle {
                Layout.preferredWidth: 260
                Layout.fillHeight: true
                color: "#0B1017"

                Rectangle {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    width: 1.5
                    color: "#1E222D"
                }

                Column {
                    anchors.fill: parent
                    spacing: 0

                    // Helper Tab Button Component
                    component ButtonTabItem: Rectangle {
                        id: tabRoot
                        property string tabKey: ""
                        property string tabTitle: ""
                        property bool isSelected: root.selectedTab === tabKey

                        width: parent.width
                        height: 96
                        color: isSelected ? "#C4E2FE" : (tabMouse.containsMouse ? "#101824" : "transparent")

                        Behavior on color { ColorAnimation { duration: 120 } }

                        // Right active indicator line
                        Rectangle {
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            width: 3.5
                            color: "#00B8FF"
                            visible: tabRoot.isSelected
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: tabRoot.tabTitle
                            color: tabRoot.isSelected ? "#0A1428" : "#A2BFD9"
                            font.pixelSize: 20
                            font.weight: tabRoot.isSelected ? Font.DemiBold : Font.Normal
                            font.family: "Roboto"
                            lineHeight: 1.15
                            wrapMode: Text.WordWrap
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.menuOpen = false
                                root.selectedTab = tabRoot.tabKey
                            }
                        }
                    }

                    ButtonTabItem {
                        tabKey: "custom_audio"
                        tabTitle: "Custom button ☆\n(Audio)"
                    }

                    ButtonTabItem {
                        tabKey: "custom_steering"
                        tabTitle: "Custom button ★\n(Steering wheel)"
                    }

                    ButtonTabItem {
                        tabKey: "mode_steering"
                        tabTitle: "MODE button\n(Steering wheel)"
                    }

                    ButtonTabItem {
                        tabKey: "seek_steering"
                        tabTitle: "[∧]/[∨] Buttons\n(Steering wheel)"
                    }
                }
            }

            // ------------------------------------------------
            // B. RIGHT CONTENT PANE
            // ------------------------------------------------
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // --------------------------------------------
                // 1. TAB 1: Custom button ☆ (Audio) - Matching Photo 1
                // --------------------------------------------
                Column {
                    anchors.fill: parent
                    anchors.margins: 28
                    spacing: 16
                    visible: root.selectedTab === "custom_audio"

                    // Top Information Box with Star Icon
                    Row {
                        spacing: 18
                        Rectangle {
                            width: 100
                            height: 48
                            radius: 3
                            color: "#1B3B5C"
                            border.color: "#376E9F"
                            border.width: 1.5

                            Text {
                                anchors.centerIn: parent
                                text: "☆"
                                color: "#80D4FF"
                                font.pixelSize: 26
                                font.weight: Font.Bold
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Please assign a function to this button (Audio)."
                            color: "#FFFFFF"
                            font.pixelSize: 21
                            font.family: "Roboto"
                        }
                    }

                    Item { width: 1; height: 10 }

                    // Radio options list
                    Column {
                        width: parent.width
                        spacing: 8

                        component AudioOptionRow: Rectangle {
                            id: optRow
                            property string optVal: ""
                            property string optText: ""
                            property bool isSelected: systemController.customButtonAudio === optVal

                            width: parent.width
                            height: 62
                            radius: 3
                            color: isSelected ? "#EAF2FA" : (rowMouse.containsMouse ? "#111822" : "transparent")

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 20
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 18

                                // Radio Dot
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: optRow.isSelected ? "#FFFFFF" : "transparent"
                                    border.color: optRow.isSelected ? "#1E88E5" : "#FFFFFF"
                                    border.width: 2

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 12
                                        height: 12
                                        radius: 6
                                        color: "#1E88E5"
                                        visible: optRow.isSelected
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: optRow.optText
                                    color: optRow.isSelected ? "#0A1428" : "#FFFFFF"
                                    font.pixelSize: 24
                                    font.weight: optRow.isSelected ? Font.DemiBold : Font.Normal
                                    font.family: "Roboto"
                                }
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: systemController.setCustomButtonAudio(optRow.optVal)
                            }
                        }

                        AudioOptionRow {
                            optVal: "quiet_mode"
                            optText: "Quiet mode"
                        }
                        AudioOptionRow {
                            optVal: "display_off"
                            optText: "Display On/Off"
                        }
                        AudioOptionRow {
                            optVal: "drvm"
                            optText: "DRVM"
                        }
                        AudioOptionRow {
                            optVal: "none"
                            optText: "None"
                        }
                    }
                }

                // --------------------------------------------
                // 2. TAB 2: Custom button ★ (Steering wheel) - Matching Photo 2
                // --------------------------------------------
                Column {
                    anchors.fill: parent
                    anchors.margins: 28
                    spacing: 16
                    visible: root.selectedTab === "custom_steering"

                    // Top Information Box with Solid Star Icon
                    Row {
                        spacing: 18
                        Rectangle {
                            width: 100
                            height: 48
                            radius: 3
                            color: "#1B3B5C"
                            border.color: "#376E9F"
                            border.width: 1.5

                            Text {
                                anchors.centerIn: parent
                                text: "★"
                                color: "#FFFFFF"
                                font.pixelSize: 26
                                font.weight: Font.Bold
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Please assign a function to this button (Steering wheel)."
                            color: "#FFFFFF"
                            font.pixelSize: 21
                            font.family: "Roboto"
                        }
                    }

                    Item { width: 1; height: 10 }

                    // Radio options list
                    Column {
                        width: parent.width
                        spacing: 8

                        component SteeringOptionRow: Rectangle {
                            id: steerRow
                            property string optVal: ""
                            property string optText: ""
                            property bool isSelected: systemController.customButtonSteering === optVal

                            width: parent.width
                            height: 62
                            radius: 3
                            color: isSelected ? "#EAF2FA" : (sRowMouse.containsMouse ? "#111822" : "transparent")

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 20
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 18

                                // Radio Dot
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: steerRow.isSelected ? "#FFFFFF" : "transparent"
                                    border.color: steerRow.isSelected ? "#1E88E5" : "#FFFFFF"
                                    border.width: 2

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 12
                                        height: 12
                                        radius: 6
                                        color: "#1E88E5"
                                        visible: steerRow.isSelected
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: steerRow.optText
                                    color: steerRow.isSelected ? "#0A1428" : "#FFFFFF"
                                    font.pixelSize: 24
                                    font.weight: steerRow.isSelected ? Font.DemiBold : Font.Normal
                                    font.family: "Roboto"
                                }
                            }

                            MouseArea {
                                id: sRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: systemController.setCustomButtonSteering(steerRow.optVal)
                            }
                        }

                        SteeringOptionRow {
                            optVal: "home"
                            optText: "Home"
                        }
                        SteeringOptionRow {
                            optVal: "media_power"
                            optText: "Radio/Media On/Off"
                        }
                        SteeringOptionRow {
                            optVal: "quiet_mode"
                            optText: "Quiet mode"
                        }
                        SteeringOptionRow {
                            optVal: "none"
                            optText: "None"
                        }
                    }
                }

                // --------------------------------------------
                // 3. TAB 3: MODE button (Steering wheel) - Matching Photo 3
                // --------------------------------------------
                Column {
                    anchors.fill: parent
                    anchors.margins: 28
                    spacing: 20
                    visible: root.selectedTab === "mode_steering"

                    Text {
                        text: "Press MODE button on steering wheel to toggle media modes."
                        color: "#C8DCEF"
                        font.pixelSize: 21
                        font.family: "Roboto"
                    }

                    Item { width: 1; height: 10 }

                    Column {
                        width: parent.width
                        spacing: 12

                        component ModeCheckboxRow: Rectangle {
                            id: chkRow
                            property string labelText: ""
                            property bool isChecked: false
                            signal toggled()

                            width: parent.width
                            height: 62
                            radius: 3
                            color: chkMouse.containsMouse ? "#111822" : "transparent"

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 18

                                // Checkbox Box
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 26
                                    height: 26
                                    radius: 3
                                    color: chkRow.isChecked ? "#389BFF" : "transparent"
                                    border.color: chkRow.isChecked ? "#80D8FF" : "#FFFFFF"
                                    border.width: 1.5

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        color: "#FFFFFF"
                                        font.pixelSize: 18
                                        font.weight: Font.Bold
                                        visible: chkRow.isChecked
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: chkRow.labelText
                                    color: "#FFFFFF"
                                    font.pixelSize: 24
                                    font.weight: Font.DemiBold
                                    font.family: "Roboto"
                                }
                            }

                            MouseArea {
                                id: chkMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: chkRow.toggled()
                            }
                        }

                        ModeCheckboxRow {
                            labelText: "Bluetooth Audio"
                            isChecked: systemController.modeBtAudio
                            onToggled: systemController.setModeBtAudio(!systemController.modeBtAudio)
                        }

                        ModeCheckboxRow {
                            labelText: "Phone projection"
                            isChecked: systemController.modeProjection
                            onToggled: systemController.setModeProjection(!systemController.modeProjection)
                        }

                        ModeCheckboxRow {
                            labelText: "USB Music"
                            isChecked: systemController.modeUsbMusic
                            onToggled: systemController.setModeUsbMusic(!systemController.modeUsbMusic)
                        }

                        ModeCheckboxRow {
                            labelText: "FM"
                            isChecked: systemController.modeFm
                            onToggled: systemController.setModeFm(!systemController.modeFm)
                        }
                    }
                }

                // --------------------------------------------
                // 4. TAB 4: [∧]/[∨] Buttons (Steering wheel) - Matching Photo 4
                // --------------------------------------------
                Column {
                    anchors.fill: parent
                    anchors.margins: 28
                    spacing: 16
                    visible: root.selectedTab === "seek_steering"

                    component SeekOptionCard: Rectangle {
                        id: seekCard
                        property string optVal: ""
                        property string optTitle: ""
                        property string optDesc: ""
                        property bool isSelected: systemController.seekButtonsSteering === optVal

                        width: parent.width
                        height: 110
                        radius: 4
                        color: isSelected ? "#EAF2FA" : (seekMouse.containsMouse ? "#111822" : "transparent")

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            anchors.right: parent.right
                            anchors.rightMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 18

                            // Radio Dot
                            Rectangle {
                                anchors.top: parent.top
                                anchors.topMargin: 4
                                width: 24
                                height: 24
                                radius: 12
                                color: seekCard.isSelected ? "#FFFFFF" : "transparent"
                                border.color: seekCard.isSelected ? "#1E88E5" : "#FFFFFF"
                                border.width: 2

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: "#1E88E5"
                                    visible: seekCard.isSelected
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8
                                width: parent.width - 44

                                Text {
                                    text: seekCard.optTitle
                                    color: seekCard.isSelected ? "#0A1428" : "#FFFFFF"
                                    font.pixelSize: 24
                                    font.weight: seekCard.isSelected ? Font.DemiBold : Font.Normal
                                    font.family: "Roboto"
                                }

                                Text {
                                    text: seekCard.optDesc
                                    color: seekCard.isSelected ? "#1E607A" : "#8AAAC8"
                                    font.pixelSize: 18
                                    font.family: "Roboto"
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                    lineHeight: 1.15
                                }
                            }
                        }

                        MouseArea {
                            id: seekMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: systemController.setSeekButtonsSteering(seekCard.optVal)
                        }
                    }

                    SeekOptionCard {
                        optVal: "station"
                        optTitle: "Change favourite station"
                        optDesc: "Press the button briefly to change favourite station, and press longer to change stations or frequencies."
                    }

                    SeekOptionCard {
                        optVal: "frequency"
                        optTitle: "Change station / frequency"
                        optDesc: "Press the button briefly to change stations or frequencies, and press longer to change favourite station."
                    }
                }
            }
        }
    }

    // ====================================================
    // 3. MENU DROPDOWN (Reset | Web manual)
    // ====================================================
    MouseArea {
        anchors.fill: parent
        z: 88
        visible: root.menuOpen
        onClicked: root.menuOpen = false
    }

    Item {
        id: buttonMenuDropdown
        anchors.top: parent.top
        anchors.topMargin: 56
        anchors.right: parent.right
        anchors.rightMargin: 16
        width: 260
        height: 120
        visible: root.menuOpen
        z: 90

        Rectangle {
            anchors.fill: parent
            color: "#EEF3F8"
            border.color: "#C6D4E2"
            border.width: 1
            radius: 3

            // Drop shadow
            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                z: -1
                color: "#38000000"
                radius: 4
            }

            Column {
                anchors.fill: parent

                // Row 1: Reset
                Rectangle {
                    width: parent.width
                    height: 60
                    color: mRow1.pressed ? "#D0DFEE" : (mRow1.containsMouse ? "#E1EBF5" : "transparent")

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 24
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Reset"
                        color: "#223344"
                        font.pixelSize: 22
                        font.family: "Roboto"
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: "#D6E0EC"
                    }

                    MouseArea {
                        id: mRow1
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.menuOpen = false
                            systemController.resetButtonSettings()
                        }
                    }
                }

                // Row 2: Web manual
                Rectangle {
                    width: parent.width
                    height: 60
                    color: mRow2.pressed ? "#D0DFEE" : (mRow2.containsMouse ? "#E1EBF5" : "transparent")

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 24
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Web manual"
                        color: "#223344"
                        font.pixelSize: 22
                        font.family: "Roboto"
                    }

                    MouseArea {
                        id: mRow2
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
    }
}
