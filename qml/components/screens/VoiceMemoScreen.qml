/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: VoiceMemoScreen.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#05070B"

    signal backClicked()
    signal manualClicked()

    property bool menuOpen: false
    property string currentView: "main" // "main" | "delete" | "memory"
    property bool isDeleteMode: (currentView === "delete")
    property var deleteSelection: []
    property bool showSavedModal: false
    property int selectedMemoIndex: (systemController.voiceMemoList.length > 0) ? 0 : -1
    property var currentMemo: (selectedMemoIndex >= 0 && selectedMemoIndex < systemController.voiceMemoList.length)
                              ? systemController.voiceMemoList[selectedMemoIndex]
                              : null

    function getNextMemoTitle() {
        var num = systemController.voiceMemoList.length + 1
        var numStr = num.toString()
        while (numStr.length < 4) numStr = "0" + numStr
        return "VoiceMemo" + numStr
    }

    function resetToDefault() {
        menuOpen = false
        currentView = "main"
        deleteSelection = []
        showSavedModal = false
        if (systemController.voiceMemoList.length > 0 && selectedMemoIndex < 0) {
            selectedMemoIndex = 0
        }
    }

    function isMemoMarked(idx) {
        return deleteSelection.indexOf(idx) !== -1
    }

    function toggleMarkMemo(idx) {
        var arr = deleteSelection.slice()
        var pos = arr.indexOf(idx)
        if (pos === -1) {
            arr.push(idx)
        } else {
            arr.splice(pos, 1)
        }
        deleteSelection = arr
    }

    function markAllMemos() {
        var arr = []
        for (var i = 0; i < systemController.voiceMemoList.length; i++) {
            arr.push(i)
        }
        deleteSelection = arr
    }

    function unmarkAllMemos() {
        deleteSelection = []
    }

    function deleteMarkedMemos() {
        if (deleteSelection.length === 0) return
        systemController.deleteMultipleVoiceMemos(deleteSelection)
        deleteSelection = []
        currentView = "main"
    }

    function formatTime(ms) {
        var totalSec = Math.floor(ms / 1000)
        var m = Math.floor(totalSec / 60)
        var s = totalSec % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    // Connections to SystemController signals
    Connections {
        target: systemController
        function onVoiceRecordingChanged() {
            // When recording stops, show the OEM "Saved" popup modal (Photo 2)
            if (!systemController.isVoiceRecording && systemController.recordingSeconds > 0) {
                root.showSavedModal = true
                savedModalTimer.restart()
                root.selectedMemoIndex = 0
            }
        }
        function onVoiceMemoPlaybackChanged() {
            if (systemController.activeVoiceMemoIndex >= 0) {
                root.selectedMemoIndex = systemController.activeVoiceMemoIndex
            }
        }
        function onVoiceMemoListChanged() {
            if (systemController.voiceMemoList.length > 0) {
                if (root.selectedMemoIndex >= systemController.voiceMemoList.length || root.selectedMemoIndex < 0) {
                    root.selectedMemoIndex = 0
                }
            } else {
                root.selectedMemoIndex = -1
            }
        }
    }

    Timer {
        id: savedModalTimer
        interval: 1600
        repeat: false
        onTriggered: root.showSavedModal = false
    }

    // ====================================================
    // REUSABLE INTERACTIVE DRAGGER: MIC RECORD SENSITIVITY (Default 3)
    // ====================================================
    component MicSensitivityDragger: RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        spacing: 14

        // Sharp, appropriately sized microphone icon
        Item {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 26
            Layout.maximumWidth: 20
            Layout.maximumHeight: 26
            Layout.fillWidth: false
            Layout.fillHeight: false
            Layout.alignment: Qt.AlignVCenter

            Image {
                anchors.centerIn: parent
                width: 18
                height: 24
                source: "qrc:/assets/voicememo/icon_mic_level.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }
        }

        // Draggable Track
        Rectangle {
            id: sensitivityTrack
            Layout.fillWidth: true
            height: 4
            radius: 2
            color: "#182638"

            // Active cyan progress up to the current sensitivity badge
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.max(0, sensitivityBadge.x + (sensitivityBadge.width / 2))
                radius: 2
                color: "#00B4D8"
            }

            // White rectangular badge with level number (Draggable dragger handle)
            Rectangle {
                id: sensitivityBadge
                width: 56
                height: 28
                radius: 3
                color: "#FFFFFF"
                anchors.verticalCenter: parent.verticalCenter

                // Default position is 3 (out of 1 to 5)
                x: {
                    var fraction = (systemController.voiceRecordLevel - 1) / 4.0
                    return fraction * (sensitivityTrack.width - width)
                }

                Text {
                    anchors.centerIn: parent
                    text: systemController.voiceRecordLevel.toString()
                    color: "#0E1826"
                    font.pixelSize: 18
                    font.bold: true
                    font.family: "Roboto"
                }

                MouseArea {
                    id: badgeDragArea
                    anchors.fill: parent
                    anchors.margins: -10
                    cursorShape: Qt.PointingHandCursor
                    drag.target: parent
                    drag.axis: Drag.XAxis
                    drag.minimumX: 0
                    drag.maximumX: sensitivityTrack.width - sensitivityBadge.width
                    onPositionChanged: {
                        if (drag.active && (sensitivityTrack.width - sensitivityBadge.width) > 0) {
                            var pct = parent.x / (sensitivityTrack.width - sensitivityBadge.width)
                            var lvl = Math.round(1 + pct * 4)
                            systemController.setVoiceRecordLevel(lvl)
                        }
                    }
                }
            }

            // Click track to jump sensitivity
            MouseArea {
                anchors.fill: parent
                z: -1
                cursorShape: Qt.PointingHandCursor
                onClicked: function(mouse) {
                    var pct = Math.max(0.0, Math.min(1.0, mouse.x / sensitivityTrack.width))
                    var lvl = Math.round(1 + pct * 4)
                    systemController.setVoiceRecordLevel(lvl)
                }
            }
        }
    }

    // Main Layout Column
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ====================================================
        // 1. SUB-HEADER BAR ("Voice memo" / "Memory" / "Delete voice memos")
        // ====================================================
        Rectangle {
            id: headerBar
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

                // Left: Icon + Title
                Row {
                    spacing: 12
                    Layout.alignment: Qt.AlignVCenter

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        source: "qrc:/assets/voicememo/icon_clipboard_mic.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        visible: (root.currentView === "main")
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (root.currentView === "memory")
                              ? "Memory"
                              : (root.currentView === "delete"
                                 ? "Delete voice memos (" + root.deleteSelection.length + "/" + systemController.voiceMemoList.length + ")"
                                 : "Voice memo")
                        color: "#FFFFFF"
                        font.pixelSize: 22
                        font.bold: true
                        font.family: "Roboto"
                    }
                }

                Item { Layout.fillWidth: true }

                // Right: [ Menu ] and [ Back ] Buttons
                Row {
                    spacing: 10
                    Layout.alignment: Qt.AlignVCenter

                    // Menu Button (only visible on main view)
                    Rectangle {
                        width: 92
                        height: 40
                        visible: (root.currentView === "main")
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

                    // Back Button (⮌)
                    Rectangle {
                        width: 72
                        height: 40
                        color: backMouse.pressed ? "#389BFF" : (backMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: backMouse.pressed ? "#80D8FF" : "#3F74A3"
                        border.width: 1
                        radius: 3

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Image {
                            anchors.centerIn: parent
                            width: 28
                            height: 24
                            source: "qrc:/assets/voicememo/icon_top_right.png"
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
                                if (root.currentView !== "main") {
                                    root.currentView = "main"
                                    root.deleteSelection = []
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
        // 2. BODY CONTENT CONTAINER (With sliding transitions between views)
        // ====================================================
        Item {
            id: bodyContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // ====================================================
            // VIEW A: NORMAL VIEW (Split Body: Left Sidebar + Right Player)
            // ====================================================
            RowLayout {
                id: viewMain
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width
                spacing: 0
                x: (root.currentView === "main") ? 0 : -width
                visible: x > -width

                Behavior on x {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutCubic
                    }
                }

                // ----------------------------------------------------
                // A. LEFT PANEL (Recorded Files List / Empty State)
                // ----------------------------------------------------
            Rectangle {
                Layout.preferredWidth: 300
                Layout.fillHeight: true
                color: "#080E18"

                // Vertical Divider Line (as seen in Photo 1 & 3)
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1.5
                    color: Qt.rgba(1, 1, 1, 0.12)
                }

                // Empty State (Matching user's Photo 1 exactly!)
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: systemController.voiceMemoList.length === 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No recorded files\navailable."
                        horizontalAlignment: Text.AlignHCenter
                        color: "#8E9EB0"
                        font.pixelSize: 22
                        font.weight: Font.Normal
                        font.family: "Roboto"
                        lineHeight: 1.25
                    }
                }

                // Populated State (List of Memos - Photo 3 style)
                ListView {
                    id: memoListView
                    anchors.fill: parent
                    anchors.rightMargin: 2
                    anchors.topMargin: 0
                    anchors.bottomMargin: 0
                    clip: true
                    visible: systemController.voiceMemoList.length > 0
                    boundsBehavior: Flickable.StopAtBounds
                    model: systemController.voiceMemoList

                    delegate: Rectangle {
                        id: memoDelegate
                        width: memoListView.width
                        height: 76
                        property bool isCurrentActive: (root.selectedMemoIndex === index)

                        // In Photo 3: Active item has solid mint/cyan background (#D4F0EB) with dark text!
                        color: isCurrentActive ? "#D4F0EB" : (itemMouse.pressed ? Qt.rgba(1, 1, 1, 0.08) : (itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"))

                        Behavior on color { ColorAnimation { duration: 90 } }

                        // Bottom separator hairline for non-active items
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.08)
                            visible: !memoDelegate.isCurrentActive
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 20
                            anchors.rightMargin: 16
                            spacing: 14

                            // Memo Text Lines (Line 1: Timestamp, Line 2: VoiceMemoXXXX)
                            Column {
                                Layout.fillWidth: true
                                spacing: 4

                                // Top Line: Timestamp (e.g. 11:17:10 AM in Photo 3)
                                Text {
                                    text: modelData.timeStr ? modelData.timeStr : (modelData.date ? modelData.date : "11:17:10 AM")
                                    color: memoDelegate.isCurrentActive ? "#152634" : "#FFFFFF"
                                    font.pixelSize: 19
                                    font.weight: Font.DemiBold
                                    font.family: "Roboto"
                                }

                                // Bottom Line: Title (e.g. VoiceMemo0001 in Photo 3)
                                Text {
                                    text: modelData.title
                                    color: memoDelegate.isCurrentActive ? "#2F4A5E" : "#7C92A8"
                                    font.pixelSize: 16
                                    font.family: "Roboto"
                                }
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedMemoIndex = index
                                systemController.playVoiceMemo(index)
                            }
                        }
                    }
                }
            }

            // ----------------------------------------------------
            // B. RIGHT MAIN RECORDER & INFO DISPLAY
            // ----------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#05070B"

                // Top Right Memo Title (as shown in Photo 1 & Photo 3)
                Text {
                    id: topRightTitle
                    anchors.right: parent.right
                    anchors.rightMargin: 36
                    anchors.top: parent.top
                    anchors.topMargin: 20
                    text: systemController.isVoiceRecording
                          ? root.getNextMemoTitle()
                          : (root.currentMemo ? root.currentMemo.title : "")
                    color: "#BAC9D8"
                    font.pixelSize: 20
                    font.weight: Font.Medium
                    font.family: "Roboto"
                    visible: text !== ""
                }

                // ====================================================
                // VIEW 1: RECORDING IN PROGRESS (Photo 1)
                // ====================================================
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 28
                    spacing: 24
                    visible: systemController.isVoiceRecording

                    Item { Layout.fillHeight: true }

                    // Middle-Upper: Boxed clipboard/mic icon + Giant Timer (Photo 1)
                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 40

                        // Framed box with clipboard mic icon
                        Rectangle {
                            width: 140
                            height: 140
                            radius: 4
                            color: "transparent"
                            border.color: "#344B64"
                            border.width: 1.5

                            Image {
                                anchors.centerIn: parent
                                width: 84
                                height: 84
                                source: "qrc:/assets/voicememo/icon_clipboard_mic.png"
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                            }
                        }

                        // Giant Digital Timer (Photo 1 "0:00")
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: systemController.recordingTimeFormatted
                            color: "#FFFFFF"
                            font.pixelSize: 62
                            font.bold: true
                            font.family: "Roboto"
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // ====================================================
                    // INTERACTIVE DRAGGER: MIC RECORD SENSITIVITY (During Recording)
                    // ====================================================
                    MicSensitivityDragger {}

                    // Bottom Action Bar: [ Pause (❚❚) ]  [ Stop (■) ] (Matching Photo 1!)
                    Row {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 68
                        spacing: 16

                        // 1. Pause / Resume Button (Photo 1)
                        Rectangle {
                            width: (parent.width - 16) / 2
                            height: parent.height
                            radius: 4
                            color: pauseRecBtnMouse.pressed ? "#205FA6" : (pauseRecBtnMouse.containsMouse ? "#2C4C70" : "#213854")
                            border.color: pauseRecBtnMouse.pressed ? "#66D9FF" : "#3F5F85"
                            border.width: 1.5

                            Behavior on color { ColorAnimation { duration: 90 } }

                            Image {
                                anchors.centerIn: parent
                                width: 28
                                height: 28
                                source: systemController.isVoiceRecordingPaused ? "qrc:/assets/voicememo/icon_play.png" : "qrc:/assets/voicememo/icon_pause.png"
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                scale: pauseRecBtnMouse.pressed ? 0.9 : 1.0
                                Behavior on scale { NumberAnimation { duration: 80 } }
                            }

                            MouseArea {
                                id: pauseRecBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (systemController.isVoiceRecordingPaused) {
                                        systemController.resumeVoiceRecording()
                                    } else {
                                        systemController.pauseVoiceRecording()
                                    }
                                }
                            }
                        }

                        // 2. Stop Button (Photo 1)
                        Rectangle {
                            width: (parent.width - 16) / 2
                            height: parent.height
                            radius: 4
                            color: stopRecBtnMouse.pressed ? "#205FA6" : (stopRecBtnMouse.containsMouse ? "#2C4C70" : "#213854")
                            border.color: stopRecBtnMouse.pressed ? "#66D9FF" : "#3F5F85"
                            border.width: 1.5

                            Behavior on color { ColorAnimation { duration: 90 } }

                            Image {
                                anchors.centerIn: parent
                                width: 24
                                height: 24
                                source: "qrc:/assets/voicememo/icon_stop_square.png"
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                scale: stopRecBtnMouse.pressed ? 0.9 : 1.0
                                Behavior on scale { NumberAnimation { duration: 80 } }
                            }

                            MouseArea {
                                id: stopRecBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    systemController.stopVoiceRecording()
                                }
                            }
                        }
                    }
                }

                // ====================================================
                // VIEW 2: PLAYBACK STATE (Photo 3)
                // ====================================================
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 28
                    spacing: 20
                    visible: !systemController.isVoiceRecording && systemController.voiceMemoList.length > 0

                    Item { Layout.fillHeight: true }

                    // Center Top: Large Date and Time (Photo 3: "10/02/2024   11:17:10 AM")
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: (root.currentMemo && root.currentMemo.dateTimeFull)
                              ? root.currentMemo.dateTimeFull
                              : "10/02/2024   11:17:10 AM"
                        color: "#FFFFFF"
                        font.pixelSize: 28
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }

                    Item { Layout.fillHeight: true }

                    // Scrubber Bar: 0:00 [===O======] 0:02 (Photo 3)
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                        spacing: 16

                        // Elapsed Time
                        Text {
                            text: systemController.isPlayingVoiceMemo
                                  ? root.formatTime(systemController.voiceMemoPosition)
                                  : "0:00"
                            color: "#FFFFFF"
                            font.pixelSize: 20
                            font.family: "Roboto"
                        }

                        // Progress track with draggable thumb
                        Rectangle {
                            id: scrubTrack
                            Layout.fillWidth: true
                            height: 4
                            radius: 2
                            color: "#2C3E52"

                            // Played cyan progress fill
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: {
                                    var dur = systemController.voiceMemoDuration
                                    if (dur > 0) {
                                        return scrubTrack.width * Math.min(1.0, Math.max(0.0, systemController.voiceMemoPosition / dur))
                                    }
                                    return 0
                                }
                                radius: 2
                                color: "#00BCD4"
                            }

                            // Circular draggable scrubber thumb (as shown in Photo 3)
                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                color: "#FFFFFF"
                                anchors.verticalCenter: parent.verticalCenter
                                x: {
                                    var dur = systemController.voiceMemoDuration
                                    if (dur > 0) {
                                        return scrubTrack.width * Math.min(1.0, Math.max(0.0, systemController.voiceMemoPosition / dur)) - 9
                                    }
                                    return -9
                                }

                                MouseArea {
                                    id: scrubMouse
                                    anchors.fill: parent
                                    anchors.margins: -10
                                    cursorShape: Qt.PointingHandCursor
                                    drag.target: parent
                                    drag.axis: Drag.XAxis
                                    drag.minimumX: -9
                                    drag.maximumX: scrubTrack.width - 9
                                    onPositionChanged: {
                                        if (drag.active && systemController.voiceMemoDuration > 0) {
                                            var pct = (parent.x + 9) / scrubTrack.width
                                            systemController.seekVoiceMemo(pct * systemController.voiceMemoDuration)
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: function(mouse) {
                                    if (systemController.voiceMemoDuration > 0) {
                                        var pct = mouse.x / scrubTrack.width
                                        systemController.seekVoiceMemo(pct * systemController.voiceMemoDuration)
                                    }
                                }
                            }
                        }

                        // Total Duration
                        Text {
                            text: (root.currentMemo && root.currentMemo.duration)
                                  ? root.currentMemo.duration
                                  : "0:02"
                            color: "#FFFFFF"
                            font.pixelSize: 20
                            font.family: "Roboto"
                        }
                    }

                    // Upper Control Row: [ |◀◀ ]  [ ❚❚ / ▶ ]  [ ▶▶| ] (Photo 3)
                    Row {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        spacing: 12

                        // Previous / Rewind Button
                        Rectangle {
                            width: (parent.width - 24) / 3
                            height: parent.height
                            radius: 4
                            color: prevBtnMouse.pressed ? "#205FA6" : (prevBtnMouse.containsMouse ? "#2C4C70" : "#213854")
                            border.color: prevBtnMouse.pressed ? "#66D9FF" : "#3F5F85"
                            border.width: 1.5

                            Behavior on color { ColorAnimation { duration: 90 } }

                            Image {
                                anchors.centerIn: parent
                                width: 28
                                height: 28
                                source: "qrc:/assets/voicememo/icon_prev.png"
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                scale: prevBtnMouse.pressed ? 0.9 : 1.0
                            }

                            MouseArea {
                                id: prevBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: systemController.previousVoiceMemo()
                            }
                        }

                        // Play / Pause Toggle Button
                        Rectangle {
                            width: (parent.width - 24) / 3
                            height: parent.height
                            radius: 4
                            color: playPauseBtnMouse.pressed ? "#205FA6" : (playPauseBtnMouse.containsMouse ? "#2C4C70" : "#213854")
                            border.color: playPauseBtnMouse.pressed ? "#66D9FF" : "#3F5F85"
                            border.width: 1.5

                            Behavior on color { ColorAnimation { duration: 90 } }

                            Image {
                                anchors.centerIn: parent
                                width: 28
                                height: 28
                                source: systemController.isPlayingVoiceMemo ? "qrc:/assets/voicememo/icon_pause.png" : "qrc:/assets/voicememo/icon_play.png"
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                scale: playPauseBtnMouse.pressed ? 0.9 : 1.0
                            }

                            MouseArea {
                                id: playPauseBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (systemController.isPlayingVoiceMemo) {
                                        systemController.pauseVoiceMemo()
                                    } else {
                                        systemController.playVoiceMemo(root.selectedMemoIndex)
                                    }
                                }
                            }
                        }

                        // Next / Fast-forward Button
                        Rectangle {
                            width: (parent.width - 24) / 3
                            height: parent.height
                            radius: 4
                            color: nextBtnMouse.pressed ? "#205FA6" : (nextBtnMouse.containsMouse ? "#2C4C70" : "#213854")
                            border.color: nextBtnMouse.pressed ? "#66D9FF" : "#3F5F85"
                            border.width: 1.5

                            Behavior on color { ColorAnimation { duration: 90 } }

                            Image {
                                anchors.centerIn: parent
                                width: 28
                                height: 28
                                source: "qrc:/assets/voicememo/icon_next.png"
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                scale: nextBtnMouse.pressed ? 0.9 : 1.0
                            }

                            MouseArea {
                                id: nextBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: systemController.nextVoiceMemo()
                            }
                        }
                    }

                    // Interactive sensitivity dragger before recording another memo
                    MicSensitivityDragger {}

                    // Lower Control Row: [ Record (Red Dot) ]  [ Stop (Square) ] (Photo 3)
                    Row {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        spacing: 12

                        // 1. Record Button (Red circle dot)
                        Rectangle {
                            width: (parent.width - 12) / 2
                            height: parent.height
                            radius: 4
                            color: recordAgainBtnMouse.pressed ? "#205FA6" : (recordAgainBtnMouse.containsMouse ? "#2C4C70" : "#213854")
                            border.color: recordAgainBtnMouse.pressed ? "#66D9FF" : "#3F5F85"
                            border.width: 1.5

                            Behavior on color { ColorAnimation { duration: 90 } }

                            Image {
                                anchors.centerIn: parent
                                width: 24
                                height: 24
                                source: "qrc:/assets/voicememo/icon_record_dot.png"
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                scale: recordAgainBtnMouse.pressed ? 0.9 : 1.0
                            }

                            MouseArea {
                                id: recordAgainBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    systemController.startVoiceRecording()
                                }
                            }
                        }

                        // 2. Stop Button (Square)
                        Rectangle {
                            width: (parent.width - 12) / 2
                            height: parent.height
                            radius: 4
                            color: stopPlayBtnMouse.pressed ? "#205FA6" : (stopPlayBtnMouse.containsMouse ? "#2C4C70" : "#213854")
                            border.color: stopPlayBtnMouse.pressed ? "#66D9FF" : "#3F5F85"
                            border.width: 1.5

                            Behavior on color { ColorAnimation { duration: 90 } }

                            Image {
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                source: "qrc:/assets/voicememo/icon_stop_square.png"
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                scale: stopPlayBtnMouse.pressed ? 0.9 : 1.0
                            }

                            MouseArea {
                                id: stopPlayBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    systemController.stopVoiceMemo()
                                }
                            }
                        }
                    }
                }

                // ====================================================
                // VIEW 3: IDLE EMPTY STATE (No recording, No files)
                // ====================================================
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 28
                    spacing: 24
                    visible: !systemController.isVoiceRecording && systemController.voiceMemoList.length === 0

                    Item { Layout.fillHeight: true }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 26

                        Rectangle {
                            width: 120
                            height: 120
                            radius: 4
                            color: "transparent"
                            border.color: "#2C3D52"
                            border.width: 1.5

                            Image {
                                anchors.centerIn: parent
                                width: 72
                                height: 72
                                source: "qrc:/assets/voicememo/icon_clipboard_mic.png"
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                text: "Voice memos are stored in\nthis vehicle system until\ndeleted. Please go to\n“Menu” to delete."
                                color: "#FFFFFF"
                                font.pixelSize: 21
                                font.weight: Font.DemiBold
                                font.family: "Roboto"
                                lineHeight: 1.3
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Interactive sensitivity dragger before recording starts
                    MicSensitivityDragger {}

                    // Bottom Action Bar: [ Record (Red Dot) ]  [ Stop (Square) ]
                    Row {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 68
                        spacing: 16

                        // Record Button
                        Rectangle {
                            width: (parent.width - 16) / 2
                            height: parent.height
                            radius: 4
                            color: idleRecordBtnMouse.pressed ? "#205FA6" : (idleRecordBtnMouse.containsMouse ? "#2C4C70" : "#213854")
                            border.color: idleRecordBtnMouse.pressed ? "#66D9FF" : "#3F5F85"
                            border.width: 1.5

                            Behavior on color { ColorAnimation { duration: 90 } }

                            Image {
                                anchors.centerIn: parent
                                width: 28
                                height: 28
                                source: "qrc:/assets/voicememo/icon_record_dot.png"
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                scale: idleRecordBtnMouse.pressed ? 0.9 : 1.0
                            }

                            MouseArea {
                                id: idleRecordBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: systemController.startVoiceRecording()
                            }
                        }

                        // Stop Button (disabled in idle)
                        Rectangle {
                            width: (parent.width - 16) / 2
                            height: parent.height
                            radius: 4
                            color: "#182638"
                            border.color: "#2C3E54"
                            border.width: 1.5

                            Image {
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                source: "qrc:/assets/voicememo/icon_stop_square.png"
                                fillMode: Image.PreserveAspectFit
                                opacity: 0.4
                            }
                        }
                    }
                }
            }
        }

            // ====================================================
            // VIEW B: DELETE VOICE MEMOS (Exact Match to Bluetooth Delete UI!)
            // ====================================================
            Item {
                id: viewDelete
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width
                x: (root.currentView === "delete") ? 0 : width
                visible: x < width

                Behavior on x {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutCubic
                    }
                }

            // Voice Memo List with Checkboxes (matching Bluetooth Delete View)
            ListView {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: deleteActionBar.top
                clip: true
                model: systemController.voiceMemoList

                delegate: Rectangle {
                    width: parent ? parent.width : 0
                    height: 76
                    color: devRowMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.15) : (devRowMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.06) : "transparent")

                    readonly property int memoIndex: index
                    readonly property var memoData: modelData
                    readonly property bool isChecked: root.isMemoMarked(memoIndex)

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

                        // Memo Title and Timestamp
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                text: memoData.title || "Voice Memo"
                                color: "#3CA9F8"
                                font.pixelSize: 22
                                font.weight: Font.DemiBold
                                font.family: "Roboto"
                            }

                            Text {
                                text: (memoData.timeStr || memoData.date || "") + "   •   " + (memoData.duration || "")
                                color: "#8E9EAF"
                                font.pixelSize: 16
                                font.family: "Roboto"
                            }
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
                        onClicked: root.toggleMarkMemo(memoIndex)
                    }
                }
            }

            // Empty state if no memos to delete
            Column {
                anchors.centerIn: parent
                spacing: 16
                visible: systemController.voiceMemoList.length === 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No voice memos to delete"
                    color: "#8E9EAF"
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                }
            }

            // Bottom Action Bar: [ Mark all ] [ Unmark all ] [ Delete ] (Identical to Bluetooth!)
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
                            onClicked: root.markAllMemos()
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
                            onClicked: root.unmarkAllMemos()
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
                            onClicked: root.deleteMarkedMemos()
                        }
                    }
                }
            }
        }

            // ====================================================
            // VIEW C: MEMORY VIEW (Storage info -> Exact Memory View from Settings!)
            // ====================================================
            Rectangle {
                id: viewMemory
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width
                color: "#05070B"
                x: (root.currentView === "memory") ? 0 : width
                visible: x < width

                Behavior on x {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutCubic
                    }
                }

            Column {
                anchors.top: parent.top
                anchors.topMargin: 40
                anchors.left: parent.left
                anchors.leftMargin: 48
                anchors.right: parent.right
                anchors.rightMargin: 48
                spacing: 32

                // Row 1: Capacity 128 MB
                Row {
                    spacing: 28
                    Text {
                        text: "Capacity"
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
                            text: "Memory for voice memos"
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
                            text: "Available"
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

                // Storage Gauge Bar (Photo 3 from settings)
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
    // 3. POPUP MODAL: "Saved" Notification (Photo 2)
    // ====================================================
    Rectangle {
        id: savedNotificationModal
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
        visible: root.showSavedModal
        z: 98

        MouseArea {
            anchors.fill: parent
            onClicked: root.showSavedModal = false
        }

        // Card matching Photo 2: wide modal with light-blue/cyan border
        Rectangle {
            anchors.centerIn: parent
            width: 720
            height: 240
            radius: 4
            color: "#162334"
            border.color: "#7AC5EE"
            border.width: 2

            Column {
                anchors.centerIn: parent
                spacing: 16

                // Circular Info Badge (Cyan circle with 'i' in center)
                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 68
                    height: 68
                    source: "qrc:/assets/voicememo/icon_info.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                // "Saved" Text (Photo 2)
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Saved"
                    color: "#FFFFFF"
                    font.pixelSize: 26
                    font.bold: true
                    font.family: "Roboto"
                }
            }
        }
    }

    // ====================================================
    // 4. OEM CONTEXT MENU DROPDOWN (Delete | Storage info | Manual)
    // ====================================================
    MouseArea {
        anchors.fill: parent
        z: 90
        visible: root.menuOpen
        onClicked: root.menuOpen = false
    }

    Rectangle {
        id: menuDropdown
        z: 100
        visible: root.menuOpen
        anchors.right: parent.right
        anchors.rightMargin: 80
        anchors.top: parent.top
        anchors.topMargin: 56
        width: 300
        height: 3 * 54
        color: "#F8FAFC"
        border.color: "#94A3B8"
        border.width: 1
        radius: 4

        // Soft drop shadow matching RadioScreen and other screens
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: 6
            color: Qt.rgba(0, 0, 0, 0.35)
            z: -1
        }

        Column {
            anchors.fill: parent

            // 1. Delete
            Rectangle {
                width: parent.width
                height: 53
                color: itemMouse1.pressed ? "#CBD5E1" : (itemMouse1.containsMouse ? "#E2E8F0" : "transparent")
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Delete"
                    color: (systemController.voiceMemoList.length === 0) ? "#94A3B8" : "#0F172A"
                    font.pixelSize: 20
                    font.weight: Font.Normal
                    font.family: "Roboto"
                }
                MouseArea {
                    id: itemMouse1
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: systemController.voiceMemoList.length > 0
                    onClicked: {
                        root.menuOpen = false
                        root.deleteSelection = []
                        root.currentView = "delete"
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#E2E8F0" }

            // 2. Storage info (Opens the Memory view from Settings!)
            Rectangle {
                width: parent.width
                height: 53
                color: itemMouse2.pressed ? "#CBD5E1" : (itemMouse2.containsMouse ? "#E2E8F0" : "transparent")
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Storage info"
                    color: "#0F172A"
                    font.pixelSize: 20
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
                        root.currentView = "memory"
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#E2E8F0" }

            // 3. Manual
            Rectangle {
                width: parent.width
                height: 53
                color: itemMouse3.pressed ? "#CBD5E1" : (itemMouse3.containsMouse ? "#E2E8F0" : "transparent")
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Manual"
                    color: "#0F172A"
                    font.pixelSize: 20
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
                        root.manualClicked()
                    }
                }
            }
        }
    }
}
