/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: BluetoothConnectionsScreen.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#05070B"

    signal backClicked()
    signal menuClicked()
    signal devicePairingCompleted(string returnScreen)

    // Screen State
    property string currentView: "list" // "list" | "add_new"
    property int currentStep: 1        // 1 to 5 for Add New tutorial
    property var deviceNamesPool: ["Galaxy S24 Ultra", "OnePlus 12", "iPhone 16 Pro", "Pixel 9 Pro", "Nothing Phone (2)"]
    property int poolIndex: 0
    property string pendingDeviceName: deviceNamesPool[poolIndex]
    property string returnScreenAfterAdd: "list"

    // Preferences Dialog State (Photo 1788551459783)
    property bool showPreferencesModal: false
    property int prefTargetIndex: 0
    property string prefTargetName: ""
    property bool prefHandsFree: true
    property bool prefAudio: true
    property bool prefIsAddingNew: false

    // Disconnecting / Disconnected Modal State (Photos 1788551610294 & 1788551717980)
    property bool showDisconnectingModal: false
    property bool showDisconnectedModal: false
    property string modalDeviceName: ""

    // Menu dropdown state
    property bool showMenuDropdown: false

    // Delete mode / view state (Photo media_1788552761346)
    property bool isDeleteMode: false
    property var deleteSelection: []

    function resetToDefault() {
        currentView = "list"
        currentStep = 1
        returnScreenAfterAdd = "list"
        showPreferencesModal = false
        showDisconnectingModal = false
        showDisconnectedModal = false
        showMenuDropdown = false
        isDeleteMode = false
        deleteSelection = []
    }

    function isIndexMarked(idx) {
        return deleteSelection.indexOf(idx) !== -1
    }

    function toggleMarkIndex(idx) {
        var arr = deleteSelection.slice()
        var pos = arr.indexOf(idx)
        if (pos !== -1) {
            arr.splice(pos, 1)
        } else {
            arr.push(idx)
        }
        deleteSelection = arr
    }

    function markAllDevices() {
        var arr = []
        for (var i = 0; i < systemController.bluetoothDeviceList.length; i++) {
            arr.push(i)
        }
        deleteSelection = arr
    }

    function unmarkAllDevices() {
        deleteSelection = []
    }

    function deleteMarkedDevices() {
        if (deleteSelection.length === 0) return
        console.log("[Bluetooth] Deleting marked devices:", deleteSelection)
        systemController.deleteMultipleBluetoothDevices(deleteSelection)
        deleteSelection = []
        root.currentView = "list"
    }

    function deleteDeviceAt(idx) {
        systemController.removeDevice(idx)
        if (systemController.bluetoothDeviceList.length === 0) {
            root.isDeleteMode = false
        }
    }

    // ====================================================
    // 1. SUB-HEADER BAR
    // ====================================================
    Rectangle {
        id: headerBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 56
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
                    text: {
                        if (root.currentView === "delete") return "Delete devices (" + root.deleteSelection.length + "/" + systemController.bluetoothDeviceList.length + ")"
                        return "Bluetooth connections"
                    }
                    color: "#FFFFFF"
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                }
            }

            Item { Layout.fillWidth: true }

            // Right Action Buttons: Menu (if list view) + Back (⮌)
            Row {
                spacing: 12
                Layout.alignment: Qt.AlignVCenter

                // Menu Button (only visible on list view)
                Rectangle {
                    visible: root.currentView === "list"
                    width: 90
                    height: 40
                    color: menuMouse.pressed ? "#389BFF" : (menuMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                    border.color: menuMouse.pressed ? "#80D8FF" : "#3F74A3"
                    border.width: 1
                    radius: 3

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
                        onClicked: {
                            root.showMenuDropdown = !root.showMenuDropdown
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

                    Image {
                        anchors.centerIn: parent
                        width: 30
                        height: 26
                        source: "qrc:/assets/ui/icon_back.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        scale: backMouse.pressed ? 0.92 : 1.0
                    }

                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.showMenuDropdown = false
                            if (root.currentView === "add_new") {
                                if (root.returnScreenAfterAdd !== "" && root.returnScreenAfterAdd !== "list") {
                                    var targetScreen = root.returnScreenAfterAdd
                                    root.returnScreenAfterAdd = "list"
                                    root.currentView = "list"
                                    root.devicePairingCompleted(targetScreen)
                                } else {
                                    root.currentView = "list"
                                }
                            } else if (root.currentView === "delete") {
                                root.deleteSelection = []
                                root.currentView = "list"
                            } else {
                                root.backClicked()
                            }
                        }
                    }
                }
            }
        }
    }

    // Menu Dropdown Card
    Rectangle {
        id: menuDropdown
        anchors.top: headerBar.bottom
        anchors.topMargin: 4
        anchors.right: parent.right
        anchors.rightMargin: 90
        width: 220
        height: 104
        radius: 6
        color: "#132130"
        border.color: "#2E4766"
        border.width: 1.5
        visible: root.showMenuDropdown && root.currentView === "list"
        z: 80

        Column {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 2

            // Option 1: Bluetooth Preferences
            Rectangle {
                width: parent.width
                height: 46
                radius: 4
                color: item1Mouse.pressed ? "#224A75" : (item1Mouse.containsMouse ? "#1A3654" : "transparent")

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Bluetooth Preferences"
                    color: "#FFFFFF"
                    font.pixelSize: 16
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: item1Mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.showMenuDropdown = false
                        if (systemController.bluetoothDeviceList.length > 0) {
                            var idx = Math.max(0, systemController.activeDeviceIndex)
                            var dev = systemController.bluetoothDeviceList[idx]
                            root.prefTargetIndex = idx
                            root.prefTargetName = dev.name
                            root.prefHandsFree = dev.handsFree
                            root.prefAudio = dev.audio
                            root.prefIsAddingNew = false
                            root.showPreferencesModal = true
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width - 20
                height: 1
                color: "#1E334A"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Option 2: Delete Devices
            Rectangle {
                width: parent.width
                height: 46
                radius: 4
                color: item2Mouse.pressed ? "#224A75" : (item2Mouse.containsMouse ? "#1A3654" : "transparent")

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Delete devices"
                    color: "#FFFFFF"
                    font.pixelSize: 16
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: item2Mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.showMenuDropdown = false
                        root.deleteSelection = []
                        root.currentView = "delete"
                    }
                }
            }
        }
    }

    // Close menu when clicking outside
    MouseArea {
        anchors.fill: parent
        visible: root.showMenuDropdown
        z: 70
        onClicked: root.showMenuDropdown = false
    }

    // ====================================================
    // 2. MAIN CONTENT AREA (List or Add New)
    // ====================================================
    Item {
        anchors.top: headerBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        // ----------------------------------------------------
        // VIEW A: BLUETOOTH CONNECTIONS LIST
        // ----------------------------------------------------
        Item {
            anchors.fill: parent
            visible: root.currentView === "list" || root.currentView === "add_new"

            // Empty State View when no devices are registered
            Column {
                anchors.centerIn: parent
                spacing: 16
                visible: systemController.bluetoothDeviceList.length === 0

                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 60
                    height: 60
                    source: "qrc:/assets/bluetooth/icon_device_conn.png"
                    fillMode: Image.PreserveAspectFit
                    opacity: 0.35
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No registered Bluetooth devices"
                    color: "#FFFFFF"
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Select \"Add new\" below to pair your phone."
                    color: "#7E96AD"
                    font.pixelSize: 18
                    font.family: "Roboto"
                }
            }

            // Device List View
            ListView {
                id: deviceListView
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: bottomButtonsBar.top
                anchors.topMargin: 10
                clip: true
                visible: systemController.bluetoothDeviceList.length > 0
                model: systemController.bluetoothDeviceList

                delegate: Rectangle {
                    id: devRow
                    width: deviceListView.width
                    height: 76
                    color: devRowMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.22) : (devRowMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.08) : "transparent")

                    Behavior on color { ColorAnimation { duration: 120 } }

                    property var devData: modelData
                    property bool isConnected: devData.connected === true
                    property bool hasHF: devData.handsFree === true
                    property bool hasAudio: devData.audio === true

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 36
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 24

                        // Device Number (1, 2, ...)
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (index + 1).toString()
                            color: "#FFFFFF"
                            font.pixelSize: 26
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        // Device Name (Cyan when connected, white when inactive)
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: devData.name || "Bluetooth Device"
                            color: isConnected ? "#38B6FF" : "#FFFFFF"
                            font.pixelSize: 26
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    // Right Side: Separate Interactive Service Icons (Hands-free Calling | Bluetooth Audio)
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 48
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 28

                        // Normal Mode Icons
                        Row {
                            spacing: 24
                            visible: !root.isDeleteMode

                            // Headset Icon (Independent Hands-free toggle button)
                            Rectangle {
                                width: 44
                                height: 44
                                radius: 22
                                color: hfMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.25) : (hfMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.12) : "transparent")

                                Image {
                                    anchors.centerIn: parent
                                    width: 34
                                    height: 32
                                    source: "qrc:/assets/bluetooth/icon_bt_headset.png"
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                    opacity: hasHF ? 1.0 : 0.35
                                    scale: hfMouse.pressed ? 0.92 : 1.0
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    id: hfMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (hasHF) {
                                            // Disconnect Hands-free on this device
                                            root.modalDeviceName = devData.name
                                            root.showDisconnectingModal = true
                                            deactivateTimer.oldIndex = index
                                            deactivateTimer.deviceName = devData.name
                                            deactivateTimer.targetAction = "disconnect_only"
                                            deactivateTimer.start()
                                        } else {
                                            // Connect Hands-free on this device
                                            var activeOtherIndex = -1
                                            var activeOtherName = ""
                                            var list = systemController.bluetoothDeviceList
                                            for (var i = 0; i < list.length; ++i) {
                                                if (i !== index && list[i].handsFree === true) {
                                                    activeOtherIndex = i
                                                    activeOtherName = list[i].name
                                                    break
                                                }
                                            }

                                            if (activeOtherIndex >= 0) {
                                                // Deactivate older device hands-free first
                                                root.modalDeviceName = activeOtherName
                                                root.showDisconnectingModal = true
                                                deactivateTimer.oldIndex = activeOtherIndex
                                                deactivateTimer.deviceName = activeOtherName
                                                deactivateTimer.newTargetIndex = index
                                                deactivateTimer.targetAction = "switch_hf"
                                                deactivateTimer.start()
                                            } else {
                                                systemController.setDevicePreferences(index, true, hasAudio)
                                            }
                                        }
                                    }
                                }
                            }

                            // Music Audio Waves Icon (Independent Bluetooth Audio toggle button)
                            Rectangle {
                                width: 44
                                height: 44
                                radius: 22
                                color: audioMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.25) : (audioMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.12) : "transparent")

                                Image {
                                    anchors.centerIn: parent
                                    width: 36
                                    height: 30
                                    source: "qrc:/assets/bluetooth/icon_bt_audio.png"
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                    opacity: hasAudio ? 1.0 : 0.35
                                    scale: audioMouse.pressed ? 0.92 : 1.0
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    id: audioMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        systemController.toggleDeviceAudio(index)
                                    }
                                }
                            }
                        }

                        // Delete Mode Trash/Delete Button
                        Rectangle {
                            visible: root.isDeleteMode
                            width: 84
                            height: 40
                            radius: 4
                            color: delItemMouse.pressed ? "#D32F2F" : "#B71C1C"
                            border.color: "#FF5252"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "Delete"
                                color: "#FFFFFF"
                                font.pixelSize: 16
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                id: delItemMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.deleteDeviceAt(index)
                                }
                            }
                        }
                    }

                    // Hairline separator below row
                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 36
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: "#181D26"
                    }

                    // Clicking the row connects the device or switches to it
                    MouseArea {
                        id: devRowMouse
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.rightMargin: 160
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.isDeleteMode) return
                            if (!isConnected || !hasHF) {
                                var activeOtherIdx = -1
                                var activeOtherNm = ""
                                var dList = systemController.bluetoothDeviceList
                                for (var k = 0; k < dList.length; ++k) {
                                    if (k !== index && dList[k].handsFree === true) {
                                        activeOtherIdx = k
                                        activeOtherNm = dList[k].name
                                        break
                                    }
                                }
                                if (activeOtherIdx >= 0) {
                                    root.modalDeviceName = activeOtherNm
                                    root.showDisconnectingModal = true
                                    deactivateTimer.oldIndex = activeOtherIdx
                                    deactivateTimer.deviceName = activeOtherNm
                                    deactivateTimer.newTargetIndex = index
                                    deactivateTimer.targetAction = "switch_hf"
                                    deactivateTimer.start()
                                } else {
                                    systemController.connectDevice(index)
                                }
                            }
                        }
                    }
                }
            }

            // Bottom Buttons Bar ("Add new" | "Delete devices")
            RowLayout {
                id: bottomButtonsBar
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.right: parent.right
                anchors.rightMargin: 24
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 20
                height: 54
                spacing: 16

                // Button 1: "Add new"
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 3
                    color: addMouse.pressed ? "#2A4E78" : (addMouse.containsMouse ? "#203A58" : "#172A40")
                    border.color: addMouse.pressed ? "#4D86BE" : "#243E5D"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Add new"
                        color: addMouse.pressed ? "#FFFFFF" : "#7EAAC8"
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                        scale: addMouse.pressed ? 0.96 : 1.0
                    }

                    MouseArea {
                        id: addMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.currentStep = 1
                            root.currentView = "add_new"
                            root.isDeleteMode = false
                        }
                    }
                }

                // Button 2: "Delete devices"
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 3
                    color: delMouse.pressed ? "#389BFF" : (delMouse.containsMouse ? "#3A6C9B" : "#2A5680")
                    border.color: delMouse.pressed ? "#80D8FF" : "#3C72A4"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Delete devices"
                        color: "#B8DAFB"
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                        scale: delMouse.pressed ? 0.96 : 1.0
                    }

                    MouseArea {
                        id: delMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.deleteSelection = []
                            root.currentView = "delete"
                        }
                    }
                }
            }
        }

        // ----------------------------------------------------
        // VIEW B: "ADD NEW DEVICE" (Exact OEM Modal Dialog matching Photo)
        // ----------------------------------------------------
        Item {
            anchors.fill: parent
            visible: root.currentView === "add_new"
            z: 50

            // Semi-transparent scrim so background Bluetooth connections screen stays visible
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.45)
            }

            // Centered Framed Modal Dialog matching automotive cockpit screen
            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width - 80, 920)
                height: Math.min(parent.height - 24, 460)
                color: "#08101A"
                border.color: "#2C4C70"
                border.width: 1.5
                radius: 4
                clip: true

                // Header Banner: "Add new device" (Solid blue bar with centered text)
                Rectangle {
                    id: addNewHdr
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 48
                    color: "#1B3A5E"

                    Text {
                        anchors.centerIn: parent
                        text: "Add new device"
                        color: "#E2F0FD"
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: "#2C5078"
                    }
                }

                // Inner Content Split (Matching user's photo exactly)
                RowLayout {
                    anchors.top: addNewHdr.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: cancelAddNewBtn.top
                    anchors.margins: 18
                    spacing: 24

                    // ============================================
                    // LEFT SIDE: Smartphone 5-Step Guide Box (Photo)
                    // ============================================
                    Item {
                        Layout.preferredWidth: 380
                        Layout.fillHeight: true

                        // Framed Illustration Box matching real car screen photo
                        Rectangle {
                            anchors.centerIn: parent
                            width: 360
                            height: 270
                            radius: 4
                            color: "transparent"
                            border.color: "#24405E"
                            border.width: 1.2

                            // Smartphone Graphic
                            Item {
                                anchors.top: parent.top
                                anchors.topMargin: 12
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 220
                                height: 180

                                Image {
                                    id: phoneImg
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                    source: "qrc:/assets/bluetooth/bt_guide_step" + root.currentStep + ".png"

                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }
                            }

                            // Bottom Navigation: [ ◀ ]   1/5   [ ▶ ]
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 14
                                spacing: 24

                                // Left Button (◀)
                                Rectangle {
                                    width: 52
                                    height: 36
                                    radius: 3
                                    color: prevMouse.pressed ? "#389BFF" : "#224A73"
                                    border.color: "#386594"
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "◀"
                                        color: root.currentStep > 1 ? "#FFFFFF" : "#557292"
                                        font.pixelSize: 16
                                    }

                                    MouseArea {
                                        id: prevMouse
                                        anchors.fill: parent
                                        cursorShape: root.currentStep > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: {
                                            if (root.currentStep > 1) root.currentStep--
                                        }
                                    }
                                }

                                // Center Step Text ("1/5")
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.currentStep + "/5"
                                    color: "#FFFFFF"
                                    font.pixelSize: 22
                                    font.weight: Font.DemiBold
                                    font.family: "Roboto"
                                }

                                // Right Button (▶)
                                Rectangle {
                                    width: 52
                                    height: 36
                                    radius: 3
                                    color: nextMouse.pressed ? "#389BFF" : "#224A73"
                                    border.color: "#386594"
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "▶"
                                        color: root.currentStep < 5 ? "#FFFFFF" : "#557292"
                                        font.pixelSize: 16
                                    }

                                    MouseArea {
                                        id: nextMouse
                                        anchors.fill: parent
                                        cursorShape: root.currentStep < 5 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: {
                                            if (root.currentStep < 5) {
                                                root.currentStep++
                                            } else {
                                                root.initiateDevicePairing()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ============================================
                    // RIGHT SIDE: Vehicle Name & Instructions (Photo)
                    // ============================================
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Column {
                            anchors.centerIn: parent
                            spacing: 16
                            width: parent.width - 24

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Vehicle name :"
                                color: "#8EABCB"
                                font.pixelSize: 24
                                font.family: "Roboto"
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: systemController.vehicleName
                                color: "#FFFFFF"
                                font.pixelSize: 44
                                font.weight: Font.Bold
                                font.family: "Roboto"

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.initiateDevicePairing()
                                }
                            }

                            Item { width: 1; height: 8 }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: "Search for the vehicle name in\nyour Bluetooth device and\nconfirm pairing."
                                color: "#8EABCB"
                                font.pixelSize: 22
                                font.family: "Roboto"
                                lineHeight: 1.35
                            }
                        }
                    }
                }

                // Bottom Cancel Button (Exact match to real car photo)
                Rectangle {
                    id: cancelAddNewBtn
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 14
                    height: 50
                    radius: 3
                    color: cancelAddMouse.pressed ? "#389BFF" : (cancelAddMouse.containsMouse ? "#2C5C8A" : "#224A73")
                    border.color: cancelAddMouse.pressed ? "#80D8FF" : "#356E9E"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: "#D0E7FF"
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }

                    MouseArea {
                        id: cancelAddMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.currentView = "list"
                            if (root.returnScreenAfterAdd !== "" && root.returnScreenAfterAdd !== "list") {
                                root.devicePairingCompleted(root.returnScreenAfterAdd)
                                root.returnScreenAfterAdd = "list"
                            }
                        }
                    }
                }
            }
        }

        // ----------------------------------------------------
        // VIEW C: DELETE DEVICES (Exact Match to Photo 1!)
        // ----------------------------------------------------
        Item {
            anchors.fill: parent
            visible: root.currentView === "delete"

            // Device List with Checkboxes
            ListView {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: deleteActionBar.top
                clip: true
                model: systemController.bluetoothDeviceList

                delegate: Rectangle {
                    width: parent ? parent.width : 0
                    height: 76
                    color: devRowMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.15) : (devRowMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.06) : "transparent")

                    readonly property int devIndex: index
                    readonly property var devData: modelData
                    readonly property bool isChecked: root.isIndexMarked(devIndex)

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 36
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 20

                        // Checkbox matching real car photo
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 26
                            height: 26
                            radius: 3
                            color: "transparent"
                            border.color: isChecked ? "#FFFFFF" : "#C8DCF0"
                            border.width: 2.0

                            Text {
                                anchors.centerIn: parent
                                text: "✓"
                                color: "#38B6FF"
                                font.pixelSize: 18
                                font.weight: Font.Bold
                                visible: isChecked
                            }
                        }

                        // Device Name (Cyan / light blue color matching photo!)
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: devData.name || "Bluetooth Device"
                            color: "#3CA9F8"
                            font.pixelSize: 24
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 36
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: "#181D26"
                    }

                    MouseArea {
                        id: devRowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleMarkIndex(devIndex)
                    }
                }
            }

            // Empty state if no devices
            Column {
                anchors.centerIn: parent
                spacing: 16
                visible: systemController.bluetoothDeviceList.length === 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No devices to delete"
                    color: "#8E9EAF"
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                }
            }

            // Bottom Action Bar: [ Mark all ] [ Unmark all ] [ Delete ]
            Rectangle {
                id: deleteActionBar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 62
                color: "#080E16"

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 1
                    color: "#1E2736"
                }

                Row {
                    anchors.fill: parent
                    spacing: 4
                    anchors.margins: 4

                    // 1. Mark all
                    Rectangle {
                        width: (parent.width - 8) / 3
                        height: parent.height
                        radius: 2
                        color: markAllMouse.pressed ? "#389BFF" : (markAllMouse.containsMouse ? "#2B5886" : "#224A73")
                        border.color: "#3C72A4"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Mark all"
                            color: "#FFFFFF"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        MouseArea {
                            id: markAllMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.markAllDevices()
                        }
                    }

                    // 2. Unmark all
                    Rectangle {
                        width: (parent.width - 8) / 3
                        height: parent.height
                        radius: 2
                        color: unmarkAllMouse.pressed ? "#389BFF" : (unmarkAllMouse.containsMouse ? "#2B5886" : "#224A73")
                        border.color: "#3C72A4"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Unmark all"
                            color: "#FFFFFF"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        MouseArea {
                            id: unmarkAllMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.unmarkAllDevices()
                        }
                    }

                    // 3. Delete
                    Rectangle {
                        readonly property bool hasSelection: root.deleteSelection.length > 0
                        width: (parent.width - 8) / 3
                        height: parent.height
                        radius: 2
                        color: hasSelection ? (deleteBtnMouse.pressed ? "#389BFF" : (deleteBtnMouse.containsMouse ? "#2B5886" : "#224A73")) : "#162230"
                        border.color: hasSelection ? "#3C72A4" : "#253344"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Delete"
                            color: parent.hasSelection ? "#FFFFFF" : "#55677D"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        MouseArea {
                            id: deleteBtnMouse
                            anchors.fill: parent
                            enabled: parent.hasSelection
                            hoverEnabled: true
                            cursorShape: parent.hasSelection ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.deleteMarkedDevices()
                        }
                    }
                }
            }
        }
    }

    // ====================================================
    // 3. AUTHENTIC AUTOMOTIVE PAIRING & DEACTIVATION LOGIC
    // ====================================================

    // Triggered when phone connects to vehicle
    function initiateDevicePairing() {
        console.log("[Bluetooth] Phone initiating connection for:", root.pendingDeviceName)

        // Check if an existing device currently has Hands-free active
        var activeOldDevice = ""
        var oldIndex = -1
        var devList = systemController.bluetoothDeviceList
        for (var i = 0; i < devList.length; ++i) {
            if (devList[i].handsFree === true) {
                activeOldDevice = devList[i].name
                oldIndex = i
                break
            }
        }

        if (activeOldDevice !== "") {
            // Older device must disconnect hands-free (Photo 1788551610294)
            root.modalDeviceName = activeOldDevice
            root.showDisconnectingModal = true

            deactivateTimer.oldIndex = oldIndex
            deactivateTimer.deviceName = activeOldDevice
            deactivateTimer.targetAction = "pair_new"
            deactivateTimer.start()
        } else {
            // Directly show Preferences (Photo 1788551459783) for the new device
            openNewDevicePreferences()
        }
    }

    function openNewDevicePreferences() {
        root.prefTargetName = root.pendingDeviceName
        root.prefHandsFree = true
        root.prefAudio = true
        root.prefIsAddingNew = true
        root.showPreferencesModal = true
    }

    // Timer 1: Disconnecting -> Disconnected (Photo 1788551610294 to Photo 1788551717980)
    Timer {
        id: deactivateTimer
        property int oldIndex: 0
        property int newTargetIndex: -1
        property string deviceName: ""
        property string targetAction: "pair_new" // "pair_new" | "disconnect_only" | "switch_hf"
        interval: 1400
        repeat: false
        onTriggered: {
            root.showDisconnectingModal = false
            // Deactivate hands-free on older device
            systemController.deactivateHandsFree(oldIndex)

            // Show "Hands-free is disconnected." (Photo 1788551717980)
            root.modalDeviceName = deviceName
            root.showDisconnectedModal = true
            disconnectedNoticeTimer.start()
        }
    }

    // Timer 2: Dismiss Disconnected notice -> Proceed to preferences or connection
    Timer {
        id: disconnectedNoticeTimer
        interval: 1300
        repeat: false
        onTriggered: {
            root.showDisconnectedModal = false
            if (deactivateTimer.targetAction === "pair_new") {
                // Open Bluetooth Preferences for the new device
                root.openNewDevicePreferences()
            } else if (deactivateTimer.targetAction === "switch_hf") {
                // Connect hands-free to target device
                if (deactivateTimer.newTargetIndex >= 0) {
                    var currentAudio = systemController.bluetoothDeviceList[deactivateTimer.newTargetIndex].audio
                    systemController.setDevicePreferences(deactivateTimer.newTargetIndex, true, currentAudio)
                }
            }
        }
    }

    // ====================================================
    // MODAL 1: BLUETOOTH PREFERENCES (Photo 1788551459783 Exact Match!)
    // ====================================================
    Rectangle {
        id: preferencesModalOverlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.65)
        visible: root.showPreferencesModal
        z: 100

        MouseArea { anchors.fill: parent }

        Rectangle {
            anchors.centerIn: parent
            width: 720
            height: 380
            radius: 6
            color: "#0F1A28"
            border.color: "#2C496A"
            border.width: 1.5

            Column {
                anchors.fill: parent
                spacing: 0

                // Dialog Header Bar
                Rectangle {
                    width: parent.width
                    height: 52
                    color: "#182E47"
                    radius: 5

                    Text {
                        anchors.centerIn: parent
                        text: "Bluetooth Preferences"
                        color: "#FFFFFF"
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }
                }

                // Checkboxes Area (Photo 1788551459783 Match!)
                Item {
                    width: parent.width
                    height: 230

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 48
                        anchors.top: parent.top
                        anchors.topMargin: 24
                        spacing: 22

                        // Row 1: Hands-free Calling Checkbox
                        Row {
                            spacing: 18
                            Rectangle {
                                width: 26; height: 26; radius: 3
                                color: root.prefHandsFree ? "#389BFF" : "#132130"
                                border.color: root.prefHandsFree ? "#80D8FF" : "#3D5B7D"
                                border.width: 1.5

                                Text {
                                    anchors.centerIn: parent
                                    visible: root.prefHandsFree
                                    text: "✓"
                                    color: "#FFFFFF"
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.prefHandsFree = !root.prefHandsFree
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Hands-free Calling"
                                color: "#FFFFFF"
                                font.pixelSize: 24
                                font.weight: Font.Medium
                                font.family: "Roboto"

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.prefHandsFree = !root.prefHandsFree
                                }
                            }
                        }

                        // Row 2: Bluetooth Audio Checkbox
                        Row {
                            spacing: 18
                            Rectangle {
                                width: 26; height: 26; radius: 3
                                color: root.prefAudio ? "#389BFF" : "#132130"
                                border.color: root.prefAudio ? "#80D8FF" : "#3D5B7D"
                                border.width: 1.5

                                Text {
                                    anchors.centerIn: parent
                                    visible: root.prefAudio
                                    text: "✓"
                                    color: "#FFFFFF"
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.prefAudio = !root.prefAudio
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Bluetooth Audio"
                                color: "#FFFFFF"
                                font.pixelSize: 24
                                font.weight: Font.Medium
                                font.family: "Roboto"

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.prefAudio = !root.prefAudio
                                }
                            }
                        }

                        Item { width: 1; height: 10 }

                        // Subtitle Instruction text (Exact Photo 1788551459783 Match!)
                        Text {
                            text: "Please select the function you want to use."
                            color: "#8FAABF"
                            font.pixelSize: 20
                            font.family: "Roboto"
                        }
                    }
                }

                // Bottom [ OK ] and [ Cancel ] Buttons (Exact Photo 1788551459783 Match!)
                RowLayout {
                    width: parent.width - 40
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 54
                    spacing: 16

                    // OK Button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: 4
                        color: okPrefMouse.pressed ? "#389BFF" : (okPrefMouse.containsMouse ? "#3A6C9B" : "#244E78")
                        border.color: "#3F77A8"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "OK"
                            color: "#FFFFFF"
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        MouseArea {
                            id: okPrefMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.showPreferencesModal = false
                                if (root.prefIsAddingNew) {
                                    // Add the new device into controller
                                    systemController.addDevice(root.pendingDeviceName, root.prefHandsFree, root.prefAudio)
                                    // Advance to next realistic device name
                                    root.poolIndex = (root.poolIndex + 1) % root.deviceNamesPool.length
                                    root.pendingDeviceName = root.deviceNamesPool[root.poolIndex]
                                    root.currentView = "list"

                                    // If invoked from another screen (e.g. Phone), return smoothly
                                    if (root.returnScreenAfterAdd !== "" && root.returnScreenAfterAdd !== "list") {
                                        var ret = root.returnScreenAfterAdd
                                        root.returnScreenAfterAdd = "list"
                                        root.devicePairingCompleted(ret)
                                    }
                                } else {
                                    // Update existing device preferences
                                    var currentHF = systemController.bluetoothDeviceList[root.prefTargetIndex].handsFree
                                    if (currentHF && !root.prefHandsFree) {
                                        root.modalDeviceName = root.prefTargetName
                                        root.showDisconnectingModal = true
                                        deactivateTimer.oldIndex = root.prefTargetIndex
                                        deactivateTimer.deviceName = root.prefTargetName
                                        deactivateTimer.targetAction = "disconnect_only"
                                        deactivateTimer.start()
                                    } else {
                                        systemController.setDevicePreferences(root.prefTargetIndex, root.prefHandsFree, root.prefAudio)
                                    }
                                }
                            }
                        }
                    }

                    // Cancel Button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: 4
                        color: cancelPrefMouse.pressed ? "#389BFF" : (cancelPrefMouse.containsMouse ? "#3A6C9B" : "#244E78")
                        border.color: "#3F77A8"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: "#FFFFFF"
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        MouseArea {
                            id: cancelPrefMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.showPreferencesModal = false
                                if (root.prefIsAddingNew) {
                                    root.currentView = "list"
                                    if (root.returnScreenAfterAdd !== "" && root.returnScreenAfterAdd !== "list") {
                                        var ret = root.returnScreenAfterAdd
                                        root.returnScreenAfterAdd = "list"
                                        root.devicePairingCompleted(ret)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ====================================================
    // MODAL 2: DISCONNECTING HANDS-FREE... (Photo 1788551610294 Exact Match!)
    // ====================================================
    Rectangle {
        id: disconnectingModalOverlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.7)
        visible: root.showDisconnectingModal
        z: 110

        MouseArea { anchors.fill: parent }

        Rectangle {
            anchors.centerIn: parent
            width: 680
            height: 290
            radius: 6
            color: "#0D1826"
            border.color: "#27405E"
            border.width: 1.5

            Column {
                anchors.centerIn: parent
                spacing: 16
                width: parent.width - 40

                // Circular Rotating Loading Dots Ring (Photo 1788551610294 Match!)
                Item {
                    width: 60
                    height: 60
                    anchors.horizontalCenter: parent.horizontalCenter

                    Repeater {
                        model: 12
                        Item {
                            anchors.centerIn: parent
                            width: 60
                            height: 60
                            rotation: index * 30

                            Rectangle {
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 5
                                height: 9
                                radius: 2.5
                                color: "#FFFFFF"
                                opacity: Math.max(0.12, 1.0 - (index / 12.0))
                            }
                        }
                    }

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: root.showDisconnectingModal
                    }
                }

                // Device Name (e.g., Redmi Note 13 Pro 5G)
                Text {
                    text: root.modalDeviceName
                    color: "#FFFFFF"
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Disconnecting hands-free..."
                    color: "#C3D8EC"
                    font.pixelSize: 22
                    font.family: "Roboto"
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Please wait."
                    color: "#C3D8EC"
                    font.pixelSize: 22
                    font.family: "Roboto"
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    // ====================================================
    // MODAL 3: HANDS-FREE IS DISCONNECTED. (Photo 1788551717980 Exact Match!)
    // ====================================================
    Rectangle {
        id: disconnectedModalOverlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.7)
        visible: root.showDisconnectedModal
        z: 110

        MouseArea { anchors.fill: parent }

        Rectangle {
            anchors.centerIn: parent
            width: 680
            height: 250
            radius: 6
            color: "#0D1826"
            border.color: "#27405E"
            border.width: 1.5

            Column {
                anchors.centerIn: parent
                spacing: 16
                width: parent.width - 40

                // Cyan Info Circle Icon ⓘ (Photo 1788551717980 Match!)
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 50
                    height: 50
                    radius: 25
                    color: "#38B6FF"

                    Text {
                        anchors.centerIn: parent
                        text: "i"
                        color: "#0B1522"
                        font.pixelSize: 32
                        font.weight: Font.Bold
                        font.family: "Roboto"
                    }
                }

                Text {
                    text: root.modalDeviceName
                    color: "#FFFFFF"
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Hands-free is disconnected."
                    color: "#C3D8EC"
                    font.pixelSize: 22
                    font.family: "Roboto"
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
