import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string callerName: ""
    property string callerNumber: ""
    property bool privacyMode: false
    property bool actionPending: false
    property bool quickRepliesVisible: false
    property string feedbackText: ""

    signal accepted()
    signal rejected()
    signal privacyToggled()
    signal quickReplySelected(string text)

    function reset() {
        actionPending = false
        quickRepliesVisible = false
        feedbackText = ""
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.58)

        MouseArea {
            anchors.fill: parent
            onClicked: {} // Modal: never pass a call action to the screen below.
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(790, root.width - 72)
        height: quickRepliesVisible ? 390 : 292
        color: "#061426"
        border.color: "#6CA8DD"
        border.width: 2
        radius: 3

        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 128
                Layout.leftMargin: 185
                Layout.rightMargin: 22
                spacing: 20

                Image {
                    Layout.preferredWidth: 82
                    Layout.preferredHeight: 82
                    source: "qrc:/assets/phone/icon_person_avatar.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        Layout.fillWidth: true
                        text: root.callerName.length > 0 && root.callerName !== root.callerNumber
                              ? root.callerName : "Incoming call"
                        color: "#F4F8FC"
                        font.family: "Roboto"
                        font.pixelSize: 22
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.callerNumber.length > 0 ? root.callerNumber : "Unknown number"
                        color: "#8BE46B"
                        font.family: "Roboto"
                        font.pixelSize: 30
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#21415F"
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                color: "transparent"

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    Rectangle {
                        width: 25
                        height: 25
                        color: root.privacyMode ? "#49A9F8" : "#F6FAFD"
                        border.color: root.privacyMode ? "#8CD2FF" : "#879BAB"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: root.privacyMode ? "✓" : ""
                            color: "#FFFFFF"
                            font.pixelSize: 20
                            font.bold: true
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Privacy Mode"
                        color: "#F4F8FC"
                        font.family: "Roboto"
                        font.pixelSize: 22
                        font.weight: Font.Medium
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !root.actionPending
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.privacyToggled()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                spacing: 8

                Repeater {
                    model: [
                        { label: "Accept", action: "accept", clipX: 148, clipY: 98, clipW: 588, clipH: 552 },
                        { label: "Reject", action: "reject", clipX: 760, clipY: 80, clipW: 652, clipH: 402 },
                        { label: "Message", action: "message", clipX: 1455, clipY: 20, clipW: 717, clipH: 630 }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 2
                        color: buttonMouse.pressed ? "#355F8D" : (buttonMouse.containsMouse ? "#315B87" : "#294E79")
                        border.color: "#5388BE"
                        border.width: 1
                        opacity: root.actionPending ? 0.58 : 1.0

                        Row {
                            anchors.centerIn: parent
                            spacing: 11

                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 42
                                height: 38
                                source: "qrc:/assets/phone/incoming_call_actions.png"
                                sourceClipRect: Qt.rect(modelData.clipX, modelData.clipY,
                                                        modelData.clipW, modelData.clipH)
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: "#F7FBFF"
                                font.family: "Roboto"
                                font.pixelSize: 23
                                font.weight: Font.Medium
                            }
                        }

                        MouseArea {
                            id: buttonMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !root.actionPending
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.action === "accept") {
                                    root.actionPending = true
                                    root.accepted()
                                } else if (modelData.action === "reject") {
                                    root.actionPending = true
                                    root.rejected()
                                } else {
                                    root.quickRepliesVisible = !root.quickRepliesVisible
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 8
                spacing: 7
                visible: root.quickRepliesVisible

                Text {
                    text: root.feedbackText.length > 0 ? root.feedbackText : "Send a quick reply and reject the call"
                    color: root.feedbackText.length > 0 ? "#FFD36B" : "#AFC5D8"
                    font.family: "Roboto"
                    font.pixelSize: 16
                    Layout.alignment: Qt.AlignHCenter
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8

                    Repeater {
                        model: ["Can't talk now", "I'll call you back", "On my way"]

                        delegate: Rectangle {
                            required property string modelData
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 4
                            color: replyMouse.pressed ? "#2F80C1" : (replyMouse.containsMouse ? "#244D72" : "#172F48")
                            border.color: "#416D94"

                            Text {
                                anchors.centerIn: parent
                                width: parent.width - 16
                                text: modelData
                                color: "#FFFFFF"
                                font.family: "Roboto"
                                font.pixelSize: 17
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                            }

                            MouseArea {
                                id: replyMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !root.actionPending
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.actionPending = true
                                    root.feedbackText = "Sending…"
                                    root.quickReplySelected(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
