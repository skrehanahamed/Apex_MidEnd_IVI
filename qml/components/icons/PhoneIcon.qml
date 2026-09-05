/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: PhoneIcon.qml
 * ============================================================================
 */

import QtQuick

Item {
    id: root
    implicitWidth: 34
    implicitHeight: 32

    // Acoustic wave arcs
    Canvas {
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var w = width;
            var h = height;

            // Left acoustic wave arc
            ctx.beginPath();
            ctx.arc(w * 0.28, h * 0.52, w * 0.24, 2.1, 4.18, false);
            ctx.strokeStyle = "#00A2E8";
            ctx.lineWidth = 2.8;
            ctx.lineCap = "round";
            ctx.stroke();

            // Right acoustic wave arc
            ctx.beginPath();
            ctx.arc(w * 0.72, h * 0.48, w * 0.24, -0.9, 1.0, false);
            ctx.strokeStyle = "#00A2E8";
            ctx.lineWidth = 2.8;
            ctx.lineCap = "round";
            ctx.stroke();
        }
    }

    // White handset silhouette
    Item {
        anchors.centerIn: parent
        width: 14
        height: 22
        rotation: -25

        // Ear piece
        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: 12
            height: 5
            radius: 2
            color: "#FFFFFF"
        }

        // Handle
        Rectangle {
            anchors.centerIn: parent
            width: 6
            height: 16
            radius: 3
            color: "#FFFFFF"
        }

        // Mouth piece
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: 12
            height: 5
            radius: 2
            color: "#FFFFFF"
        }
    }
}
