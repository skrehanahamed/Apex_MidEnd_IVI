/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: EditWidgetScreen.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#05070B"

    signal backClicked()

    readonly property string currentSide: systemController.editingWidgetSide
    readonly property string selectedWidgetForThisSide: (currentSide === "right") ? systemController.rightWidget : systemController.leftWidget
    readonly property string otherSideWidget: (currentSide === "right") ? systemController.leftWidget : systemController.rightWidget

    property bool showSwitchDialog: false
    property string pendingWidget: ""

    function resetToDefault() {
        showSwitchDialog = false
        pendingWidget = ""
    }

    function handleWidgetSelection(widgetType) {
        if (otherSideWidget === widgetType) {
            // Widget is already placed on the other side -> Prompt confirmation dialog
            console.log("[EditWidget] Selected widget is on other side -> Showing switch confirmation dialog")
            pendingWidget = widgetType
            showSwitchDialog = true
        } else {
            // Widget is not on the other side -> Apply change and return directly to Home screen
            console.log("[EditWidget] Applying widget", widgetType, "and returning to Home")
            systemController.selectWidgetForSide(currentSide, widgetType)
            systemController.navigateTo("home")
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ====================================================
        // 1. SUB-HEADER BAR ("Edit right widget" + Default + Back)
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

                // Left: Gear icon + "Edit right widget"
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
                        text: root.currentSide === "right" ? "Edit right widget" : "Edit left widget"
                        color: "#FFFFFF"
                        font.pixelSize: 24
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }
                }

                Item { Layout.fillWidth: true }

                // Right 2 Blue Action Buttons: Default | Back (⮌)
                Row {
                    spacing: 12
                    Layout.alignment: Qt.AlignVCenter

                    // 1. Default Button
                    Rectangle {
                        width: 100
                        height: 40
                        color: defMouse.pressed ? "#389BFF" : (defMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: defMouse.pressed ? "#80D8FF" : "#3F74A3"
                        border.width: 1
                        radius: 3

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Default"
                            color: "#FFFFFF"
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                            scale: defMouse.pressed ? 0.94 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: defMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[EditWidget] Default clicked -> Resetting widgets and returning to Home")
                                systemController.resetWidgetsToDefault()
                                systemController.navigateTo("home")
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
                                console.log("[EditWidget] Back clicked -> Returning to Home")
                                root.backClicked()
                            }
                        }
                    }
                }
            }
        }

        // ====================================================
        // 2. MAIN CONTENT AREA (Subtitle + 3 Widget Selection Cards)
        // ====================================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Subtitle: "Select a widget for right side."
            Text {
                id: subtitleText
                anchors.top: parent.top
                anchors.topMargin: 24
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.currentSide === "right" ? "Select a widget for right side." : "Select a widget for left side."
                color: "#E2EDF8"
                font.pixelSize: 24
                font.weight: Font.Medium
                font.family: "Roboto"
            }

            // 3 Horizontal Widget Cards
            Row {
                anchors.top: subtitleText.bottom
                anchors.topMargin: 36
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 28

                // --------------------------------------------
                // CARD 1: Radio/Media
                // --------------------------------------------
                Rectangle {
                    width: 330
                    height: 250
                    radius: 4
                    color: radioCardMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.15) : (radioCardMouse.containsMouse ? "#0E1420" : "#080B10")
                    border.color: (root.selectedWidgetForThisSide === "radio_media") ? "#389BFF" : "#1A2230"
                    border.width: (root.selectedWidgetForThisSide === "radio_media") ? 2.0 : 1.0

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    // Card Title
                    Text {
                        anchors.top: parent.top
                        anchors.topMargin: 22
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Radio/Media"
                        color: "#FFFFFF"
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }

                    // Center Graphic: Radio + Sound waves note
                    Image {
                        anchors.centerIn: parent
                        width: 140
                        height: 72
                        source: "qrc:/assets/ui/icon_widget_radiomedia.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        scale: radioCardMouse.pressed ? 0.95 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }
                    }

                    // Bottom Label if active on other side
                    Text {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 18
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.currentSide === "right" ? "Left widget" : "Right widget"
                        color: "#38B6FF"
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                        visible: root.otherSideWidget === "radio_media"
                    }

                    MouseArea {
                        id: radioCardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.handleWidgetSelection("radio_media")
                    }
                }

                // --------------------------------------------
                // CARD 2: Phone projection
                // --------------------------------------------
                Rectangle {
                    width: 330
                    height: 250
                    radius: 4
                    color: projCardMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.15) : (projCardMouse.containsMouse ? "#0E1420" : "#080B10")
                    border.color: (root.selectedWidgetForThisSide === "phone_projection") ? "#389BFF" : "#1A2230"
                    border.width: (root.selectedWidgetForThisSide === "phone_projection") ? 2.0 : 1.0

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    // Card Title
                    Text {
                        anchors.top: parent.top
                        anchors.topMargin: 22
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Phone projection"
                        color: "#FFFFFF"
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }

                    // Center Graphic: Phone with USB + Car
                    Image {
                        anchors.centerIn: parent
                        width: 76
                        height: 76
                        source: "qrc:/assets/apps/icon_all_projection.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        scale: projCardMouse.pressed ? 0.95 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }
                    }

                    // Bottom Label if active on other side
                    Text {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 18
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.currentSide === "right" ? "Left widget" : "Right widget"
                        color: "#38B6FF"
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                        visible: root.otherSideWidget === "phone_projection"
                    }

                    MouseArea {
                        id: projCardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.handleWidgetSelection("phone_projection")
                    }
                }

                // --------------------------------------------
                // CARD 3: Clock
                // --------------------------------------------
                Rectangle {
                    width: 330
                    height: 250
                    radius: 4
                    color: clockCardMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.15) : (clockCardMouse.containsMouse ? "#0E1420" : "#080B10")
                    border.color: (root.selectedWidgetForThisSide === "clock") ? "#389BFF" : "#1A2230"
                    border.width: (root.selectedWidgetForThisSide === "clock") ? 2.0 : 1.0

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    // Card Title
                    Text {
                        anchors.top: parent.top
                        anchors.topMargin: 22
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Clock"
                        color: "#FFFFFF"
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }

                    // Center Graphic: Big Digital Automotive Clock
                    Text {
                        anchors.centerIn: parent
                        text: systemController.currentTime
                        color: "#FFFFFF"
                        font.pixelSize: 56
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                        scale: clockCardMouse.pressed ? 0.95 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }
                    }

                    // Bottom Label if active on other side
                    Text {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 18
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.currentSide === "right" ? "Left widget" : "Right widget"
                        color: "#38B6FF"
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                        visible: root.otherSideWidget === "clock"
                    }

                    MouseArea {
                        id: clockCardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.handleWidgetSelection("clock")
                    }
                }
            }
        }
    }

    // ====================================================
    // 3. CONFIRMATION POPUP MODAL (When selecting the other side's widget)
    // ====================================================
    Rectangle {
        id: switchDialogOverlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.68)
        visible: root.showSwitchDialog
        z: 100

        // Block touch events to background
        MouseArea {
            anchors.fill: parent
            onClicked: {} // consume click
        }

        Rectangle {
            id: dialogBox
            anchors.centerIn: parent
            width: 780
            height: 330
            color: "#121824"
            border.color: "#2C394C"
            border.width: 1.5
            radius: 4

            Column {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 20

                // Question Mark Blue Badge
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 56
                    height: 56
                    radius: 28
                    color: "#3CA9F8"

                    Text {
                        anchors.centerIn: parent
                        text: "?"
                        color: "#FFFFFF"
                        font.pixelSize: 34
                        font.weight: Font.Bold
                        font.family: "Roboto"
                    }
                }

                // Question Text
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 40
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    lineHeight: 1.25
                    text: "Do you want to switch the current widget to the\nother side of the Home screen?"
                    color: "#FFFFFF"
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                }

                Item { width: 1; height: 4 }

                // Yes / No Action Buttons
                RowLayout {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 16
                    height: 58
                    spacing: 16

                    // YES Button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 3
                        color: yesMouse.pressed ? "#389BFF" : (yesMouse.containsMouse ? "#2A4E74" : "#1D3650")
                        border.color: yesMouse.pressed ? "#80D8FF" : "#325780"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Yes"
                            color: "#FFFFFF"
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                            scale: yesMouse.pressed ? 0.95 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: yesMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[EditWidget] Confirmed switch of widget", root.pendingWidget)
                                systemController.selectWidgetForSide(root.currentSide, root.pendingWidget)
                                root.showSwitchDialog = false
                                systemController.navigateTo("home")
                            }
                        }
                    }

                    // NO Button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 3
                        color: noMouse.pressed ? "#389BFF" : (noMouse.containsMouse ? "#2A4E74" : "#1D3650")
                        border.color: noMouse.pressed ? "#80D8FF" : "#325780"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "No"
                            color: "#FFFFFF"
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                            scale: noMouse.pressed ? 0.95 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: noMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[EditWidget] Cancelled switch dialog")
                                root.showSwitchDialog = false
                            }
                        }
                    }
                }
            }
        }
    }
}
