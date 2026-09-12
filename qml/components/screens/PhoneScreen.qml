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
    onCurrentTabChanged: {
        if (currentTab === "recents") {
            systemController.syncRecentCallHistory()
        }
    }

    Component.onCompleted: {
        systemController.syncRecentCallHistory()
        if (systemController.bluetoothCallActive) {
            root.activeCallName = (systemController.bluetoothCallName.length > 0) ? systemController.bluetoothCallName : systemController.bluetoothCallNumber
            root.activeCallNumber = systemController.bluetoothCallNumber
            root.callStatus = (systemController.bluetoothCallStatus === "active") ? "active" : "calling"
            root.isCallActive = true
            root.isCallMinimized = false
            root.showActiveCallModal = true
        }
    }
    property string dialedNumber: ""
    property string contactSearchQuery: ""
    property bool showActiveCallModal: false
    property string activeCallName: ""
    property string activeCallNumber: ""
    property bool isCallActive: false
    property bool isCallMinimized: false
    property int activeCallDurationSeconds: 0
    property string callStatus: "calling" // "calling" | "active" | "ended"
    property bool isCallMuted: false
    property bool isPrivateMode: false
    property bool showInCallKeypad: false
    property string inCallDtmfDigits: ""
    property bool showInCallContacts: false
    property string inCallContactSearchQuery: ""
    property bool showDialConfirmation: false
    property string pendingCallName: ""
    property string pendingCallNumber: ""

    Timer {
        id: callDurationTimer
        interval: 1000
        repeat: true
        running: root.isCallActive && root.callStatus === "active"
        onTriggered: {
            root.activeCallDurationSeconds += 1
        }
    }

    Timer {
        id: callEndedDismissTimer
        interval: 1600
        repeat: false
        onTriggered: {
            console.log("[PhoneScreen] Dismissing ended call overlay")
            activeCallOverlay.opacity = 1.0
            root.isCallActive = false
            root.isCallMinimized = false
            root.showActiveCallModal = false
            root.showInCallKeypad = false
            root.showInCallContacts = false
            root.activeCallDurationSeconds = 0
            root.inCallDtmfDigits = ""
            root.inCallContactSearchQuery = ""
            root.isCallMuted = false
            root.isPrivateMode = false
            root.callStatus = "calling"
        }
    }

    Connections {
        target: systemController

        function onBluetoothCallActiveChanged() {
            console.log("[PhoneScreen] bluetoothCallActive changed:", systemController.bluetoothCallActive)
            if (!systemController.bluetoothCallActive) {
                if (root.isCallActive) root.endActiveCall(false)
            } else {
                if (callEndedDismissTimer.running) {
                    console.log("[PhoneScreen] Ignoring call active pulse while dismiss timer is running")
                    return
                }
                callEndedDismissTimer.stop()
                activeCallOverlay.opacity = 1.0
                root.activeCallName = (systemController.bluetoothCallName.length > 0) ? systemController.bluetoothCallName : systemController.bluetoothCallNumber
                root.activeCallNumber = systemController.bluetoothCallNumber
                var newStatus = (systemController.bluetoothCallStatus === "active") ? "active" : "calling"
                if (newStatus === "active" && root.callStatus !== "active") {
                    root.activeCallDurationSeconds = 0
                } else if (newStatus !== "active") {
                    root.activeCallDurationSeconds = 0
                }
                root.callStatus = newStatus
                root.isCallActive = true
                root.isCallMinimized = false
                root.showActiveCallModal = true
            }
        }

        function onRemoteCallStarted(name, number, status) {
            console.log("[PhoneScreen] Mobile phone initiated call! Name:", name, "Number:", number, "Status:", status)
            if (callEndedDismissTimer.running) {
                console.log("[PhoneScreen] Ignoring remoteCallStarted while dismiss timer is running")
                return
            }
            callEndedDismissTimer.stop()
            activeCallOverlay.opacity = 1.0
            root.activeCallName = (name && name.length > 0) ? name : number
            root.activeCallNumber = number
            root.activeCallDurationSeconds = 0
            root.callStatus = (status === "active") ? "active" : "calling"
            root.isCallActive = true
            root.isCallMinimized = false
            root.showActiveCallModal = true
            root.showInCallKeypad = false
            root.showInCallContacts = false
        }

        function onRemoteCallStatusChanged(status) {
            console.log("[PhoneScreen] Mobile phone call status changed:", status)
            if (status === "active") {
                callEndedDismissTimer.stop()
                activeCallOverlay.opacity = 1.0
                if (root.callStatus !== "active") {
                    root.activeCallDurationSeconds = 0
                }
                root.callStatus = "active"
            } else if (status === "calling" || status === "alerting") {
                root.callStatus = "calling"
                root.activeCallDurationSeconds = 0
            } else if (status === "ended") {
                if (root.isCallActive) root.endActiveCall(false)
            }
        }

        function onRemoteCallEnded() {
            console.log("[PhoneScreen] Mobile phone ended call!")
            if (root.isCallActive) root.endActiveCall(false)
        }
    }

    function formatCallDuration(seconds) {
        var hrs = Math.floor(seconds / 3600)
        var mins = Math.floor((seconds % 3600) / 60)
        var secs = seconds % 60
        var sMin = (mins < 10 ? "0" : "") + mins
        var sSec = (secs < 10 ? "0" : "") + secs
        if (hrs > 0) {
            var sHr = (hrs < 10 ? "0" : "") + hrs
            return sHr + ":" + sMin + ":" + sSec
        }
        return sMin + ":" + sSec
    }

    function endActiveCall(immediate) {
        console.log("[PhoneScreen] Ending active call, immediate:", immediate)
        root.callStatus = "ended"
        if (immediate || !root.isCallActive) {
            callEndedDismissTimer.stop()
            activeCallOverlay.opacity = 1.0
            root.isCallActive = false
            root.isCallMinimized = false
            root.showActiveCallModal = false
            root.showInCallKeypad = false
            root.showInCallContacts = false
            root.activeCallDurationSeconds = 0
            root.inCallDtmfDigits = ""
            root.inCallContactSearchQuery = ""
            root.isCallMuted = false
            root.isPrivateMode = false
            root.callStatus = "calling"
            return
        }
        callEndedDismissTimer.restart()
    }

    // On-Screen Keyboard State for Phonebook Search
    property bool isSearchKeyboardOpen: false
    property bool isKeyboardShift: false
    property bool isCapsLock: false
    property bool isSymbolMode: false
    property bool isSymbolPage2: false

    function insertSearchKey(k) {
        if (!contactSearchInput) return
        if (contactSearchInput.selectedText && contactSearchInput.selectedText.length > 0) {
            var selStart = contactSearchInput.selectionStart
            contactSearchInput.remove(contactSearchInput.selectionStart, contactSearchInput.selectionEnd)
            contactSearchInput.insert(selStart, k)
        } else {
            contactSearchInput.insert(contactSearchInput.cursorPosition, k)
        }
        if (isKeyboardShift && !isCapsLock) {
            isKeyboardShift = false
        }
    }

    function deleteSearchKey() {
        if (!contactSearchInput) return
        if (contactSearchInput.selectedText && contactSearchInput.selectedText.length > 0) {
            contactSearchInput.remove(contactSearchInput.selectionStart, contactSearchInput.selectionEnd)
        } else if (contactSearchInput.cursorPosition > 0) {
            contactSearchInput.remove(contactSearchInput.cursorPosition - 1, contactSearchInput.cursorPosition)
        }
    }

    function clearSearchInput() {
        if (contactSearchInput) contactSearchInput.text = ""
        root.contactSearchQuery = ""
    }

    function getFilteredContacts() {
        var list = systemController.contactsList
        if (!contactSearchQuery || contactSearchQuery.trim() === "") {
            return list
        }
        var q = contactSearchQuery.trim().toLowerCase()
        var res = []
        for (var i = 0; i < list.length; ++i) {
            var item = list[i]
            var name = ((item && item.name) ? item.name : "").toLowerCase()
            var number = ((item && item.number) ? item.number : "").toLowerCase()
            if (name.indexOf(q) !== -1 || number.indexOf(q) !== -1) {
                res.push(item)
            }
        }
        return res
    }

    function triggerCall(name, number) {
        var callTarget = (number && number.length > 0) ? number : name
        if (!callTarget || callTarget.length === 0 || isCallActive || showDialConfirmation) return
        pendingCallName = (name && name.length > 0) ? name : callTarget
        pendingCallNumber = (number && number.length > 0) ? number : callTarget
        showDialConfirmation = true
    }

    function confirmPendingCall() {
        if (!showDialConfirmation || pendingCallNumber.length === 0 || isCallActive) return
        var callTarget = pendingCallNumber
        activeCallName = pendingCallName
        activeCallNumber = pendingCallNumber
        showDialConfirmation = false
        pendingCallName = ""
        pendingCallNumber = ""
        activeCallDurationSeconds = 0
        callStatus = "calling"
        isCallMuted = false
        showInCallKeypad = false
        showInCallContacts = false
        inCallDtmfDigits = ""
        inCallContactSearchQuery = ""
        isCallActive = true
        isCallMinimized = false
        showActiveCallModal = true
        callEndedDismissTimer.stop()
        // Keep the UI in "Calling…" until HFP reports an actual active call.
        systemController.dialNumber(callTarget)
    }

    function cancelPendingCall() {
        showDialConfirmation = false
        pendingCallName = ""
        pendingCallNumber = ""
    }

    function getInCallFilteredContacts() {
        var list = systemController.contactsList
        if (!inCallContactSearchQuery || inCallContactSearchQuery.trim() === "") {
            return list
        }
        var q = inCallContactSearchQuery.trim().toLowerCase()
        var res = []
        for (var i = 0; i < list.length; ++i) {
            var item = list[i]
            var name = ((item && item.name) ? item.name : "").toLowerCase()
            var number = ((item && item.number) ? item.number : "").toLowerCase()
            if (name.indexOf(q) !== -1 || number.indexOf(q) !== -1) {
                res.push(item)
            }
        }
        return res
    }

    function t9MapLetter(ch) {
        if (!ch) return ""
        var c = ch.toLowerCase()
        if (c >= 'a' && c <= 'c') return '2'
        if (c >= 'd' && c <= 'f') return '3'
        if (c >= 'g' && c <= 'i') return '4'
        if (c >= 'j' && c <= 'l') return '5'
        if (c >= 'm' && c <= 'o') return '6'
        if (c >= 'p' && c <= 's') return '7'
        if (c >= 't' && c <= 'v') return '8'
        if (c >= 'w' && c <= 'z') return '9'
        return ""
    }

    function nameToT9(name) {
        if (!name) return ""
        var res = ""
        for (var i = 0; i < name.length; ++i) {
            res += t9MapLetter(name[i])
        }
        return res
    }

    function cleanDigits(val) {
        if (!val) return ""
        var res = ""
        for (var i = 0; i < val.length; ++i) {
            var ch = val[i]
            if (ch >= '0' && ch <= '9') res += ch
        }
        return res
    }

    function getSmartDialContacts(filterText, contactsSource) {
        var contacts = (contactsSource !== undefined) ? contactsSource : systemController.contactsList
        if (!contacts || contacts.length === 0) return []
        var query = ((filterText !== undefined) ? filterText : root.dialedNumber).trim()
        var queryDigits = cleanDigits(query)

        var results = []
        var seen = {}

        if (queryDigits.length === 0) {
            return []
        }

        // 1. Direct number matches
        for (var j = 0; j < contacts.length; ++j) {
            var c = contacts[j]
            var cNum = (c && c.number) ? c.number : ""
            var cName = (c && c.name) ? c.name : cNum
            var cDigits = cleanDigits(cNum)
            if (cDigits.indexOf(queryDigits) !== -1) {
                if (!seen[cNum]) {
                    seen[cNum] = true
                    results.push({ name: cName, number: cNum })
                }
            }
        }

        // 2. T9 Name matches
        for (var k = 0; k < contacts.length; ++k) {
            var c2 = contacts[k]
            var cNum2 = (c2 && c2.number) ? c2.number : ""
            var cName2 = (c2 && c2.name) ? c2.name : cNum2
            if (seen[cNum2]) continue
            var t9 = nameToT9(cName2)
            if (t9.indexOf(queryDigits) !== -1) {
                seen[cNum2] = true
                results.push({ name: cName2, number: cNum2 })
            }
        }

        return results
    }

    function resetToDefault() {
        currentTab = "recents"
        dialedNumber = ""
        contactSearchQuery = ""
        isSearchKeyboardOpen = false
        changeConnScrim.visible = false
        if (!root.isCallActive) {
            showActiveCallModal = false
            showInCallKeypad = false
            showInCallContacts = false
        }
    }

    // ----------------------------------------------------
    // Models bound to real systemController telemetries
    // ----------------------------------------------------

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
        // MINIMIZED IN-CALL STATUS BANNER (Photo & OEM Functionality)
        // ====================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            color: "#0B1929"
            border.color: "#1E4976"
            border.width: 1
            visible: root.isCallActive && root.isCallMinimized

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 16
                spacing: 14

                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: "#22C55E"
                    Layout.alignment: Qt.AlignVCenter

                    Image {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        source: "qrc:/assets/phone/icon_phone_green.png"
                        fillMode: Image.PreserveAspectFit
                    }

                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        running: root.isCallActive && root.isCallMinimized
                        NumberAnimation { to: 1.12; duration: 800; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                    }
                }

                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    Text {
                        text: "Active Call: " + root.activeCallName + (root.activeCallNumber !== root.activeCallName && root.activeCallNumber.length > 0 ? (" • " + root.activeCallNumber) : "")
                        color: "#FFFFFF"
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                        elide: Text.ElideRight
                    }

                    Text {
                        text: root.callStatus === "ended" ? "Call ended" : ("Duration: " + root.formatCallDuration(root.activeCallDurationSeconds) + (root.isCallMuted ? " (Muted)" : ""))
                        color: root.callStatus === "ended" ? "#EF4444" : "#60A5FA"
                        font.pixelSize: 13
                        font.family: "Roboto"
                    }
                }

                // Return to Call Screen Button
                Rectangle {
                    width: 120
                    height: 34
                    radius: 4
                    color: bannerReturnMouse.pressed ? "#1E3B5C" : "#162C44"
                    border.color: "#389BFF"
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: "Return to Call"
                        color: "#FFFFFF"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: bannerReturnMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.isCallMinimized = false
                    }
                }

                // Quick Hangup Button
                Rectangle {
                    width: 90
                    height: 34
                    radius: 4
                    color: bannerEndMouse.pressed ? "#B91C1C" : "#E03535"
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: "End call"
                        color: "#FFFFFF"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: bannerEndMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.endActiveCall()
                            systemController.hangUpCall()
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                cursorShape: Qt.PointingHandCursor
                onClicked: root.isCallMinimized = false
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
                // TAB 1: RECENTS / CALL HISTORY VIEW (Photo 1 Match!)
                // ============================================
                Item {
                    anchors.fill: parent
                    visible: root.currentTab === "recents"

                    ListView {
                        id: recentsListView
                        anchors.fill: parent
                        anchors.rightMargin: 60
                        anchors.topMargin: 4
                        model: systemController.callHistory
                        clip: true

                        delegate: Rectangle {
                            property string historyType: {
                                if (modelData && modelData.type !== undefined)
                                    return String(modelData.type).toUpperCase()
                                if (modelData && modelData.isMissed === true)
                                    return "MISSED"
                                if (modelData && modelData.isIncoming === true)
                                    return "RECEIVED"
                                return "DIALED"
                            }

                            width: recentsListView.width
                            height: 74
                            color: rowMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.22) : (rowMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.06) : "transparent")

                            Behavior on color { ColorAnimation { duration: 120 } }

                            // Incoming / outgoing / missed icon
                            Image {
                                id: historyDirectionIcon
                                anchors.left: parent.left
                                anchors.leftMargin: 20
                                anchors.verticalCenter: parent.verticalCenter
                                width: 32
                                height: 32
                                source: {
                                    if (historyType === "MISSED")
                                        return "qrc:/assets/phone/icon_history_missed.png"
                                    if (historyType === "DIALED" || historyType === "OUTGOING")
                                        return "qrc:/assets/phone/icon_history_outgoing.png"
                                    return "qrc:/assets/phone/icon_history_incoming.png"
                                }
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                            }

                            // Caller Name on the left
                            Text {
                                anchors.left: historyDirectionIcon.right
                                anchors.leftMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                text: (modelData && modelData.name !== undefined) ? modelData.name : (model.name || "")
                                color: rowMouse.pressed ? "#70D6FF" : "#FFFFFF"
                                font.pixelSize: 26
                                font.weight: Font.DemiBold
                                font.family: "Roboto"
                            }

                            // Date / Time on the right (Today -> "9:05 AM", Yesterday/older -> "09-02-2024")
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 32
                                anchors.verticalCenter: parent.verticalCenter
                                text: (modelData && modelData.date !== undefined) ? modelData.date : (model.date || "")
                                color: rowMouse.pressed ? "#70D6FF" : "#FFFFFF"
                                font.pixelSize: 24
                                font.weight: Font.Normal
                                font.family: "Roboto"
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
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var cName = (modelData && modelData.name !== undefined) ? modelData.name : (model.name || "")
                                    var cNum = (modelData && modelData.number !== undefined) ? modelData.number : (model.number || "")
                                    console.log("[Phone] Calling recent contact:", cName, cNum)
                                    root.triggerCall(cName, cNum)
                                }
                            }
                        }
                    }

                    // Big Slider on the right (Exact Photo 1 Match!)
                    Item {
                        id: recentsScrollTrack
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        width: 58

                        // Track Background
                        Rectangle {
                            anchors.fill: parent
                            color: "#080C14"
                            opacity: 0.6
                        }

                        // The Big Slider Handle (Light-blue with 3 horizontal grip lines ☰)
                        Rectangle {
                            id: recentsSliderHandle
                            width: 48
                            height: 58
                            radius: 4
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: "#8BD3FF"
                            border.color: "#5FAEDF"
                            border.width: 1

                            // Vertical position bound to ListView scrolling
                            y: {
                                if (recentsListView.contentHeight <= recentsListView.height) return 0
                                var maxContentY = recentsListView.contentHeight - recentsListView.height
                                var maxHandleY = recentsScrollTrack.height - height
                                var ratio = Math.max(0.0, Math.min(1.0, recentsListView.contentY / maxContentY))
                                return ratio * maxHandleY
                            }

                            // 3 Horizontal Grip Lines (☰)
                            Column {
                                anchors.centerIn: parent
                                spacing: 5

                                Rectangle {
                                    width: 22
                                    height: 3
                                    radius: 1.5
                                    color: "#163456"
                                }
                                Rectangle {
                                    width: 22
                                    height: 3
                                    radius: 1.5
                                    color: "#163456"
                                }
                                Rectangle {
                                    width: 22
                                    height: 3
                                    radius: 1.5
                                    color: "#163456"
                                }
                            }
                        }

                        // Drag & Tap MouseArea for the Big Slider
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            function updateScroll(mouseY) {
                                if (recentsListView.contentHeight <= recentsListView.height) return
                                var maxHandleY = recentsScrollTrack.height - recentsSliderHandle.height
                                var clampedY = Math.max(0, Math.min(maxHandleY, mouseY - recentsSliderHandle.height / 2))
                                var ratio = clampedY / maxHandleY
                                recentsListView.contentY = ratio * (recentsListView.contentHeight - recentsListView.height)
                            }

                            onPressed: function(mouse) { updateScroll(mouse.y) }
                            onPositionChanged: function(mouse) {
                                if (pressed) updateScroll(mouse.y)
                            }
                        }
                    }
                }

                // ============================================
                // TAB 2: CONTACTS VIEW (Photo 2 Match!)
                // ============================================
                Item {
                    anchors.fill: parent
                    visible: root.currentTab === "contacts"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        // Header Bar: Searchable "Entire list" block taking the whole block across the top
                        Rectangle {
                            id: searchHeaderBox
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            radius: 6
                            color: root.isSearchKeyboardOpen ? "#E2E8F0" : "#CAD3DE"
                            border.color: root.isSearchKeyboardOpen ? "#389BFF" : "transparent"
                            border.width: root.isSearchKeyboardOpen ? 2 : 0

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 12

                                // Search Icon
                                Text {
                                    text: "🔍"
                                    font.pixelSize: 20
                                    color: "#3A4756"
                                    Layout.alignment: Qt.AlignVCenter

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.isSearchKeyboardOpen = true
                                            contactSearchInput.forceActiveFocus()
                                        }
                                    }
                                }

                                // Search Input Field
                                TextInput {
                                    id: contactSearchInput
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    font.pixelSize: 22
                                    font.weight: Font.DemiBold
                                    font.family: "Roboto"
                                    color: "#1E293B"
                                    clip: true
                                    text: root.contactSearchQuery
                                    onTextChanged: root.contactSearchQuery = text
                                    onActiveFocusChanged: {
                                        if (activeFocus) {
                                            root.isSearchKeyboardOpen = true
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.isSearchKeyboardOpen = true
                                            contactSearchInput.forceActiveFocus()
                                        }
                                    }

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "Search contacts / Entire list (" + (root.contactSearchQuery.length > 0 ? root.getFilteredContacts().length : systemController.contactsCount) + ")"
                                        color: "#5B6B7C"
                                        font.pixelSize: 22
                                        font.weight: Font.DemiBold
                                        font.family: "Roboto"
                                        visible: !contactSearchInput.text && !contactSearchInput.activeFocus
                                    }
                                }

                                // Clear Search Button
                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: clearSearchMouse.pressed ? "#94A3B8" : "#AAB7C6"
                                    visible: root.contactSearchQuery.length > 0
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        color: "#1E293B"
                                        font.pixelSize: 14
                                        font.weight: Font.Bold
                                    }

                                    MouseArea {
                                        id: clearSearchMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.clearSearchInput()
                                        }
                                    }
                                }

                            }

                            MouseArea {
                                anchors.fill: parent
                                z: -1
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.isSearchKeyboardOpen = true
                                    contactSearchInput.forceActiveFocus()
                                }
                            }
                        }

                        // Contacts List + Alphabet Index + Scrollbar
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ListView {
                                id: contactsListView
                                anchors.fill: parent
                                anchors.rightMargin: 70
                                anchors.topMargin: 4
                                model: root.contactSearchQuery.length > 0 ? root.getFilteredContacts() : systemController.contactsList
                                clip: true

                                delegate: Rectangle {
                                    width: contactsListView.width
                                    height: 72
                                    color: contactMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.22) : (contactMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.06) : "transparent")

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    // Contact Name on the left
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 28
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: (modelData && modelData.name !== undefined) ? modelData.name : (model.name || "")
                                        color: contactMouse.pressed ? "#70D6FF" : "#FFFFFF"
                                        font.pixelSize: 26
                                        font.weight: Font.DemiBold
                                        font.family: "Roboto"
                                    }

                                    // Right: Clean Mobile Phone Handset Outline Icon 📱 (Photo 2 Match!)
                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 24
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 18
                                        height: 30
                                        radius: 2.5
                                        color: "transparent"
                                        border.color: "#8FA3B8"
                                        border.width: 1.6
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
                                        onClicked: {
                                            var cName = (modelData && modelData.name !== undefined) ? modelData.name : (model.name || "")
                                            var cNum = (modelData && modelData.number !== undefined) ? modelData.number : (model.number || "")
                                            console.log("[Phone] Calling contact:", cName, cNum)
                                            root.triggerCall(cName, cNum)
                                        }
                                    }
                                }
                            }

                            // Alphabet Index Bar: # • A • D • G • J • M • P • S • V (Photo 2 Match!)
                            Column {
                                id: alphabetBar
                                anchors.right: contactsScrollTrack.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                Repeater {
                                    model: ["#", "•", "A", "•", "D", "•", "G", "•", "J", "•", "M", "•", "P", "•", "S", "•", "V"]
                                    Item {
                                        width: 24
                                        height: modelData === "•" ? 12 : 22
                                        anchors.horizontalCenter: parent.horizontalCenter

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: modelData === "•" ? "#7A8F9E" : (letterMouse.pressed ? "#389BFF" : "#CAD8E6")
                                            font.pixelSize: modelData === "•" ? 14 : 17
                                            font.weight: Font.Bold
                                            font.family: "Roboto"
                                        }

                                        MouseArea {
                                            id: letterMouse
                                            anchors.fill: parent
                                            cursorShape: modelData !== "•" ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            enabled: modelData !== "•"
                                            onClicked: {
                                                var idx = systemController.getFirstContactIndexForLetter(modelData)
                                                contactsListView.positionViewAtIndex(idx, ListView.Beginning)
                                            }
                                        }
                                    }
                                }
                            }

                            // Far Right: Vertical Scrollbar track with cyan thumb pill (Photo 2 Match!)
                            Item {
                                id: contactsScrollTrack
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                width: 24

                                Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"
                                }

                                Rectangle {
                                    id: contactsScrollThumb
                                    width: 8
                                    radius: 4
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: "#8BD3FF"
                                    height: {
                                        if (contactsListView.contentHeight <= contactsListView.height) return contactsScrollTrack.height
                                        return Math.max(40, (contactsListView.height / contactsListView.contentHeight) * contactsScrollTrack.height)
                                    }
                                    y: {
                                        if (contactsListView.contentHeight <= contactsListView.height) return 0
                                        var maxContentY = contactsListView.contentHeight - contactsListView.height
                                        var maxThumbY = contactsScrollTrack.height - height
                                        var ratio = Math.max(0.0, Math.min(1.0, contactsListView.contentY / maxContentY))
                                        return ratio * maxThumbY
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    function updateScroll(mouseY) {
                                        if (contactsListView.contentHeight <= contactsListView.height) return
                                        var maxThumbY = contactsScrollTrack.height - contactsScrollThumb.height
                                        var clampedY = Math.max(0, Math.min(maxThumbY, mouseY - contactsScrollThumb.height / 2))
                                        var ratio = clampedY / maxThumbY
                                        contactsListView.contentY = ratio * (contactsListView.contentHeight - contactsListView.height)
                                    }
                                    onPressed: function(mouse) { updateScroll(mouse.y) }
                                    onPositionChanged: function(mouse) { if (pressed) updateScroll(mouse.y) }
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
                            id: dialerInputBox
                            anchors.left: parent.left
                            anchors.leftMargin: 24
                            anchors.top: parent.top
                            anchors.topMargin: 20
                            anchors.right: parent.right
                            anchors.rightMargin: 32
                            height: 58
                            color: "#CAD3DE"
                            radius: 4

                            Text {
                                id: inputNumberText
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 18
                                anchors.right: inputControlsRow.left
                                anchors.rightMargin: 8
                                elide: Text.ElideLeft
                                text: root.dialedNumber.length > 0 ? root.dialedNumber : "Enter phone number."
                                color: root.dialedNumber.length > 0 ? "#0A1428" : "#5A6778"
                                font.pixelSize: 26
                                font.weight: Font.DemiBold
                                font.family: "Roboto"
                            }

                            // Right controls: [count] and ⌫ backspace
                            Row {
                                id: inputControlsRow
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10

                                // Match count in brackets e.g. [10]
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: root.dialedNumber.length > 0 && smartDialList.count > 0
                                    text: "[" + smartDialList.count + "]"
                                    color: "#4A5568"
                                    font.pixelSize: 22
                                    font.weight: Font.Medium
                                    font.family: "Roboto"
                                }

                                // Backspace ⌫ Icon inside display
                                Item {
                                    id: clearIconArea
                                    width: 36
                                    height: 36
                                    anchors.verticalCenter: parent.verticalCenter
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
                        }

                        // Middle: Smart Dial Suggestions (Only Name & Number)
                        Item {
                            id: smartDialPanel
                            anchors.left: parent.left
                            anchors.leftMargin: 24
                            anchors.right: parent.right
                            anchors.rightMargin: 32
                            anchors.top: dialerInputBox.bottom
                            anchors.topMargin: 16
                            anchors.bottom: dialerBottomStatusRow.top
                            anchors.bottomMargin: 12
                            visible: root.dialedNumber.length > 0
                            clip: true

                            ListView {
                                id: smartDialList
                                anchors.fill: parent
                                clip: true
                                spacing: 14
                                model: root.dialedNumber.length > 0 ? root.getSmartDialContacts(root.dialedNumber, systemController.contactsList) : []

                                delegate: Item {
                                    width: smartDialList.width
                                    height: 48

                                    Column {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2

                                        // Contact Name
                                        Text {
                                            width: parent.width
                                            text: modelData.name
                                            color: smartRowMouse.pressed ? "#70D6FF" : "#BACBDD"
                                            font.pixelSize: 21
                                            font.weight: Font.Normal
                                            font.family: "Roboto"
                                            elide: Text.ElideRight
                                        }

                                        // Contact Number
                                        Text {
                                            width: parent.width
                                            text: modelData.number
                                            color: "#6B7C8E"
                                            font.pixelSize: 15
                                            font.family: "Roboto"
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        id: smartRowMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.dialedNumber = modelData.number
                                        }
                                    }
                                }
                            }
                        }

                        // Bottom Left: Device Name + Indicators (Phone Name -> BT -> Tower -> Battery)
                        Row {
                            id: dialerBottomStatusRow
                            anchors.left: parent.left
                            anchors.leftMargin: 24
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 18
                            spacing: 12
                            Layout.alignment: Qt.AlignVCenter
                            visible: systemController.isBluetoothConnected || (systemController.detectedBluetoothName !== "" && systemController.detectedBluetoothName !== "No Device Connected")

                            // 1. Phone Name
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: (systemController.activeHandsFreeDeviceName !== "" ? systemController.activeHandsFreeDeviceName : (systemController.detectedBluetoothName !== "" ? systemController.detectedBluetoothName : "Connected Phone"))
                                color: "#BACBDD"
                                font.pixelSize: 19
                                font.weight: Font.DemiBold
                                font.family: "Roboto"
                            }

                            // 2. Bluetooth Symbol
                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 14
                                height: 20
                                source: "qrc:/assets/phone/icon_phone_bt.png"
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                            }

                            // 3. Cellular Signal Tower Indicator (Antenna Mast + 4 Bars)
                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                // Antenna Mast symbol
                                Item {
                                    width: 12
                                    height: 18
                                    anchors.bottom: parent.bottom

                                    Rectangle {
                                        width: 2
                                        height: 18
                                        color: systemController.phoneSignalLevel > 0 ? "#BACBDD" : "#475569"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.bottom
                                    }
                                    Rectangle {
                                        width: 10
                                        height: 2
                                        radius: 1
                                        color: systemController.phoneSignalLevel > 0 ? "#BACBDD" : "#475569"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.top: parent.top
                                    }
                                    Rectangle {
                                        width: 6
                                        height: 1.5
                                        color: systemController.phoneSignalLevel > 0 ? "#BACBDD" : "#475569"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.top: parent.top
                                        anchors.topMargin: 5
                                    }
                                }

                                // 4 Signal Bars
                                Row {
                                    anchors.bottom: parent.bottom
                                    spacing: 3

                                    Rectangle {
                                        width: 3.5
                                        height: 6
                                        radius: 1
                                        color: systemController.phoneSignalLevel >= 1 ? "#BACBDD" : "#263548"
                                        anchors.bottom: parent.bottom
                                    }
                                    Rectangle {
                                        width: 3.5
                                        height: 10
                                        radius: 1
                                        color: systemController.phoneSignalLevel >= 2 ? "#BACBDD" : "#263548"
                                        anchors.bottom: parent.bottom
                                    }
                                    Rectangle {
                                        width: 3.5
                                        height: 14
                                        radius: 1
                                        color: systemController.phoneSignalLevel >= 3 ? "#BACBDD" : "#263548"
                                        anchors.bottom: parent.bottom
                                    }
                                    Rectangle {
                                        width: 3.5
                                        height: 18
                                        radius: 1
                                        color: systemController.phoneSignalLevel >= 4 ? "#BACBDD" : "#263548"
                                        anchors.bottom: parent.bottom
                                    }
                                }
                            }

                            // 4. Battery Indicator (Shell + Dynamic Level Fill + Terminal Nub)
                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                Rectangle {
                                    width: 28
                                    height: 14
                                    radius: 2.5
                                    color: "transparent"
                                    border.color: systemController.phoneBatteryLevel <= 0 ? "#475569" : (systemController.phoneBatteryLevel <= 20 ? "#EF4444" : "#BACBDD")
                                    border.width: 1.5

                                    // Inside fill bar
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: systemController.phoneBatteryLevel <= 0 ? 0 : Math.max(3, Math.min(21, Math.round((systemController.phoneBatteryLevel / 100.0) * 21)))
                                        height: 8
                                        radius: 1
                                        color: systemController.phoneBatteryLevel <= 20 ? "#EF4444" : (systemController.phoneBatteryLevel <= 35 ? "#EAB308" : "#22C55E")
                                    }
                                }

                                // Positive terminal nub
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 2.5
                                    height: 6
                                    radius: 1
                                    color: systemController.phoneBatteryLevel <= 0 ? "#475569" : (systemController.phoneBatteryLevel <= 20 ? "#EF4444" : "#BACBDD")
                                }
                            }
                        }

                        // Fallback message when no phone is connected
                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 24
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 18
                            spacing: 8
                            visible: !dialerBottomStatusRow.visible

                            Text {
                                text: "No Phone Connected"
                                color: "#475569"
                                font.pixelSize: 17
                                font.weight: Font.Normal
                                font.family: "Roboto"
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
                                    onClicked: {
                                        if (root.dialedNumber.length > 0) {
                                            console.log("[Phone] Dialing call to:", root.dialedNumber)
                                            root.triggerCall(root.dialedNumber, root.dialedNumber)
                                        }
                                    }
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

    // A deliberate second action prevents list scrolling, touch-up leakage,
    // or an accidental row tap from placing a real phone call.
    Rectangle {
        id: dialConfirmationScrim
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.72)
        visible: root.showDialConfirmation
        z: 1200

        MouseArea {
            anchors.fill: parent
            onClicked: root.cancelPendingCall()
        }

        Rectangle {
            anchors.centerIn: parent
            width: 620
            height: 270
            radius: 12
            color: "#121C29"
            border.color: "#36526F"
            border.width: 1

            MouseArea { anchors.fill: parent; onClicked: {} }

            Column {
                anchors.centerIn: parent
                spacing: 18

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Call " + root.pendingCallName + "?"
                    color: "#FFFFFF"
                    font.pixelSize: 28
                    font.weight: Font.DemiBold
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.pendingCallNumber
                    color: "#9FB3C8"
                    font.pixelSize: 20
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20
                    Rectangle {
                        width: 190; height: 58; radius: 8; color: "#26384B"
                        Text { anchors.centerIn: parent; text: "Cancel"; color: "#FFFFFF"; font.pixelSize: 19 }
                        MouseArea { anchors.fill: parent; onClicked: root.cancelPendingCall() }
                    }
                    Rectangle {
                        width: 190; height: 58; radius: 8; color: "#1F9D55"
                        Text { anchors.centerIn: parent; text: "Call"; color: "#FFFFFF"; font.pixelSize: 19; font.bold: true }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.confirmPendingCall()
                        }
                    }
                }
            }
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

    // ====================================================
    // ACTIVE IN-CALL OVERLAY (Genuine IVI Match: Caller Info + Middle Panel + Right Sidebar)
    // ====================================================
    Rectangle {
        id: activeCallOverlay
        anchors.fill: parent
        color: "#050B14"
        visible: (root.isCallActive || callEndedDismissTimer.running) && !root.isCallMinimized
        z: 999
        opacity: 1.0

        // End-Call Fade Animation
        SequentialAnimation {
            id: callEndedFadeAnim
            running: root.callStatus === "ended" && activeCallOverlay.visible
            PauseAnimation { duration: 1100 }
            NumberAnimation {
                target: activeCallOverlay
                property: "opacity"
                to: 0.0
                duration: 450
                easing.type: Easing.InOutQuad
            }
        }

        // Deep automotive gradient background
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0A182A" }
            GradientStop { position: 0.45; color: "#06101D" }
            GradientStop { position: 1.0; color: "#03080F" }
        }

        // Prevent mouse event leakage to underlying views
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // ------------------------------------------------
        // 1. IN-CALL TOP HEADER BAR (Phone on left, Middle Title, Back on right)
        // ------------------------------------------------
        Item {
            id: inCallHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 60

            // Bottom hairline border
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: "#122032"
            }

            // LEFT: Handset Icon + "Phone"
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 26
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Image {
                    width: 28
                    height: 28
                    source: "qrc:/assets/apps/icon_phone.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Phone"
                    color: "#FFFFFF"
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // CENTER: Header Title for Middle Panel ("Contacts" / "Dialer")
            Text {
                anchors.verticalCenter: parent.verticalCenter
                x: inCallMainArea.x + (root.showInCallKeypad || root.showInCallContacts ? 400 : 0)
                text: root.showInCallContacts ? "Contacts" : (root.showInCallKeypad ? "Dialer" : "")
                color: "#FFFFFF"
                font.pixelSize: 24
                font.weight: Font.DemiBold
                font.family: "Roboto"
                visible: root.showInCallContacts || root.showInCallKeypad
            }

            // RIGHT: Back Arrow Button [ ↩ ]
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                width: 78
                height: 42
                radius: 6
                color: inCallBackMouse.pressed ? "#1E3B5C" : (inCallBackMouse.containsMouse ? "#182E47" : "#0F2033")
                border.color: inCallBackMouse.pressed ? "#389BFF" : "#1B3652"
                border.width: 1.5

                Image {
                    anchors.centerIn: parent
                    width: 30
                    height: 24
                    source: "qrc:/assets/ui/icon_back.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                MouseArea {
                    id: inCallBackMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.showInCallContacts || root.showInCallKeypad) {
                            // Close the middle panel and return to normal in-call view
                            root.showInCallContacts = false
                            root.showInCallKeypad = false
                        } else {
                            // Minimize call to browse background IVI screens
                            console.log("[Phone] Back pressed from active call -> Minimizing call")
                            root.isCallMinimized = true
                        }
                    }
                }
            }
        }

        // ------------------------------------------------
        // 2. BOTTOM ACTION BUTTONS BAR (Spanning Entire Bottom Width: Use Private & End)
        // ------------------------------------------------
        Item {
            id: inCallBottomBar
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: inCallRightSidebar.left
            anchors.rightMargin: 16
            height: 72

            Row {
                anchors.fill: parent
                spacing: 16

                property real btnWidth: (width - spacing) / 2

                // 1. USE PRIVATE BUTTON (Left)
                Rectangle {
                    width: parent.btnWidth
                    height: parent.height
                    radius: 8
                    color: usePrivateMouse.pressed ? "#18324E" : (usePrivateMouse.containsMouse ? "#12253B" : "#0A1726")
                    border.color: usePrivateMouse.pressed ? "#389BFF" : "#1C3754"
                    border.width: 1.5

                    // Gradient sheen
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: "#284A6E"
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 16

                        Image {
                            width: 36
                            height: 24
                            source: "qrc:/assets/phone/icon_call_private.png"
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: root.isPrivateMode ? "Use Handsfree" : "Use Private"
                            color: "#96B1D0"
                            font.pixelSize: 24
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: usePrivateMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.isPrivateMode = !root.isPrivateMode
                            console.log("[Phone] Private mode toggled:", root.isPrivateMode)
                        }
                    }
                }

                // 2. END CALL BUTTON (Right)
                Rectangle {
                    width: parent.btnWidth
                    height: parent.height
                    radius: 8
                    color: endCallMouse.pressed ? "#6B1D1D" : (endCallMouse.containsMouse ? "#1A2534" : "#0A1726")
                    border.color: endCallMouse.pressed ? "#EF4444" : "#1C3754"
                    border.width: 1.5

                    // Gradient sheen
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: endCallMouse.pressed ? "#B91C1C" : "#284A6E"
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 16

                        Image {
                            width: 48
                            height: 26
                            source: "qrc:/assets/phone/icon_call_end.png"
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "End"
                            color: "#FFFFFF"
                            font.pixelSize: 26
                            font.weight: Font.Bold
                            font.family: "Roboto"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: endCallMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            console.log("[Phone] End button clicked -> Hanging up call")
                            root.endActiveCall(false)
                            systemController.hangUpCall()
                        }
                    }
                }
            }
        }

        // ------------------------------------------------
        // 3. RIGHT SIDEBAR (3 Stacked Buttons: Contacts, Mute, Keypad)
        // ------------------------------------------------
        Column {
            id: inCallRightSidebar
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.top: inCallHeader.bottom
            anchors.topMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            width: 150
            spacing: 12

            property real btnHeight: (height - (2 * spacing)) / 3

            // Button 1 (Top): Phonebook / Contacts
            Rectangle {
                width: parent.width
                height: inCallRightSidebar.btnHeight
                radius: 8
                color: root.showInCallContacts ? "#0E345C" : (inCallContactsMouse.pressed ? "#162B44" : "#0A1828")
                border.color: root.showInCallContacts ? "#389BFF" : "#1B334E"
                border.width: root.showInCallContacts ? 2.0 : 1.5

                Image {
                    anchors.centerIn: parent
                    width: 68
                    height: 68
                    source: "qrc:/assets/phone/icon_call_contacts.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }

                MouseArea {
                    id: inCallContactsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.showInCallContacts = !root.showInCallContacts
                        if (root.showInCallContacts) root.showInCallKeypad = false
                        console.log("[Phone] Contacts toggled:", root.showInCallContacts)
                    }
                }
            }

            // Button 2 (Middle): Mute Microphone
            Rectangle {
                width: parent.width
                height: inCallRightSidebar.btnHeight
                radius: 8
                color: root.isCallMuted ? "#1C3C60" : (inCallMuteMouse.pressed ? "#162B44" : "#0A1828")
                border.color: root.isCallMuted ? "#389BFF" : "#1B334E"
                border.width: root.isCallMuted ? 2.0 : 1.5

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 58
                        height: 62
                        source: "qrc:/assets/phone/icon_call_mute.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "3"
                        color: root.isCallMuted ? "#389BFF" : "#748EA8"
                        font.pixelSize: 22
                        font.weight: Font.Medium
                        font.family: "Roboto"
                    }
                }

                MouseArea {
                    id: inCallMuteMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.isCallMuted = !root.isCallMuted
                        console.log("[Phone] Mute toggled:", root.isCallMuted)
                        systemController.setCallMuted(root.isCallMuted)
                    }
                }
            }

            // Button 3 (Bottom): Keypad / Dialpad
            Rectangle {
                width: parent.width
                height: inCallRightSidebar.btnHeight
                radius: 8
                color: root.showInCallKeypad ? "#0E345C" : (inCallKeypadMouse.pressed ? "#162B44" : "#0A1828")
                border.color: root.showInCallKeypad ? "#389BFF" : "#1B334E"
                border.width: root.showInCallKeypad ? 2.0 : 1.5

                // Left drawer tab indicator [ ◀ ]
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "◀"
                    color: root.showInCallKeypad ? "#389BFF" : "#748EA8"
                    font.pixelSize: 15
                }

                // Sharp 2x2 Grid Icon matching OEM photo
                Grid {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 6
                    columns: 2
                    spacing: 4

                    Repeater {
                        model: ["1", "2", "*", "#"]
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 3
                            color: "#182A3E"
                            border.color: "#3F6488"
                            border.width: 1.5

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: "#FFFFFF"
                                font.pixelSize: 16
                                font.weight: Font.Bold
                                font.family: "Roboto"
                            }
                        }
                    }
                }

                MouseArea {
                    id: inCallKeypadMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.showInCallKeypad = !root.showInCallKeypad
                        if (root.showInCallKeypad) root.showInCallContacts = false
                        console.log("[Phone] Keypad toggled:", root.showInCallKeypad)
                    }
                }
            }
        }

        // ------------------------------------------------
        // 4. MAIN WORKING AREA (Caller Display on left, Contacts/Dialer in middle)
        // ------------------------------------------------
        Item {
            id: inCallMainArea
            anchors.top: inCallHeader.bottom
            anchors.bottom: inCallBottomBar.top
            anchors.left: parent.left
            anchors.right: inCallRightSidebar.left
            anchors.rightMargin: 16

            // ============================================
            // LEFT COLUMN: CALLER INFO (Always Visible: Status, Name, Number, Duration)
            // ============================================
            Item {
                id: callerInfoCol
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: (root.showInCallKeypad || root.showInCallContacts) ? 380 : parent.width

                Behavior on width {
                    NumberAnimation { duration: 220; easing.type: Easing.InOutQuad }
                }

                // Calling... / Call Ended Status Line (Top-Left)
                Row {
                    anchors.top: parent.top
                    anchors.topMargin: 20
                    anchors.left: parent.left
                    anchors.leftMargin: 32
                    spacing: 12

                    // Radiating Green Handset Icon (Pulsing animation when dialing)
                    Item {
                        width: 40
                        height: 40
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            anchors.centerIn: parent
                            width: 38
                            height: 38
                            source: "qrc:/assets/phone/icon_call_status_green.png"
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            visible: root.callStatus !== "ended"

                            SequentialAnimation on scale {
                                loops: Animation.Infinite
                                running: root.callStatus === "calling"
                                NumberAnimation { to: 1.15; duration: 750; easing.type: Easing.InOutQuad }
                                NumberAnimation { to: 1.0; duration: 750; easing.type: Easing.InOutQuad }
                            }
                        }

                        // Red Hangup Indicator when Call Ends
                        Image {
                            anchors.centerIn: parent
                            width: 36
                            height: 20
                            source: "qrc:/assets/phone/icon_call_end.png"
                            fillMode: Image.PreserveAspectFit
                            visible: root.callStatus === "ended"
                        }
                    }

                    // Status Text: Calling... / Active Call / Call ended
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.callStatus === "ended" ? "Call ended" : (root.callStatus === "calling" ? "Calling..." : "Active Call")
                        color: root.callStatus === "ended" ? "#EF4444" : "#3CE86D"
                        font.pixelSize: 26
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }
                }

                // Center Identity Stack: Contact Name, Phone Number, Duration
                Column {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -6
                    spacing: 8
                    width: parent.width - 40

                    // Prominent Caller Avatar / Logo Badge (Takes good space, fills the center)
                    Rectangle {
                        id: callerAvatarBadge
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: (root.showInCallKeypad || root.showInCallContacts) ? 96 : 140
                        height: width
                        radius: width / 2
                        color: "#12253B"
                        border.color: root.callStatus === "ended" ? "#EF4444" : (root.callStatus === "calling" ? "#3CE86D" : "#389BFF")
                        border.width: 3

                        Behavior on width { NumberAnimation { duration: 180 } }
                        Behavior on border.color { ColorAnimation { duration: 200 } }

                        // Subtle outer glow ring
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width + 12
                            height: parent.height + 12
                            radius: width / 2
                            color: "transparent"
                            border.color: root.callStatus === "ended" ? Qt.rgba(0.94, 0.27, 0.27, 0.25) : (root.callStatus === "calling" ? Qt.rgba(0.24, 0.91, 0.43, 0.28) : Qt.rgba(0.22, 0.61, 1.0, 0.25))
                            border.width: 2
                            z: -1
                        }

                        // Gradient fill
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#193654" }
                            GradientStop { position: 1.0; color: "#0B1A2C" }
                        }

                        // High-res caller silhouette icon
                        Image {
                            anchors.centerIn: parent
                            width: parent.width * 0.60
                            height: parent.height * 0.60
                            source: "qrc:/assets/phone/icon_person_avatar.png"
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            opacity: 0.92
                        }

                        // Gentle breathing pulse animation when dialing
                        SequentialAnimation on scale {
                            loops: Animation.Infinite
                            running: root.callStatus === "calling"
                            NumberAnimation { to: 1.06; duration: 800; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                        }
                    }

                    Item { width: 1; height: 6 }

                    // Contact Name (e.g. "AA 1") in bright bold lime green
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.activeCallName.length > 0 ? root.activeCallName : root.activeCallNumber
                        color: root.callStatus === "ended" ? "#EF4444" : "#3CE86D"
                        font.pixelSize: (root.showInCallKeypad || root.showInCallContacts) ? 38 : 48
                        font.weight: Font.Bold
                        font.family: "Roboto"
                        elide: Text.ElideRight
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter

                        Behavior on font.pixelSize { NumberAnimation { duration: 180 } }
                    }

                    // Phone Number (e.g. "714-555-1111") in bright bold lime green
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.activeCallNumber
                        color: root.callStatus === "ended" ? "#EF4444" : "#3CE86D"
                        font.pixelSize: (root.showInCallKeypad || root.showInCallContacts) ? 28 : 38
                        font.weight: Font.Bold
                        font.family: "Roboto"
                        elide: Text.ElideRight
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        visible: root.activeCallName.length > 0 && root.activeCallNumber !== root.activeCallName

                        Behavior on font.pixelSize { NumberAnimation { duration: 180 } }
                    }

                    // Live Duration Timer (visible only once the call is active/picked up, matching OEM!)
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.callStatus === "active" || root.callStatus === "ended" ? root.formatCallDuration(root.activeCallDurationSeconds) : ""
                        color: root.callStatus === "ended" ? "#EF4444" : "#A2B6CC"
                        font.pixelSize: (root.showInCallKeypad || root.showInCallContacts) ? 22 : 26
                        font.weight: Font.Medium
                        font.family: "Roboto"
                        horizontalAlignment: Text.AlignHCenter
                        visible: root.callStatus === "active" || (root.callStatus === "ended" && root.activeCallDurationSeconds > 0)

                        Behavior on font.pixelSize { NumberAnimation { duration: 180 } }
                    }
                }
            }

            // ============================================
            // MIDDLE PANEL: IN-CALL CONTACTS OR IN-CALL DIALER
            // ============================================
            Item {
                id: inCallMiddlePanel
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: callerInfoCol.right
                anchors.leftMargin: 16
                anchors.right: parent.right
                visible: root.showInCallKeypad || root.showInCallContacts

                // Left vertical separator line
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin: 12
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 12
                    width: 1.5
                    color: "#16283C"
                }

                // ------------------------------------------------
                // SUBVIEW 1: IN-CALL CONTACTS LIST (Exact Photo Match!)
                // ------------------------------------------------
                Item {
                    id: inCallContactsSubView
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    visible: root.showInCallContacts

                    ListView {
                        id: inCallContactsListView
                        anchors.fill: parent
                        anchors.rightMargin: 46
                        anchors.topMargin: 8
                        anchors.bottomMargin: 8
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: systemController.contactsList

                        delegate: Rectangle {
                            width: inCallContactsListView.width
                            height: 66
                            color: contactRowMouse.pressed ? "#162D47" : (contactRowMouse.containsMouse ? "#0E1E30" : "transparent")

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                // Contact Name (Left)
                                Text {
                                    Layout.fillWidth: true
                                    text: (modelData && modelData.name !== undefined) ? modelData.name : (model.name || "")
                                    color: "#E2EEFA"
                                    font.pixelSize: 22
                                    font.weight: Font.DemiBold
                                    font.family: "Roboto"
                                    elide: Text.ElideRight
                                }

                                // Phone Number (Right)
                                Text {
                                    text: (modelData && modelData.number !== undefined) ? modelData.number : (model.number || "")
                                    color: "#7FAACF"
                                    font.pixelSize: 18
                                    font.weight: Font.Normal
                                    font.family: "Roboto"
                                }
                            }

                            // Horizontal divider line
                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 1
                                color: "#142436"
                            }

                            MouseArea {
                                id: contactRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    console.log("[Phone] Selected in-call contact:", modelData.name, modelData.number)
                                }
                            }
                        }
                    }

                    // OEM Automotive Scrollbar on the Right Edge
                    Item {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 38

                        // Top Up Arrow Button [ ▲ ]
                        Rectangle {
                            id: scrollUpBtn
                            anchors.top: parent.top
                            anchors.topMargin: 8
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 34
                            height: 34
                            radius: 4
                            color: scrollUpMouse.pressed ? "#1E3B5C" : "#0D1E30"
                            border.color: "#1E3652"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "▲"
                                color: "#7FAACF"
                                font.pixelSize: 12
                            }

                            MouseArea {
                                id: scrollUpMouse
                                anchors.fill: parent
                                onClicked: {
                                    var newY = Math.max(0, inCallContactsListView.contentY - 200)
                                    inCallContactsListView.contentY = newY
                                }
                            }
                        }

                        // Scroll Track
                        Rectangle {
                            anchors.top: scrollUpBtn.bottom
                            anchors.topMargin: 6
                            anchors.bottom: scrollDownBtn.top
                            anchors.bottomMargin: 6
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 6
                            radius: 3
                            color: "#102032"

                            // Scroll Thumb Indicator
                            Rectangle {
                                width: parent.width
                                radius: 3
                                color: "#3B72A8"
                                y: inCallContactsListView.contentHeight > 0 ? (inCallContactsListView.contentY / inCallContactsListView.contentHeight) * parent.height : 0
                                height: inCallContactsListView.contentHeight > 0 ? Math.max(24, (inCallContactsListView.height / inCallContactsListView.contentHeight) * parent.height) : 30
                            }
                        }

                        // Bottom Down Arrow Button [ ▼ ]
                        Rectangle {
                            id: scrollDownBtn
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 8
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 34
                            height: 34
                            radius: 4
                            color: scrollDownMouse.pressed ? "#1E3B5C" : "#0D1E30"
                            border.color: "#1E3652"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "▼"
                                color: "#7FAACF"
                                font.pixelSize: 12
                            }

                            MouseArea {
                                id: scrollDownMouse
                                anchors.fill: parent
                                onClicked: {
                                    var maxScroll = Math.max(0, inCallContactsListView.contentHeight - inCallContactsListView.height)
                                    var newY = Math.min(maxScroll, inCallContactsListView.contentY + 200)
                                    inCallContactsListView.contentY = newY
                                }
                            }
                        }
                    }
                }

                // ------------------------------------------------
                // SUBVIEW 2: IN-CALL DIALER (Exact Photo Match: Input Box with [X] + 3x4 Keypad)
                // ------------------------------------------------
                Item {
                    id: inCallDialerSubView
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    visible: root.showInCallKeypad

                    Column {
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 24, 460)
                        spacing: 12

                        // Top Input Display Box with Clear [ ✕ ] Button
                        Rectangle {
                            width: parent.width
                            height: 52
                            radius: 6
                            color: "#081320"
                            border.color: "#192F47"
                            border.width: 1.5

                            // Digits text
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 16
                                anchors.right: clearDtmfBtn.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.inCallDtmfDigits.length > 0 ? root.inCallDtmfDigits : ""
                                color: "#70D6FF"
                                font.pixelSize: 24
                                font.weight: Font.Bold
                                font.family: "Roboto"
                                elide: Text.ElideRight
                            }

                            // Clear / Delete Button [ ✕ ]
                            Rectangle {
                                id: clearDtmfBtn
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                width: 40
                                height: 40
                                radius: 4
                                color: clearDtmfMouse.pressed ? "#1E3B5C" : (clearDtmfMouse.containsMouse ? "#14273C" : "#0D1E30")
                                border.color: "#1F3854"
                                border.width: 1
                                visible: root.inCallDtmfDigits.length > 0

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: "#A2BCD8"
                                    font.pixelSize: 16
                                    font.weight: Font.Bold
                                }

                                MouseArea {
                                    id: clearDtmfMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.inCallDtmfDigits.length > 0) {
                                            root.inCallDtmfDigits = root.inCallDtmfDigits.slice(0, -1)
                                        }
                                    }
                                }
                            }
                        }

                        // 3x4 Dialpad Grid
                        Grid {
                            id: inCallGrid
                            width: parent.width
                            columns: 3
                            spacing: 8

                            property real cellWidth: (width - (2 * spacing)) / 3
                            property real cellHeight: 74

                            Repeater {
                                model: [
                                    { digit: "1", letters: "" },
                                    { digit: "2", letters: "ABC" },
                                    { digit: "3", letters: "DEF" },
                                    { digit: "4", letters: "GHI" },
                                    { digit: "5", letters: "JKL" },
                                    { digit: "6", letters: "MNO" },
                                    { digit: "7", letters: "PQRS" },
                                    { digit: "8", letters: "TUV" },
                                    { digit: "9", letters: "WXYZ" },
                                    { digit: "*", letters: "" },
                                    { digit: "0", letters: "+" },
                                    { digit: "#", letters: "" }
                                ]

                                delegate: Rectangle {
                                    width: inCallGrid.cellWidth
                                    height: inCallGrid.cellHeight
                                    radius: 6
                                    color: keyMouse.pressed ? "#1B3B60" : (keyMouse.containsMouse ? "#12253A" : "#0A1624")
                                    border.color: keyMouse.pressed ? "#389BFF" : "#1A334E"
                                    border.width: 1.5

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 2

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.digit
                                            color: "#FFFFFF"
                                            font.pixelSize: 26
                                            font.weight: Font.Bold
                                            font.family: "Roboto"
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.letters
                                            color: "#6B85A0"
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                            font.family: "Roboto"
                                            visible: modelData.letters.length > 0
                                        }
                                    }

                                    MouseArea {
                                        id: keyMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.inCallDtmfDigits += modelData.digit
                                            console.log("[Phone] In-call DTMF key clicked:", modelData.digit)
                                            systemController.sendDtmf(modelData.digit)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ========================================================
    // ON-SCREEN KEYBOARD FOR PHONEBOOK SEARCH (OEM Match!)
    // ========================================================
    Rectangle {
        id: searchKeyboardOverlay
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 290
        color: "#05070B"
        border.color: "#1E2A3A"
        border.width: 1
        z: 90
        clip: true
        visible: root.currentTab === "contacts" && (root.isSearchKeyboardOpen || searchKbAnim.running)

        transform: Translate {
            y: root.isSearchKeyboardOpen ? 0 : searchKeyboardOverlay.height
            Behavior on y {
                NumberAnimation {
                    id: searchKbAnim
                    duration: 220
                    easing.type: root.isSearchKeyboardOpen ? Easing.OutCubic : Easing.InCubic
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {} // Absorb clicks so they don't fall through
        }

        Column {
            id: searchKbKeysArea
            anchors.fill: parent
            anchors.margins: 10
            spacing: 7

            readonly property real keyW: (width - 9 * 8) / 10
            readonly property real keyH: 58

            // Repeat Timer for Backspace
            Timer {
                id: bsKbRepeatTimer
                interval: 70
                repeat: true
                onTriggered: root.deleteSearchKey()
            }
            Timer {
                id: bsKbInitialDelayTimer
                interval: 350
                repeat: false
                onTriggered: bsKbRepeatTimer.start()
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
                        width: searchKbKeysArea.keyW
                        height: searchKbKeysArea.keyH
                        color: k1m.pressed ? "#224A73" : (k1m.containsMouse ? "#2C3E55" : "#1F2E42")
                        border.color: k1m.pressed ? "#80D8FF" : (k1m.containsMouse ? "#4D76A5" : "#354A63")
                        border.width: 1
                        radius: 4
                        scale: k1m.pressed ? 0.90 : 1.0
                        Behavior on scale { NumberAnimation { duration: 70 } }

                        readonly property string charKey: (!root.isSymbolMode && (root.isKeyboardShift || root.isCapsLock)) ? modelData.toUpperCase() : modelData

                        Text {
                            anchors.centerIn: parent
                            text: charKey
                            color: "#FFFFFF"
                            font.pixelSize: root.isSymbolMode ? 22 : 24
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        MouseArea {
                            id: k1m
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.insertSearchKey(charKey)
                        }
                    }
                }
            }

            // Row 2: 9 Keys (Letters) or 10 Keys (Symbols)
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
                        width: searchKbKeysArea.keyW
                        height: searchKbKeysArea.keyH
                        color: k2m.pressed ? "#224A73" : (k2m.containsMouse ? "#2C3E55" : "#1F2E42")
                        border.color: k2m.pressed ? "#80D8FF" : (k2m.containsMouse ? "#4D76A5" : "#354A63")
                        border.width: 1
                        radius: 4
                        scale: k2m.pressed ? 0.90 : 1.0
                        Behavior on scale { NumberAnimation { duration: 70 } }

                        readonly property string charKey: (!root.isSymbolMode && (root.isKeyboardShift || root.isCapsLock)) ? modelData.toUpperCase() : modelData

                        Text {
                            anchors.centerIn: parent
                            text: charKey
                            color: "#FFFFFF"
                            font.pixelSize: root.isSymbolMode ? 22 : 24
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        MouseArea {
                            id: k2m
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.insertSearchKey(charKey)
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
                        width: searchKbKeysArea.keyW
                        height: searchKbKeysArea.keyH
                        color: k3m.pressed ? "#224A73" : (k3m.containsMouse ? "#2C3E55" : "#1F2E42")
                        border.color: k3m.pressed ? "#80D8FF" : (k3m.containsMouse ? "#4D76A5" : "#354A63")
                        border.width: 1
                        radius: 4
                        scale: k3m.pressed ? 0.90 : 1.0
                        Behavior on scale { NumberAnimation { duration: 70 } }

                        readonly property string charKey: (!root.isSymbolMode && (root.isKeyboardShift || root.isCapsLock)) ? modelData.toUpperCase() : modelData

                        Text {
                            anchors.centerIn: parent
                            text: charKey
                            color: "#FFFFFF"
                            font.pixelSize: root.isSymbolMode ? 22 : 24
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        MouseArea {
                            id: k3m
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.insertSearchKey(charKey)
                        }
                    }
                }

                // Backspace Key [⌫] (Spans remaining width)
                Rectangle {
                    width: searchKbKeysArea.keyW * 3 + 16
                    height: searchKbKeysArea.keyH
                    color: bsm.pressed ? "#224A73" : (bsm.containsMouse ? "#2C3E55" : "#1F2E42")
                    border.color: bsm.pressed ? "#80D8FF" : (bsm.containsMouse ? "#4D76A5" : "#354A63")
                    border.width: 1
                    radius: 4
                    scale: bsm.pressed ? 0.92 : 1.0
                    Behavior on scale { NumberAnimation { duration: 70 } }

                    Text {
                        anchors.centerIn: parent
                        text: "⌫"
                        color: "#FFFFFF"
                        font.pixelSize: 28
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: bsm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: {
                            root.deleteSearchKey()
                            bsKbInitialDelayTimer.start()
                        }
                        onReleased: {
                            bsKbInitialDelayTimer.stop()
                            bsKbRepeatTimer.stop()
                        }
                        onCanceled: {
                            bsKbInitialDelayTimer.stop()
                            bsKbRepeatTimer.stop()
                        }
                    }
                }
            }

            // Row 4: Shift | 123# | Spacebar | Clear | OK (Hide)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                // Shift
                Rectangle {
                    width: searchKbKeysArea.keyW
                    height: searchKbKeysArea.keyH
                    color: (!root.isSymbolMode && (root.isKeyboardShift || root.isCapsLock)) ? "#3CA9F8" : (shiftm.pressed ? "#224A73" : "#1F2E42")
                    border.color: (!root.isSymbolMode && (root.isKeyboardShift || root.isCapsLock)) ? "#80D8FF" : "#354A63"
                    border.width: 1
                    radius: 4
                    scale: shiftm.pressed ? 0.90 : 1.0

                    Text {
                        anchors.centerIn: parent
                        text: root.isSymbolMode ? "ABC" : (root.isCapsLock ? "⇪" : "⇧")
                        color: "#FFFFFF"
                        font.pixelSize: root.isSymbolMode ? 18 : 24
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: shiftm
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

                // 123# / #+=
                Rectangle {
                    width: searchKbKeysArea.keyW * 1.3
                    height: searchKbKeysArea.keyH
                    color: symm.pressed ? "#224A73" : "#1F2E42"
                    border.color: symm.pressed ? "#80D8FF" : "#354A63"
                    border.width: 1
                    radius: 4
                    scale: symm.pressed ? 0.90 : 1.0

                    Text {
                        anchors.centerIn: parent
                        text: !root.isSymbolMode ? "123#" : (!root.isSymbolPage2 ? "#+=" : "123#")
                        color: "#FFFFFF"
                        font.pixelSize: 19
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: symm
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

                // Spacebar
                Rectangle {
                    width: searchKbKeysArea.keyW * 4.5 + 24
                    height: searchKbKeysArea.keyH
                    color: spm.pressed ? "#224A73" : "#1F2E42"
                    border.color: spm.pressed ? "#80D8FF" : "#354A63"
                    border.width: 1
                    radius: 4
                    scale: spm.pressed ? 0.96 : 1.0

                    Rectangle {
                        anchors.centerIn: parent
                        width: 68
                        height: 3
                        radius: 1.5
                        color: spm.pressed ? "#80D8FF" : "#8E9EAF"
                    }

                    MouseArea {
                        id: spm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.insertSearchKey(" ")
                    }
                }

                // Clear [✕]
                Rectangle {
                    width: searchKbKeysArea.keyW * 1.2
                    height: searchKbKeysArea.keyH
                    color: clrm.pressed ? "#7F1D1D" : "#3F1D24"
                    border.color: clrm.pressed ? "#EF4444" : "#7F1D1D"
                    border.width: 1
                    radius: 4
                    scale: clrm.pressed ? 0.90 : 1.0

                    Text {
                        anchors.centerIn: parent
                        text: "Clear"
                        color: "#FCA5A5"
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: clrm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clearSearchInput()
                    }
                }

                // Hide / Done [Hide ▾]
                Rectangle {
                    width: searchKbKeysArea.keyW * 2.0
                    height: searchKbKeysArea.keyH
                    color: okm.pressed ? "#16549E" : (okm.containsMouse ? "#3190F0" : "#247CDB")
                    border.color: okm.pressed ? "#FFFFFF" : "#5AA7FA"
                    border.width: 1
                    radius: 4
                    scale: okm.pressed ? 0.92 : 1.0

                    Text {
                        anchors.centerIn: parent
                        text: "Hide ▾"
                        color: "#FFFFFF"
                        font.pixelSize: 20
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: okm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.isSearchKeyboardOpen = false
                    }
                }
            }
        }
    }
}
