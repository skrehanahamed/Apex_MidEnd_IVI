/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: AllMenusIcon.qml
 * ============================================================================
 */

import QtQuick

Item {
    id: root
    implicitWidth: 32
    implicitHeight: 32

    Grid {
        anchors.centerIn: parent
        columns: 3
        rows: 3
        spacing: 4

        Repeater {
            model: 9
            Rectangle {
                width: 7
                height: 7
                radius: 1.5
                // Index 6 is bottom-left square (row 2, col 0)
                color: index === 6 ? "#00A2E8" : "transparent"
                border.color: index === 6 ? "transparent" : "#FFFFFF"
                border.width: 1.6
            }
        }
    }
}
