/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: PhoneScreen.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#05070B"

    signal backClicked()
    signal menuClicked()
    signal addDeviceRequested()
    signal bluetoothSettingsRequested()

    property string currentTab: "recents" // "recents" | "contacts" | "keypad"
    property string dialedNumber: ""

    function resetToDefault() {
        currentTab = "recents"
        dialedNumber = ""
        changeConnScrim.visible = false
    }

    // ----------------------------------------------------
    // Models
    // ----------------------------------------------------
    ListModel {
        id: callHistoryModel
        ListElement { name: "Anubhav Agra"; number: "+91 98765 43210"; date: "21-02-2025"; isIncoming: false }
        ListElement { name: "Anubhav Agra"; number: "+91 98765 43210"; date: "21-02-2025"; isIncoming: false }
        ListElement { name: "Anubhav Agra"; number: "+91 98765 43210"; date: "21-02-2025"; isIncoming: false }
        ListElement { name: "MG Motor Jubilant Motor S"; number: "+91 91234 56789"; date: "21-02-2025"; isIncoming: true }
        ListElement { name: "Sudhanshu Bhai"; number: "+91 99887 76655"; date: "21-02-2025"; isIncoming: false }
    }

    ListModel {
        id: contactsModel
        ListElement { initial: "#"; name: "993505000"; number: "993505000" }
        ListElement { initial: ""; name: "9xm Selfiesh"; number: "9876543210" }
        ListElement { initial: "A"; name: "Anubhav Agra"; number: "+91 98765 43210" }
        ListElement { initial: "M"; name: "MG Motor Jubilant Motor S"; number: "+91 91234 56789" }
        ListElement { initial: "S"; name: "Sudhanshu Bhai"; number: "+91 99887 76655" }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ====================================================
        // 1. SUB-HEADER BAR (3 Navigation Tabs + Device Switch + Menu + Back)
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
                anchors.leftMargin: 18
                anchors.rightMargin: 16
                spacing: 12

                // LEFT: 3 Tabs (Recents | Contacts | Keypad)
                Row {
                    spacing: 12
                    Layout.alignment: Qt.AlignVCenter

                    // Tab 1: Recents / Call History (Phone with blue arrow)
                    Rectangle {
                        width: 72
                        height: 44
                        radius: 3
                        color: root.currentTab === "recents" ? "#0C1826" : "transparent"
                        border.color: root.currentTab === "recents" ? "#389BFF" : "transparent"
                        border.width: 1.5

                        Image {
                            anchors.centerIn: parent
                            width: 34
                            height: 34
                            source: "qrc:/assets/phone/icon_phone_callhistory.png"
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            scale: recentsMouse.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: recentsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentTab = "recents"
                        }
                    }

                    // Tab 2: Contacts (Phone book)
                    Rectangle {
                        width: 72
                        height: 44
                        radius: 3
                        color: root.currentTab === "contacts" ? "#0C1826" : "transparent"
                        border.color: root.currentTab === "contacts" ? "#389BFF" : "transparent"
                        border.width: 1.5

                        Image {
                            anchors.centerIn: parent
                            width: 34
                            height: 34
                            source: "qrc:/assets/phone/icon_phone_phonebook.png"
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            scale: contactsMouse.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: contactsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentTab = "contacts"
                        }
                    }

                    // Tab 3: Keypad (Number dial)
                    Rectangle {
                        width: 72
                        height: 44
                        radius: 3
                        color: root.currentTab === "keypad" ? "#0C1826" : "transparent"
                        border.color: root.currentTab === "keypad" ? "#389BFF" : "transparent"
                        border.width: 1.5

                        Image {
                            anchors.centerIn: parent
                            width: 34
                            height: 34
                            source: "qrc:/assets/phone/icon_phone_dialpad.png"
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            scale: keypadMouse.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: keypadMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentTab = "keypad"
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // RIGHT: Device Switch + Menu + Back
                Row {
                    spacing: 14
                    Layout.alignment: Qt.AlignVCenter

                    // Device Switch Button (Two phones with transfer arrows)
                    Rectangle {
                        width: 44
                        height: 40
                        color: switchMouse.pressed ? "#1E354F" : "transparent"
                        radius: 3

                        Image {
                            anchors.centerIn: parent
                            width: 34
                            height: 32
                            source: "qrc:/assets/phone/icon_phone_device_switch.png"
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            scale: switchMouse.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: switchMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[Phone] Device switch clicked -> Opening Change connection modal")
                                changeConnScrim.visible = true
                            }
                        }
                    }

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
                            onClicked: {
                                console.log("[Phone] Menu clicked")
                                root.menuClicked()
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
                                console.log("[Phone] Back clicked -> Returning to previous")
                                root.backClicked()
                            }
                        }
                    }
                }
            }
        }

        // ====================================================
        // 2. MAIN BODY CONTENT
        // ====================================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ------------------------------------------------
            // STATE A: PHONE SYNCED WITH BLUETOOTH
            // ------------------------------------------------
            Item {
                anchors.fill: parent
                visible: systemController.hasHandsFreeDevice

                // ============================================
                // TAB 1: RECENTS / CALL HISTORY VIEW
                // ============================================
                ListView {
                    id: recentsListView
                    anchors.fill: parent
                    anchors.topMargin: 4
                    visible: root.currentTab === "recents"
                    model: callHistoryModel
                    clip: true

                    delegate: Rectangle {
                        width: recentsListView.width
                        height: 74
                        color: rowMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.22) : (rowMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.06) : "transparent")

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 28
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 18

                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 28
                                height: 28
                                source: model.isIncoming ? "qrc:/assets/phone/icon_call_incoming.png" : "qrc:/assets/phone/icon_call_outgoing.png"
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.name
                                color: rowMouse.pressed ? "#70D6FF" : "#FFFFFF"
                                font.pixelSize: 25
                                font.weight: Font.DemiBold
                                font.family: "Roboto"
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: 36
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 14

                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 30
                                height: 26
                                source: "qrc:/assets/phone/icon_call_details.png"
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.date
                                color: rowMouse.pressed ? "#70D6FF" : "#FFFFFF"
                                font.pixelSize: 24
                                font.weight: Font.Normal
                                font.family: "Roboto"
                            }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 28
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: "#181D26"
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: console.log("[Phone] Calling", model.name, model.number)
                        }
                    }
                }

                // ============================================
                // TAB 2: CONTACTS VIEW (Matching Photo 1!)
                // ============================================
                Item {
                    anchors.fill: parent
                    visible: root.currentTab === "contacts"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        // Header Bar: "Search contacts" | 👤 "Entire list (306)"
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            color: "#CAD3DE"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 24
                                anchors.rightMargin: 28

                                Text {
                                    text: "Search contacts"
                                    color: "#3A4756"
                                    font.pixelSize: 22
                                    font.weight: Font.DemiBold
                                    font.family: "Roboto"
                                }

                                Item { Layout.fillWidth: true }

                                Row {
                                    spacing: 10
                                    Layout.alignment: Qt.AlignVCenter

                                    // Silhouette icon 👤
                                    Canvas {
                                        width: 18
                                        height: 20
                                        anchors.verticalCenter: parent.verticalCenter
                                        onPaint: {
                                            var ctx = getContext("2d");
                                            ctx.reset();
                                            ctx.fillStyle = "#3A4756";
                                            // head
                                            ctx.beginPath();
                                            ctx.arc(9, 6, 5, 0, 2 * Math.PI);
                                            ctx.fill();
                                            // body
                                            ctx.beginPath();
                                            ctx.arc(9, 20, 8, Math.PI, 2 * Math.PI);
                                            ctx.fill();
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Entire list (306)"
                                        color: "#3A4756"
                                        font.pixelSize: 22
                                        font.weight: Font.DemiBold
                                        font.family: "Roboto"
                                    }
                                }
                            }
                        }

                        // Contacts List + Alphabet Index
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ListView {
                                id: contactsListView
                                anchors.fill: parent
                                anchors.rightMargin: 48
                                anchors.topMargin: 4
                                model: contactsModel
                                clip: true

                                delegate: Rectangle {
                                    width: contactsListView.width
                                    height: 72
                                    color: contactMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.22) : (contactMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.06) : "transparent")

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Row {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 28
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 24

                                        // Category / Initial
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 24
                                            text: model.initial
                                            color: "#8FA3B8"
                                            font.pixelSize: 24
                                            font.weight: Font.DemiBold
                                            font.family: "Roboto"
                                        }

                                        // Contact Name / Number
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: model.name
                                            color: contactMouse.pressed ? "#70D6FF" : "#FFFFFF"
                                            font.pixelSize: 26
                                            font.weight: Font.DemiBold
                                            font.family: "Roboto"
                                        }
                                    }

                                    // Right: Mobile Phone Outline Icon 📱
                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 32
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 22
                                        height: 34
                                        radius: 3
                                        color: "transparent"
                                        border.color: "#8FA3B8"
                                        border.width: 1.5

                                        // Screen hairline
                                        Rectangle {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.top: parent.top
                                            anchors.topMargin: 4
                                            width: 14
                                            height: 20
                                            color: "#182230"
                                        }

                                        // Home dot
                                        Rectangle {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 3
                                            width: 4
                                            height: 4
                                            radius: 2
                                            color: "#8FA3B8"
                                        }
                                    }

                                    // Hairline separator
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 28
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: 1
                                        color: "#181D26"
                                    }

                                    MouseArea {
                                        id: contactMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: console.log("[Phone] Dialing contact:", model.name)
                                    }
                                }
                            }

                            // Far Right: Alphabet Index Bar
                            Column {
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10

                                Repeater {
                                    model: ["#", "A", "D", "G", "J", "M", "P", "T", "W"]
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData
                                        color: "#8FA3B8"
                                        font.pixelSize: 18
                                        font.weight: Font.DemiBold
                                        font.family: "Roboto"
                                    }
                                }
                            }
                        }
                    }
                }

                // ============================================
                // TAB 3: KEYPAD VIEW (Matching Photo 2!)
                // ============================================
                Item {
                    anchors.fill: parent
                    visible: root.currentTab === "keypad"

                    // Left Side: Display Box + Device status
                    Item {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: keypadGridContainer.left

                        // Top Input Display Box
                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 24
                            anchors.top: parent.top
                            anchors.topMargin: 24
                            anchors.right: parent.right
                            anchors.rightMargin: 36
                            height: 60
                            color: "#CAD3DE"
                            radius: 3

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 18
                                anchors.right: clearIconArea.left
                                elide: Text.ElideLeft
                                text: root.dialedNumber.length > 0 ? root.dialedNumber : "Enter phone number."
                                color: root.dialedNumber.length > 0 ? "#0A1428" : "#5A6778"
                                font.pixelSize: 26
                                font.weight: Font.DemiBold
                                font.family: "Roboto"
                            }

                            // Backspace ⌫ Icon inside display
                            Item {
                                id: clearIconArea
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: 36
                                height: 36
                                visible: root.dialedNumber.length > 0

                                Text {
                                    anchors.centerIn: parent
                                    text: "⌫"
                                    color: "#3A4756"
                                    font.pixelSize: 22
                                    font.weight: Font.Bold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.dialedNumber.length > 0) {
                                            root.dialedNumber = root.dialedNumber.substring(0, root.dialedNumber.length - 1)
                                        }
                                    }
                                }
                            }
                        }

                        // Bottom Left: Device Name + Indicators
                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 28
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 24
                            spacing: 16
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "realme narzo 30"
                                color: "#BACBDD"
                                font.pixelSize: 22
                                font.weight: Font.DemiBold
                                font.family: "Roboto"
                            }

                            // BT icon badge
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18
                                height: 18
                                radius: 9
                                color: "#2E5B84"

                                Text {
                                    anchors.centerIn: parent
                                    text: "ᛒ"
                                    color: "#6CD0FF"
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                }
                            }

                            // Signal Reception Bars (4 bars)
                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3
                                Rectangle { width: 3; height: 6; color: "#BACBDD"; anchors.bottom: parent.bottom }
                                Rectangle { width: 3; height: 10; color: "#BACBDD"; anchors.bottom: parent.bottom }
                                Rectangle { width: 3; height: 14; color: "#BACBDD"; anchors.bottom: parent.bottom }
                                Rectangle { width: 3; height: 18; color: "#BACBDD"; anchors.bottom: parent.bottom }
                            }

                            // Battery Indicator
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 26
                                height: 14
                                radius: 2
                                color: "transparent"
                                border.color: "#BACBDD"
                                border.width: 1.5

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 16
                                    height: 8
                                    color: "#BACBDD"
                                }

                                Rectangle {
                                    anchors.left: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 2
                                    height: 6
                                    color: "#BACBDD"
                                }
                            }
                        }
                    }

                    // Right Side: 3x5 Keypad Grid Container (Matching Photo 2!)
                    Rectangle {
                        id: keypadGridContainer
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 660
                        color: "#121A26"

                        Grid {
                            anchors.fill: parent
                            columns: 3
                            spacing: 1

                            // Row 1
                            KeypadButton { text: "1"; subtext: ""; onClicked: root.dialedNumber += "1" }
                            KeypadButton { text: "2"; subtext: "ABC"; onClicked: root.dialedNumber += "2" }
                            KeypadButton { text: "3"; subtext: "DEF"; onClicked: root.dialedNumber += "3" }

                            // Row 2
                            KeypadButton { text: "4"; subtext: "GHI"; onClicked: root.dialedNumber += "4" }
                            KeypadButton { text: "5"; subtext: "JKL"; onClicked: root.dialedNumber += "5" }
                            KeypadButton { text: "6"; subtext: "MNO"; onClicked: root.dialedNumber += "6" }

                            // Row 3
                            KeypadButton { text: "7"; subtext: "PQRS"; onClicked: root.dialedNumber += "7" }
                            KeypadButton { text: "8"; subtext: "TUV"; onClicked: root.dialedNumber += "8" }
                            KeypadButton { text: "9"; subtext: "WXYZ"; onClicked: root.dialedNumber += "9" }

                            // Row 4
                            KeypadButton { text: "*"; subtext: ""; onClicked: root.dialedNumber += "*" }
                            KeypadButton { text: "0"; subtext: "+"; onClicked: root.dialedNumber += "0" }
                            KeypadButton { text: "#"; subtext: ""; onClicked: root.dialedNumber += "#" }

                            // Row 5: Action Row
                            // 1. Backspace button
                            Rectangle {
                                width: (keypadGridContainer.width - 2) / 3
                                height: keypadGridContainer.height / 5
                                color: bsMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.25) : (bsMouse.containsMouse ? "#182434" : "#101824")
                                Text {
                                    anchors.centerIn: parent
                                    text: "⌫"
                                    color: root.dialedNumber.length > 0 ? "#CAD3DE" : "#2E3F52"
                                    font.pixelSize: 26
                                    font.weight: Font.Bold
                                }
                                MouseArea {
                                    id: bsMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: root.dialedNumber.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (root.dialedNumber.length > 0) {
                                            root.dialedNumber = root.dialedNumber.substring(0, root.dialedNumber.length - 1)
                                        }
                                    }
                                }
                            }

                            // 2. Settings button
                            Rectangle {
                                width: (keypadGridContainer.width - 2) / 3
                                height: keypadGridContainer.height / 5
                                color: setMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.25) : (setMouse.containsMouse ? "#182434" : "#101824")
                                Image {
                                    anchors.centerIn: parent
                                    width: 28
                                    height: 28
                                    source: "qrc:/assets/ui/icon_settings_hdr.png"
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                    scale: setMouse.pressed ? 0.92 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 100 } }
                                }
                                MouseArea {
                                    id: setMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: systemController.navigateTo("settings")
                                }
                            }

                            // 3. Green Call Handset Button (At the end of dialer)
                            Rectangle {
                                width: (keypadGridContainer.width - 2) / 3
                                height: keypadGridContainer.height / 5
                                color: callMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.25) : (callMouse.containsMouse ? "#182434" : "#101824")

                                Image {
                                    anchors.centerIn: parent
                                    width: 32
                                    height: 32
                                    source: "qrc:/assets/phone/icon_phone_green.png"
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                    scale: callMouse.pressed ? 0.90 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 100 } }
                                }

                                MouseArea {
                                    id: callMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: console.log("[Phone] Dialing call to:", root.dialedNumber)
                                }
                            }
                        }
                    }
                }
            }

            // ------------------------------------------------
            // STATE B: NO BLUETOOTH PHONE CONNECTED
            // ------------------------------------------------
            Column {
                anchors.centerIn: parent
                spacing: 24
                visible: !systemController.hasHandsFreeDevice

                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 72
                    height: 72
                    source: "qrc:/assets/apps/icon_all_phone.png"
                    opacity: 0.45
                    fillMode: Image.PreserveAspectFit
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No phone connected"
                    color: "#FFFFFF"
                    font.pixelSize: 28
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Connect a Bluetooth device to view contacts and make calls."
                    color: "#8FA3B8"
                    font.pixelSize: 20
                    font.family: "Roboto"
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 200
                    height: 48
                    radius: 4
                    color: connectMouse.pressed ? "#389BFF" : (connectMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                    border.color: "#3F74A3"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: (systemController.bluetoothDeviceList.length === 0) ? "Add new device" : "Connect device"
                        color: "#FFFFFF"
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: connectMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (systemController.bluetoothDeviceList.length === 0) {
                                root.addDeviceRequested()
                            } else {
                                root.bluetoothSettingsRequested()
                            }
                        }
                    }
                }
            }
        }
    }

    // ----------------------------------------------------
    // Inline Keypad Button Component
    // ----------------------------------------------------
    component KeypadButton: Rectangle {
        property string text: ""
        property string subtext: ""
        signal clicked()

        width: (keypadGridContainer.width - 2) / 3
        height: keypadGridContainer.height / 5
        color: keyMouseArea.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.25) : (keyMouseArea.containsMouse ? "#182434" : "#101824")

        Behavior on color { ColorAnimation { duration: 100 } }

        Row {
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: parent.parent.text
                color: "#FFFFFF"
                font.pixelSize: 32
                font.weight: Font.DemiBold
                font.family: "Roboto"
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: parent.parent.subtext
                color: "#7D94AC"
                font.pixelSize: 15
                font.weight: Font.DemiBold
                font.family: "Roboto"
                visible: parent.parent.subtext.length > 0
            }
        }

        MouseArea {
            id: keyMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    // ====================================================
    // CHANGE CONNECTION MODAL WINDOW (Matching Genuine IVI Photo)
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
                onClicked: {} // prevent dismiss when clicking dialog body
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

            // Paired Mobile Devices List (Redmi Note 10, vivo T1 5G, vivo V29 Pro)
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
                            color: modelData.handsFree ? "#7CE8FF" : "#FFFFFF"
                            font.pixelSize: 24
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        // Connected indicator badge
                        Text {
                            text: modelData.handsFree ? "Connected" : ""
                            color: "#7CE8FF"
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                            visible: modelData.handsFree
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
                            root.bluetoothSettingsRequested()
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
