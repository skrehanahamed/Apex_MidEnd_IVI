/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: EditHomeIconsScreen.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#05070B"

    signal backClicked()

    // Active dock icons from SystemController
    readonly property var dockIcons: systemController.dockIcons
    property int selectedDockIndex: -1
    property int dragTargetSlotIndex: -1
    property int currentPage: 0 // 0 for Page 1, 1 for Page 2

    // Drag state
    property bool isDragging: false
    property string draggedIconId: ""
    property string draggedIconSrc: ""
    property string draggedIconTitle: ""
    property real originX: 0
    property real originY: 0

    // Touch selection state (Tap candidate then tap dock, or tap dock then tap candidate)
    property string selectedCandidateId: ""
    property real pagesSlideOffset: 0
    property bool isSwipingPages: false

    function resetToDefault() {
        currentPage = 0
        selectedDockIndex = -1
        selectedCandidateId = ""
        dragTargetSlotIndex = -1
        isDragging = false
        pagesSlideOffset = 0
        isSwipingPages = false
        avatarFlyBackAnim.stop()
        dragAvatar.opacity = 1.0
    }

    function startDragging(globalX, globalY, iconId, iconSrc, iconTitle, candItem) {
        if (iconId === "" || root.isIconInDock(iconId) || !candItem) return
        avatarFlyBackAnim.stop()
        root.draggedIconId = iconId
        root.draggedIconSrc = iconSrc
        root.draggedIconTitle = iconTitle
        var originPt = candItem.mapToItem(root, 0, 0)
        root.originX = originPt.x
        root.originY = originPt.y
        dragAvatar.x = globalX - dragAvatar.width / 2
        dragAvatar.y = globalY - dragAvatar.height / 2
        dragAvatar.opacity = 1.0
        root.isDragging = true
        root.dragTargetSlotIndex = root.checkSlotHover(globalX, globalY)
    }

    function updateDragging(globalX, globalY) {
        if (!root.isDragging) return
        dragAvatar.x = globalX - dragAvatar.width / 2
        dragAvatar.y = globalY - dragAvatar.height / 2
        root.dragTargetSlotIndex = root.checkSlotHover(globalX, globalY)
    }

    function finishDragging(globalX, globalY) {
        if (!root.isDragging) return
        var targetSlot = root.checkSlotHover(globalX, globalY)
        if (targetSlot >= 0 && targetSlot < 4) {
            console.log("[EditHomeIcons] Dropped", root.draggedIconId, "onto slot", targetSlot)
            systemController.updateDockIcon(targetSlot, root.draggedIconId)
            root.selectedDockIndex = -1
            root.selectedCandidateId = ""
            root.isDragging = false
            root.dragTargetSlotIndex = -1
        } else {
            // Cancel drag: smoothly return avatar home
            avatarFlyBackAnim.stop()
            avatarFlyBackAnim.toX = root.originX
            avatarFlyBackAnim.toY = root.originY
            avatarFlyBackAnim.restart()
        }
    }

    // Factory reset modal state
    property bool isResetDone: false

    function isIconInDock(iconId) {
        if (!dockIcons) return false
        return dockIcons.indexOf(iconId) !== -1
    }

    function checkSlotHover(globalX, globalY) {
        var dockPos = dockBorderBox.mapFromItem(root, globalX, globalY)
        if (dockPos.x >= 0 && dockPos.x <= dockBorderBox.width &&
            dockPos.y >= 0 && dockPos.y <= dockBorderBox.height) {
            var slotW = dockBorderBox.width / 4
            var slotIdx = Math.floor(dockPos.x / slotW)
            return Math.max(0, Math.min(3, slotIdx))
        }
        return -1
    }

    function getCandidateCenter(iconId) {
        var item = null
        switch (iconId) {
            case "phone": item = candPhone; break
            case "projection": item = candProjection; break
            case "voicememo": item = candVoicememo; break
            case "radio": item = candRadio; break
            case "media": item = candMedia; break
            case "drvm": item = candDrvm; break
            case "quietmode": item = candQuietmode; break
            case "settings": item = candSettings; break
            case "manual": item = candManual; break
            default: item = null; break
        }
        if (item) {
            var pt = item.mapToItem(root, item.width / 2, item.height / 2)
            return { x: pt.x, y: pt.y }
        }
        return { x: root.width / 2, y: 180 }
    }

    function getDockSlotCenter(slotIdx) {
        var slotW = dockBorderBox.width / 4
        var localX = (slotIdx + 0.5) * slotW
        var localY = dockBorderBox.height / 2
        var pt = dockBorderBox.mapToItem(root, localX, localY)
        return { x: pt.x, y: pt.y }
    }

    function triggerDefaultFlyAnimation() {
        var defaultIcons = ["all_menus", "phone", "media", "settings"]
        var flyIndex = 0
        var changedCount = 0

        // Check each dock slot: ONLY animate if this slot was actually replaced/changed!
        for (var i = 0; i < root.dockIcons.length; i++) {
            var currentId = root.dockIcons[i]
            var defaultId = defaultIcons[i]

            if (currentId !== defaultId) {
                changedCount++

                var dockPt = getDockSlotCenter(i)
                var customCandPt = (currentId === "all_menus") ? { x: 120, y: 160 } : getCandidateCenter(currentId)
                var defaultCandPt = (defaultId === "all_menus") ? { x: 120, y: 160 } : getCandidateCenter(defaultId)

                // 1. The replaced icon in this slot moves UP to its place in the upper menu
                var upAvatar = flyRepeater.itemAt(flyIndex++)
                if (upAvatar) {
                    var upDelay = (changedCount - 1) * 40
                    upAvatar.launch(root.getIconSource(currentId), root.getIconLabel(currentId), dockPt.x, dockPt.y, customCandPt.x, customCandPt.y, upDelay)
                }

                // 2. The default icon moves DOWN from the upper menu to this dock slot
                var downAvatar = flyRepeater.itemAt(flyIndex++)
                if (downAvatar) {
                    var downDelay = 90 + ((changedCount - 1) * 60)
                    downAvatar.launch(root.getIconSource(defaultId), root.getIconLabel(defaultId), defaultCandPt.x, defaultCandPt.y, dockPt.x, dockPt.y, downDelay)
                }
            }
        }

        if (changedCount > 0) {
            flightOverlayTimer.restart()
            defaultSettleTimer.restart()
        } else {
            systemController.resetDockIcons()
            systemController.resetWidgetsToDefault()
            root.selectedDockIndex = -1
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ====================================================
        // 1. SUB-HEADER BAR ("Edit Home icons" + Default + Back)
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

                // Left: Gear icon + "Edit Home icons"
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
                        text: "Edit Home icons"
                        color: "#FFFFFF"
                        font.pixelSize: 24
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }
                }

                Item { Layout.fillWidth: true }

                // Right: Default + Back Button
                Row {
                    spacing: 12
                    Layout.alignment: Qt.AlignVCenter

                    // Default Button
                    Rectangle {
                        width: 96
                        height: 40
                        color: defMouse.pressed ? "#389BFF" : (defMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: defMouse.pressed ? "#80D8FF" : "#3F74A3"
                        border.width: 1
                        radius: 3

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Default"
                            color: "#FFFFFF"
                            font.pixelSize: 18
                            font.family: "Roboto"
                            scale: defMouse.pressed ? 0.94 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: defMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.isResetDone = false
                                resetModal.visible = true
                            }
                        }
                    }

                    // Back Button (⮌)
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
                            onClicked: root.backClicked()
                        }
                    }
                }
            }
        }

        // ====================================================
        // 2. INSTRUCTION SUBTITLE
        // ====================================================
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 46

            Text {
                anchors.centerIn: parent
                text: root.selectedCandidateId !== "" 
                      ? "Tap a slot below to place the selected icon."
                      : (root.selectedDockIndex >= 0 
                         ? "Tap an icon above to place it into the highlighted slot."
                         : "Tap or drag an icon from the top to a position in the box below.")
                color: (root.selectedCandidateId !== "" || root.selectedDockIndex >= 0) ? "#80D8FF" : "#7BD192"
                font.pixelSize: 19
                font.family: "Roboto"
            }
        }

        // ====================================================
        // 3. UPPER CANDIDATE ICONS (Multi-Page Swipable View)
        // ====================================================
        Item {
            id: candidateGridArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // Clean background touch swipe area
            MouseArea {
                id: swipeArea
                anchors.fill: parent
                z: 0
                property real startX: 0
                property real startY: 0
                property bool swiping: false

                onPressed: function(mouse) {
                    startX = mouse.x
                    startY = mouse.y
                    swiping = false
                }

                onPositionChanged: function(mouse) {
                    if (!pressed) return
                    var dx = mouse.x - startX
                    var dy = mouse.y - startY
                    if (!swiping && Math.abs(dx) > 15 && Math.abs(dx) > Math.abs(dy)) {
                        swiping = true
                        root.isSwipingPages = true
                    }
                    if (swiping) {
                        if ((root.currentPage === 0 && dx > 0) || (root.currentPage === 1 && dx < 0)) {
                            root.pagesSlideOffset = dx * 0.35
                        } else {
                            root.pagesSlideOffset = dx
                        }
                    }
                }

                onReleased: function(mouse) {
                    var dx = mouse.x - startX
                    var dy = mouse.y - startY
                    if (swiping) {
                        root.isSwipingPages = false
                        if (dx < -50 && root.currentPage === 0) {
                            root.currentPage = 1
                        } else if (dx > 50 && root.currentPage === 1) {
                            root.currentPage = 0
                        }
                        root.pagesSlideOffset = 0
                        swiping = false
                    } else if (Math.abs(dx) < 20 && Math.abs(dy) < 20) {
                        root.selectedDockIndex = -1
                        root.selectedCandidateId = ""
                    }
                }

                onCanceled: function() {
                    root.isSwipingPages = false
                    root.pagesSlideOffset = 0
                    swiping = false
                }

                onWheel: function(wheel) {
                    if (wheel.angleDelta.x < -30 || wheel.angleDelta.y < -30) {
                        root.currentPage = 1
                    } else if (wheel.angleDelta.x > 30 || wheel.angleDelta.y > 30) {
                        root.currentPage = 0
                    }
                }
            }

            // Pages Container with real-time tracking + 280ms cubic ease slide animation
            Item {
                id: pagesContainer
                width: candidateGridArea.width * 2
                height: candidateGridArea.height
                x: (-root.currentPage * candidateGridArea.width) + root.pagesSlideOffset

                Behavior on x {
                    enabled: !root.isSwipingPages
                    NumberAnimation {
                        duration: 280
                        easing.type: Easing.OutCubic
                    }
                }

                // PAGE 1: 8 Items
                Item {
                    id: page1Item
                    width: candidateGridArea.width
                    height: candidateGridArea.height
                    x: 0

                    Grid {
                        anchors.centerIn: parent
                        columns: 4
                        rowSpacing: 34
                        columnSpacing: 36

                        // Row 1
                        CandidateIcon {
                            id: candPhone
                            iconId: "phone"
                            iconSrc: "qrc:/assets/apps/icon_all_phone.png"
                            title: "Phone"
                        }

                        CandidateIcon {
                            id: candProjection
                            iconId: "projection"
                            iconSrc: "qrc:/assets/apps/icon_all_projection.png"
                            title: "Phone\nprojection"
                        }

                        CandidateIcon {
                            id: candVoicememo
                            iconId: "voicememo"
                            iconSrc: "qrc:/assets/apps/icon_all_voicememo.png"
                            title: "Voice\nmemo"
                        }

                        CandidateIcon {
                            id: candRadio
                            iconId: "radio"
                            iconSrc: "qrc:/assets/apps/icon_all_radio.png"
                            title: "Radio"
                        }

                        // Row 2
                        CandidateIcon {
                            id: candMedia
                            iconId: "media"
                            iconSrc: "qrc:/assets/apps/icon_all_media.png"
                            title: "Media"
                        }

                        CandidateIcon {
                            id: candDrvm
                            iconId: "drvm"
                            iconSrc: "qrc:/assets/apps/icon_all_drvm.png"
                            title: "DRVM"
                        }

                        CandidateIcon {
                            id: candQuietmode
                            iconId: "quietmode"
                            iconSrc: "qrc:/assets/apps/icon_all_quietmode.png"
                            title: "Quiet mode"
                        }

                        CandidateIcon {
                            id: candSettings
                            iconId: "settings"
                            iconSrc: "qrc:/assets/apps/icon_all_settings.png"
                            title: "Settings"
                        }
                    }
                }

                // PAGE 2: Manual (Matching User's Photo!)
                Item {
                    id: page2Item
                    width: candidateGridArea.width
                    height: candidateGridArea.height
                    x: candidateGridArea.width

                    Grid {
                        anchors.centerIn: parent
                        columns: 4
                        rowSpacing: 34
                        columnSpacing: 36

                        // Row 1, Item 1: Manual
                        CandidateIcon {
                            id: candManual
                            iconId: "manual"
                            iconSrc: "qrc:/assets/apps/icon_all_manual.png"
                            title: "Manual"
                        }

                        // Empty spacer slots to maintain column alignment
                        Item { width: 190; height: 64 }
                        Item { width: 190; height: 64 }
                        Item { width: 190; height: 64 }
                    }
                }
            }

            // Left Chevron Arrow (Page 2 -> Page 1)
            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 38
                height: 52
                radius: 6
                color: leftArrowMouse.pressed ? "#1E88E5" : (leftArrowMouse.containsMouse ? "#2A3C50" : Qt.rgba(0.08, 0.14, 0.22, 0.7))
                border.color: leftArrowMouse.pressed ? "#66D9FF" : "#3F5468"
                border.width: 1
                visible: root.currentPage === 1
                z: 15

                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "❮"
                    color: "#FFFFFF"
                    font.pixelSize: 20
                    scale: leftArrowMouse.pressed ? 0.9 : 1.0
                }

                MouseArea {
                    id: leftArrowMouse
                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.currentPage = 0
                }
            }

            // Right Chevron Arrow (Page 1 -> Page 2)
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 38
                height: 52
                radius: 6
                color: rightArrowMouse.pressed ? "#1E88E5" : (rightArrowMouse.containsMouse ? "#2A3C50" : Qt.rgba(0.08, 0.14, 0.22, 0.7))
                border.color: rightArrowMouse.pressed ? "#66D9FF" : "#3F5468"
                border.width: 1
                visible: root.currentPage === 0
                z: 15

                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "❯"
                    color: "#FFFFFF"
                    font.pixelSize: 20
                    scale: rightArrowMouse.pressed ? 0.9 : 1.0
                }

                MouseArea {
                    id: rightArrowMouse
                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.currentPage = 1
                }
            }

            // Pagination Indicator (• -)
            Row {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                z: 20

                // Dot 1
                Rectangle {
                    width: root.currentPage === 0 ? 32 : 14
                    height: 5
                    radius: 2.5
                    color: root.currentPage === 0 ? "#FFFFFF" : "#4A5463"

                    Behavior on width { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -12
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentPage = 0
                    }
                }

                // Dot 2
                Rectangle {
                    width: root.currentPage === 1 ? 32 : 14
                    height: 5
                    radius: 2.5
                    color: root.currentPage === 1 ? "#FFFFFF" : "#4A5463"

                    Behavior on width { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -12
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentPage = 1
                    }
                }
            }
        }

        // ====================================================
        // 4. LOWER DOCK CUSTOMIZATION BOX (Electric Blue Outline!)
        // ====================================================
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 124

            Rectangle {
                id: dockBorderBox
                anchors.centerIn: parent
                width: parent.width - 48
                height: 106
                color: "#070D14"
                border.color: root.isDragging ? "#68C6FF" : "#389BFF"
                border.width: root.isDragging ? 2.5 : 2
                radius: 4

                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Repeater {
                        model: root.dockIcons

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            property bool isDropTarget: root.isDragging && root.dragTargetSlotIndex === index
                            property bool isSelected: root.selectedDockIndex === index
                            property bool isCandidateTarget: root.selectedCandidateId !== ""

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 4
                                color: isDropTarget ? Qt.rgba(0.22, 0.75, 1.0, 0.40) : (isSelected ? Qt.rgba(0.22, 0.61, 1.0, 0.25) : (isCandidateTarget ? Qt.rgba(0.0, 0.72, 1.0, 0.15) : (slotMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")))
                                border.color: isDropTarget ? "#00E5FF" : (isSelected ? "#80D8FF" : (isCandidateTarget ? "#00B8FF" : "transparent"))
                                border.width: isDropTarget ? 2.5 : ((isSelected || isCandidateTarget) ? 1.5 : 0)
                                radius: 4

                                scale: isDropTarget ? 1.04 : (isCandidateTarget ? 1.02 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 120 } }
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Row {
                                    id: slotContentRow
                                    anchors.centerIn: parent
                                    spacing: 16
                                    transformOrigin: Item.Center

                                    SequentialAnimation {
                                        id: slotChangeAnim
                                        ParallelAnimation {
                                            NumberAnimation { target: slotContentRow; property: "scale"; from: 1.0; to: 0.65; duration: 90; easing.type: Easing.InQuad }
                                            NumberAnimation { target: slotContentRow; property: "opacity"; from: 1.0; to: 0.3; duration: 90 }
                                        }
                                        ParallelAnimation {
                                            NumberAnimation { target: slotContentRow; property: "scale"; from: 0.65; to: 1.0; duration: 220; easing.type: Easing.OutBack }
                                            NumberAnimation { target: slotContentRow; property: "opacity"; from: 0.3; to: 1.0; duration: 220 }
                                        }
                                    }

                                    Connections {
                                        target: systemController
                                        function onDockIconsChanged() {
                                            slotChangeAnim.restart()
                                        }
                                    }

                                    Image {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 44
                                        height: 44
                                        source: root.getIconSource(modelData)
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        mipmap: true
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.getIconLabel(modelData)
                                        color: isDropTarget ? "#80D8FF" : "#FFFFFF"
                                        font.pixelSize: 22
                                        font.weight: Font.DemiBold
                                        font.family: "Roboto"
                                    }
                                }

                                MouseArea {
                                    id: slotMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.selectedCandidateId !== "") {
                                            console.log("[EditHomeIcons] Placing candidate", root.selectedCandidateId, "into slot", index)
                                            systemController.updateDockIcon(index, root.selectedCandidateId)
                                            root.selectedCandidateId = ""
                                            root.selectedDockIndex = -1
                                        } else if (root.selectedDockIndex === index) {
                                            root.selectedDockIndex = -1
                                        } else {
                                            root.selectedDockIndex = index
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ========================================================
    // 5. DRAGGING GHOST AVATAR (Follows cursor smoothly)
    // ========================================================
    Rectangle {
        id: dragAvatar
        visible: root.isDragging
        width: 170
        height: 60
        radius: 8
        color: Qt.rgba(0.05, 0.15, 0.28, 0.90)
        border.color: "#389BFF"
        border.width: 2
        z: 999

        Row {
            anchors.centerIn: parent
            spacing: 12

            Image {
                anchors.verticalCenter: parent.verticalCenter
                width: 38
                height: 38
                source: root.draggedIconSrc
                fillMode: Image.PreserveAspectFit
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.draggedIconTitle
                color: "#FFFFFF"
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }
        }
    }

    ParallelAnimation {
        id: avatarFlyBackAnim
        property real toX: 0
        property real toY: 0
        NumberAnimation { target: dragAvatar; property: "x"; to: avatarFlyBackAnim.toX; duration: 240; easing.type: Easing.OutCubic }
        NumberAnimation { target: dragAvatar; property: "y"; to: avatarFlyBackAnim.toY; duration: 240; easing.type: Easing.OutCubic }
        NumberAnimation { target: dragAvatar; property: "opacity"; from: 1.0; to: 0.0; duration: 240 }
        onFinished: {
            root.isDragging = false
            root.dragTargetSlotIndex = -1
            dragAvatar.opacity = 1.0
        }
        onStopped: {
            root.isDragging = false
            root.dragTargetSlotIndex = -1
            dragAvatar.opacity = 1.0
        }
    }

    // ========================================================
    // 5B. FLYING ICONS ON DEFAULT RESET (Runs in Background, z: 50)
    // Animated transit from upper menu down into actual dock slots
    // ========================================================
    Timer {
        id: flightOverlayTimer
        interval: 1100
    }

    Timer {
        id: defaultSettleTimer
        interval: 850
        onTriggered: {
            systemController.resetDockIcons()
            systemController.resetWidgetsToDefault()
            root.selectedDockIndex = -1
        }
    }

    Item {
        id: flightOverlay
        anchors.fill: parent
        z: 50
        visible: flightOverlayTimer.running

        Repeater {
            id: flyRepeater
            model: 8

            Rectangle {
                id: flyAvatar
                width: 176
                height: 56
                radius: 8
                color: Qt.rgba(0.06, 0.18, 0.32, 0.95)
                border.color: "#389BFF"
                border.width: 2
                visible: false

                property string iconSrc: ""
                property string iconTitle: ""

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 38
                        height: 38
                        source: flyAvatar.iconSrc
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: flyAvatar.iconTitle
                        color: "#FFFFFF"
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }
                }

                ParallelAnimation {
                    id: anim
                    property real startX: 0
                    property real startY: 0
                    property real endX: 0
                    property real endY: 0

                    NumberAnimation {
                        target: flyAvatar
                        property: "x"
                        from: anim.startX
                        to: anim.endX
                        duration: 440
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        target: flyAvatar
                        property: "y"
                        from: anim.startY
                        to: anim.endY
                        duration: 440
                        easing.type: Easing.OutBack
                    }

                    NumberAnimation {
                        target: flyAvatar
                        property: "scale"
                        from: 0.85
                        to: 1.05
                        duration: 220
                        easing.type: Easing.OutQuad
                    }

                    NumberAnimation {
                        target: flyAvatar
                        property: "opacity"
                        from: 0.3
                        to: 1.0
                        duration: 150
                    }

                    onFinished: {
                        flyAvatar.visible = false
                    }
                }

                Timer {
                    id: delayTimer
                    onTriggered: anim.restart()
                }

                function launch(src, title, fromX, fromY, toX, toY, delayMs) {
                    flyAvatar.iconSrc = src
                    flyAvatar.iconTitle = title
                    flyAvatar.x = fromX - flyAvatar.width / 2
                    flyAvatar.y = fromY - flyAvatar.height / 2
                    flyAvatar.scale = 0.85
                    flyAvatar.opacity = 0.3
                    flyAvatar.visible = true
                    anim.startX = fromX - flyAvatar.width / 2
                    anim.startY = fromY - flyAvatar.height / 2
                    anim.endX = toX - flyAvatar.width / 2
                    anim.endY = toY - flyAvatar.height / 2

                    if (delayMs > 0) {
                        delayTimer.interval = delayMs
                        delayTimer.restart()
                    } else {
                        anim.restart()
                    }
                }
            }
        }
    }

    // ========================================================
    // ========================================================
    // 6. FACTORY RESET MODAL DIALOG (Focused in foreground, z: 100)
    // Seamlessly handles Yes/No confirmation & Factory Restart Done
    // while the moving animation runs in the background behind it
    // ========================================================
    Rectangle {
        id: resetModal
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.52)
        visible: false
        z: 100

        Behavior on opacity { NumberAnimation { duration: 180 } }

        Timer {
            id: modalDismissTimer
            interval: 1800
            onTriggered: resetModal.visible = false
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (root.isResetDone) {
                    resetModal.visible = false
                }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 780
            height: root.isResetDone ? 230 : 280
            color: "#121824"
            border.color: "#2C394C"
            border.width: 1.5
            radius: 6

            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            // Drop shadow glow
            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                z: -1
                color: "#40000000"
                radius: 8
            }

            Column {
                anchors.centerIn: parent
                spacing: 18
                width: parent.width - 60

                // ----------------------------------------------------
                // BADGE ICON (? for confirm, (i) for factory reset done)
                // ----------------------------------------------------
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 52
                    height: 52
                    radius: 26
                    color: "#3CA9F8"

                    Text {
                        anchors.centerIn: parent
                        text: root.isResetDone ? "i" : "?"
                        color: "#FFFFFF"
                        font.pixelSize: 32
                        font.weight: Font.Bold
                    }
                }

                // ----------------------------------------------------
                // MAIN TITLE / PROMPT
                // ----------------------------------------------------
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.isResetDone 
                          ? "Factory settings successfully restored."
                          : "Do you want to reset the Home screen settings to factory defaults?"
                    color: "#FFFFFF"
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                    horizontalAlignment: Text.AlignHCenter
                }

                // ----------------------------------------------------
                // BUTTONS (YES / NO) - Visible during confirmation
                // ----------------------------------------------------
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 24
                    visible: !root.isResetDone

                    // Yes Button
                    Rectangle {
                        width: 170
                        height: 48
                        color: yesMouse.pressed ? "#1E88E5" : (yesMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: yesMouse.pressed ? "#66D9FF" : "#3F74A3"
                        border.width: 1
                        radius: 4

                        Text {
                            anchors.centerIn: parent
                            text: "Yes"
                            color: "#FFFFFF"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: yesMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[EditHomeIcons] Yes clicked -> Transitioning to factory restart done and flying icons in background")
                                root.isResetDone = true
                                root.currentPage = 0
                                root.triggerDefaultFlyAnimation()
                                modalDismissTimer.restart()
                            }
                        }
                    }

                    // No Button
                    Rectangle {
                        width: 170
                        height: 48
                        color: noMouse.pressed ? "#1E88E5" : (noMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                        border.color: noMouse.pressed ? "#66D9FF" : "#3F74A3"
                        border.width: 1
                        radius: 4

                        Text {
                            anchors.centerIn: parent
                            text: "No"
                            color: "#FFFFFF"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: noMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                resetModal.visible = false
                            }
                        }
                    }
                }
            }
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
            case "radio": return "Radio"
            case "drvm": return "DRVM"
            case "quietmode": return "Quiet mode"
            case "manual": return "Manual"
            default: return iconId
        }
    }

    // Candidate Icon Component with DRAG & DROP support and Return Animation
    component CandidateIcon: Item {
        id: candidateRoot
        property string iconId: ""
        property string iconSrc: ""
        property string title: ""
        readonly property bool inDock: (root.dockIcons && root.dockIcons.indexOf(candidateRoot.iconId) !== -1)
        readonly property bool isSelected: (root.selectedCandidateId === candidateRoot.iconId)

        width: 190
        height: 64
        scale: inDock ? 0.93 : (candidateRoot.isSelected ? 1.05 : (candMouse.pressed ? 0.96 : 1.0))
        opacity: inDock ? 0.35 : (candMouse.pressed ? 0.75 : 1.0)

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        // Touch card background highlight
        Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            radius: 8
            color: candidateRoot.isSelected ? Qt.rgba(0.0, 0.72, 1.0, 0.20) : (candMouse.pressed ? "#162334" : (candMouse.containsMouse ? "#0D1622" : "transparent"))
            border.color: candidateRoot.isSelected ? "#00E5FF" : (candMouse.pressed ? "#2C80D0" : (candMouse.containsMouse ? "#1E2F44" : "transparent"))
            border.width: candidateRoot.isSelected ? 2 : 1
            visible: !candidateRoot.inDock
            Behavior on color { ColorAnimation { duration: 100 } }
            Behavior on border.color { ColorAnimation { duration: 100 } }
        }

        // Bounce back into original place when returning from dock
        property real returnBounceY: 0
        onInDockChanged: {
            if (!inDock) {
                returnBounceAnim.restart()
            }
        }

        SequentialAnimation {
            id: returnBounceAnim
            NumberAnimation { target: candidateRoot; property: "returnBounceY"; from: 18; to: -4; duration: 200; easing.type: Easing.OutQuad }
            NumberAnimation { target: candidateRoot; property: "returnBounceY"; to: 0; duration: 160; easing.type: Easing.OutBack }
        }

        Row {
            anchors.fill: parent
            anchors.topMargin: candidateRoot.returnBounceY
            spacing: 14

            Image {
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                height: 44
                source: candidateRoot.iconSrc
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: candidateRoot.title
                color: candidateRoot.isSelected ? "#80D8FF" : "#FFFFFF"
                font.pixelSize: 20
                font.weight: Font.DemiBold
                font.family: "Roboto"
            }
        }

        MouseArea {
            id: candMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: candidateRoot.inDock ? Qt.ArrowCursor : Qt.PointingHandCursor
            property real startX: 0
            property real startY: 0
            property bool isSwiping: false
            property bool isDraggingToDock: false

            onPressed: function(mouse) {
                startX = mouse.x
                startY = mouse.y
                isSwiping = false
                isDraggingToDock = false
            }

            onPositionChanged: function(mouse) {
                if (!candMouse.pressed) return
                var dx = mouse.x - startX
                var dy = mouse.y - startY

                if (isDraggingToDock) {
                    var pt = mapToItem(root, mouse.x, mouse.y)
                    root.updateDragging(pt.x, pt.y)
                    return
                }

                if (isSwiping) {
                    if ((root.currentPage === 0 && dx > 0) || (root.currentPage === 1 && dx < 0)) {
                        root.pagesSlideOffset = dx * 0.35
                    } else {
                        root.pagesSlideOffset = dx
                    }
                    return
                }

                // Detect horizontal swipe across pages first (preventing accidental icon drag)
                if (Math.abs(dx) > 15 && Math.abs(dx) > Math.abs(dy)) {
                    isSwiping = true
                    root.isSwipingPages = true
                    if ((root.currentPage === 0 && dx > 0) || (root.currentPage === 1 && dx < 0)) {
                        root.pagesSlideOffset = dx * 0.35
                    } else {
                        root.pagesSlideOffset = dx
                    }
                    return
                }

                // Only if deliberate downward motion towards dock box, start drag
                if (!candidateRoot.inDock && dy > 30 && dy > Math.abs(dx) * 1.5) {
                    isDraggingToDock = true
                    var ptStart = mapToItem(root, mouse.x, mouse.y)
                    root.startDragging(ptStart.x, ptStart.y, candidateRoot.iconId, candidateRoot.iconSrc, candidateRoot.title, candidateRoot)
                }
            }

            onReleased: function(mouse) {
                var dx = mouse.x - startX
                var dy = mouse.y - startY

                if (isDraggingToDock) {
                    var pt = mapToItem(root, mouse.x, mouse.y)
                    root.finishDragging(pt.x, pt.y)
                    isDraggingToDock = false
                    return
                }

                if (isSwiping) {
                    root.isSwipingPages = false
                    if (dx < -50 && root.currentPage === 0) {
                        root.currentPage = 1
                    } else if (dx > 50 && root.currentPage === 1) {
                        root.currentPage = 0
                    }
                    root.pagesSlideOffset = 0
                    isSwiping = false
                    return
                }

                // Clean touch tap (< 18px movement)
                if (Math.abs(dx) < 18 && Math.abs(dy) < 18) {
                    if (candidateRoot.inDock) {
                        // Highlight whichever dock slot currently contains this icon
                        var foundIdx = root.dockIcons ? root.dockIcons.indexOf(candidateRoot.iconId) : -1
                        if (foundIdx >= 0) {
                            root.selectedDockIndex = foundIdx
                        }
                    } else if (root.selectedDockIndex >= 0) {
                        // Place into selected dock slot!
                        console.log("[EditHomeIcons] Tapped to replace slot", root.selectedDockIndex, "with", candidateRoot.iconId)
                        systemController.updateDockIcon(root.selectedDockIndex, candidateRoot.iconId)
                        root.selectedDockIndex = -1
                        root.selectedCandidateId = ""
                    } else if (root.selectedCandidateId === candidateRoot.iconId) {
                        // Toggle candidate selection off
                        root.selectedCandidateId = ""
                    } else {
                        // Select candidate icon for assignment
                        console.log("[EditHomeIcons] Candidate selected:", candidateRoot.iconId)
                        root.selectedCandidateId = candidateRoot.iconId
                    }
                }
            }

            onCanceled: function() {
                if (isDraggingToDock) {
                    root.finishDragging(0, 0)
                    isDraggingToDock = false
                }
                if (isSwiping) {
                    root.isSwipingPages = false
                    root.pagesSlideOffset = 0
                    isSwiping = false
                }
            }

            onWheel: function(wheel) {
                if (wheel.angleDelta.x < -30 || wheel.angleDelta.y < -30) {
                    root.currentPage = 1
                } else if (wheel.angleDelta.x > 30 || wheel.angleDelta.y > 30) {
                    root.currentPage = 0
                }
            }
        }
    }
}
