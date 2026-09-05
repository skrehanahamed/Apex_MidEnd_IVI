/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: HomeScreen.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    signal radioClicked()
    signal projectionClicked()

    property bool leftHoldTriggered: false
    property bool rightHoldTriggered: false

    Timer {
        id: leftHoldTimer
        interval: 1500
        repeat: false
        onTriggered: {
            root.leftHoldTriggered = true
            console.log("[HomeScreen] Held left widget for 1.5s -> Opening Edit left widget")
            systemController.openWidgetEditor("left")
        }
    }

    Timer {
        id: rightHoldTimer
        interval: 1500
        repeat: false
        onTriggered: {
            root.rightHoldTriggered = true
            console.log("[HomeScreen] Held right widget for 1.5s -> Opening Edit right widget")
            systemController.openWidgetEditor("right")
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ==========================================
        // LEFT CARD
        // ==========================================
        Rectangle {
            id: leftCard
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: leftMouse.pressed ? "#0B0E14" : "#05070B"

            Behavior on color { ColorAnimation { duration: 100 } }

            // 1. Clock Widget (Active in user's photo!)
            Column {
                anchors.centerIn: parent
                spacing: 28
                visible: systemController.leftWidget === "clock"

                // Time + AM/PM
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Text {
                        id: leftClockText
                        anchors.verticalCenter: parent.verticalCenter
                        text: systemController.currentTime
                        color: "#FFFFFF"
                        font.pixelSize: 84
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }

                    Text {
                        anchors.bottom: leftClockText.bottom
                        anchors.bottomMargin: 14
                        text: systemController.currentAmPm
                        color: "#FFFFFF"
                        font.pixelSize: 26
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }
                }

                // Full Date: "Saturday, 22-02-2025"
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: systemController.fullDate
                    color: "#C2D2E4"
                    font.pixelSize: 28
                    font.weight: Font.Normal
                    font.family: "Roboto"
                }
            }

            // 2. Radio/Media Widget (Matching authentic D-Audio screen)
            RadioMediaCardView {
                id: leftRadioCard
                side: "left"
                visible: systemController.leftWidget === "radio_media"
                onRadioClicked: root.radioClicked()
                z: 10
            }

            // 3. Phone Projection Widget (if set on left)
            Column {
                anchors.centerIn: parent
                spacing: 28
                width: parent.width * 0.92
                visible: systemController.leftWidget === "phone_projection"

                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 420
                    height: 155
                    source: "qrc:/assets/ui/phone_projection.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.3
                    text: "Connect a phone projection device via USB.\nTo change the default connection, press this widget\nand edit the settings."
                    color: "#FFFFFF"
                    font.pixelSize: 21
                    font.weight: Font.Normal
                    font.family: "Roboto"
                }
            }

            // Subtle press border / glow
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: "#389BFF"
                border.width: (leftMouse.pressed || (leftRadioCard.visible && leftRadioCard.bodyPressed)) ? 2 : 0
                opacity: (leftMouse.pressed || (leftRadioCard.visible && leftRadioCard.bodyPressed)) ? 0.6 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            // Sleek hold progress bar at bottom
            Rectangle {
                id: leftHoldProgress
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                height: 3
                color: "#389BFF"
                width: 0
                visible: leftMouse.pressed || (leftRadioCard.visible && leftRadioCard.bodyPressed)

                NumberAnimation on width {
                    id: leftHoldProgressAnim
                    running: false
                    from: 0
                    to: leftCard.width
                    duration: 1500
                    easing.type: Easing.Linear
                }
            }

            MouseArea {
                id: leftMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                preventStealing: true
                enabled: systemController.leftWidget !== "radio_media"

                onPressed: {
                    root.leftHoldTriggered = false
                    leftHoldProgress.width = 0
                    leftHoldProgressAnim.restart()
                    leftHoldTimer.restart()
                }

                onReleased: {
                    leftHoldTimer.stop()
                    leftHoldProgressAnim.stop()
                    leftHoldProgress.width = 0
                    if (!root.leftHoldTriggered) {
                        if (systemController.leftWidget === "radio_media") {
                            root.radioClicked()
                        } else if (systemController.leftWidget === "phone_projection") {
                            systemController.triggerProjection()
                            root.projectionClicked()
                        }
                    }
                }

                onCanceled: {
                    leftHoldTimer.stop()
                    leftHoldProgressAnim.stop()
                    leftHoldProgress.width = 0
                }
            }
        }

        // ==========================================
        // VERTICAL DIVIDER
        // ==========================================
        Rectangle {
            Layout.preferredWidth: 1.5
            Layout.fillHeight: true
            color: "#1E222D"
        }

        // ==========================================
        // RIGHT CARD
        // ==========================================
        Rectangle {
            id: rightCard
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: rightMouse.pressed ? "#0B0E14" : "#05070B"

            Behavior on color { ColorAnimation { duration: 100 } }

            // 1. Phone Projection Widget
            Column {
                anchors.centerIn: parent
                spacing: 28
                width: parent.width * 0.92
                visible: systemController.rightWidget === "phone_projection"

                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 420
                    height: 155
                    source: "qrc:/assets/ui/phone_projection.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.3
                    text: "Connect a phone projection device via USB.\nTo change the default connection, press this widget\nand edit the settings."
                    color: "#FFFFFF"
                    font.pixelSize: 21
                    font.weight: Font.Normal
                    font.family: "Roboto"
                }
            }

            // 2. Clock Widget (if set on right)
            Column {
                anchors.centerIn: parent
                spacing: 28
                visible: systemController.rightWidget === "clock"

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Text {
                        id: rightClockText
                        anchors.verticalCenter: parent.verticalCenter
                        text: systemController.currentTime
                        color: "#FFFFFF"
                        font.pixelSize: 84
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }

                    Text {
                        anchors.bottom: rightClockText.bottom
                        anchors.bottomMargin: 14
                        text: systemController.currentAmPm
                        color: "#FFFFFF"
                        font.pixelSize: 26
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: systemController.fullDate
                    color: "#C2D2E4"
                    font.pixelSize: 28
                    font.weight: Font.Normal
                    font.family: "Roboto"
                }
            }

            // 3. Radio/Media Widget (if set on right)
            RadioMediaCardView {
                id: rightRadioCard
                side: "right"
                visible: systemController.rightWidget === "radio_media"
                onRadioClicked: root.radioClicked()
                z: 10
            }

            // Subtle press border / glow
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: "#389BFF"
                border.width: (rightMouse.pressed || (rightRadioCard.visible && rightRadioCard.bodyPressed)) ? 2 : 0
                opacity: (rightMouse.pressed || (rightRadioCard.visible && rightRadioCard.bodyPressed)) ? 0.6 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            // Sleek hold progress bar at bottom
            Rectangle {
                id: rightHoldProgress
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                height: 3
                color: "#389BFF"
                width: 0
                visible: rightMouse.pressed || (rightRadioCard.visible && rightRadioCard.bodyPressed)

                NumberAnimation on width {
                    id: rightHoldProgressAnim
                    running: false
                    from: 0
                    to: rightCard.width
                    duration: 1500
                    easing.type: Easing.Linear
                }
            }

            MouseArea {
                id: rightMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                preventStealing: true
                enabled: systemController.rightWidget !== "radio_media"

                onPressed: {
                    root.rightHoldTriggered = false
                    rightHoldProgress.width = 0
                    rightHoldProgressAnim.restart()
                    rightHoldTimer.restart()
                }

                onReleased: {
                    rightHoldTimer.stop()
                    rightHoldProgressAnim.stop()
                    rightHoldProgress.width = 0
                    if (!root.rightHoldTriggered) {
                        if (systemController.rightWidget === "phone_projection") {
                            systemController.triggerProjection()
                            root.projectionClicked()
                        } else if (systemController.rightWidget === "radio_media") {
                            root.radioClicked()
                        }
                    }
                }

                onCanceled: {
                    rightHoldTimer.stop()
                    rightHoldProgressAnim.stop()
                    rightHoldProgress.width = 0
                }
            }
        }
    }

    // ====================================================
    // REUSABLE RADIO/MEDIA CARD (Matching Authentic D-Audio IVI Interface)
    // ====================================================
    component RadioMediaCardView: Item {
        id: cardViewRoot
        anchors.fill: parent
        property string side: "left"
        property bool bodyPressed: cardBodyMouse.pressed
        signal radioClicked()

        // Card body tap area: covers the card EXCEPT the bottom presetRow buttons
        MouseArea {
            id: cardBodyMouse
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: (systemController.selectedMediaSource === "fm" || systemController.selectedMediaSource === "am") ? 96 : 0
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            preventStealing: true

            onPressed: {
                if (cardViewRoot.side === "left") {
                    root.leftHoldTriggered = false
                    leftHoldProgress.width = 0
                    leftHoldProgressAnim.restart()
                    leftHoldTimer.restart()
                } else {
                    root.rightHoldTriggered = false
                    rightHoldProgress.width = 0
                    rightHoldProgressAnim.restart()
                    rightHoldTimer.restart()
                }
            }

            onReleased: {
                if (cardViewRoot.side === "left") {
                    leftHoldTimer.stop()
                    leftHoldProgressAnim.stop()
                    leftHoldProgress.width = 0
                    if (!root.leftHoldTriggered) {
                        cardViewRoot.radioClicked()
                    }
                } else {
                    rightHoldTimer.stop()
                    rightHoldProgressAnim.stop()
                    rightHoldProgress.width = 0
                    if (!root.rightHoldTriggered) {
                        cardViewRoot.radioClicked()
                    }
                }
            }

            onCanceled: {
                if (cardViewRoot.side === "left") {
                    leftHoldTimer.stop()
                    leftHoldProgressAnim.stop()
                    leftHoldProgress.width = 0
                } else {
                    rightHoldTimer.stop()
                    rightHoldProgressAnim.stop()
                    rightHoldProgress.width = 0
                }
            }
        }

        // 1. When Media (FM or AM) is active (running or paused)
        Item {
            anchors.fill: parent
            visible: (systemController.selectedMediaSource === "fm" || systemController.selectedMediaSource === "am")

            // Top: Band Title "FM" or "AM"
            Text {
                id: bandTitleText
                anchors.top: parent.top
                anchors.topMargin: 36
                anchors.horizontalCenter: parent.horizontalCenter
                text: systemController.radioBand
                color: "#38B6FF"
                font.pixelSize: 24
                font.weight: Font.Bold
                font.family: "Roboto"
            }

            // Hairline separator line under FM
            Rectangle {
                id: bandDividerLine
                anchors.top: bandTitleText.bottom
                anchors.topMargin: 16
                anchors.left: parent.left
                anchors.leftMargin: 28
                anchors.right: parent.right
                anchors.rightMargin: 28
                height: 1
                color: "#1E2A38"
            }

            // Middle: Giant Frequency + Station Name
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: bandDividerLine.bottom
                anchors.bottom: presetRow.top
                spacing: 12
                anchors.topMargin: 26

                // Huge frequency digits: "93.5"
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: systemController.radioStation
                    color: "#FFFFFF"
                    font.pixelSize: 84
                    font.weight: Font.Bold
                    font.family: "Roboto"
                }

                // Station RDS name: "SURYAN"
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: systemController.currentStationName
                    color: "#DCE7F5"
                    font.pixelSize: 25
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                }
            }

            // Bottom: Two preset navigation buttons side by side
            Row {
                id: presetRow
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 32
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 18
                z: 20

                // Previous Station Button: [ ◀  FM 91.9 ]
                Rectangle {
                    width: 218
                    height: 54
                    radius: 6
                    color: prevBtnMouse.pressed ? "#284568" : (prevBtnMouse.containsMouse ? "#1E334D" : "#172739")
                    border.color: prevBtnMouse.pressed ? "#4882BA" : "#2E4766"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 90 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 14

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "◀"
                            color: prevBtnMouse.pressed ? "#80D8FF" : "#CBD5E1"
                            font.pixelSize: 18
                            scale: prevBtnMouse.pressed ? 0.9 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            Text {
                                text: systemController.radioBand
                                color: "#38B6FF"
                                font.pixelSize: 22
                                font.weight: Font.Bold
                                font.family: "Roboto"
                            }

                            Text {
                                text: systemController.previousStationFrequency
                                color: "#FFFFFF"
                                font.pixelSize: 22
                                font.weight: Font.DemiBold
                                font.family: "Roboto"
                            }
                        }
                    }

                    MouseArea {
                        id: prevBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: true
                        onClicked: {
                            systemController.tuneFrequency(-1)
                        }
                    }
                }

                // Next Station Button: [ FM 98.3  ▶ ]
                Rectangle {
                    width: 218
                    height: 54
                    radius: 6
                    color: nextBtnMouse.pressed ? "#284568" : (nextBtnMouse.containsMouse ? "#1E334D" : "#172739")
                    border.color: nextBtnMouse.pressed ? "#4882BA" : "#2E4766"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 90 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 14

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            Text {
                                text: systemController.radioBand
                                color: "#38B6FF"
                                font.pixelSize: 22
                                font.weight: Font.Bold
                                font.family: "Roboto"
                            }

                            Text {
                                text: systemController.nextStationFrequency
                                color: "#FFFFFF"
                                font.pixelSize: 22
                                font.weight: Font.DemiBold
                                font.family: "Roboto"
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "▶"
                            color: nextBtnMouse.pressed ? "#80D8FF" : "#CBD5E1"
                            font.pixelSize: 18
                            scale: nextBtnMouse.pressed ? 0.9 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                        }
                    }

                    MouseArea {
                        id: nextBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: true
                        onClicked: {
                            systemController.tuneFrequency(1)
                        }
                    }
                }
            }
        }

        // 2. When Media is USB or Bluetooth
        Item {
            anchors.fill: parent
            visible: (systemController.selectedMediaSource === "usb" || systemController.selectedMediaSource === "bluetooth")

            Text {
                id: mediaTitleText
                anchors.top: parent.top
                anchors.topMargin: 36
                anchors.horizontalCenter: parent.horizontalCenter
                text: (systemController.selectedMediaSource === "usb") ? "USB Music" : "Bluetooth Audio"
                color: "#BAC7D5"
                font.pixelSize: 24
                font.weight: Font.Bold
                font.family: "Roboto"
            }

            Rectangle {
                anchors.top: mediaTitleText.bottom
                anchors.topMargin: 16
                anchors.left: parent.left
                anchors.leftMargin: 28
                anchors.right: parent.right
                anchors.rightMargin: 28
                height: 1
                color: "#1E2A38"
            }

            Column {
                anchors.centerIn: parent
                spacing: 14
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: (systemController.selectedMediaSource === "usb") ? "No USB Device" : (systemController.hasHandsFreeDevice ? systemController.activeHandsFreeDeviceName : "Connected Device")
                    color: "#FFFFFF"
                    font.pixelSize: 32
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: (systemController.selectedMediaSource === "usb") ? "Insert USB to play media" : "Ready for audio playback"
                    color: "#7B92AB"
                    font.pixelSize: 18
                    font.family: "Roboto"
                }
            }
        }

        // 3. When Media is off (no media source)
        Column {
            anchors.centerIn: parent
            spacing: 12
            visible: (systemController.selectedMediaSource === "none")

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Radio/Media Off"
                color: "#FFFFFF"
                font.pixelSize: 38
                font.weight: Font.DemiBold
                font.family: "Roboto"
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Press to select media"
                color: "#7B92AB"
                font.pixelSize: 18
                font.family: "Roboto"
            }
        }
    }
}
