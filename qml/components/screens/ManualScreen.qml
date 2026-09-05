/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: ManualScreen.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#05080E"

    signal backClicked()
    property string sectionTitle: "Home"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ====================================================
        // 1. SUB-HEADER BAR ("Manual" + Back)
        // ====================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            color: "#111A24"

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1.5
                color: "#1E2836"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 16
                spacing: 12

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
                        text: "Manual"
                        color: "#FFFFFF"
                        font.pixelSize: 24
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }
                }

                Item { Layout.fillWidth: true }

                // Back Button (⮌)
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
                        onClicked: root.backClicked()
                    }
                }
            }
        }

        // ====================================================
        // 2. MAIN CONTENT (Matching Genuine Photo media_1788548873253.png)
        // ====================================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Screen Section Subtitle: "Home"
            Text {
                id: sectionTitleText
                anchors.top: parent.top
                anchors.topMargin: 36
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.sectionTitle
                color: "#FFFFFF"
                font.pixelSize: 28
                font.weight: Font.DemiBold
                font.family: "Roboto"
            }

            // QR + Instruction Text Row (Left-aligned QR matching photo!)
            Row {
                anchors.top: sectionTitleText.bottom
                anchors.topMargin: 34
                anchors.left: parent.left
                anchors.leftMargin: 64
                anchors.right: parent.right
                anchors.rightMargin: 48
                spacing: 38

                // White Card with QR Code
                Rectangle {
                    id: qrCard
                    width: 216
                    height: 216
                    color: "#FFFFFF"
                    radius: 4

                    Image {
                        anchors.centerIn: parent
                        width: 206
                        height: 206
                        source: "qrc:/assets/ui/qr_manual.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }
                }

                // Text Column
                Column {
                    anchors.verticalCenter: qrCard.verticalCenter
                    width: parent.width - qrCard.width - 38
                    spacing: 16

                    Text {
                        width: parent.width
                        text: "Scan with your smartphone's QR reader app."
                        color: "#FFFFFF"
                        font.pixelSize: 24
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent.width
                        text: "When scanning, keep the display bright and avoid glare."
                        color: "#A2B6CC"
                        font.pixelSize: 20
                        font.family: "Roboto"
                        wrapMode: Text.WordWrap
                        lineHeight: 1.25
                    }

                    Row {
                        spacing: 8

                        Text {
                            text: "GitHub:"
                            color: "#94A3B8"
                            font.pixelSize: 19
                            font.family: "Roboto"
                        }

                        Text {
                            text: "https://github.com/skrehanahamed"
                            color: "#38B6FF"
                            font.pixelSize: 19
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }
                    }
                }
            }
        }
    }
}
