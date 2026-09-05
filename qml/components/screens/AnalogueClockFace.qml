/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: AnalogueClockFace.qml
 * ============================================================================
 */

import QtQuick

Item {
    id: root
    width: 140
    height: 140

    property int clockStyle: 1 // 1..8
    property real hourAngle: 0
    property real minuteAngle: 0
    property real secondAngle: 0
    property bool animated: true

    // Auto-update angles at ~30 FPS for continuous smooth sweeping seconds
    Timer {
        id: clockTimer
        interval: root.animated ? 33 : 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var d = new Date()
            var h = d.getHours() % 12
            var m = d.getMinutes()
            var s = d.getSeconds()
            var ms = d.getMilliseconds()
            root.hourAngle = (h * 30) + (m * 0.5) + (s * (0.5 / 60))
            root.minuteAngle = (m * 6) + (s * 0.1) + (ms * 0.0001)
            root.secondAngle = (s * 6) + (ms * 0.006)
        }
    }

    // Outer Bezel
    Rectangle {
        id: outerBezel
        anchors.fill: parent
        radius: width / 2
        color: {
            if (clockStyle === 3 || clockStyle === 6) return "#BACCDA"
            if (clockStyle === 5) return "#222D3A"
            if (clockStyle === 4) return "#344252"
            if (clockStyle === 2) return "#141D27"
            return "#2A3644"
        }
        border.color: {
            if (clockStyle === 3 || clockStyle === 6) return "#E0EDF8"
            if (clockStyle === 5) return "#405062"
            if (clockStyle === 2) return "#4D00B8FF"
            return "#3E4E60"
        }
        border.width: (clockStyle === 3 || clockStyle === 6) ? 4 : ((clockStyle === 2) ? 2.5 : 2)

        // Inner Dial Face
        Rectangle {
            id: dial
            anchors.fill: parent
            anchors.margins: (clockStyle === 3 || clockStyle === 6) ? 8 : ((clockStyle === 4 || clockStyle === 2) ? 6 : 4)
            radius: width / 2
            color: {
                if (clockStyle === 5) return "#F2F5F8"
                if (clockStyle === 2) return "#0A111A"
                if (clockStyle === 3) return "#142D4C"
                if (clockStyle === 6) return "#0E1E34"
                if (clockStyle === 7) return "#161B22"
                return "#1A212B"
            }

            // Sweeping Radar Fan Sector for Clock 2 (translucent glowing blue sector trailing second hand)
            Canvas {
                id: radarCanvas
                anchors.fill: parent
                visible: clockStyle === 2
                renderTarget: Canvas.FramebufferObject

                Connections {
                    target: root
                    function onSecondAngleChanged() {
                        if (clockStyle === 2) {
                            radarCanvas.requestPaint()
                        }
                    }
                }

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    var cx = width / 2
                    var cy = height / 2
                    var r = width / 2 - 2

                    // secondAngle: 0 deg = 12 o'clock (-Math.PI / 2)
                    var currentRad = (root.secondAngle - 90) * Math.PI / 180
                    var sweepSpan = 42 * Math.PI / 180 // ~42 degree trailing fan

                    // Draw layered fan sector with gradient alpha fade trailing the second needle
                    var slices = 28
                    for (var i = 0; i < slices; i++) {
                        var a1 = currentRad - (sweepSpan * (slices - i) / slices)
                        var a2 = currentRad - (sweepSpan * (slices - i - 1) / slices)
                        var progress = (i + 1) / slices // 0 to 1
                        var alpha = 0.58 * Math.pow(progress, 1.8) // smooth curved fade

                        ctx.beginPath()
                        ctx.moveTo(cx, cy)
                        ctx.arc(cx, cy, r, a1, a2, false)
                        ctx.closePath()
                        ctx.fillStyle = "rgba(0, 168, 255, " + alpha.toFixed(3) + ")"
                        ctx.fill()
                    }

                    // Outer arc subtle highlight
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, currentRad - (sweepSpan * 0.35), currentRad, false)
                    ctx.strokeStyle = "rgba(100, 215, 255, 0.45)"
                    ctx.lineWidth = 2.5
                    ctx.stroke()
                }
            }

            // 60-Minute Dots for Clock 2
            Repeater {
                model: 60
                Item {
                    anchors.fill: parent
                    rotation: index * 6
                    visible: clockStyle === 2 && (index % 5 !== 0)

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 4
                        width: 1.5
                        height: 1.5
                        radius: 0.75
                        color: "#73FFFFFF"
                    }
                }
            }

            // Hour Ticks around the dial
            Repeater {
                model: 12
                Item {
                    anchors.fill: parent
                    rotation: index * 30

                    // Regular Hour Tick
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: (clockStyle === 7 && index === 0) ? 999 : ((clockStyle === 2) ? 3 : 4)
                        width: (clockStyle === 2) ? 3 : ((index % 3 === 0) ? 3 : 1.5)
                        height: (clockStyle === 2) ? 9 : ((index % 3 === 0) ? 8 : 5)
                        color: {
                            if (clockStyle === 2) return (index === 0) ? "#00B8FF" : "#FFFFFF"
                            if (clockStyle === 5) return (index % 3 === 0) ? "#1A222C" : "#5A6A7C"
                            if (clockStyle === 6) return (index % 3 === 0) ? "#E59842" : "#94AABF"
                            if (clockStyle === 7) return "#C49A6C"
                            return "#FFFFFF"
                        }
                        radius: 1.5
                        visible: !(clockStyle === 8 && index === 0) && !(clockStyle === 7 && index === 0)
                    }

                    // Clock 7 Roman "XII" at top
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 3
                        text: "XII"
                        color: "#D4A574"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                        visible: clockStyle === 7 && index === 0
                        rotation: -parent.rotation
                    }

                    // Clock 8 Double Bar at top
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 4
                        spacing: 2
                        visible: clockStyle === 8 && index === 0

                        Rectangle { width: 2; height: 9; color: "#FFFFFF"; radius: 1 }
                        Rectangle { width: 2; height: 9; color: "#FFFFFF"; radius: 1 }
                    }
                }
            }

            // Hour Hand
            Item {
                anchors.centerIn: parent
                width: 1
                height: 1
                rotation: root.hourAngle

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.top
                    width: (clockStyle === 2) ? 3.5 : ((clockStyle === 4) ? 4.5 : ((clockStyle === 8) ? 4 : 3))
                    height: dial.width * 0.28
                    radius: (clockStyle === 8) ? 0 : 1.75
                    color: {
                        if (clockStyle === 5) return "#1A222C"
                        if (clockStyle === 6) return "#E89C46"
                        if (clockStyle === 7) return "#D4A574"
                        return "#FFFFFF"
                    }
                    border.color: (clockStyle === 8) ? "#FFFFFF" : "transparent"
                    border.width: (clockStyle === 8) ? 1 : 0
                }
            }

            // Minute Hand
            Item {
                anchors.centerIn: parent
                width: 1
                height: 1
                rotation: root.minuteAngle

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.top
                    width: (clockStyle === 2) ? 2.5 : ((clockStyle === 4) ? 3.5 : ((clockStyle === 8) ? 3.5 : 2))
                    height: dial.width * 0.40
                    radius: (clockStyle === 8) ? 0 : 1.25
                    color: {
                        if (clockStyle === 5) return "#1A222C"
                        if (clockStyle === 6) return "#E89C46"
                        if (clockStyle === 7) return "#D4A574"
                        return "#FFFFFF"
                    }
                    border.color: (clockStyle === 8) ? "#FFFFFF" : "transparent"
                    border.width: (clockStyle === 8) ? 1 : 0
                }
            }

            // Seconds Hand with smooth continuous sweep
            Item {
                anchors.centerIn: parent
                width: 1
                height: 1
                rotation: root.secondAngle

                // Leading Needle
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.top
                    width: (clockStyle === 2) ? 2 : 1.5
                    height: dial.width * 0.46
                    radius: 1
                    color: {
                        if (clockStyle === 2) return "#80E5FF" // Glowing cyan needle
                        if (clockStyle === 6) return "#FFA726"
                        if (clockStyle === 5) return "#E53935"
                        if (clockStyle === 7) return "#D4A574"
                        return "#00E5FF"
                    }
                }

                // Counterweight tail
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    width: (clockStyle === 2) ? 2 : 1.5
                    height: dial.width * 0.10
                    radius: 1
                    color: {
                        if (clockStyle === 2) return "#80E5FF"
                        if (clockStyle === 5) return "#E53935"
                        return "#00E5FF"
                    }
                }
            }

            // Center Pin / Cap
            Rectangle {
                anchors.centerIn: parent
                width: (clockStyle === 2) ? 10 : 7
                height: width
                radius: width / 2
                color: {
                    if (clockStyle === 2) return "#FFFFFF"
                    if (clockStyle === 5) return "#1A222C"
                    if (clockStyle === 6) return "#E89C46"
                    if (clockStyle === 7) return "#D4A574"
                    return "#FFFFFF"
                }
                border.color: (clockStyle === 2) ? "#00B8FF" : "#304050"
                border.width: (clockStyle === 2) ? 2 : 1

                // Inner tiny dot for Clock 2
                Rectangle {
                    anchors.centerIn: parent
                    width: 3
                    height: 3
                    radius: 1.5
                    color: "#00B8FF"
                    visible: clockStyle === 2
                }
            }
        }
    }
}
