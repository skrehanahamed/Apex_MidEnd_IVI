/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: RearrangeSettingsScreen.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#05070B"

    signal backClicked()

    readonly property bool isHindi: (systemController.systemLanguage === "Hindi")
    function tr(en, hi) { return isHindi ? hi : en; }

    // Selected slot for tap-to-swap or drag
    property int selectedSlot: -1
    property int dragSourceIndex: -1
    property int dragTargetIndex: -1
    property bool isDragging: false
    property var currentOrder: systemController.settingsIconsOrder

    // Icon info metadata helper
    function getIconInfo(iconId) {
        switch (iconId) {
            case "sound":
                return {
                    id: "sound",
                    title: root.tr("Sound", "ध्वनि"),
                    icon: "qrc:/assets/apps/icon_sound.png",
                    width: 58,
                    height: 56
                };
            case "device_connection":
                return {
                    id: "device_connection",
                    title: root.tr("Device\nconnection", "डिवाइस\nकनेक्शन"),
                    icon: "qrc:/assets/bluetooth/icon_device_conn.png",
                    width: 76,
                    height: 58
                };
            case "display":
                return {
                    id: "display",
                    title: root.tr("Display", "डिस्प्ले"),
                    icon: "qrc:/assets/ui/icon_display.png",
                    width: 66,
                    height: 58
                };
            case "button":
                return {
                    id: "button",
                    title: root.tr("Button", "बटन"),
                    icon: "qrc:/assets/ui/icon_button.png",
                    width: 58,
                    height: 58
                };
            case "general":
                return {
                    id: "general",
                    title: root.tr("General", "सामान्य"),
                    icon: "qrc:/assets/ui/icon_general.png",
                    width: 66,
                    height: 58
                };
            default:
                return null;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ====================================================
        // 1. SUB-HEADER BAR ("Rearrange settings screen" + Default + Back)
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
                        text: root.tr("Rearrange settings screen", "सेटिंग्स स्क्रीन पुनर्व्यवस्थित करें")
                        color: "#FFFFFF"
                        font.pixelSize: 24
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }
                }

                Item { Layout.fillWidth: true }

                // Right Buttons: [ Default ] and [ Back ]
                Row {
                    spacing: 12
                    Layout.alignment: Qt.AlignVCenter

                    // Default Button
                    Rectangle {
                        width: 110
                        height: 40
                        color: defaultMouse.pressed ? "#1E88E5" : (defaultMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: defaultMouse.pressed ? "#66D9FF" : "#3F74A3"
                        border.width: 1
                        radius: 3

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: root.tr("Default", "डिफ़ॉल्ट")
                            color: "#FFFFFF"
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                            scale: defaultMouse.pressed ? 0.94 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: defaultMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[RearrangeSettings] Reset to Default clicked")
                                systemController.resetSettingsIconsOrder()
                                root.selectedSlot = -1
                            }
                        }
                    }

                    // Back Arrow Button (⮌)
                    Rectangle {
                        width: 70
                        height: 40
                        color: backMouse.pressed ? "#1E88E5" : (backMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: backMouse.pressed ? "#66D9FF" : "#3F74A3"
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
                                root.selectedSlot = -1
                                root.backClicked()
                            }
                        }
                    }
                }
            }
        }

        // ====================================================
        // 2. MAIN CONTENT AREA (Subtitle + Rearrange Frame Box)
        // ====================================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Subtitle matching Image 2
            Text {
                id: subtitleText
                anchors.top: parent.top
                anchors.topMargin: 20
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.tr("Press and hold an item to drag it to another position.", "किसी आइटम को दूसरी स्थिति में खींचने के लिए उसे दबाकर रखें।")
                color: "#CCD8E6"
                font.pixelSize: 20
                font.weight: Font.Normal
                font.family: "Roboto"
            }

            // Framed Box Container (matching Image 2)
            Rectangle {
                id: cardBox
                anchors.top: subtitleText.bottom
                anchors.topMargin: 24
                anchors.horizontalCenter: parent.horizontalCenter
                width: 900
                height: 360
                color: Qt.rgba(0.04, 0.08, 0.14, 0.40)
                border.color: "#6A7B8C"
                border.width: 1.5
                radius: 8

                // Subtle Crosshairs between slots on Row 1
                Repeater {
                    model: 3
                    Text {
                        x: (index + 1) * (cardBox.width / 4) - width / 2
                        y: 80 - height / 2
                        text: "+"
                        color: "#4A6075"
                        font.pixelSize: 20
                        font.weight: Font.Light
                        font.family: "Roboto"
                    }
                }

                // Subtle Crosshairs between slots on Row 2
                Repeater {
                    model: 3
                    Text {
                        x: (index + 1) * (cardBox.width / 4) - width / 2
                        y: 255 - height / 2
                        text: "+"
                        color: "#4A6075"
                        font.pixelSize: 20
                        font.weight: Font.Light
                        font.family: "Roboto"
                    }
                }

                // 8 Slots Grid (2 rows x 4 cols)
                Grid {
                    id: slotsGrid
                    anchors.fill: parent
                    anchors.margins: 10
                    columns: 4
                    rows: 2
                    rowSpacing: 10
                    columnSpacing: 10

                    Repeater {
                        model: 8

                        Rectangle {
                            id: slotItem
                            property int slotIndex: index
                            width: (cardBox.width - 20 - 30) / 4
                            height: (cardBox.height - 20 - 10) / 2
                            radius: 8

                            property bool isTarget: (root.isDragging && root.dragTargetIndex === slotIndex)
                            property bool isSelected: (root.selectedSlot === slotIndex)
                            property string iconId: (slotIndex < systemController.settingsIconsOrder.length) ? systemController.settingsIconsOrder[slotIndex] : ""
                            property var info: root.getIconInfo(iconId)

                            color: isTarget ? Qt.rgba(0.0, 0.72, 1.0, 0.22) : (isSelected ? Qt.rgba(0.0, 0.72, 1.0, 0.14) : (slotMouse.containsMouse && info ? Qt.rgba(1, 1, 1, 0.04) : "transparent"))
                            border.color: isTarget ? "#00E5FF" : (isSelected ? "#389BFF" : (slotMouse.containsMouse && info ? "#2C4054" : "transparent"))
                            border.width: (isTarget || isSelected) ? 2 : 1

                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            // Content of slot (Icon + Title)
                            Column {
                                anchors.centerIn: parent
                                spacing: 12
                                visible: info !== null && (!root.isDragging || root.dragSourceIndex !== slotIndex)
                                scale: (root.selectedSlot === slotIndex) ? 1.05 : (slotMouse.pressed ? 0.94 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 120 } }

                                Item {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: info ? info.width : 58
                                    height: info ? info.height : 58

                                    Image {
                                        anchors.fill: parent
                                        source: info ? info.icon : ""
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        mipmap: true
                                    }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: info ? info.title : ""
                                    color: (root.selectedSlot === slotIndex) ? "#70D6FF" : "#FFFFFF"
                                    font.pixelSize: 20
                                    font.weight: Font.DemiBold
                                    font.family: "Roboto"
                                }
                            }

                            MouseArea {
                                id: slotMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: info ? Qt.PointingHandCursor : (root.isDragging || root.selectedSlot >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor)

                                property real startX: 0
                                property real startY: 0
                                property bool dragTriggered: false

                                onPressed: function(mouse) {
                                    startX = mouse.x
                                    startY = mouse.y
                                    dragTriggered = false
                                }

                                onPositionChanged: function(mouse) {
                                    if (!slotMouse.pressed || !info) return
                                    var dx = mouse.x - startX
                                    var dy = mouse.y - startY

                                    if (!dragTriggered && (Math.abs(dx) > 10 || Math.abs(dy) > 10)) {
                                        dragTriggered = true
                                        root.dragSourceIndex = slotIndex
                                        root.isDragging = true
                                        var pt = mapToItem(root, mouse.x, mouse.y)
                                        dragGhost.x = pt.x - dragGhost.width / 2
                                        dragGhost.y = pt.y - dragGhost.height / 2
                                        dragGhost.info = info
                                    }

                                    if (root.isDragging) {
                                        var ptMove = mapToItem(root, mouse.x, mouse.y)
                                        dragGhost.x = ptMove.x - dragGhost.width / 2
                                        dragGhost.y = ptMove.y - dragGhost.height / 2
                                        root.dragTargetIndex = root.findSlotAt(ptMove.x, ptMove.y)
                                    }
                                }

                                onReleased: function(mouse) {
                                    if (root.isDragging) {
                                        var ptRel = mapToItem(root, mouse.x, mouse.y)
                                        var target = root.findSlotAt(ptRel.x, ptRel.y)
                                        if (target >= 0 && target < systemController.settingsIconsOrder.length && target !== root.dragSourceIndex) {
                                            console.log("[RearrangeSettings] Drag swapped", root.dragSourceIndex, "with", target)
                                            systemController.swapSettingsIcons(root.dragSourceIndex, target)
                                        }
                                        root.isDragging = false
                                        root.dragSourceIndex = -1
                                        root.dragTargetIndex = -1
                                        root.selectedSlot = -1
                                        return
                                    }

                                    // Tap to Swap Logic:
                                    if (root.selectedSlot === -1) {
                                        if (info) {
                                            root.selectedSlot = slotIndex
                                            console.log("[RearrangeSettings] Selected slot", slotIndex)
                                        }
                                    } else if (root.selectedSlot === slotIndex) {
                                        root.selectedSlot = -1
                                    } else {
                                        if (slotIndex < systemController.settingsIconsOrder.length) {
                                            console.log("[RearrangeSettings] Tap swapped", root.selectedSlot, "with", slotIndex)
                                            systemController.swapSettingsIcons(root.selectedSlot, slotIndex)
                                        }
                                        root.selectedSlot = -1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Floating Drag Ghost Avatar
    Rectangle {
        id: dragGhost
        visible: root.isDragging
        width: 190
        height: 140
        radius: 10
        color: Qt.rgba(0.05, 0.18, 0.32, 0.92)
        border.color: "#00E5FF"
        border.width: 2
        z: 999
        property var info: null

        Column {
            anchors.centerIn: parent
            spacing: 12

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: dragGhost.info ? dragGhost.info.width : 58
                height: dragGhost.info ? dragGhost.info.height : 58

                Image {
                    anchors.fill: parent
                    source: dragGhost.info ? dragGhost.info.icon : ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                text: dragGhost.info ? dragGhost.info.title : ""
                color: "#FFFFFF"
                font.pixelSize: 20
                font.weight: Font.DemiBold
                font.family: "Roboto"
            }
        }
    }

    function findSlotAt(globalX, globalY) {
        var local = cardBox.mapFromItem(root, globalX, globalY)
        if (local.x >= 10 && local.x <= cardBox.width - 10 &&
            local.y >= 10 && local.y <= cardBox.height - 10) {
            var colW = (cardBox.width - 20) / 4
            var rowH = (cardBox.height - 20) / 2
            var col = Math.floor((local.x - 10) / colW)
            var row = Math.floor((local.y - 10) / rowH)
            col = Math.max(0, Math.min(3, col))
            row = Math.max(0, Math.min(1, row))
            var idx = row * 4 + col
            if (idx >= 0 && idx < systemController.settingsIconsOrder.length) {
                return idx
            }
        }
        return -1
    }
}
