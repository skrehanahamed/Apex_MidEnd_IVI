/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: MediaIcon.qml
 * ============================================================================
 */

import QtQuick

Item {
    id: root
    implicitWidth: 34
    implicitHeight: 32

    Canvas {
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var w = width;
            var h = height;

            // Left acoustic wave arc
            ctx.beginPath();
            ctx.arc(w * 0.22, h * 0.52, w * 0.22, 2.2, 4.1, false);
            ctx.strokeStyle = "#00A2E8";
            ctx.lineWidth = 3;
            ctx.lineCap = "round";
            ctx.stroke();

            // Right acoustic wave arc
            ctx.beginPath();
            ctx.arc(w * 0.78, h * 0.48, w * 0.22, -0.95, 0.95, false);
            ctx.strokeStyle = "#00A2E8";
            ctx.lineWidth = 3;
            ctx.lineCap = "round";
            ctx.stroke();

            // Music Note Notehead (white)
            ctx.beginPath();
            ctx.ellipse(w * 0.44, h * 0.65, 5.5, 4, -0.3, 0, 2 * Math.PI);
            ctx.fillStyle = "#FFFFFF";
            ctx.fill();

            // Stem
            ctx.beginPath();
            ctx.moveTo(w * 0.52, h * 0.64);
            ctx.lineTo(w * 0.52, h * 0.25);
            ctx.strokeStyle = "#FFFFFF";
            ctx.lineWidth = 3;
            ctx.stroke();

            // Flag / Hook
            ctx.beginPath();
            ctx.moveTo(w * 0.52, h * 0.25);
            ctx.bezierCurveTo(w * 0.62, h * 0.28, w * 0.66, h * 0.38, w * 0.68, h * 0.46);
            ctx.lineWidth = 2.5;
            ctx.stroke();
        }
    }
}
