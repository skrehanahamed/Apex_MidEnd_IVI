/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: DeviceConnectionScreen.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#05070B"

    signal backClicked()
    signal menuClicked()
    signal bluetoothConnectionsClicked()

    property string selectedTab: "bluetooth"
    property string currentView: "main" // "main" | "priority" | "privacy" | "bt_info" | "vehicle_name" | "passkey"
    property string tempVehicleName: systemController.vehicleName
    property string tempPasskey: systemController.passkey
    property bool isKeyboardShift: false
    property bool isCapsLock: false
    property bool isSymbolMode: false
    property bool isSymbolPage2: false
    property string keyboardLang: "ENG"
    property bool passkeyEdited: false
    property bool vNameExiting: false
    property bool passkeyExiting: false

    function resetToDefault() {
        currentView = "main"
        selectedTab = "bluetooth"
        isKeyboardShift = false
        isCapsLock = false
        isSymbolMode = false
        isSymbolPage2 = false
        keyboardLang = "ENG"
        passkeyEdited = false
        vNameExiting = false
        passkeyExiting = false
        tempVehicleName = systemController.vehicleName
        tempPasskey = systemController.passkey
    }

    function insertKey(k) {
        if (!vNameInput) return
        if (vNameInput.text.length >= 24) return
        if (vNameInput.selectedText.length > 0) {
            var selStart = vNameInput.selectionStart
            vNameInput.remove(vNameInput.selectionStart, vNameInput.selectionEnd)
            vNameInput.insert(selStart, k)
        } else {
            vNameInput.insert(vNameInput.cursorPosition, k)
        }
        if (root.isKeyboardShift && !root.isCapsLock) {
            root.isKeyboardShift = false
        }
    }

    function deleteKey() {
        if (!vNameInput) return
        if (vNameInput.selectedText.length > 0) {
            vNameInput.remove(vNameInput.selectionStart, vNameInput.selectionEnd)
        } else if (vNameInput.cursorPosition > 0) {
            vNameInput.remove(vNameInput.cursorPosition - 1, vNameInput.cursorPosition)
        }
    }

    function clearInput() {
        if (!vNameInput) return
        vNameInput.text = ""
        root.tempVehicleName = ""
    }

    function closeVehicleNameKeyboard(save) {
        if (root.vNameExiting) return
        if (save && vNameInput && vNameInput.text.trim().length > 0) {
            systemController.setVehicleName(vNameInput.text.trim())
        }
        root.vNameExiting = true
        exitTimer.restart()
    }

    function closePasskeyKeyboard(save) {
        if (root.passkeyExiting) return
        if (save && root.tempPasskey.length === 4) {
            systemController.setPasskey(root.tempPasskey)
        }
        root.passkeyExiting = true
        passkeyExitTimer.restart()
    }

    Timer {
        id: exitTimer
        interval: 260
        repeat: false
        onTriggered: {
            root.vNameExiting = false
            root.currentView = "bt_info"
        }
    }

    Timer {
        id: passkeyExitTimer
        interval: 260
        repeat: false
        onTriggered: {
            root.passkeyExiting = false
            root.currentView = "bt_info"
        }
    }

    Timer {
        id: passkeyAutoSaveTimer
        interval: 380
        repeat: false
        onTriggered: {
            if (root.tempPasskey.length === 4) {
                root.closePasskeyKeyboard(true)
            }
        }
    }

    onCurrentViewChanged: {
        if (currentView === "vehicle_name") {
            vNameExiting = false
            isKeyboardShift = false
            isCapsLock = false
            isSymbolMode = false
            isSymbolPage2 = false
            tempVehicleName = systemController.vehicleName
            if (vNameInput) {
                vNameInput.text = tempVehicleName
                vNameInput.cursorPosition = tempVehicleName.length
                vNameInput.forceActiveFocus()
            }
        } else if (currentView === "passkey") {
            passkeyExiting = false
            tempPasskey = systemController.passkey
            passkeyEdited = false
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ====================================================
        // 1. SUB-HEADER BAR ("Device connection settings" + Menu + Back)
        // ====================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            color: "#10141C"

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
                            if (root.currentView === "priority") return "Auto connection priority"
                            if (root.currentView === "privacy") return "Privacy mode"
                            if (root.currentView === "bt_info") return "Bluetooth system info"
                            if (root.currentView === "vehicle_name" && !root.vNameExiting) return "Vehicle name"
                            if (root.currentView === "passkey" && !root.passkeyExiting) return "Passkey"
                            if (root.vNameExiting || root.passkeyExiting) return "Bluetooth system info"
                            return "Device connection settings"
                        }
                        color: "#FFFFFF"
                        font.pixelSize: 24
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }
                }

                Item { Layout.fillWidth: true }

                // Right 2 Blue Buttons: Menu | Back (⮌)
                Row {
                    spacing: 12
                    Layout.alignment: Qt.AlignVCenter

                    // 1. Menu Button (only visible on main view)
                    Rectangle {
                        visible: root.currentView === "main"
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
                            onClicked: {
                                console.log("[DeviceConnection] Menu clicked")
                                root.menuClicked()
                            }
                        }
                    }

                    // 2. Back Arrow Button (⮌)
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
                                if (root.currentView === "vehicle_name") {
                                    root.closeVehicleNameKeyboard(true)
                                } else if (root.currentView === "passkey") {
                                    root.closePasskeyKeyboard(true)
                                } else if (root.currentView === "bt_info" || root.currentView === "priority" || root.currentView === "privacy") {
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
        // 2. MAIN SPLIT CONTENT: TABS (Left) + SETTINGS LIST (Right)
        // ====================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            visible: root.currentView === "main"

            // ------------------------------------------------
            // A. LEFT VERTICAL TABS SIDEBAR (Bluetooth | Android Auto | Apple CarPlay)
            // ------------------------------------------------
            Rectangle {
                Layout.preferredWidth: 260
                Layout.fillHeight: true
                color: "#05070B"

                // Right vertical divider separating tabs from list
                Rectangle {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    width: 1.5
                    color: "#1E222D"
                }

                Column {
                    anchors.fill: parent
                    anchors.leftMargin: 2
                    anchors.topMargin: 0
                    spacing: 0

                    // 1. Bluetooth Tab
                    Rectangle {
                        width: parent.width - 3
                        height: 72
                        color: root.selectedTab === "bluetooth"
                               ? "#C4E2FE"
                               : (btTabMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.25) : (btTabMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.08) : "transparent"))

                        Behavior on color { ColorAnimation { duration: 140 } }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 24
                            text: "Bluetooth"
                            color: root.selectedTab === "bluetooth" ? "#0A1428" : (btTabMouse.pressed ? "#70D6FF" : "#FFFFFF")
                            font.pixelSize: 26
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        MouseArea {
                            id: btTabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedTab = "bluetooth"
                        }
                    }

                    // 2. Android Auto Tab
                    Rectangle {
                        width: parent.width - 3
                        height: 84
                        color: root.selectedTab === "android_auto"
                               ? "#C4E2FE"
                               : (aaTabMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.25) : (aaTabMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.08) : "transparent"))

                        Behavior on color { ColorAnimation { duration: 140 } }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 24
                            text: "Android\nAuto"
                            color: root.selectedTab === "android_auto" ? "#0A1428" : (aaTabMouse.pressed ? "#70D6FF" : "#FFFFFF")
                            font.pixelSize: 26
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                            lineHeight: 1.1
                        }

                        MouseArea {
                            id: aaTabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedTab = "android_auto"
                        }
                    }

                    // 3. Apple CarPlay Tab
                    Rectangle {
                        width: parent.width - 3
                        height: 84
                        color: root.selectedTab === "carplay"
                               ? "#C4E2FE"
                               : (cpTabMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.25) : (cpTabMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.08) : "transparent"))

                        Behavior on color { ColorAnimation { duration: 140 } }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 24
                            text: "Apple\nCarPlay"
                            color: root.selectedTab === "carplay" ? "#0A1428" : (cpTabMouse.pressed ? "#70D6FF" : "#FFFFFF")
                            font.pixelSize: 26
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                            lineHeight: 1.1
                        }

                        MouseArea {
                            id: cpTabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedTab = "carplay"
                        }
                    }
                }
            }

            // ------------------------------------------------
            // B. RIGHT SETTINGS LIST AREA
            // ------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#05070B"

                // 1. BLUETOOTH SETTINGS LIST
                Column {
                    anchors.fill: parent
                    anchors.topMargin: 4
                    visible: root.selectedTab === "bluetooth"
                    spacing: 0

                    // Row 1: Bluetooth connections
                    Rectangle {
                        width: parent.width
                        height: 76
                        color: row1Mouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.22) : (row1Mouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.07) : "transparent")

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 36
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Bluetooth connections"
                            color: row1Mouse.pressed ? "#70D6FF" : "#FFFFFF"
                            font.pixelSize: 26
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        // Right Chevron ▶
                        Canvas {
                            anchors.right: parent.right
                            anchors.rightMargin: 48
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 20
                            scale: row1Mouse.pressed ? 0.9 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.fillStyle = "#FFFFFF";
                                ctx.beginPath();
                                ctx.moveTo(2, 2);
                                ctx.lineTo(13, 10);
                                ctx.lineTo(2, 18);
                                ctx.closePath();
                                ctx.fill();
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
                            id: row1Mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[DeviceConnection] Bluetooth connections clicked")
                                root.bluetoothConnectionsClicked()
                            }
                        }
                    }

                    // Row 2: Auto connection priority
                    Rectangle {
                        width: parent.width
                        height: 76
                        color: row2Mouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.22) : (row2Mouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.07) : "transparent")

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 36
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Auto connection priority"
                            color: row2Mouse.pressed ? "#70D6FF" : "#FFFFFF"
                            font.pixelSize: 26
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        // Right Chevron ▶
                        Canvas {
                            anchors.right: parent.right
                            anchors.rightMargin: 48
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 20
                            scale: row2Mouse.pressed ? 0.9 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.fillStyle = "#FFFFFF";
                                ctx.beginPath();
                                ctx.moveTo(2, 2);
                                ctx.lineTo(13, 10);
                                ctx.lineTo(2, 18);
                                ctx.closePath();
                                ctx.fill();
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
                            id: row2Mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[DeviceConnection] Auto connection priority clicked")
                                root.currentView = "priority"
                            }
                        }
                    }

                    // Row 3: Privacy mode
                    Rectangle {
                        width: parent.width
                        height: 76
                        color: row3Mouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.22) : (row3Mouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.07) : "transparent")

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 36
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Privacy mode"
                            color: row3Mouse.pressed ? "#70D6FF" : "#FFFFFF"
                            font.pixelSize: 26
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        // Right Chevron ▶
                        Canvas {
                            anchors.right: parent.right
                            anchors.rightMargin: 48
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 20
                            scale: row3Mouse.pressed ? 0.9 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.fillStyle = "#FFFFFF";
                                ctx.beginPath();
                                ctx.moveTo(2, 2);
                                ctx.lineTo(13, 10);
                                ctx.lineTo(2, 18);
                                ctx.closePath();
                                ctx.fill();
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
                            id: row3Mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[DeviceConnection] Privacy mode clicked")
                                root.currentView = "privacy"
                            }
                        }
                    }

                    // Row 4: Bluetooth system info
                    Rectangle {
                        width: parent.width
                        height: 76
                        color: row4Mouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.22) : (row4Mouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.07) : "transparent")

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 36
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Bluetooth system info"
                            color: row4Mouse.pressed ? "#70D6FF" : "#FFFFFF"
                            font.pixelSize: 26
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        // Right Chevron ▶
                        Canvas {
                            anchors.right: parent.right
                            anchors.rightMargin: 48
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 20
                            scale: row4Mouse.pressed ? 0.9 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.fillStyle = "#FFFFFF";
                                ctx.beginPath();
                                ctx.moveTo(2, 2);
                                ctx.lineTo(13, 10);
                                ctx.lineTo(2, 18);
                                ctx.closePath();
                                ctx.fill();
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
                            id: row4Mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[DeviceConnection] Bluetooth system info clicked")
                                root.currentView = "bt_info"
                            }
                        }
                    }
                }

                // 2. ANDROID AUTO SETTINGS LIST (Photo 4 Match)
                Column {
                    anchors.fill: parent
                    anchors.topMargin: 0
                    visible: root.selectedTab === "android_auto"
                    spacing: 0

                    // Row: Enable Android Auto
                    Rectangle {
                        width: parent.width
                        height: 76
                        color: aaRowMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.22) : (aaRowMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.07) : "transparent")

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 36
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 20

                            // Checkbox
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 28
                                height: 28
                                radius: 4
                                color: systemController.androidAutoEnabled ? "#3CA9F8" : "#121822"
                                border.color: systemController.androidAutoEnabled ? "#80D8FF" : "#566E87"
                                border.width: 1.5

                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "✓"
                                    color: "#FFFFFF"
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    visible: systemController.androidAutoEnabled
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Enable Android Auto"
                                color: "#FFFFFF"
                                font.pixelSize: 26
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
                            id: aaRowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                systemController.setAndroidAutoEnabled(!systemController.androidAutoEnabled)
                            }
                        }
                    }

                    // 3 Explanatory Paragraphs verbatim from Photo 4
                    Column {
                        width: parent.width
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 36
                        anchors.rightMargin: 48
                        anchors.topMargin: 24
                        spacing: 20

                        Text {
                            width: parent.width
                            text: "A compatible Android Auto-enabled smartphone can be connected to the system by <font color='#FFFFFF'><b>using an approved USB cable</b></font>.<br><br>Please make sure the Android Auto app on your phone is up-to-date and working correctly before connecting. To connect to Android Auto, all agreements on the smartphone must be accepted."
                            color: "#B8CADB"
                            font.pixelSize: 18
                            font.family: "Roboto"
                            textFormat: Text.RichText
                            wrapMode: Text.WordWrap
                            lineHeight: 1.35
                        }

                        Text {
                            width: parent.width
                            text: "If you want to activate Android Auto, while an Android Auto-enabled device is connected, please reconnect the USB cable for an Android Auto connection."
                            color: "#B8CADB"
                            font.pixelSize: 18
                            font.family: "Roboto"
                            wrapMode: Text.WordWrap
                            lineHeight: 1.35
                        }

                        Text {
                            width: parent.width
                            text: "Carrier fees may apply when using Android Auto."
                            color: "#B8CADB"
                            font.pixelSize: 18
                            font.family: "Roboto"
                            wrapMode: Text.WordWrap
                            lineHeight: 1.35
                        }
                    }
                }

                // 3. APPLE CARPLAY SETTINGS LIST (Photo 5 Match)
                Column {
                    anchors.fill: parent
                    anchors.topMargin: 0
                    visible: root.selectedTab === "carplay"
                    spacing: 0

                    // Row: Enable Apple CarPlay
                    Rectangle {
                        width: parent.width
                        height: 76
                        color: cpRowMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.22) : (cpRowMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.07) : "transparent")

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 36
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 20

                            // Checkbox
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 28
                                height: 28
                                radius: 4
                                color: systemController.appleCarPlayEnabled ? "#3CA9F8" : "#121822"
                                border.color: systemController.appleCarPlayEnabled ? "#80D8FF" : "#566E87"
                                border.width: 1.5

                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "✓"
                                    color: "#FFFFFF"
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    visible: systemController.appleCarPlayEnabled
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Enable Apple CarPlay"
                                color: "#FFFFFF"
                                font.pixelSize: 26
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
                            id: cpRowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                systemController.setAppleCarPlayEnabled(!systemController.appleCarPlayEnabled)
                            }
                        }
                    }

                    // 4 Explanatory Paragraphs verbatim from Photo 5
                    Column {
                        width: parent.width
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 36
                        anchors.rightMargin: 48
                        anchors.topMargin: 24
                        spacing: 18

                        Text {
                            width: parent.width
                            text: "A compatible Apple CarPlay-enabled iPhone can be connected to the system by <font color='#FFFFFF'><b>using an approved USB cable</b></font>."
                            color: "#B8CADB"
                            font.pixelSize: 18
                            font.family: "Roboto"
                            textFormat: Text.RichText
                            wrapMode: Text.WordWrap
                            lineHeight: 1.35
                        }

                        Text {
                            width: parent.width
                            text: "Activate Siri in the iPhone settings."
                            color: "#B8CADB"
                            font.pixelSize: 18
                            font.family: "Roboto"
                            wrapMode: Text.WordWrap
                            lineHeight: 1.35
                        }

                        Text {
                            width: parent.width
                            text: "If you want to activate Apple CarPlay, while an Apple CarPlay-enabled iPhone is connected, please reconnect the USB cable for Apple CarPlay connection."
                            color: "#B8CADB"
                            font.pixelSize: 18
                            font.family: "Roboto"
                            wrapMode: Text.WordWrap
                            lineHeight: 1.35
                        }

                        Text {
                            width: parent.width
                            text: "Carrier fees may apply when using CarPlay."
                            color: "#B8CADB"
                            font.pixelSize: 18
                            font.family: "Roboto"
                            wrapMode: Text.WordWrap
                            lineHeight: 1.35
                        }
                    }
                }
            }
        }

        // ====================================================
        // VIEW 2: AUTO CONNECTION PRIORITY (Exact Match to Photo 2!)
        // ====================================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.currentView === "priority"

            ListView {
                anchors.fill: parent
                clip: true
                model: systemController.bluetoothDeviceList

                delegate: Rectangle {
                    width: parent ? parent.width : 0
                    height: 76
                    color: pRowMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.15) : (pRowMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.06) : "transparent")

                    readonly property int itemIndex: index
                    readonly property var devData: modelData

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 36
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 36

                        // Priority Number (1, 2, 3...)
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (itemIndex + 1).toString()
                            color: "#FFFFFF"
                            font.pixelSize: 24
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        // Device Name (White font matching Photo 2!)
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: devData.name || "Bluetooth Device"
                            color: "#FFFFFF"
                            font.pixelSize: 24
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }
                    }

                    // Reorder Handle: 3 horizontal bars (☰)
                    Column {
                        anchors.right: parent.right
                        anchors.rightMargin: 48
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Rectangle { width: 24; height: 2.5; radius: 1; color: "#FFFFFF" }
                        Rectangle { width: 24; height: 2.5; radius: 1; color: "#FFFFFF" }
                        Rectangle { width: 24; height: 2.5; radius: 1; color: "#FFFFFF" }
                    }

                    // Bottom divider line
                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 36
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: "#181D26"
                    }

                    MouseArea {
                        id: pRowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // Tapping promotes item if not top, or moves it
                            if (itemIndex > 0) {
                                console.log("[DeviceConnection] Promoting device priority:", itemIndex)
                                systemController.moveBluetoothDevice(itemIndex, itemIndex - 1)
                            }
                        }
                    }
                }
            }

            // Empty state if no registered devices
            Column {
                anchors.centerIn: parent
                spacing: 16
                visible: systemController.bluetoothDeviceList.length === 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No registered Bluetooth devices"
                    color: "#8E9EAF"
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                }
            }
        }

        // ====================================================
        // VIEW 3: PRIVACY MODE (Exact Match to Photo 3!)
        // ====================================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.currentView === "privacy"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    console.log("[DeviceConnection] Privacy mode toggled")
                    systemController.togglePrivacyMode()
                }
            }

            Column {
                anchors.fill: parent
                anchors.topMargin: 36
                anchors.leftMargin: 36
                anchors.rightMargin: 36
                spacing: 16

                // Checkbox Row
                Row {
                    spacing: 20

                    // Checkbox
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        radius: 4
                        color: systemController.privacyMode ? "#3CA9F8" : "#121822"
                        border.color: systemController.privacyMode ? "#80D8FF" : "#566E87"
                        border.width: 1.5

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "✓"
                            color: "#FFFFFF"
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            visible: systemController.privacyMode
                        }
                    }

                    // Label: "Enable privacy mode"
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Enable privacy mode"
                        color: "#FFFFFF"
                        font.pixelSize: 24
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }
                }

                // Subtext description
                Text {
                    width: parent.width - 20
                    text: "Activates privacy mode. Info displayed in features may be restricted."
                    color: "#94A3B8"
                    font.pixelSize: 20
                    font.weight: Font.Normal
                    font.family: "Roboto"
                    wrapMode: Text.WordWrap
                }
            }
        }

        // ====================================================
        // VIEW 4: BLUETOOTH SYSTEM INFO (Exact Match to Photo 1!)
        // ====================================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.currentView === "bt_info" || root.currentView === "vehicle_name" || root.currentView === "passkey" || root.vNameExiting || root.passkeyExiting

            Column {
                anchors.fill: parent
                anchors.topMargin: 8
                spacing: 0

                // Row 1: Vehicle name: Apex MidEnd ▶
                Rectangle {
                    width: parent.width
                    height: 80
                    color: vNameMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.22) : (vNameMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.07) : "transparent")
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 36
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Vehicle name: " + systemController.vehicleName
                        color: vNameMouse.pressed ? "#70D6FF" : "#FFFFFF"
                        font.pixelSize: 26
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }

                    Canvas {
                        anchors.right: parent.right
                        anchors.rightMargin: 48
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14
                        height: 20
                        scale: vNameMouse.pressed ? 0.9 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.fillStyle = "#FFFFFF";
                            ctx.beginPath();
                            ctx.moveTo(2, 2);
                            ctx.lineTo(13, 10);
                            ctx.lineTo(2, 18);
                            ctx.closePath();
                            ctx.fill();
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
                        id: vNameMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.tempVehicleName = systemController.vehicleName
                            root.currentView = "vehicle_name"
                        }
                    }
                }

                // Row 2: Passkey: 0000 ▶
                Rectangle {
                    width: parent.width
                    height: 80
                    color: passMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.22) : (passMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.07) : "transparent")
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 36
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Passkey: " + systemController.passkey
                        color: passMouse.pressed ? "#70D6FF" : "#FFFFFF"
                        font.pixelSize: 26
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }

                    Canvas {
                        anchors.right: parent.right
                        anchors.rightMargin: 48
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14
                        height: 20
                        scale: passMouse.pressed ? 0.9 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.fillStyle = "#FFFFFF";
                            ctx.beginPath();
                            ctx.moveTo(2, 2);
                            ctx.lineTo(13, 10);
                            ctx.lineTo(2, 18);
                            ctx.closePath();
                            ctx.fill();
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
                        id: passMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.tempPasskey = systemController.passkey
                            root.currentView = "passkey"
                        }
                    }
                }
            }
        }
    }

    // ====================================================
    // OVERLAY VIEW 5: VEHICLE NAME KEYBOARD (Exact Match to Photo 2!)
    // ====================================================
    Rectangle {
        id: vNameKeyboardOverlay
        anchors.top: parent.top
        anchors.topMargin: 56
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: "#05070B"
        z: 60
        clip: true
        visible: root.currentView === "vehicle_name" || root.vNameExiting

        // Cohesive slide up on enter / slide down on exit animation
        transform: Translate {
            y: (root.currentView === "vehicle_name" && !root.vNameExiting) ? 0 : vNameKeyboardOverlay.height
            Behavior on y {
                NumberAnimation {
                    duration: 250
                    easing.type: (root.currentView === "vehicle_name" && !root.vNameExiting) ? Easing.OutCubic : Easing.InCubic
                }
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // Top Input Box: Light grey box with [X] button
            Rectangle {
                id: inputContainerBox
                width: parent.width
                height: 52
                color: "#E2E8F0"
                border.color: vNameInput.activeFocus ? "#3CA9F8" : "#CBD5E1"
                border.width: vNameInput.activeFocus ? 1.5 : 1
                radius: 4

                TextInput {
                    id: vNameInput
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: clearBtn.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.tempVehicleName
                    color: "#0F172A"
                    font.pixelSize: 26
                    font.weight: Font.Medium
                    font.family: "Roboto"
                    maximumLength: 24
                    focus: root.currentView === "vehicle_name"
                    activeFocusOnPress: true
                    cursorVisible: root.currentView === "vehicle_name"
                    selectByMouse: true
                    onTextChanged: {
                        if (root.tempVehicleName !== text) {
                            root.tempVehicleName = text
                        }
                    }
                    Keys.onReturnPressed: root.closeVehicleNameKeyboard(true)
                    Keys.onEnterPressed: root.closeVehicleNameKeyboard(true)
                    Keys.onEscapePressed: root.closeVehicleNameKeyboard(false)
                }

                // Clear [X] Button on right
                Rectangle {
                    id: clearBtn
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 58
                    color: clearMouse.pressed ? "#1E293B" : (clearMouse.containsMouse ? "#334155" : "#475569")
                    radius: 3
                    scale: clearMouse.pressed ? 0.90 : (clearMouse.containsMouse ? 1.04 : 1.0)

                    Behavior on color { ColorAnimation { duration: 80 } }
                    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: "#FFFFFF"
                        font.pixelSize: 22
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clearInput()
                    }
                }
            }

            // Keyboard Keys Area
            Column {
                id: keyboardKeysArea
                width: parent.width
                spacing: 8

                readonly property real keyW: (width - 9 * 8) / 10
                readonly property real keyH: 56

                // Repeat Timer for Backspace
                Timer {
                    id: bsRepeatTimer
                    interval: 70
                    repeat: true
                    onTriggered: root.deleteKey()
                }
                Timer {
                    id: bsInitialDelayTimer
                    interval: 350
                    repeat: false
                    onTriggered: bsRepeatTimer.start()
                }

                // Row 1: 10 Keys (Letters or Numbers)
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Repeater {
                        model: {
                            if (!root.isSymbolMode) {
                                return ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
                            } else if (!root.isSymbolPage2) {
                                return ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
                            } else {
                                return ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="]
                            }
                        }

                        delegate: Rectangle {
                            width: keyboardKeysArea.keyW
                            height: keyboardKeysArea.keyH
                            color: k1Mouse.pressed ? "#224A73" : (k1Mouse.containsMouse ? "#2C3E55" : "#1F2E42")
                            border.color: k1Mouse.pressed ? "#80D8FF" : (k1Mouse.containsMouse ? "#4D76A5" : "#354A63")
                            border.width: 1
                            radius: 4
                            scale: k1Mouse.pressed ? 0.90 : (k1Mouse.containsMouse ? 1.03 : 1.0)

                            Behavior on color { ColorAnimation { duration: 80 } }
                            Behavior on border.color { ColorAnimation { duration: 80 } }
                            Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                            readonly property string charKey: (!root.isSymbolMode && (root.isKeyboardShift || root.isCapsLock)) ? modelData.toUpperCase() : modelData

                            Rectangle {
                                anchors.fill: parent
                                radius: 4
                                color: Qt.rgba(0.24, 0.66, 1.0, 0.22)
                                visible: k1Mouse.pressed
                            }

                            Text {
                                anchors.centerIn: parent
                                text: charKey
                                color: "#FFFFFF"
                                font.pixelSize: root.isSymbolMode ? 22 : 24
                                font.weight: Font.DemiBold
                                scale: k1Mouse.pressed ? 0.94 : 1.0
                                Behavior on scale { NumberAnimation { duration: 80 } }
                            }

                            MouseArea {
                                id: k1Mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.insertKey(charKey)
                            }
                        }
                    }
                }

                // Row 2: Letters (9 keys) or Symbols (10 keys)
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Repeater {
                        model: {
                            if (!root.isSymbolMode) {
                                return ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
                            } else if (!root.isSymbolPage2) {
                                return ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""]
                            } else {
                                return ["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"]
                            }
                        }

                        delegate: Rectangle {
                            width: keyboardKeysArea.keyW
                            height: keyboardKeysArea.keyH
                            color: k2Mouse.pressed ? "#224A73" : (k2Mouse.containsMouse ? "#2C3E55" : "#1F2E42")
                            border.color: k2Mouse.pressed ? "#80D8FF" : (k2Mouse.containsMouse ? "#4D76A5" : "#354A63")
                            border.width: 1
                            radius: 4
                            scale: k2Mouse.pressed ? 0.90 : (k2Mouse.containsMouse ? 1.03 : 1.0)

                            Behavior on color { ColorAnimation { duration: 80 } }
                            Behavior on border.color { ColorAnimation { duration: 80 } }
                            Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                            readonly property string charKey: (!root.isSymbolMode && (root.isKeyboardShift || root.isCapsLock)) ? modelData.toUpperCase() : modelData

                            Rectangle {
                                anchors.fill: parent
                                radius: 4
                                color: Qt.rgba(0.24, 0.66, 1.0, 0.22)
                                visible: k2Mouse.pressed
                            }

                            Text {
                                anchors.centerIn: parent
                                text: charKey
                                color: "#FFFFFF"
                                font.pixelSize: root.isSymbolMode ? 22 : 24
                                font.weight: Font.DemiBold
                                scale: k2Mouse.pressed ? 0.94 : 1.0
                                Behavior on scale { NumberAnimation { duration: 80 } }
                            }

                            MouseArea {
                                id: k2Mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.insertKey(charKey)
                            }
                        }
                    }
                }

                // Row 3: 7 Keys + Backspace [⌫]
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Repeater {
                        model: {
                            if (!root.isSymbolMode) {
                                return ["z", "x", "c", "v", "b", "n", "m"]
                            } else if (!root.isSymbolPage2) {
                                return [".", ",", "?", "!", "'", "_", "+"]
                            } else {
                                return [".", ",", "?", "!", "'", ";", "/"]
                            }
                        }

                        delegate: Rectangle {
                            width: keyboardKeysArea.keyW
                            height: keyboardKeysArea.keyH
                            color: k3Mouse.pressed ? "#224A73" : (k3Mouse.containsMouse ? "#2C3E55" : "#1F2E42")
                            border.color: k3Mouse.pressed ? "#80D8FF" : (k3Mouse.containsMouse ? "#4D76A5" : "#354A63")
                            border.width: 1
                            radius: 4
                            scale: k3Mouse.pressed ? 0.90 : (k3Mouse.containsMouse ? 1.03 : 1.0)

                            Behavior on color { ColorAnimation { duration: 80 } }
                            Behavior on border.color { ColorAnimation { duration: 80 } }
                            Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                            readonly property string charKey: (!root.isSymbolMode && (root.isKeyboardShift || root.isCapsLock)) ? modelData.toUpperCase() : modelData

                            Rectangle {
                                anchors.fill: parent
                                radius: 4
                                color: Qt.rgba(0.24, 0.66, 1.0, 0.22)
                                visible: k3Mouse.pressed
                            }

                            Text {
                                anchors.centerIn: parent
                                text: charKey
                                color: "#FFFFFF"
                                font.pixelSize: root.isSymbolMode ? 22 : 24
                                font.weight: Font.DemiBold
                                scale: k3Mouse.pressed ? 0.94 : 1.0
                                Behavior on scale { NumberAnimation { duration: 80 } }
                            }

                            MouseArea {
                                id: k3Mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.insertKey(charKey)
                            }
                        }
                    }

                    // Backspace Key [⌫] (Spans remaining width to match full 10-key row!)
                    Rectangle {
                        width: keyboardKeysArea.keyW * 3 + 16
                        height: keyboardKeysArea.keyH
                        color: bsMouse.pressed ? "#224A73" : (bsMouse.containsMouse ? "#2C3E55" : "#1F2E42")
                        border.color: bsMouse.pressed ? "#80D8FF" : (bsMouse.containsMouse ? "#4D76A5" : "#354A63")
                        border.width: 1
                        radius: 4
                        scale: bsMouse.pressed ? 0.92 : (bsMouse.containsMouse ? 1.02 : 1.0)

                        Behavior on color { ColorAnimation { duration: 80 } }
                        Behavior on border.color { ColorAnimation { duration: 80 } }
                        Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            color: Qt.rgba(0.24, 0.66, 1.0, 0.22)
                            visible: bsMouse.pressed
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "⌫"
                            color: "#FFFFFF"
                            font.pixelSize: 28
                            font.weight: Font.Bold
                            scale: bsMouse.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                        }

                        MouseArea {
                            id: bsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: {
                                root.deleteKey()
                                bsInitialDelayTimer.start()
                            }
                            onReleased: {
                                bsInitialDelayTimer.stop()
                                bsRepeatTimer.stop()
                            }
                            onCanceled: {
                                bsInitialDelayTimer.stop()
                                bsRepeatTimer.stop()
                            }
                        }
                    }
                }

                // Row 4: Action Keys (Shift/ABC | 123#/#+= | Spacebar | Lang | Settings | OK)
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    // 1. Shift [⇧] or [ABC]
                    Rectangle {
                        width: keyboardKeysArea.keyW
                        height: keyboardKeysArea.keyH
                        color: (!root.isSymbolMode && (root.isKeyboardShift || root.isCapsLock))
                               ? "#3CA9F8"
                               : (shiftMouse.pressed ? "#224A73" : (shiftMouse.containsMouse ? "#2C3E55" : "#1F2E42"))
                        border.color: (!root.isSymbolMode && (root.isKeyboardShift || root.isCapsLock))
                                      ? "#80D8FF"
                                      : (shiftMouse.pressed ? "#80D8FF" : (shiftMouse.containsMouse ? "#4D76A5" : "#354A63"))
                        border.width: 1
                        radius: 4
                        scale: shiftMouse.pressed ? 0.90 : (shiftMouse.containsMouse ? 1.03 : 1.0)

                        Behavior on color { ColorAnimation { duration: 80 } }
                        Behavior on border.color { ColorAnimation { duration: 80 } }
                        Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                        Text {
                            anchors.centerIn: parent
                            text: {
                                if (root.isSymbolMode) return "ABC"
                                if (root.isCapsLock) return "⇪"
                                return "⇧"
                            }
                            color: "#FFFFFF"
                            font.pixelSize: root.isSymbolMode ? 18 : 24
                            font.weight: Font.Bold
                            scale: shiftMouse.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                        }

                        MouseArea {
                            id: shiftMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.isSymbolMode) {
                                    root.isSymbolMode = false
                                    root.isSymbolPage2 = false
                                } else {
                                    if (!root.isKeyboardShift) {
                                        root.isKeyboardShift = true
                                        root.isCapsLock = false
                                    } else if (!root.isCapsLock) {
                                        root.isCapsLock = true
                                    } else {
                                        root.isKeyboardShift = false
                                        root.isCapsLock = false
                                    }
                                }
                            }
                        }
                    }

                    // 2. [123#] or [#+=]
                    Rectangle {
                        width: keyboardKeysArea.keyW * 1.2
                        height: keyboardKeysArea.keyH
                        color: symMouse.pressed ? "#224A73" : (symMouse.containsMouse ? "#2C3E55" : "#1F2E42")
                        border.color: symMouse.pressed ? "#80D8FF" : (symMouse.containsMouse ? "#4D76A5" : "#354A63")
                        border.width: 1
                        radius: 4
                        scale: symMouse.pressed ? 0.90 : (symMouse.containsMouse ? 1.03 : 1.0)

                        Behavior on color { ColorAnimation { duration: 80 } }
                        Behavior on border.color { ColorAnimation { duration: 80 } }
                        Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                        Text {
                            anchors.centerIn: parent
                            text: {
                                if (!root.isSymbolMode) return "123#"
                                if (!root.isSymbolPage2) return "#+="
                                return "123#"
                            }
                            color: "#FFFFFF"
                            font.pixelSize: 19
                            font.weight: Font.DemiBold
                            scale: symMouse.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                        }

                        MouseArea {
                            id: symMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!root.isSymbolMode) {
                                    root.isSymbolMode = true
                                    root.isSymbolPage2 = false
                                } else {
                                    root.isSymbolPage2 = !root.isSymbolPage2
                                }
                            }
                        }
                    }

                    // 3. Spacebar [ — ]
                    Rectangle {
                        width: keyboardKeysArea.keyW * 4.0 + 32
                        height: keyboardKeysArea.keyH
                        color: spMouse.pressed ? "#224A73" : (spMouse.containsMouse ? "#2C3E55" : "#1F2E42")
                        border.color: spMouse.pressed ? "#80D8FF" : (spMouse.containsMouse ? "#4D76A5" : "#354A63")
                        border.width: 1
                        radius: 4
                        scale: spMouse.pressed ? 0.96 : (spMouse.containsMouse ? 1.01 : 1.0)

                        Behavior on color { ColorAnimation { duration: 80 } }
                        Behavior on border.color { ColorAnimation { duration: 80 } }
                        Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 68
                            height: 3
                            radius: 1.5
                            color: spMouse.pressed ? "#80D8FF" : "#8E9EAF"
                            Behavior on color { ColorAnimation { duration: 80 } }
                        }

                        MouseArea {
                            id: spMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.insertKey(" ")
                        }
                    }

                    // 4. Language / Mode Key [ 한글 / ENG ] (Matching Photo 2)
                    Rectangle {
                        width: keyboardKeysArea.keyW
                        height: keyboardKeysArea.keyH
                        color: langMouse.pressed ? "#224A73" : (langMouse.containsMouse ? "#2C3E55" : "#1F2E42")
                        border.color: langMouse.pressed ? "#80D8FF" : (langMouse.containsMouse ? "#4D76A5" : "#354A63")
                        border.width: 1
                        radius: 4
                        scale: langMouse.pressed ? 0.90 : (langMouse.containsMouse ? 1.03 : 1.0)

                        Behavior on color { ColorAnimation { duration: 80 } }
                        Behavior on border.color { ColorAnimation { duration: 80 } }
                        Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                        Text {
                            anchors.centerIn: parent
                            text: root.keyboardLang === "ENG" ? "한글" : "ENG"
                            color: "#FFFFFF"
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            scale: langMouse.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                        }

                        MouseArea {
                            id: langMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.keyboardLang = (root.keyboardLang === "ENG" ? "한글" : "ENG")
                            }
                        }
                    }

                    // 5. Settings [ ⚙ ]
                    Rectangle {
                        width: keyboardKeysArea.keyW
                        height: keyboardKeysArea.keyH
                        color: setKeyMouse.pressed ? "#224A73" : (setKeyMouse.containsMouse ? "#2C3E55" : "#1F2E42")
                        border.color: setKeyMouse.pressed ? "#80D8FF" : (setKeyMouse.containsMouse ? "#4D76A5" : "#354A63")
                        border.width: 1
                        radius: 4
                        scale: setKeyMouse.pressed ? 0.90 : (setKeyMouse.containsMouse ? 1.03 : 1.0)

                        Behavior on color { ColorAnimation { duration: 80 } }
                        Behavior on border.color { ColorAnimation { duration: 80 } }
                        Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                        Text {
                            anchors.centerIn: parent
                            text: "⚙"
                            color: "#FFFFFF"
                            font.pixelSize: 22
                            scale: setKeyMouse.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                        }

                        MouseArea {
                            id: setKeyMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    // 6. [ OK ] (Bright Blue Button matching Photo 2!)
                    Rectangle {
                        width: keyboardKeysArea.keyW * 1.8
                        height: keyboardKeysArea.keyH
                        color: okMouse.pressed ? "#16549E" : (okMouse.containsMouse ? "#3190F0" : "#247CDB")
                        border.color: okMouse.pressed ? "#FFFFFF" : "#5AA7FA"
                        border.width: 1
                        radius: 4
                        scale: okMouse.pressed ? 0.91 : (okMouse.containsMouse ? 1.03 : 1.0)

                        Behavior on color { ColorAnimation { duration: 80 } }
                        Behavior on border.color { ColorAnimation { duration: 80 } }
                        Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                        Text {
                            anchors.centerIn: parent
                            text: "OK"
                            color: "#FFFFFF"
                            font.pixelSize: 22
                            font.weight: Font.Bold
                            scale: okMouse.pressed ? 0.93 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                        }

                        MouseArea {
                            id: okMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeVehicleNameKeyboard(true)
                        }
                    }
                }
            }
        }
    }

    // ====================================================
    // OVERLAY VIEW 6: PASSKEY EDITOR WITH NUMERIC KEYPAD
    // ====================================================
    Rectangle {
        id: passkeyOverlay
        anchors.top: parent.top
        anchors.topMargin: 56
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: "#05070B"
        z: 60
        clip: true
        visible: root.currentView === "passkey" || root.passkeyExiting

        // Slide up on enter / slide down on exit animation
        transform: Translate {
            y: (root.currentView === "passkey" && !root.passkeyExiting) ? 0 : passkeyOverlay.height
            Behavior on y {
                NumberAnimation {
                    duration: 250
                    easing.type: (root.currentView === "passkey" && !root.passkeyExiting) ? Easing.OutCubic : Easing.InCubic
                }
            }
        }

        // Support physical keyboard numbers & keys on passkey screen
        focus: root.currentView === "passkey"
        Keys.onPressed: function(event) {
            if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                var d = String(event.key - Qt.Key_0)
                if (!root.passkeyEdited) {
                    root.passkeyEdited = true
                    root.tempPasskey = d
                } else if (root.tempPasskey.length < 4) {
                    root.tempPasskey += d
                }
                if (root.tempPasskey.length === 4) {
                    passkeyAutoSaveTimer.restart()
                }
                event.accepted = true
            } else if (event.key === Qt.Key_Backspace) {
                passkeyAutoSaveTimer.stop()
                root.passkeyEdited = true
                if (root.tempPasskey.length > 0) {
                    root.tempPasskey = root.tempPasskey.slice(0, -1)
                }
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.closePasskeyKeyboard(true)
                event.accepted = true
            } else if (event.key === Qt.Key_Escape) {
                root.closePasskeyKeyboard(false)
                event.accepted = true
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Top 4 boxes: evenly divided in light background with digits
            Rectangle {
                width: parent.width
                height: 58
                color: "#E2E8F0"
                border.color: "#94A3B8"
                border.width: 1
                radius: 4

                Row {
                    anchors.fill: parent

                    Repeater {
                        model: 4
                        delegate: Rectangle {
                            width: parent.width / 4
                            height: parent.height
                            color: "transparent"

                            // Divider line between cells
                            Rectangle {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: (index < 3) ? 1 : 0
                                color: "#94A3B8"
                            }

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    if (!root.passkeyEdited) {
                                        return (root.tempPasskey.length > index) ? root.tempPasskey.charAt(index) : "0"
                                    }
                                    if (root.tempPasskey.length > index) {
                                        return root.tempPasskey.charAt(index)
                                    }
                                    return ""
                                }
                                color: "#0F172A"
                                font.pixelSize: 32
                                font.weight: Font.Bold
                                font.family: "Roboto"
                            }

                            // Active cursor indicator for currently targeted digit
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 8
                                width: 28
                                height: 3
                                radius: 1.5
                                color: "#3CA9F8"
                                visible: root.passkeyEdited && (index === root.tempPasskey.length)
                            }
                        }
                    }
                }
            }

            // Numeric Keypad: 4 columns x 4 rows
            Item {
                id: keypadArea
                width: parent.width
                height: 250

                readonly property real colW: (width - 24) / 4
                readonly property real rowH: (height - 24) / 4

                // Grid for cols 1-3
                Grid {
                    columns: 3
                    columnSpacing: 8
                    rowSpacing: 8
                    width: parent.colW * 3 + 16
                    height: parent.height

                    Repeater {
                        model: [
                            { label: "1", isKey: true },
                            { label: "2", isKey: true },
                            { label: "3", isKey: true },
                            { label: "4", isKey: true },
                            { label: "5", isKey: true },
                            { label: "6", isKey: true },
                            { label: "7", isKey: true },
                            { label: "8", isKey: true },
                            { label: "9", isKey: true },
                            { label: "", isKey: false },
                            { label: "0", isKey: true },
                            { label: "", isKey: false }
                        ]

                        delegate: Rectangle {
                            width: (parent.width - 16) / 3
                            height: (parent.height - 24) / 4
                            visible: modelData.isKey
                            color: numMouse.pressed ? "#224A73" : (numMouse.containsMouse ? "#2C3E55" : "#1F2E42")
                            border.color: numMouse.pressed ? "#80D8FF" : (numMouse.containsMouse ? "#4D76A5" : "#354A63")
                            border.width: 1
                            radius: 4
                            scale: numMouse.pressed ? 0.90 : (numMouse.containsMouse ? 1.03 : 1.0)

                            Behavior on color { ColorAnimation { duration: 80 } }
                            Behavior on border.color { ColorAnimation { duration: 80 } }
                            Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                            Rectangle {
                                anchors.fill: parent
                                radius: 4
                                color: Qt.rgba(0.24, 0.66, 1.0, 0.22)
                                visible: numMouse.pressed
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: "#FFFFFF"
                                font.pixelSize: 28
                                font.weight: Font.DemiBold
                                scale: numMouse.pressed ? 0.93 : 1.0
                                Behavior on scale { NumberAnimation { duration: 80 } }
                            }

                            MouseArea {
                                id: numMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!root.passkeyEdited) {
                                        root.passkeyEdited = true
                                        root.tempPasskey = modelData.label
                                    } else if (root.tempPasskey.length < 4) {
                                        root.tempPasskey += modelData.label
                                    }
                                    if (root.tempPasskey.length === 4) {
                                        passkeyAutoSaveTimer.restart()
                                    }
                                }
                            }
                        }
                    }
                }

                // Col 4: Top Backspace [⌫] (spans 2 rows), Bottom Clear [Clear] (spans 2 rows)
                Column {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.colW
                    spacing: 8

                    // Backspace [⌫] (Height spans 2 rows)
                    Rectangle {
                        width: parent.width
                        height: (parent.height - 8) / 2
                        color: padBsMouse.pressed ? "#224A73" : (padBsMouse.containsMouse ? "#2C3E55" : "#1F2E42")
                        border.color: padBsMouse.pressed ? "#80D8FF" : (padBsMouse.containsMouse ? "#4D76A5" : "#354A63")
                        border.width: 1
                        radius: 4
                        scale: padBsMouse.pressed ? 0.92 : (padBsMouse.containsMouse ? 1.02 : 1.0)

                        Behavior on color { ColorAnimation { duration: 80 } }
                        Behavior on border.color { ColorAnimation { duration: 80 } }
                        Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            color: Qt.rgba(0.24, 0.66, 1.0, 0.22)
                            visible: padBsMouse.pressed
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "⌫"
                            color: "#FFFFFF"
                            font.pixelSize: 34
                            font.weight: Font.Bold
                            scale: padBsMouse.pressed ? 0.93 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                        }

                        MouseArea {
                            id: padBsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                passkeyAutoSaveTimer.stop()
                                root.passkeyEdited = true
                                if (root.tempPasskey.length > 0) {
                                    root.tempPasskey = root.tempPasskey.slice(0, -1)
                                }
                            }
                        }
                    }

                    // [ Clear ] (Bright Blue Button matching Photo 3!)
                    Rectangle {
                        width: parent.width
                        height: (parent.height - 8) / 2
                        color: padClrMouse.pressed ? "#16549E" : (padClrMouse.containsMouse ? "#3190F0" : "#247CDB")
                        border.color: padClrMouse.pressed ? "#FFFFFF" : "#5AA7FA"
                        border.width: 1
                        radius: 4
                        scale: padClrMouse.pressed ? 0.92 : (padClrMouse.containsMouse ? 1.02 : 1.0)

                        Behavior on color { ColorAnimation { duration: 80 } }
                        Behavior on border.color { ColorAnimation { duration: 80 } }
                        Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                        Text {
                            anchors.centerIn: parent
                            text: "Clear"
                            color: "#FFFFFF"
                            font.pixelSize: 26
                            font.weight: Font.Bold
                            scale: padClrMouse.pressed ? 0.93 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                        }

                        MouseArea {
                            id: padClrMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                passkeyAutoSaveTimer.stop()
                                root.passkeyEdited = true
                                root.tempPasskey = ""
                            }
                        }
                    }
                }
            }
        }
    }
}
