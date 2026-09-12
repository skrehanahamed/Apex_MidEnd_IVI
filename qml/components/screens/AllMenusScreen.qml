/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: AllMenusScreen.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#05070B"

    signal backToHomeClicked()
    signal menuClicked()
    signal settingsClicked()
    signal phoneClicked()
    signal projectionClicked()
    signal radioClicked()
    signal mediaClicked()
    signal voiceMemoClicked()
    signal drvmClicked()
    signal quietModeClicked()
    signal manualClicked()
    signal editHomeIconsClicked()

    property int currentPage: 0

    function resetToDefault() {
        currentPage = 0
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ====================================================
        // 1. SUB-HEADER BAR ("All menus" title + Menu + Back)
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

                // Left: Grid icon + "All menus"
                Row {
                    spacing: 14
                    Layout.alignment: Qt.AlignVCenter

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 30
                        height: 30
                        source: "qrc:/assets/ui/icon_all_menus_hdr.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "All menus"
                        color: "#FFFFFF"
                        font.pixelSize: 24
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }
                }

                Item { Layout.fillWidth: true }

                // Right 2 Blue Action Buttons: Menu | Back (⮌)
                Row {
                    spacing: 12
                    Layout.alignment: Qt.AlignVCenter

                    // 1. Menu Button
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
                                allMenusDropdown.visible = !allMenusDropdown.visible
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
                                console.log("[AllMenus] Back clicked -> Returning to Home")
                                root.backToHomeClicked()
                            }
                        }
                    }
                }
            }
        }

        // ====================================================
        // 2. MULTI-PAGE SWIPABLE VIEW (Scalable for future menus/options)
        // ====================================================
        Item {
            id: allMenusGridArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // Reusable App Card Component
            component MenuAppCard: Rectangle {
                id: cardRoot
                property string title: ""
                property string iconSrc: ""
                property bool isPressed: cardMouse.pressed && !root.isSliding
                signal clicked()

                width: 230
                height: 160
                radius: 12
                color: isPressed ? "#162334" : (cardMouse.containsMouse ? "#0D1622" : "transparent")
                border.color: isPressed ? "#2C80D0" : (cardMouse.containsMouse ? "#1E2F44" : "transparent")
                border.width: 1.5

                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on border.color { ColorAnimation { duration: 100 } }

                Column {
                    anchors.centerIn: parent
                    spacing: 14
                    scale: cardRoot.isPressed ? 0.96 : 1.0
                    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 64
                        height: 64


                        Image {
                            anchors.fill: parent
                            source: cardRoot.iconSrc
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: cardRoot.title
                        color: cardRoot.isPressed ? "#99D5FF" : "#FFFFFF"
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }
                }

                MouseArea {
                    id: cardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    property real startX: 0
                    property real startY: 0
                    onPressed: function(mouse) {
                        startX = mouse.x
                        startY = mouse.y
                    }
                    onReleased: function(mouse) {
                        var dx = mouse.x - startX
                        var dy = mouse.y - startY
                        if (Math.abs(dx) > 50 && Math.abs(dx) > Math.abs(dy)) {
                            if (dx < -50 && root.currentPage === 0) {
                                root.currentPage = 1
                            } else if (dx > 50 && root.currentPage === 1) {
                                root.currentPage = 0
                            }
                        } else if (Math.abs(dx) < 20 && Math.abs(dy) < 20) {
                            cardRoot.clicked()
                        }
                    }
                }
            }

            // Background swipe detector for empty spaces
            MouseArea {
                id: swipeArea
                anchors.fill: parent
                z: 0
                property real startX: 0
                onPressed: function(mouse) { startX = mouse.x }
                onReleased: function(mouse) {
                    var diff = mouse.x - startX
                    if (diff < -50 && root.currentPage === 0) {
                        root.currentPage = 1
                    } else if (diff > 50 && root.currentPage === 1) {
                        root.currentPage = 0
                    }
                }
            }

            // Sliding Pages Container
            Item {
                id: pagesContainer
                width: allMenusGridArea.width * 2
                height: allMenusGridArea.height
                x: -root.currentPage * allMenusGridArea.width

                Behavior on x {
                    NumberAnimation {
                        duration: 280
                        easing.type: Easing.OutCubic
                    }
                }

                // ==========================================
                // PAGE 1: 8 Primary Apps
                // ==========================================
                Item {
                    id: page1Item
                    width: allMenusGridArea.width
                    height: allMenusGridArea.height
                    x: 0

                    Grid {
                        id: page1Grid
                        anchors.centerIn: parent
                        columns: 4
                        rowSpacing: 36
                        columnSpacing: 48

                        MenuAppCard {
                            title: "Phone"
                            iconSrc: "qrc:/assets/apps/icon_all_phone.png"
                            onClicked: {
                                console.log("[AllMenus] Phone clicked")
                                root.phoneClicked()
                            }
                        }

                        MenuAppCard {
                            title: "Phone projection"
                            iconSrc: "qrc:/assets/apps/icon_all_projection.png"
                            onClicked: {
                                console.log("[AllMenus] Projection clicked")
                                root.projectionClicked()
                            }
                        }

                        MenuAppCard {
                            title: "FM/AM"
                            iconSrc: "qrc:/assets/apps/icon_all_radio.png"
                            onClicked: {
                                console.log("[AllMenus] FM/AM clicked")
                                root.radioClicked()
                            }
                        }

                        MenuAppCard {
                            title: "Media"
                            iconSrc: "qrc:/assets/apps/icon_all_media.png"
                            onClicked: {
                                console.log("[AllMenus] Media clicked")
                                root.mediaClicked()
                            }
                        }

                        MenuAppCard {
                            title: "Voice memo"
                            iconSrc: "qrc:/assets/apps/icon_all_voicememo.png"
                            onClicked: {
                                console.log("[AllMenus] Voice memo clicked")
                                root.voiceMemoClicked()
                            }
                        }

                        MenuAppCard {
                            title: "DRVM"
                            iconSrc: "qrc:/assets/apps/icon_all_drvm.png"
                            onClicked: {
                                console.log("[AllMenus] DRVM clicked")
                                root.drvmClicked()
                            }
                        }

                        MenuAppCard {
                            title: "Quiet mode"
                            iconSrc: "qrc:/assets/apps/icon_all_quietmode.png"
                            onClicked: {
                                console.log("[AllMenus] Quiet mode clicked")
                                root.quietModeClicked()
                            }
                        }

                        MenuAppCard {
                            title: "Settings"
                            iconSrc: "qrc:/assets/apps/icon_all_settings.png"
                            onClicked: {
                                console.log("[AllMenus] Settings clicked -> Sliding to Settings")
                                root.settingsClicked()
                            }
                        }
                    }
                }

                // ==========================================
                // PAGE 2: Manual App & Future Menus / Options
                // ==========================================
                Item {
                    id: page2Item
                    width: allMenusGridArea.width
                    height: allMenusGridArea.height
                    x: allMenusGridArea.width

                    Grid {
                        id: page2Grid
                        x: page1Grid.x
                        y: page1Grid.y
                        columns: 4
                        rowSpacing: 36
                        columnSpacing: 48

                        MenuAppCard {
                            title: "Manual"
                            iconSrc: "qrc:/assets/apps/icon_all_manual.png"
                            onClicked: {
                                console.log("[AllMenus] Manual clicked -> Opening Manual screen")
                                root.manualClicked()
                            }
                        }

                        MenuAppCard {
                            title: "Android Auto"
                            iconSrc: "qrc:/assets/media/icon_media_androidauto.png"
                            onClicked: {
                                console.log("[AllMenus] Android Auto clicked")
                                systemController.triggerProjection()
                            }
                        }

                        MenuAppCard {
                            title: "Apple CarPlay"
                            iconSrc: "qrc:/assets/media/icon_media_carplay.png"
                            onClicked: {
                                console.log("[AllMenus] Apple CarPlay clicked")
                                systemController.triggerProjection()
                            }
                        }
                    }
                }
            }

            // Pagination dots
            Row {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 14
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                z: 10

                Repeater {
                    model: 2
                    Rectangle {
                        width: (root.currentPage === index) ? 22 : 8
                        height: 8
                        radius: 4
                        color: (root.currentPage === index) ? "#FFFFFF" : "#4A5463"
                        Behavior on width { NumberAnimation { duration: 150 } }
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -10
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentPage = index
                        }
                    }
                }
            }
        }
    }

    // Backdrop to dismiss dropdown
    MouseArea {
        anchors.fill: parent
        z: 89
        visible: allMenusDropdown.visible
        onClicked: allMenusDropdown.visible = false
    }

    // Dropdown for "Menu" button
    Item {
        id: allMenusDropdown
        anchors.top: parent.top
        anchors.topMargin: 56
        anchors.right: parent.right
        anchors.rightMargin: 16
        width: 320
        height: 120
        visible: false
        z: 90

        Rectangle {
            anchors.fill: parent
            color: "#EEF3F8"
            border.color: "#C6D4E2"
            border.width: 1
            radius: 3

            // Drop shadow
            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                z: -1
                color: "#38000000"
                radius: 4
            }

            Column {
                anchors.fill: parent

                Rectangle {
                    width: parent.width
                    height: 60
                    color: dropRow1.pressed ? "#D0DFEE" : (dropRow1.containsMouse ? "#E1EBF5" : "transparent")

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 24
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Edit Home icons"
                        color: "#223344"
                        font.pixelSize: 22
                        font.family: "Roboto"
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: "#D6E0EC"
                    }

                    MouseArea {
                        id: dropRow1
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            allMenusDropdown.visible = false
                            root.editHomeIconsClicked()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 60
                    color: dropRow2.pressed ? "#D0DFEE" : (dropRow2.containsMouse ? "#E1EBF5" : "transparent")

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 24
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Manual"
                        color: "#223344"
                        font.pixelSize: 22
                        font.family: "Roboto"
                    }

                    MouseArea {
                        id: dropRow2
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            allMenusDropdown.visible = false
                            root.manualClicked()
                        }
                    }
                }
            }
        }
    }
}
