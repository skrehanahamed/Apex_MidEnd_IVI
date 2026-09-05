/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: GeneralSettingsScreen.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#05070B"

    signal backClicked()
    signal manualClicked()

    readonly property bool isHindi: (systemController.systemLanguage === "Hindi")
    function tr(en, hi) { return isHindi ? hi : en; }

    property string selectedTab: "version" // "version" | "system_info" | "bt_lock" | "datetime" | "language" | "keyboard" | "media" | "default"
    property string currentView: "main"   // "main" | "memory" | "datetime_settings" | "keyboard_type" | "hindi_keyboard_type"
    property bool menuOpen: false
    property bool updateModalVisible: false
    property bool resetModalVisible: false
    property bool isResetDone: false

    function resetToDefault() {
        selectedTab = "version"
        currentView = "main"
        menuOpen = false
        updateModalVisible = false
        resetModalVisible = false
        isResetDone = false
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
                            if (root.currentView === "memory") return root.tr("Memory", "मेमोरी")
                            if (root.currentView === "datetime_settings") return root.tr("Date/Time settings", "दिनांक/समय सेटिंग्स")
                            if (root.currentView === "keyboard_type") return root.tr("English keyboard type", "अंग्रेजी कीबोर्ड प्रकार")
                            if (root.currentView === "hindi_keyboard_type") return root.tr("Hindi keyboard type", "हिन्दी कीबोर्ड प्रकार")
                            return root.tr("General settings", "सामान्य सेटिंग्स")
                        }
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

                    // Menu Button (only on main view)
                    Rectangle {
                        width: 90
                        height: 40
                        visible: root.currentView === "main"
                        color: menuMouse.pressed ? "#389BFF" : (menuMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: menuMouse.pressed ? "#80D8FF" : "#3F74A3"
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
                            }
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

            // Dropdown Menu (Reset + Web manual)
            Rectangle {
                id: generalDropdown
                visible: root.menuOpen && root.currentView === "main"
                anchors.top: parent.bottom
                anchors.topMargin: 4
                anchors.right: parent.right
                anchors.rightMargin: 16
                width: 220
                height: 120
                color: "#182230"
                border.color: "#2C394C"
                border.width: 1.5
                radius: 4
                z: 100

                Column {
                    anchors.fill: parent

                    // 1. Reset
                    Rectangle {
                        width: parent.width
                        height: 60
                        color: resetMenuMouse.pressed ? "#233348" : (resetMenuMouse.containsMouse ? "#1E2B3D" : "transparent")

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.tr("Reset", "रीसेट")
                            color: "#FFFFFF"
                            font.pixelSize: 20
                            font.family: "Roboto"
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: "#253344"
                        }

                        MouseArea {
                            id: resetMenuMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.menuOpen = false
                                root.isResetDone = false
                                root.resetModalVisible = true
                            }
                        }
                    }

                    // 2. Web manual
                    Rectangle {
                        width: parent.width
                        height: 60
                        color: manualMenuMouse.pressed ? "#233348" : (manualMenuMouse.containsMouse ? "#1E2B3D" : "transparent")

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.tr("Web manual", "वेब मैनुअल")
                            color: "#FFFFFF"
                            font.pixelSize: 20
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
                }
            }
        }

        // ====================================================
        // 2. BODY CONTENT
        // ====================================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ------------------------------------------------
            // 2A. MAIN VIEW (Sidebar + Content Pane)
            // ------------------------------------------------
            RowLayout {
                anchors.fill: parent
                spacing: 0
                visible: root.currentView === "main"

                // A. SCROLLABLE LEFT SIDEBAR (8 Tabs matching photos)
                Rectangle {
                    Layout.preferredWidth: 260
                    Layout.fillHeight: true
                    color: "#0B0E14"

                    Rectangle {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        width: 1.5
                        color: "#1E2533"
                    }

                    Flickable {
                        anchors.fill: parent
                        contentWidth: width
                        contentHeight: sidebarCol.height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: sidebarCol
                            width: parent.width

                            // Tab 1: Version info/Update
                            GeneralSidebarTab {
                                tabId: "version"
                                title: root.tr("Version\ninfo/\nUpdate", "संस्करण\nजानकारी/\nअपडेट")
                                isSelected: root.selectedTab === "version"
                                tabHeight: 84
                                onClicked: root.selectedTab = "version"
                            }

                            // Tab 2: System info
                            GeneralSidebarTab {
                                tabId: "system_info"
                                title: root.tr("System info", "सिस्टम\nजानकारी")
                                isSelected: root.selectedTab === "system_info"
                                tabHeight: 58
                                onClicked: root.selectedTab = "system_info"
                            }

                            // Tab 3: Bluetooth remote lock
                            GeneralSidebarTab {
                                tabId: "bt_lock"
                                title: root.tr("Bluetooth\nremote lock", "ब्लूटूथ\nरिमोट लॉक")
                                isSelected: root.selectedTab === "bt_lock"
                                tabHeight: 70
                                onClicked: root.selectedTab = "bt_lock"
                            }

                            // Tab 4: Date/Time
                            GeneralSidebarTab {
                                tabId: "datetime"
                                title: root.tr("Date/Time", "दिनांक/समय")
                                isSelected: root.selectedTab === "datetime"
                                tabHeight: 58
                                onClicked: root.selectedTab = "datetime"
                            }

                            // Tab 5: Language (Hindi & English only as requested)
                            GeneralSidebarTab {
                                tabId: "language"
                                title: root.tr("Language", "भाषा")
                                isSelected: root.selectedTab === "language"
                                tabHeight: 58
                                onClicked: root.selectedTab = "language"
                            }

                            // Tab 6: Keyboard
                            GeneralSidebarTab {
                                tabId: "keyboard"
                                title: root.tr("Keyboard", "कीबोर्ड")
                                isSelected: root.selectedTab === "keyboard"
                                tabHeight: 58
                                onClicked: root.selectedTab = "keyboard"
                            }

                            // Tab 7: Media settings
                            GeneralSidebarTab {
                                tabId: "media"
                                title: root.tr("Media\nsettings", "मीडिया\nसेटिंग्स")
                                isSelected: root.selectedTab === "media"
                                tabHeight: 66
                                onClicked: root.selectedTab = "media"
                            }

                            // Tab 8: Default
                            GeneralSidebarTab {
                                tabId: "default"
                                title: root.tr("Default", "डिफ़ॉल्ट")
                                isSelected: root.selectedTab === "default"
                                tabHeight: 58
                                isLast: true
                                onClicked: root.selectedTab = "default"
                            }
                        }
                    }
                }

                // B. RIGHT CONTENT PANE
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#05070B"

                    // TAB 1: VERSION INFO / UPDATE (Photo 1)
                    Item {
                        anchors.fill: parent
                        visible: root.selectedTab === "version"

                        Column {
                            anchors.top: parent.top
                            anchors.topMargin: 24
                            anchors.left: parent.left
                            anchors.leftMargin: 36
                            anchors.right: parent.right
                            anchors.rightMargin: 36
                            spacing: 22

                            Column {
                                spacing: 6
                                Text {
                                    text: root.tr("Model", "मॉडल")
                                    color: "#FFFFFF"
                                    font.pixelSize: 22
                                    font.weight: Font.DemiBold
                                    font.family: "Roboto"
                                }
                                Text {
                                    text: systemController.systemModel
                                    color: "#99AABF"
                                    font.pixelSize: 20
                                    font.family: "Roboto"
                                }
                            }

                            Column {
                                spacing: 6
                                Text {
                                    text: root.tr("Software version", "सॉफ्टवेयर संस्करण")
                                    color: "#FFFFFF"
                                    font.pixelSize: 22
                                    font.weight: Font.DemiBold
                                    font.family: "Roboto"
                                }
                                Text {
                                    text: systemController.softwareVersion
                                    color: "#99AABF"
                                    font.pixelSize: 20
                                    font.family: "Roboto"
                                }
                            }

                            Column {
                                spacing: 6
                                Text {
                                    text: root.tr("Firmware version", "फर्मवेयर संस्करण")
                                    color: "#FFFFFF"
                                    font.pixelSize: 22
                                    font.weight: Font.DemiBold
                                    font.family: "Roboto"
                                }
                                Text {
                                    text: systemController.firmwareVersion
                                    color: "#99AABF"
                                    font.pixelSize: 20
                                    font.family: "Roboto"
                                }
                            }

                            Column {
                                spacing: 6
                                Text {
                                    text: root.tr("Apex Build / Release version", "एपेक्स बिल्ड / रिलीज़ संस्करण")
                                    color: "#FFFFFF"
                                    font.pixelSize: 22
                                    font.weight: Font.DemiBold
                                    font.family: "Roboto"
                                }
                                Text {
                                    text: systemController.appVersion
                                    color: "#2680EB"
                                    font.pixelSize: 20
                                    font.weight: Font.DemiBold
                                    font.family: "Roboto"
                                }
                            }
                        }

                        // Bottom "Update" Button (Photo 1)
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 24
                            anchors.left: parent.left
                            anchors.leftMargin: 36
                            anchors.right: parent.right
                            anchors.rightMargin: 36
                            height: 48
                            radius: 4
                            color: updateBtnMouse.pressed ? "#1E88E5" : (updateBtnMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                            border.color: updateBtnMouse.pressed ? "#80D8FF" : "#3F74A3"
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: root.tr("Update", "अपडेट")
                                color: "#FFFFFF"
                                font.pixelSize: 20
                                font.weight: Font.DemiBold
                                font.family: "Roboto"
                            }

                            MouseArea {
                                id: updateBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.updateModalVisible = true
                                }
                            }
                        }
                    }

                    // TAB 2: SYSTEM INFO
                    Item {
                        anchors.fill: parent
                        visible: root.selectedTab === "system_info"

                        Column {
                            anchors.top: parent.top
                            anchors.topMargin: 28
                            anchors.left: parent.left
                            anchors.leftMargin: 32
                            anchors.right: parent.right
                            anchors.rightMargin: 32
                            spacing: 16

                            // Memory Item Card
                            Rectangle {
                                width: parent.width
                                height: 72
                                radius: 4
                                color: memCardMouse.pressed ? "#1E2B3D" : (memCardMouse.containsMouse ? "#121A26" : "#0C111A")
                                border.color: memCardMouse.pressed ? "#00E5FF" : "#1F2B3B"
                                border.width: 1.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 20
                                    anchors.rightMargin: 20

                                    Column {
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 4

                                        Text {
                                            text: root.tr("Memory", "मेमोरी")
                                            color: "#FFFFFF"
                                            font.pixelSize: 22
                                            font.weight: Font.DemiBold
                                            font.family: "Roboto"
                                        }

                                        Text {
                                            text: root.tr("Check storage usage for voice memos", "वॉयस मेमो के लिए स्टोरेज उपयोग देखें")
                                            color: "#8FA3BC"
                                            font.pixelSize: 16
                                            font.family: "Roboto"
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: "❯"
                                        color: "#8FA3BC"
                                        font.pixelSize: 20
                                    }
                                }

                                MouseArea {
                                    id: memCardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.currentView = "memory"
                                    }
                                }
                            }

                            // Web Manual Item Card
                            Rectangle {
                                width: parent.width
                                height: 72
                                radius: 4
                                color: manCardMouse.pressed ? "#1E2B3D" : (manCardMouse.containsMouse ? "#121A26" : "#0C111A")
                                border.color: manCardMouse.pressed ? "#00E5FF" : "#1F2B3B"
                                border.width: 1.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 20
                                    anchors.rightMargin: 20

                                    Column {
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 4

                                        Text {
                                            text: root.tr("Web manual", "वेब मैनुअल")
                                            color: "#FFFFFF"
                                            font.pixelSize: 22
                                            font.weight: Font.DemiBold
                                            font.family: "Roboto"
                                        }

                                        Text {
                                            text: root.tr("Scan QR code to access online user manual", "ऑनलाइन मैनुअल देखने हेतु QR कोड स्कैन करें")
                                            color: "#8FA3BC"
                                            font.pixelSize: 16
                                            font.family: "Roboto"
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: "❯"
                                        color: "#8FA3BC"
                                        font.pixelSize: 20
                                    }
                                }

                                MouseArea {
                                    id: manCardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.manualClicked()
                                    }
                                }
                            }
                        }
                    }

                    // TAB 3: BLUETOOTH REMOTE LOCK (Photo 5)
                    Item {
                        anchors.fill: parent
                        visible: root.selectedTab === "bt_lock"

                        Column {
                            anchors.top: parent.top
                            anchors.topMargin: 36
                            anchors.left: parent.left
                            anchors.leftMargin: 36
                            anchors.right: parent.right
                            anchors.rightMargin: 36
                            spacing: 16

                            Row {
                                spacing: 18

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 26
                                    height: 26
                                    radius: 3
                                    color: systemController.bluetoothRemoteLock ? "#1E88E5" : "transparent"
                                    border.color: systemController.bluetoothRemoteLock ? "#00E5FF" : "#6A7B8F"
                                    border.width: 2

                                    Text {
                                        anchors.centerIn: parent
                                        visible: systemController.bluetoothRemoteLock
                                        text: "✓"
                                        color: "#FFFFFF"
                                        font.pixelSize: 18
                                        font.weight: Font.Bold
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.tr("Bluetooth remote lock", "ब्लूटूथ रिमोट लॉक")
                                    color: "#FFFFFF"
                                    font.pixelSize: 24
                                    font.weight: Font.DemiBold
                                    font.family: "Roboto"
                                }
                            }

                            Text {
                                width: parent.width
                                text: root.tr("When the Bluetooth remote lock is turned on,\nthe system cannot be operated from the Bluetooth device.", "जब ब्लूटूथ रिमोट लॉक चालू होता है,\nतो ब्लूटूथ डिवाइस से सिस्टम संचालित नहीं किया जा सकता।")
                                color: "#9FB3C8"
                                font.pixelSize: 20
                                font.family: "Roboto"
                                lineHeight: 1.3
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                systemController.setBluetoothRemoteLock(!systemController.bluetoothRemoteLock)
                            }
                        }
                    }

                    // TAB 4: DATE / TIME (Matching Photo 1)
                    Item {
                        anchors.fill: parent
                        visible: root.selectedTab === "datetime"

                        Column {
                            anchors.top: parent.top
                            anchors.topMargin: 36
                            anchors.left: parent.left
                            anchors.leftMargin: 36
                            anchors.right: parent.right
                            anchors.rightMargin: 36
                            spacing: 28

                            // 1. Auto time setting checkbox (Photo 1)
                            Item {
                                width: parent.width
                                height: 36

                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 18

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 26
                                        height: 26
                                        radius: 3
                                        color: systemController.autoTimeSetting ? "#1E88E5" : "transparent"
                                        border.color: systemController.autoTimeSetting ? "#00E5FF" : "#6A7B8F"
                                        border.width: 2

                                        Text {
                                            anchors.centerIn: parent
                                            visible: systemController.autoTimeSetting
                                            text: "✓"
                                            color: "#FFFFFF"
                                            font.pixelSize: 18
                                            font.weight: Font.Bold
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.tr("Auto time setting", "स्वचालित समय सेटिंग")
                                        color: "#FFFFFF"
                                        font.pixelSize: 24
                                        font.weight: Font.DemiBold
                                        font.family: "Roboto"
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        systemController.setAutoTimeSetting(!systemController.autoTimeSetting)
                                    }
                                }
                            }

                            // 2. Date & Time Row (Clickable -> Opens Date/Time settings Photo 2!)
                            Rectangle {
                                width: parent.width
                                height: 50
                                radius: 4
                                color: dtCardMouse.pressed ? "#142030" : (dtCardMouse.containsMouse ? "#0D141F" : "transparent")
                                border.color: dtCardMouse.pressed ? "#00E5FF" : "transparent"
                                border.width: 1

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 44
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "15-02-2026   " + (systemController.is24HourFormat ? "15:08" : "3:08 PM")
                                    color: systemController.autoTimeSetting ? "#72889F" : "#99D8FF"
                                    font.pixelSize: 22
                                    font.weight: Font.DemiBold
                                    font.family: "Roboto"
                                }

                                MouseArea {
                                    id: dtCardMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        console.log("[GeneralSettings] Opening Date/Time settings stepper view")
                                        root.currentView = "datetime_settings"
                                    }
                                }
                            }

                            // 3. 24-hour format checkbox (Photo 1)
                            Item {
                                width: parent.width
                                height: 36

                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 18

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 26
                                        height: 26
                                        radius: 3
                                        color: systemController.is24HourFormat ? "#1E88E5" : "transparent"
                                        border.color: systemController.is24HourFormat ? "#00E5FF" : "#6A7B8F"
                                        border.width: 2

                                        Text {
                                            anchors.centerIn: parent
                                            visible: systemController.is24HourFormat
                                            text: "✓"
                                            color: "#FFFFFF"
                                            font.pixelSize: 18
                                            font.weight: Font.Bold
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.tr("24-hour format", "24-घंटे प्रारूप")
                                        color: "#FFFFFF"
                                        font.pixelSize: 24
                                        font.weight: Font.DemiBold
                                        font.family: "Roboto"
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        systemController.setIs24HourFormat(!systemController.is24HourFormat)
                                    }
                                }
                            }
                        }
                    }

                    // TAB 5: LANGUAGE (HINDI & ENGLISH ONLY AS REQUESTED)
                    Item {
                        anchors.fill: parent
                        visible: root.selectedTab === "language"

                        Column {
                            anchors.top: parent.top
                            anchors.topMargin: 24
                            anchors.left: parent.left
                            anchors.leftMargin: 28
                            anchors.right: parent.right
                            anchors.rightMargin: 28
                            spacing: 12

                            // 1. English
                            Rectangle {
                                width: parent.width
                                height: 60
                                radius: 4
                                color: (systemController.systemLanguage === "English") ? "#EAF2FA" : (engMouse.containsMouse ? "#0D141E" : "transparent")
                                border.color: (systemController.systemLanguage === "English") ? "#A0C4E8" : "transparent"
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 100 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 20
                                    anchors.rightMargin: 20

                                    Rectangle {
                                        Layout.alignment: Qt.AlignVCenter
                                        width: 22
                                        height: 22
                                        radius: 11
                                        color: "transparent"
                                        border.color: (systemController.systemLanguage === "English") ? "#1E88E5" : "#6A7B8F"
                                        border.width: 2

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 10
                                            height: 10
                                            radius: 5
                                            color: "#1E88E5"
                                            visible: systemController.systemLanguage === "English"
                                        }
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.leftMargin: 16
                                        text: "English"
                                        color: (systemController.systemLanguage === "English") ? "#0A1428" : "#FFFFFF"
                                        font.pixelSize: 22
                                        font.weight: (systemController.systemLanguage === "English") ? Font.DemiBold : Font.Normal
                                        font.family: "Roboto"
                                    }

                                    Item { Layout.fillWidth: true }
                                }

                                MouseArea {
                                    id: engMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        console.log("[GeneralSettings] Language selected: English")
                                        systemController.setSystemLanguage("English")
                                    }
                                }
                            }

                            // 2. हिन्दी (Hindi)
                            Rectangle {
                                width: parent.width
                                height: 60
                                radius: 4
                                color: (systemController.systemLanguage === "Hindi") ? "#EAF2FA" : (hinMouse.containsMouse ? "#0D141E" : "transparent")
                                border.color: (systemController.systemLanguage === "Hindi") ? "#A0C4E8" : "transparent"
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 100 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 20
                                    anchors.rightMargin: 20

                                    Rectangle {
                                        Layout.alignment: Qt.AlignVCenter
                                        width: 22
                                        height: 22
                                        radius: 11
                                        color: "transparent"
                                        border.color: (systemController.systemLanguage === "Hindi") ? "#1E88E5" : "#6A7B8F"
                                        border.width: 2

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 10
                                            height: 10
                                            radius: 5
                                            color: "#1E88E5"
                                            visible: systemController.systemLanguage === "Hindi"
                                        }
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.leftMargin: 16
                                        text: "हिन्दी"
                                        color: (systemController.systemLanguage === "Hindi") ? "#0A1428" : "#FFFFFF"
                                        font.pixelSize: 22
                                        font.weight: (systemController.systemLanguage === "Hindi") ? Font.DemiBold : Font.Normal
                                        font.family: "Roboto"
                                    }

                                    Item { Layout.fillWidth: true }
                                }

                                MouseArea {
                                    id: hinMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        console.log("[GeneralSettings] Language selected: Hindi")
                                        systemController.setSystemLanguage("Hindi")
                                    }
                                }
                            }
                        }
                    }

                    // TAB 6: KEYBOARD (Photo 4)
                    Item {
                        anchors.fill: parent
                        visible: root.selectedTab === "keyboard"

                        Column {
                            anchors.top: parent.top
                            anchors.topMargin: 24
                            anchors.left: parent.left
                            anchors.leftMargin: 32
                            anchors.right: parent.right
                            anchors.rightMargin: 32
                            spacing: 16

                            // English keyboard type card
                            Rectangle {
                                width: parent.width
                                height: 72
                                radius: 4
                                color: engKeyMouse.pressed ? "#162334" : (engKeyMouse.containsMouse ? "#0E1622" : "transparent")
                                border.color: engKeyMouse.pressed ? "#00E5FF" : "#1E2B3D"
                                border.width: 1.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 20
                                    anchors.rightMargin: 20

                                    Column {
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 4

                                        Text {
                                            text: root.tr("English keyboard type", "अंग्रेजी कीबोर्ड प्रकार")
                                            color: "#FFFFFF"
                                            font.pixelSize: 22
                                            font.weight: Font.DemiBold
                                            font.family: "Roboto"
                                        }

                                        Text {
                                            text: systemController.keyboardType
                                            color: "#8FA3BC"
                                            font.pixelSize: 18
                                            font.family: "Roboto"
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: "▶"
                                        color: "#8FA3BC"
                                        font.pixelSize: 18
                                    }
                                }

                                MouseArea {
                                    id: engKeyMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        console.log("[GeneralSettings] Opening English keyboard type view")
                                        root.currentView = "keyboard_type"
                                    }
                                }
                            }

                            // Hindi keyboard type card
                            Rectangle {
                                width: parent.width
                                height: 72
                                radius: 4
                                color: hinKeyMouse.pressed ? "#162334" : (hinKeyMouse.containsMouse ? "#0E1622" : "transparent")
                                border.color: hinKeyMouse.pressed ? "#00E5FF" : "#1E2B3D"
                                border.width: 1.5

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 20
                                    anchors.rightMargin: 20

                                    Column {
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 4

                                        Text {
                                            text: root.tr("Hindi keyboard type", "हिन्दी कीबोर्ड प्रकार")
                                            color: "#FFFFFF"
                                            font.pixelSize: 22
                                            font.weight: Font.DemiBold
                                            font.family: "Roboto"
                                        }

                                        Text {
                                            text: systemController.hindiKeyboardType
                                            color: "#8FA3BC"
                                            font.pixelSize: 18
                                            font.family: "Roboto"
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: "▶"
                                        color: "#8FA3BC"
                                        font.pixelSize: 18
                                    }
                                }

                                MouseArea {
                                    id: hinKeyMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        console.log("[GeneralSettings] Opening Hindi keyboard type view")
                                        root.currentView = "hindi_keyboard_type"
                                    }
                                }
                            }
                        }
                    }

                    // TAB 7: MEDIA SETTINGS (Matching Photo 2)
                    Item {
                        anchors.fill: parent
                        visible: root.selectedTab === "media"

                        Column {
                            anchors.top: parent.top
                            anchors.topMargin: 28
                            anchors.left: parent.left
                            anchors.leftMargin: 36
                            anchors.right: parent.right
                            anchors.rightMargin: 36
                            spacing: 24

                            // 1. Radio/Media Off at vehicle start-up (Photo 2)
                            Item {
                                width: parent.width
                                height: mediaCol1.height

                                Column {
                                    id: mediaCol1
                                    width: parent.width
                                    spacing: 8

                                    Row {
                                        spacing: 16

                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 26
                                            height: 26
                                            radius: 3
                                            color: systemController.mediaOffAtStartup ? "#1E88E5" : "transparent"
                                            border.color: systemController.mediaOffAtStartup ? "#00E5FF" : "#6A7B8F"
                                            border.width: 2

                                            Text {
                                                anchors.centerIn: parent
                                                visible: systemController.mediaOffAtStartup
                                                text: "✓"
                                                color: "#FFFFFF"
                                                font.pixelSize: 18
                                                font.weight: Font.Bold
                                            }
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: root.tr("Radio/Media Off at vehicle start-up", "वाहन स्टार्ट होने पर रेडियो/मीडिया बंद रखें")
                                            color: "#FFFFFF"
                                            font.pixelSize: 22
                                            font.weight: Font.DemiBold
                                            font.family: "Roboto"
                                        }
                                    }

                                    Text {
                                        width: parent.width - 42
                                        x: 42
                                        text: root.tr("Radio/Media will not turn On automatically at vehicle start-up.", "वाहन शुरू होने पर रेडियो/मीडिया अपने आप चालू नहीं होगा।")
                                        color: "#8FA3BC"
                                        font.pixelSize: 18
                                        font.family: "Roboto"
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        systemController.setMediaOffAtStartup(!systemController.mediaOffAtStartup)
                                    }
                                }
                            }

                            // 2. Infotainment remains On when the vehicle is turned Off. (Photo 2)
                            Item {
                                width: parent.width
                                height: mediaCol2.height

                                Column {
                                    id: mediaCol2
                                    width: parent.width
                                    spacing: 8

                                    Row {
                                        spacing: 16

                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 26
                                            height: 26
                                            radius: 3
                                            color: systemController.infotainmentRemainsOn ? "#1E88E5" : "transparent"
                                            border.color: systemController.infotainmentRemainsOn ? "#00E5FF" : "#6A7B8F"
                                            border.width: 2

                                            Text {
                                                anchors.centerIn: parent
                                                visible: systemController.infotainmentRemainsOn
                                                text: "✓"
                                                color: "#FFFFFF"
                                                font.pixelSize: 18
                                                font.weight: Font.Bold
                                            }
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: root.tr("Infotainment remains On when the vehicle is turned Off.", "वाहन बंद होने पर इंफोटेनमेंट चालू रखें")
                                            color: "#FFFFFF"
                                            font.pixelSize: 22
                                            font.weight: Font.DemiBold
                                            font.family: "Roboto"
                                        }
                                    }

                                    Text {
                                        width: parent.width - 42
                                        x: 42
                                        text: root.tr("When the vehicle is turned Off, the infotainment system remains On for a given length of time, or until the driver's door is opened.", "वाहन बंद होने पर, इंफोटेनमेंट सिस्टम कुछ समय या ड्राइवर का दरवाजा खुलने तक चालू रहता है।")
                                        color: "#8FA3BC"
                                        font.pixelSize: 18
                                        font.family: "Roboto"
                                        wrapMode: Text.WordWrap
                                        lineHeight: 1.2
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        systemController.setInfotainmentRemainsOn(!systemController.infotainmentRemainsOn)
                                    }
                                }
                            }

                            // 3. Display media change notifications (Photo 2)
                            Item {
                                width: parent.width
                                height: 36

                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 16

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 26
                                        height: 26
                                        radius: 3
                                        color: systemController.displayMediaNotifications ? "#1E88E5" : "transparent"
                                        border.color: systemController.displayMediaNotifications ? "#00E5FF" : "#6A7B8F"
                                        border.width: 2

                                        Text {
                                            anchors.centerIn: parent
                                            visible: systemController.displayMediaNotifications
                                            text: "✓"
                                            color: "#FFFFFF"
                                            font.pixelSize: 18
                                            font.weight: Font.Bold
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.tr("Display media change notifications", "मीडिया परिवर्तन सूचनाएं प्रदर्शित करें")
                                        color: "#FFFFFF"
                                        font.pixelSize: 22
                                        font.weight: Font.DemiBold
                                        font.family: "Roboto"
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        systemController.setDisplayMediaNotifications(!systemController.displayMediaNotifications)
                                    }
                                }
                            }
                        }
                    }

                    // TAB 8: DEFAULT (Matching Photo 3)
                    Item {
                        anchors.fill: parent
                        visible: root.selectedTab === "default"

                        // Centered text prompt exactly matching Photo 3
                        Text {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: -40
                            width: parent.width - 80
                            text: root.tr("The system will be reset to the default\nsettings and all stored data and settings\nwill be lost.", "सिस्टम को डिफ़ॉल्ट सेटिंग्स पर रीसेट कर दिया जाएगा\nऔर सभी संग्रहीत डेटा और सेटिंग्स खो जाएंगी।")
                            color: "#E2E8F0"
                            font.pixelSize: 26
                            font.weight: Font.Normal
                            font.family: "Roboto"
                            horizontalAlignment: Text.AlignHCenter
                            lineHeight: 1.3
                        }

                        // Wide centered "Default" button matching Photo 3
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 32
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 460
                            height: 52
                            radius: 4
                            color: defResetMouse.pressed ? "#1E88E5" : (defResetMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                            border.color: defResetMouse.pressed ? "#80D8FF" : "#3F74A3"
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: root.tr("Default", "डिफ़ॉल्ट")
                                color: "#FFFFFF"
                                font.pixelSize: 22
                                font.weight: Font.DemiBold
                                font.family: "Roboto"
                            }

                            MouseArea {
                                id: defResetMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    console.log("[GeneralSettings] Reset to Default clicked -> Opening confirmation modal")
                                    root.isResetDone = false
                                    root.resetModalVisible = true
                                }
                            }
                        }
                    }
                }
            }

            // ------------------------------------------------
            // 2B. DATE/TIME SETTINGS STEPPER VIEW (Photo 2)
            // ------------------------------------------------
            Rectangle {
                anchors.fill: parent
                color: "#05070B"
                visible: root.currentView === "datetime_settings"

                Row {
                    anchors.centerIn: parent
                    spacing: 10

                    // 1. Day Stepper
                    DateTimeStepperCol {
                        label: root.tr("Day", "दिन")
                        valText: systemController.manualDay.toString()
                        onUpClicked: systemController.adjustManualDay(1)
                        onDownClicked: systemController.adjustManualDay(-1)
                    }

                    // 2. Month Stepper
                    DateTimeStepperCol {
                        label: root.tr("Month", "माह")
                        valText: systemController.manualMonth.toString()
                        onUpClicked: systemController.adjustManualMonth(1)
                        onDownClicked: systemController.adjustManualMonth(-1)
                    }

                    // 3. Year Stepper
                    DateTimeStepperCol {
                        label: root.tr("Year", "वर्ष")
                        valText: systemController.manualYear.toString()
                        colWidth: 120
                        onUpClicked: systemController.adjustManualYear(1)
                        onDownClicked: systemController.adjustManualYear(-1)
                    }

                    // 4. Hour Stepper
                    DateTimeStepperCol {
                        label: root.tr("Hour", "घंटे")
                        valText: systemController.manualHour.toString()
                        onUpClicked: systemController.adjustManualHour(1)
                        onDownClicked: systemController.adjustManualHour(-1)
                    }

                    // Colon separator
                    Item {
                        width: 18
                        height: 180
                        Column {
                            anchors.centerIn: parent
                            spacing: 12
                            Rectangle { width: 6; height: 6; radius: 3; color: "#FFFFFF" }
                            Rectangle { width: 6; height: 6; radius: 3; color: "#FFFFFF" }
                        }
                    }

                    // 5. Minute Stepper
                    DateTimeStepperCol {
                        label: root.tr("min", "मिनट")
                        valText: (systemController.manualMinute < 10 ? "0" : "") + systemController.manualMinute
                        onUpClicked: systemController.adjustManualMinute(1)
                        onDownClicked: systemController.adjustManualMinute(-1)
                    }

                    // 6. AM/PM Stepper
                    DateTimeStepperCol {
                        label: ""
                        valText: systemController.manualAmPm
                        onUpClicked: systemController.toggleManualAmPm()
                        onDownClicked: systemController.toggleManualAmPm()
                    }
                }
            }

            // ------------------------------------------------
            // 2C. ENGLISH KEYBOARD TYPE VIEW (Photo 5)
            // ------------------------------------------------
            Rectangle {
                anchors.fill: parent
                color: "#05070B"
                visible: root.currentView === "keyboard_type"

                Row {
                    anchors.centerIn: parent
                    spacing: 28

                    // Card 1: QWERTY
                    Rectangle {
                        width: 380
                        height: 220
                        radius: 6
                        color: (systemController.keyboardType === "QWERTY") ? "#C8E4FE" : "#1A2B3D"
                        border.color: (systemController.keyboardType === "QWERTY") ? "#68B2F8" : "#2A405A"
                        border.width: 1.5

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 14

                            // Mini keyboard graphic representation
                            Rectangle {
                                width: parent.width
                                height: 120
                                radius: 4
                                color: "#141C26"
                                border.color: "#2C3949"
                                border.width: 1

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Row {
                                        spacing: 3
                                        Repeater {
                                            model: ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
                                            Rectangle {
                                                width: 28; height: 26; radius: 2; color: "#223142"
                                                Text { anchors.centerIn: parent; text: modelData; color: "#FFFFFF"; font.pixelSize: 13; font.family: "Roboto" }
                                            }
                                        }
                                    }
                                    Row {
                                        spacing: 3
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        Repeater {
                                            model: ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
                                            Rectangle {
                                                width: 28; height: 26; radius: 2; color: "#223142"
                                                Text { anchors.centerIn: parent; text: modelData; color: "#FFFFFF"; font.pixelSize: 13; font.family: "Roboto" }
                                            }
                                        }
                                    }
                                    Row {
                                        spacing: 3
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        Repeater {
                                            model: ["z", "x", "c", "v", "b", "n", "m"]
                                            Rectangle {
                                                width: 28; height: 26; radius: 2; color: "#223142"
                                                Text { anchors.centerIn: parent; text: modelData; color: "#FFFFFF"; font.pixelSize: 13; font.family: "Roboto" }
                                            }
                                        }
                                    }
                                }
                            }

                            // Radio selection row
                            Row {
                                spacing: 14
                                anchors.horizontalCenter: parent.horizontalCenter

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: "transparent"
                                    border.color: (systemController.keyboardType === "QWERTY") ? "#1E88E5" : "#6A7B8F"
                                    border.width: 2

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 12
                                        height: 12
                                        radius: 6
                                        color: "#1E88E5"
                                        visible: systemController.keyboardType === "QWERTY"
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "QWERTY"
                                    color: (systemController.keyboardType === "QWERTY") ? "#0A1428" : "#FFFFFF"
                                    font.pixelSize: 22
                                    font.weight: Font.DemiBold
                                    font.family: "Roboto"
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                systemController.setKeyboardType("QWERTY")
                            }
                        }
                    }

                    // Card 2: ABCD
                    Rectangle {
                        width: 380
                        height: 220
                        radius: 6
                        color: (systemController.keyboardType === "ABCD") ? "#C8E4FE" : "#294668"
                        border.color: (systemController.keyboardType === "ABCD") ? "#68B2F8" : "#3D5F86"
                        border.width: 1.5

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 14

                            // Mini keyboard graphic representation
                            Rectangle {
                                width: parent.width
                                height: 120
                                radius: 4
                                color: "#141C26"
                                border.color: "#2C3949"
                                border.width: 1

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Row {
                                        spacing: 3
                                        Repeater {
                                            model: ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"]
                                            Rectangle {
                                                width: 28; height: 26; radius: 2; color: "#223142"
                                                Text { anchors.centerIn: parent; text: modelData; color: "#FFFFFF"; font.pixelSize: 13; font.family: "Roboto" }
                                            }
                                        }
                                    }
                                    Row {
                                        spacing: 3
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        Repeater {
                                            model: ["k", "l", "m", "n", "o", "p", "q", "r", "s", "t"]
                                            Rectangle {
                                                width: 28; height: 26; radius: 2; color: "#223142"
                                                Text { anchors.centerIn: parent; text: modelData; color: "#FFFFFF"; font.pixelSize: 13; font.family: "Roboto" }
                                            }
                                        }
                                    }
                                    Row {
                                        spacing: 3
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        Repeater {
                                            model: ["u", "v", "w", "x", "y", "z"]
                                            Rectangle {
                                                width: 28; height: 26; radius: 2; color: "#223142"
                                                Text { anchors.centerIn: parent; text: modelData; color: "#FFFFFF"; font.pixelSize: 13; font.family: "Roboto" }
                                            }
                                        }
                                    }
                                }
                            }

                            // Radio selection row
                            Row {
                                spacing: 14
                                anchors.horizontalCenter: parent.horizontalCenter

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: "transparent"
                                    border.color: (systemController.keyboardType === "ABCD") ? "#1E88E5" : "#6A7B8F"
                                    border.width: 2

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 12
                                        height: 12
                                        radius: 6
                                        color: "#1E88E5"
                                        visible: systemController.keyboardType === "ABCD"
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "ABCD"
                                    color: (systemController.keyboardType === "ABCD") ? "#0A1428" : "#FFFFFF"
                                    font.pixelSize: 22
                                    font.weight: Font.DemiBold
                                    font.family: "Roboto"
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                systemController.setKeyboardType("ABCD")
                            }
                        }
                    }
                }
            }

            // ------------------------------------------------
            // 2E. HINDI KEYBOARD TYPE VIEW
            // ------------------------------------------------
            Rectangle {
                anchors.fill: parent
                color: "#05070B"
                visible: root.currentView === "hindi_keyboard_type"

                Row {
                    anchors.centerIn: parent
                    spacing: 28

                    // Card 1: ध्वन्यात्मक (QWERTY)
                    Rectangle {
                        width: 380
                        height: 220
                        radius: 6
                        color: (systemController.hindiKeyboardType === "ध्वन्यात्मक") ? "#C8E4FE" : "#1A2B3D"
                        border.color: (systemController.hindiKeyboardType === "ध्वन्यात्मक") ? "#68B2F8" : "#2A405A"
                        border.width: 1.5

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 14

                            // Mini Hindi QWERTY graphic
                            Rectangle {
                                width: parent.width
                                height: 120
                                radius: 4
                                color: "#141C26"
                                border.color: "#2C3949"
                                border.width: 1

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Row {
                                        spacing: 3
                                        Repeater {
                                            model: ["ौ", "ै", "ा", "ी", "ू", "ब", "ह", "ग", "द", "ज"]
                                            Rectangle {
                                                width: 28; height: 26; radius: 2; color: "#223142"
                                                Text { anchors.centerIn: parent; text: modelData; color: "#FFFFFF"; font.pixelSize: 13; font.family: "Roboto" }
                                            }
                                        }
                                    }
                                    Row {
                                        spacing: 3
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        Repeater {
                                            model: ["ो", "े", "्", "ि", "ु", "प", "र", "क", "त", "च"]
                                            Rectangle {
                                                width: 28; height: 26; radius: 2; color: "#223142"
                                                Text { anchors.centerIn: parent; text: modelData; color: "#FFFFFF"; font.pixelSize: 13; font.family: "Roboto" }
                                            }
                                        }
                                    }
                                    Row {
                                        spacing: 3
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        Repeater {
                                            model: ["ं", "म", "न", "व", "ल", "स", "य", "श"]
                                            Rectangle {
                                                width: 28; height: 26; radius: 2; color: "#223142"
                                                Text { anchors.centerIn: parent; text: modelData; color: "#FFFFFF"; font.pixelSize: 13; font.family: "Roboto" }
                                            }
                                        }
                                    }
                                }
                            }

                            // Radio selection row
                            Row {
                                spacing: 14
                                anchors.horizontalCenter: parent.horizontalCenter

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: "transparent"
                                    border.color: (systemController.hindiKeyboardType === "ध्वन्यात्मक") ? "#1E88E5" : "#6A7B8F"
                                    border.width: 2

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 12
                                        height: 12
                                        radius: 6
                                        color: "#1E88E5"
                                        visible: systemController.hindiKeyboardType === "ध्वन्यात्मक"
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "ध्वन्यात्मक (QWERTY)"
                                    color: (systemController.hindiKeyboardType === "ध्वन्यात्मक") ? "#0A1428" : "#FFFFFF"
                                    font.pixelSize: 22
                                    font.weight: Font.DemiBold
                                    font.family: "Roboto"
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                systemController.setHindiKeyboardType("ध्वन्यात्मक")
                            }
                        }
                    }

                    // Card 2: वर्णमाला (अ आ इ ई)
                    Rectangle {
                        width: 380
                        height: 220
                        radius: 6
                        color: (systemController.hindiKeyboardType === "वर्णमाला") ? "#C8E4FE" : "#294668"
                        border.color: (systemController.hindiKeyboardType === "वर्णमाला") ? "#68B2F8" : "#3D5F86"
                        border.width: 1.5

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 14

                            // Mini Hindi Alphabetical (Varnamala) graphic representation
                            Rectangle {
                                width: parent.width
                                height: 120
                                radius: 4
                                color: "#141C26"
                                border.color: "#2C3949"
                                border.width: 1

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Row {
                                        spacing: 3
                                        Repeater {
                                            model: ["अ", "आ", "इ", "ई", "उ", "ऊ", "ए", "ऐ", "ओ", "औ"]
                                            Rectangle {
                                                width: 28; height: 26; radius: 2; color: "#223142"
                                                Text { anchors.centerIn: parent; text: modelData; color: "#FFFFFF"; font.pixelSize: 13; font.family: "Roboto" }
                                            }
                                        }
                                    }
                                    Row {
                                        spacing: 3
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        Repeater {
                                            model: ["क", "ख", "ग", "घ", "च", "छ", "ज", "झ", "ट", "ठ"]
                                            Rectangle {
                                                width: 28; height: 26; radius: 2; color: "#223142"
                                                Text { anchors.centerIn: parent; text: modelData; color: "#FFFFFF"; font.pixelSize: 13; font.family: "Roboto" }
                                            }
                                        }
                                    }
                                    Row {
                                        spacing: 3
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        Repeater {
                                            model: ["ड", "ढ", "त", "थ", "द", "ध", "न", "प", "फ", "ब"]
                                            Rectangle {
                                                width: 28; height: 26; radius: 2; color: "#223142"
                                                Text { anchors.centerIn: parent; text: modelData; color: "#FFFFFF"; font.pixelSize: 13; font.family: "Roboto" }
                                            }
                                        }
                                    }
                                }
                            }

                            // Radio selection row
                            Row {
                                spacing: 14
                                anchors.horizontalCenter: parent.horizontalCenter

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: "transparent"
                                    border.color: (systemController.hindiKeyboardType === "वर्णमाला") ? "#1E88E5" : "#6A7B8F"
                                    border.width: 2

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 12
                                        height: 12
                                        radius: 6
                                        color: "#1E88E5"
                                        visible: systemController.hindiKeyboardType === "वर्णमाला"
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "अ आ इ ई (वर्णमाला)"
                                    color: (systemController.hindiKeyboardType === "वर्णमाला") ? "#0A1428" : "#FFFFFF"
                                    font.pixelSize: 22
                                    font.weight: Font.DemiBold
                                    font.family: "Roboto"
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                systemController.setHindiKeyboardType("वर्णमाला")
                            }
                        }
                    }
                }
            }

            // ------------------------------------------------
            // 2D. MEMORY VIEW (Photo 3)
            // ------------------------------------------------
            Rectangle {
                anchors.fill: parent
                color: "#05070B"
                visible: root.currentView === "memory"

                Column {
                    anchors.top: parent.top
                    anchors.topMargin: 36
                    anchors.left: parent.left
                    anchors.leftMargin: 48
                    anchors.right: parent.right
                    anchors.rightMargin: 48
                    spacing: 28

                    // Row 1: Capacity 128 MB
                    Row {
                        spacing: 28
                        Text {
                            text: root.tr("Capacity", "क्षमता")
                            color: "#FFFFFF"
                            font.pixelSize: 24
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }
                        Text {
                            text: systemController.memoryCapacityMB + " MB"
                            color: "#FFFFFF"
                            font.pixelSize: 24
                            font.weight: Font.Normal
                            font.family: "Roboto"
                        }
                    }

                    // Row 2: Memory for voice memos & Available
                    Item {
                        width: parent.width
                        height: 36

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 16

                            Text {
                                text: root.tr("Memory for voice memos", "वॉयस मेमो के लिए मेमोरी")
                                color: "#FFFFFF"
                                font.pixelSize: 22
                                font.family: "Roboto"
                            }
                            Text {
                                text: systemController.memoryUsedVoiceMB + " MB"
                                color: "#00B8FF"
                                font.pixelSize: 22
                                font.weight: Font.DemiBold
                                font.family: "Roboto"
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 16

                            Text {
                                text: root.tr("Available", "उपलब्ध")
                                color: "#A5B8CC"
                                font.pixelSize: 22
                                font.family: "Roboto"
                            }
                            Text {
                                text: systemController.memoryAvailableMB + " MB"
                                color: "#FFFFFF"
                                font.pixelSize: 22
                                font.weight: Font.DemiBold
                                font.family: "Roboto"
                            }
                        }
                    }

                    // Storage Gauge Bar (Photo 3)
                    Rectangle {
                        width: parent.width
                        height: 8
                        radius: 4
                        color: "#182433"

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.max(4, parent.width * (systemController.memoryUsedVoiceMB / systemController.memoryCapacityMB))
                            radius: 4
                            color: "#00B8FF"
                            visible: systemController.memoryUsedVoiceMB > 0
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: 3
                            color: "#2C6FA8"
                            radius: 1.5
                        }
                    }
                }
            }
        }
    }

    // ====================================================
    // 3. UPDATE MODAL DIALOG (Photo 2)
    // ====================================================
    Rectangle {
        id: updateModal
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.70)
        visible: root.updateModalVisible
        z: 200

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Rectangle {
            anchors.centerIn: parent
            width: 760
            height: 270
            color: "#111823"
            border.color: "#2A3A4E"
            border.width: 1.5
            radius: 4

            Column {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 18

                // Blue Info Badge (i)
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 52
                    height: 52
                    radius: 26
                    color: "#3CA9F8"

                    Text {
                        anchors.centerIn: parent
                        text: "i"
                        color: "#FFFFFF"
                        font.pixelSize: 32
                        font.weight: Font.Bold
                        font.family: "Roboto"
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.tr("Insert the memory device containing the update\nfile(s) and try again.", "अपडेट फ़ाइल वाला मेमोरी डिवाइस डालें और पुनः प्रयास करें।")
                    color: "#FFFFFF"
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.25
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 24
                    height: 48
                    radius: 4
                    color: okMouse.pressed ? "#1E88E5" : (okMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                    border.color: okMouse.pressed ? "#80D8FF" : "#3F74A3"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: root.tr("OK", "ठीक है")
                        color: "#FFFFFF"
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }

                    MouseArea {
                        id: okMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.updateModalVisible = false
                        }
                    }
                }
            }
        }
    }

    // ====================================================
    // 4. RESET CONFIRMATION / FEEDBACK MODAL DIALOG
    // ====================================================
    Rectangle {
        id: resetModal
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.72)
        visible: root.resetModalVisible
        z: 210

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Rectangle {
            anchors.centerIn: parent
            width: 740
            height: 280
            color: "#111823"
            border.color: "#2A3A4E"
            border.width: 1.5
            radius: 6

            Column {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 18

                // Badge Icon (Question mark when asking, Checkmark when done)
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 52
                    height: 52
                    radius: 26
                    color: root.isResetDone ? "#2E7D32" : "#E65100"

                    Text {
                        anchors.centerIn: parent
                        text: root.isResetDone ? "✓" : "?"
                        color: "#FFFFFF"
                        font.pixelSize: 30
                        font.weight: Font.Bold
                        font.family: "Roboto"
                    }
                }

                // Prompt / Message
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.isResetDone
                          ? root.tr("All general settings have been reset to default.", "सभी सामान्य सेटिंग्स डिफ़ॉल्ट पर रीसेट कर दी गई हैं।")
                          : root.tr("Reset all general settings to default?", "क्या सभी सामान्य सेटिंग्स को डिफ़ॉल्ट पर रीसेट करें?")
                    color: "#FFFFFF"
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.25
                }

                Item { width: 1; height: 4 }

                // Buttons Row
                // State 1: Confirmation (No / Yes)
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20
                    visible: !root.isResetDone

                    // No Button
                    Rectangle {
                        width: 200
                        height: 48
                        radius: 4
                        color: noMouse.pressed ? "#223144" : (noMouse.containsMouse ? "#1D2838" : "#16202D")
                        border.color: noMouse.pressed ? "#66D9FF" : "#32445A"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: root.tr("No", "नहीं")
                            color: "#FFFFFF"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        MouseArea {
                            id: noMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.resetModalVisible = false
                            }
                        }
                    }

                    // Yes Button
                    Rectangle {
                        width: 200
                        height: 48
                        radius: 4
                        color: yesMouse.pressed ? "#1E88E5" : (yesMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: yesMouse.pressed ? "#80D8FF" : "#3F74A3"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: root.tr("Yes", "हाँ")
                            color: "#FFFFFF"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        MouseArea {
                            id: yesMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                systemController.resetGeneralSettings()
                                root.isResetDone = true
                            }
                        }
                    }
                }

                // State 2: Done (OK Button)
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.isResetDone

                    Rectangle {
                        width: 320
                        height: 48
                        radius: 4
                        color: resetDoneOkMouse.pressed ? "#1E88E5" : (resetDoneOkMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: resetDoneOkMouse.pressed ? "#80D8FF" : "#3F74A3"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: root.tr("OK", "ठीक है")
                            color: "#FFFFFF"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        MouseArea {
                            id: resetDoneOkMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.resetModalVisible = false
                                root.isResetDone = false
                            }
                        }
                    }
                }
            }
        }
    }

    // Sidebar Tab Component
    component GeneralSidebarTab: Rectangle {
        id: tabRoot
        property string tabId: ""
        property string title: ""
        property bool isSelected: false
        property int tabHeight: 60
        property bool isLast: false
        signal clicked()

        width: parent.width
        height: tabHeight
        color: isSelected ? "#C4E2FE" : (tabMouse.containsMouse ? "#141A24" : "transparent")

        Behavior on color { ColorAnimation { duration: 120 } }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 3
            color: "#00B8FF"
            visible: tabRoot.isSelected
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: "#1E2533"
            visible: !tabRoot.isLast
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: tabRoot.title
            color: tabRoot.isSelected ? "#0A1428" : "#99AABF"
            font.pixelSize: 21
            font.weight: tabRoot.isSelected ? Font.DemiBold : Font.Normal
            font.family: "Roboto"
            wrapMode: Text.WordWrap
            lineHeight: 1.15
        }

        MouseArea {
            id: tabMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tabRoot.clicked()
        }
    }

    // Date/Time Stepper Column Component (Photo 2)
    component DateTimeStepperCol: Column {
        id: stepperRoot
        property string label: ""
        property string valText: ""
        property int colWidth: 100
        signal upClicked()
        signal downClicked()

        spacing: 6
        width: colWidth

        // Up Arrow Button
        Rectangle {
            width: parent.width
            height: 48
            radius: 3
            color: upMouse.pressed ? "#1E88E5" : (upMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
            border.color: upMouse.pressed ? "#80D8FF" : "#3F74A3"
            border.width: 1

            Behavior on color { ColorAnimation { duration: 90 } }

            Text {
                anchors.centerIn: parent
                text: "▲"
                color: "#FFFFFF"
                font.pixelSize: 18
                scale: upMouse.pressed ? 0.88 : 1.0
            }

            MouseArea {
                id: upMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: stepperRoot.upClicked()
            }
        }

        // Center Value Box (White box matching Photo 2)
        Rectangle {
            width: parent.width
            height: 64
            radius: 2
            color: "#FFFFFF"

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: stepperRoot.label
                    color: "#2C6FA8"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                    visible: stepperRoot.label !== ""
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: stepperRoot.valText
                    color: "#0A1428"
                    font.pixelSize: 24
                    font.weight: Font.Bold
                    font.family: "Roboto"
                }
            }
        }

        // Down Arrow Button
        Rectangle {
            width: parent.width
            height: 48
            radius: 3
            color: downMouse.pressed ? "#1E88E5" : (downMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
            border.color: downMouse.pressed ? "#80D8FF" : "#3F74A3"
            border.width: 1

            Behavior on color { ColorAnimation { duration: 90 } }

            Text {
                anchors.centerIn: parent
                text: "▼"
                color: "#FFFFFF"
                font.pixelSize: 18
                scale: downMouse.pressed ? 0.88 : 1.0
            }

            MouseArea {
                id: downMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: stepperRoot.downClicked()
            }
        }
    }
}
