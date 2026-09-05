/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: QuietModeScreen.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#070C14"

    signal backClicked()
    signal manualClicked()

    property bool menuOpen: false

    function resetToDefault() {
        menuOpen = false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ====================================================
        // 1. SUB-HEADER BAR ("Quiet mode" + Menu + Back)
        // ====================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            color: "#101622"
            z: 30

            // Hairline bottom divider
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1.5
                color: "#1E2736"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 16
                spacing: 12

                // Left: Moon Icon + Title
                Row {
                    spacing: 12
                    Layout.alignment: Qt.AlignVCenter

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 30
                        height: 30
                        source: "qrc:/assets/ui/icon_quiet_mode.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Quiet mode"
                        color: "#FFFFFF"
                        font.pixelSize: 24
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }
                }

                Item { Layout.fillWidth: true }

                // Right: Action Buttons (Menu | Back)
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
                                root.menuOpen = false
                                root.backClicked()
                            }
                        }
                    }
                }
            }
        }

        // ====================================================
        // 2. MAIN CONTENT AREA (Matching Genuine IVI Photo)
        // ====================================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Background subtle gradient glow
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#0B1424" }
                    GradientStop { position: 0.55; color: "#070D18" }
                    GradientStop { position: 1.0; color: "#050910" }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 30
                width: parent.width

                // 1. Center Moon & Stars Graphic (Matching Genuine Photo)
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 180
                    height: 180

                    // Ambient glow pulse when enabled
                    Rectangle {
                        anchors.centerIn: parent
                        width: 198
                        height: 198
                        radius: 99
                        color: "transparent"
                        border.color: systemController.quietModeEnabled ? "#38B6FF" : "transparent"
                        border.width: 2.5
                        opacity: systemController.quietModeEnabled ? 0.7 : 0.0

                        Behavior on opacity {
                            NumberAnimation { duration: 250 }
                        }

                        SequentialAnimation on scale {
                            running: systemController.quietModeEnabled
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 1.03; duration: 1800; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.03; to: 1.0; duration: 1800; easing.type: Easing.InOutSine }
                        }
                    }

                    Image {
                        anchors.centerIn: parent
                        width: 180
                        height: 180
                        source: "qrc:/assets/apps/icon_all_quietmode.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }
                }

                // 2. Explanatory Text (Exact wording & formatting from photo)
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Sound is provided only to the front seats. Volume is limited to the factory-\nset 'quiet' level."
                    color: "#FFFFFF"
                    font.pixelSize: 22
                    font.weight: Font.Normal
                    font.family: "Roboto"
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.32
                    wrapMode: Text.WordWrap
                    width: Math.min(parent.width - 64, 820)
                }

                // 3. Quiet Mode Toggle Button: [ | Quiet mode ]
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 280
                    height: 54
                    radius: 4
                    color: systemController.quietModeEnabled
                           ? (btnMouse.pressed ? "#1F78CC" : (btnMouse.containsMouse ? "#357CBF" : "#2868A4"))
                           : (btnMouse.pressed ? "#22354A" : (btnMouse.containsMouse ? "#1E3044" : "#162436"))
                    border.color: systemController.quietModeEnabled ? "#4D9CE6" : "#2D425A"
                    border.width: 1.5

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 12

                        // Vertical status indicator pill
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3.5
                            height: 24
                            radius: 1.5
                            color: systemController.quietModeEnabled ? "#00E5FF" : "#566B80"

                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        // Label
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Quiet mode"
                            color: systemController.quietModeEnabled ? "#FFFFFF" : "#A2B6CC"
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                            scale: btnMouse.pressed ? 0.96 : 1.0

                            Behavior on scale { NumberAnimation { duration: 80 } }
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                    }

                    MouseArea {
                        id: btnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            systemController.toggleQuietMode()
                        }
                    }
                }
            }
        }
    }

    // ====================================================
    // 3. DROPDOWN MENU FOR "MENU" BUTTON
    // ====================================================
    MouseArea {
        anchors.fill: parent
        z: 90
        visible: root.menuOpen
        onClicked: root.menuOpen = false
    }

    Rectangle {
        id: quietMenuDropdown
        z: 100
        visible: root.menuOpen
        x: root.width - width - 98
        y: 60
        width: 210
        height: 50
        color: "#EDF2F7"
        border.color: "#A4B8CD"
        border.width: 1
        radius: 4

        // Soft Drop Shadow
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: 6
            color: Qt.rgba(0, 0, 0, 0.25)
            z: -1
        }

        Rectangle {
            anchors.fill: parent
            radius: 4
            color: optManualMouse.pressed ? "#D0E0F0" : (optManualMouse.containsMouse ? "#DEEAF6" : "transparent")

            Behavior on color { ColorAnimation { duration: 100 } }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                text: "Manual"
                color: "#101824"
                font.pixelSize: 18
                font.weight: Font.DemiBold
                font.family: "Roboto"
            }

            MouseArea {
                id: optManualMouse
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
