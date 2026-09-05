/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: SettingsIcon.qml
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
            var cx = width * 0.5;
            var cy = height * 0.5;
            var outerR = width * 0.42;
            var innerR = width * 0.28;
            var teeth = 8;

            ctx.beginPath();
            for (var i = 0; i < teeth; i++) {
                var angle = (i * 2 * Math.PI) / teeth;
                var angleStep = (2 * Math.PI) / (teeth * 4);

                var a1 = angle - angleStep;
                var a2 = angle - angleStep * 0.5;
                var a3 = angle + angleStep * 0.5;
                var a4 = angle + angleStep;

                if (i === 0) {
                    ctx.moveTo(cx + Math.cos(a1) * innerR, cy + Math.sin(a1) * innerR);
                } else {
                    ctx.lineTo(cx + Math.cos(a1) * innerR, cy + Math.sin(a1) * innerR);
                }
                ctx.lineTo(cx + Math.cos(a2) * outerR, cy + Math.sin(a2) * outerR);
                ctx.lineTo(cx + Math.cos(a3) * outerR, cy + Math.sin(a3) * outerR);
                ctx.lineTo(cx + Math.cos(a4) * innerR, cy + Math.sin(a4) * innerR);
            }
            ctx.closePath();
            ctx.fillStyle = "#FFFFFF";
            ctx.fill();

            // Center hub circle in cyan
            ctx.beginPath();
            ctx.arc(cx, cy, width * 0.16, 0, 2 * Math.PI);
            ctx.fillStyle = "#00A2E8";
            ctx.fill();
        }
    }
}
