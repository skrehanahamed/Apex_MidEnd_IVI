/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: BottomDock.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    height: 104
    color: "#05070B"

    signal allMenusClicked()
    signal phoneClicked()
    signal mediaClicked()
    signal settingsClicked()
    signal projectionClicked()
    signal radioClicked()
    signal voiceMemoClicked()
    signal drvmClicked()
    signal quietModeClicked()
    signal manualClicked()

    function handleIconClick(iconId) {
        switch (iconId) {
            case "all_menus": root.allMenusClicked(); break;
            case "phone": root.phoneClicked(); break;
            case "media": root.mediaClicked(); break;
            case "settings": root.settingsClicked(); break;
            case "projection": root.projectionClicked(); break;
            case "radio": root.radioClicked(); break;
            case "voicememo": root.voiceMemoClicked(); break;
            case "drvm": root.drvmClicked(); break;
            case "quietmode": root.quietModeClicked(); break;
            case "manual": root.manualClicked(); break;
            default: root.allMenusClicked(); break;
        }
    }

    function getIconSource(iconId) {
        switch (iconId) {
            case "all_menus": return "qrc:/assets/apps/icon_all_menus.png"
            case "phone": return "qrc:/assets/apps/icon_all_phone.png"
            case "media": return "qrc:/assets/apps/icon_all_media.png"
            case "settings": return "qrc:/assets/apps/icon_all_settings.png"
            case "projection": return "qrc:/assets/apps/icon_all_projection.png"
            case "voicememo": return "qrc:/assets/apps/icon_all_voicememo.png"
            case "radio": return "qrc:/assets/apps/icon_all_radio.png"
            case "drvm": return "qrc:/assets/apps/icon_all_drvm.png"
            case "quietmode": return "qrc:/assets/apps/icon_all_quietmode.png"
            case "manual": return "qrc:/assets/apps/icon_all_manual.png"
            default: return "qrc:/assets/apps/icon_all_menus.png"
        }
    }

    function getIconLabel(iconId) {
        switch (iconId) {
            case "all_menus": return "All menus"
            case "phone": return "Phone"
            case "media": return "Media"
            case "settings": return "Settings"
            case "projection": return "Projection"
            case "voicememo": return "Voice memo"
            case "radio": return "FM/AM"
            case "drvm": return "DRVM"
            case "quietmode": return "Quiet mode"
            case "manual": return "Manual"
            default: return iconId
        }
    }

    // Top hairline divider
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 1.5
        color: "#1E222D"
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 36
        anchors.rightMargin: 36
        spacing: 0

        Repeater {
            model: systemController.dockIcons

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: 10
                    color: slotMouse.pressed ? Qt.rgba(0.25, 0.72, 1.0, 0.25) : (slotMouse.containsMouse ? Qt.rgba(0.25, 0.72, 1.0, 0.08) : "transparent")
                    border.color: slotMouse.pressed ? "#66D2FF" : "transparent"
                    border.width: 1.5

                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 16
                    scale: slotMouse.pressed ? 0.95 : 1.0
                    Behavior on scale {
                        NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                    }

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 52
                        height: 52


                        Image {
                            anchors.fill: parent
                            source: root.getIconSource(modelData)
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.getIconLabel(modelData)
                        color: slotMouse.pressed ? "#70D6FF" : "#FFFFFF"
                        font.pixelSize: 24
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }
                }

                MouseArea {
                    id: slotMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.handleIconClick(modelData)
                }
            }
        }
    }
}
