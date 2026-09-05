/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: MediaSelectScreen.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#070C15"

    signal closeClicked()
    signal fmSelected()
    signal amSelected()
    signal bluetoothSelected()
    signal usbSelected()

    property string selectedCard: ""

    function resetToDefault() {
        selectedCard = ""
        navTimer.stop()
    }

    Timer {
        id: navTimer
        interval: 220
        repeat: false
        property string pendingSource: ""
        onTriggered: {
            if (pendingSource === "fm") {
                systemController.selectMediaSource("fm")
                root.fmSelected()
            } else if (pendingSource === "am") {
                systemController.selectMediaSource("am")
                root.amSelected()
            } else if (pendingSource === "bluetooth") {
                systemController.selectMediaSource("bluetooth")
                root.bluetoothSelected()
            } else if (pendingSource === "usb") {
                systemController.selectMediaSource("usb")
                root.usbSelected()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ====================================================
        // 1. MAIN GRID AREA (Matching Genuine Photo 1)
        // ====================================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Background subtle car dashboard gradient
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#0B1424" }
                    GradientStop { position: 0.6; color: "#070D18" }
                    GradientStop { position: 1.0; color: "#050910" }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 36
                width: Math.min(parent.width - 60, 1160)

                // Row 1: FM, Bluetooth Audio, USB Music, Android Auto, Apple CarPlay
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 24

                    // 1. FM (Active / Bright)
                    MediaCard {
                        title: "FM"
                        iconSource: "qrc:/assets/media/icon_media_fm.png"
                        isActive: true
                        isSelected: root.selectedCard === "fm"
                        onClicked: {
                            root.selectedCard = "fm"
                            navTimer.pendingSource = "fm"
                            navTimer.restart()
                        }
                    }

                    // 2. Bluetooth Audio (Active / Bright if connected)
                    MediaCard {
                        title: "Bluetooth\nAudio"
                        iconSource: "qrc:/assets/media/icon_media_bluetooth.png"
                        isActive: systemController.isBluetoothConnected
                        isSelected: root.selectedCard === "bluetooth"
                        onClicked: {
                            root.selectedCard = "bluetooth"
                            navTimer.pendingSource = "bluetooth"
                            navTimer.restart()
                        }
                    }

                    // 3. USB Music (Inactive / Dim unless USB connected)
                    MediaCard {
                        title: "USB Music"
                        iconSource: "qrc:/assets/media/icon_media_usb.png"
                        isActive: systemController.usbConnected
                        isSelected: root.selectedCard === "usb"
                        onClicked: {
                            if (isActive) {
                                root.selectedCard = "usb"
                                navTimer.pendingSource = "usb"
                                navTimer.restart()
                            }
                        }
                    }

                    // 4. Android Auto (Inactive / Dim unless connected)
                    MediaCard {
                        title: "Android Auto"
                        iconSource: "qrc:/assets/media/icon_media_androidauto.png"
                        isActive: systemController.androidAutoEnabled && systemController.phoneConnected
                        isSelected: false
                        onClicked: {
                            if (isActive) systemController.triggerProjection()
                        }
                    }

                    // 5. Apple CarPlay (Inactive / Dim unless connected)
                    MediaCard {
                        title: "Apple CarPlay"
                        iconSource: "qrc:/assets/media/icon_media_carplay.png"
                        isActive: systemController.appleCarPlayEnabled && systemController.phoneConnected
                        isSelected: false
                        onClicked: {
                            if (isActive) systemController.triggerProjection()
                        }
                    }
                }

                // Row 2: AM (Left-aligned under FM)
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: (parent.width - (5 * 200 + 4 * 24)) / 2
                    spacing: 24

                    // 6. AM (Active / Bright)
                    MediaCard {
                        title: "AM"
                        iconSource: "qrc:/assets/media/icon_media_am.png"
                        isActive: true
                        isSelected: root.selectedCard === "am"
                        onClicked: {
                            root.selectedCard = "am"
                            navTimer.pendingSource = "am"
                            navTimer.restart()
                        }
                    }
                }
            }
        }

        // ====================================================
        // 2. BOTTOM "CLOSE" ACTION BAR (Matching Photo 1)
        // ====================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            color: closeMouse.pressed ? "#1565C0" : (closeMouse.containsMouse ? "#2A78D0" : "#246BB5")
            border.color: "#4298EB"
            border.width: 1

            Behavior on color { ColorAnimation { duration: 100 } }

            Text {
                anchors.centerIn: parent
                text: "Close"
                color: "#FFFFFF"
                font.pixelSize: 22
                font.weight: Font.DemiBold
                font.family: "Roboto"
                scale: closeMouse.pressed ? 0.96 : 1.0
                Behavior on scale { NumberAnimation { duration: 80 } }
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    console.log("[MediaSelect] Close clicked")
                    root.closeClicked()
                }
            }
        }
    }

    // ====================================================
    // COMPONENT: MediaCard
    // ====================================================
    component MediaCard: Item {
        id: card
        property string title: ""
        property string iconSource: ""
        property bool isActive: true
        property bool isSelected: false
        signal clicked()

        width: 200
        height: 180

        // Highlight box (when selected as USB in photo 1)
        Rectangle {
            anchors.fill: parent
            radius: 4
            visible: card.isSelected
            color: "#D8F3ED"
            border.color: "#A2DFD0"
            border.width: 1.5
        }

        Column {
            anchors.centerIn: parent
            spacing: 12
            opacity: card.isActive ? 1.0 : 0.22

            Behavior on opacity { NumberAnimation { duration: 150 } }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 96
                height: 96

                Image {
                    anchors.centerIn: parent
                    width: 90
                    height: 90
                    source: card.iconSource
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    scale: cardMouse.pressed ? 0.94 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80 } }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: card.title
                color: card.isSelected ? "#1E7E68" : "#FFFFFF"
                font.pixelSize: 21
                font.weight: Font.DemiBold
                font.family: "Roboto"
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.15
            }
        }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: card.isActive
            cursorShape: card.isActive ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (card.isActive) card.clicked()
            }
        }
    }
}
