/**
 * ============================================================================
 * Project: Apex IVI - Automotive In-Vehicle Infotainment System
 * Developer: Sk Rehan Ahamed
 * File: Main.qml
 * ============================================================================
 */

import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import "components/screens"
import "components/navigation"
import "components/icons"
import "components"

Window {
    id: mainWindow
    visible: true
    width: 1280
    height: 720
    minimumWidth: 1024
    minimumHeight: 600
    title: "Apex IVI - D-Audio System"
    color: "#000000"

    // ====================================================
    // PHYSICAL BUTTON EMULATION VIA KEYBOARD SHORTCUTS
    // Key '9': Emulate physical Play/Pause toggle
    // Key '0': Emulate physical Stop button
    // ====================================================
    Shortcut {
        sequence: "9"
        onActivated: {
            console.log("[Apex IVI] Physical Key 9 pressed -> Toggle Play/Pause")
            systemController.toggleRadio()
        }
    }

    Shortcut {
        sequence: "0"
        onActivated: {
            console.log("[Apex IVI] Physical Key 0 pressed -> Current screen:", systemController.currentScreen)
            if (systemController.currentScreen === "home" || systemController.currentScreen === "all_menus") {
                console.log("[Apex IVI] On main screen -> Turning off media completely")
                systemController.turnOffMedia()
            } else {
                console.log("[Apex IVI] Inside media screen -> Stopping playback only")
                systemController.stopRadio()
            }
        }
    }

    Shortcut {
        sequence: "Up"
        onActivated: {
            console.log("[Apex IVI] Physical Up Arrow pressed -> Volume Up")
            systemController.increaseVolume()
            mainWindow.showVolumeBar()
        }
    }

    Shortcut {
        sequence: "Down"
        onActivated: {
            console.log("[Apex IVI] Physical Down Arrow pressed -> Volume Down")
            systemController.decreaseVolume()
            mainWindow.showVolumeBar()
        }
    }

    Shortcut {
        sequence: "R"
        onActivated: {
            console.log("[Apex IVI] Key R pressed -> Toggle Reverse Gear")
            mainWindow.toggleReverseGear()
        }
    }

    Shortcut {
        sequence: "+"
        onActivated: {
            systemController.increaseVolume()
            mainWindow.showVolumeBar()
        }
    }

    Shortcut {
        sequence: "="
        onActivated: {
            systemController.increaseVolume()
            mainWindow.showVolumeBar()
        }
    }

    Shortcut {
        sequence: "-"
        onActivated: {
            systemController.decreaseVolume()
            mainWindow.showVolumeBar()
        }
    }

    // ====================================================
    // 1. TOP STATUS BAR (FIXED & STATIC - NEVER SLIDES)
    // ====================================================
    TopStatusBar {
        id: persistentTopBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 64
        z: 10
        visible: (systemController.currentScreen !== "drvm")

        onMenuClicked: {
            if (systemController.currentScreen === "home") {
                homeMenuDropdown.visible = !homeMenuDropdown.visible
                persistentTopBar.menuOpen = homeMenuDropdown.visible
                console.log("[Apex IVI] Home Menu toggled:", homeMenuDropdown.visible)
            } else {
                mainWindow.previousScreenBeforeSettings = systemController.currentScreen
                mainWindow.resetAllScreensToDefault()
                systemController.navigateTo("settings")
            }
        }

        onHomeClicked: {
            console.log("[Apex IVI] Top Home Clicked -> Returning to Home")
            mainWindow.resetAllScreensToDefault()
            systemController.navigateTo("home")
        }
    }

    property string previousScreenBeforeManual: "home"
    property string previousScreenBeforePhone: "home"
    property string previousScreenBeforeEditHome: "home"
    property string previousScreenBeforeQuietMode: "all_menus"
    property string previousScreenBeforeMedia: "home"
    property string previousScreenBeforeRadio: "home"
    property string previousScreenBeforeSound: "settings"
    property string previousScreenBeforeSettings: "home"
    property string previousScreenBeforeBt: "device_connection"
    property string previousScreenBeforeVoiceMemo: "home"
    property string previousScreenBeforeDrvm: "home"
    property string previousScreenBeforeReverse: "home"
    property string previousScreenBeforeDisplay: "settings"
    property bool volumeBarVisible: false
    property string incomingQuickReplyFeedback: ""

    function showVolumeBar() {
        volumeBarVisible = true
        volumeDismissTimer.restart()
    }

    Timer {
        id: volumeDismissTimer
        interval: 3000
        repeat: false
        onTriggered: {
            mainWindow.volumeBarVisible = false
        }
    }

    Timer {
        id: quickReplyFeedbackTimer
        interval: 5000
        repeat: false
        onTriggered: mainWindow.incomingQuickReplyFeedback = ""
    }

    Connections {
        target: systemController
        function onVolumeChanged() {
            mainWindow.showVolumeBar()
        }
    }

    function toggleReverseGear() {
        if (!systemController.isReverseGear) {
            console.log("[Apex IVI] Shifting to Reverse Gear -> Opening Reverse Camera")
            mainWindow.previousScreenBeforeReverse = systemController.currentScreen
            systemController.isReverseGear = true
            systemController.navigateTo("drvm")
        } else {
            console.log("[Apex IVI] Shifting out of Reverse Gear -> Returning to previous screen")
            systemController.isReverseGear = false
            if (mainWindow.previousScreenBeforeReverse === "drvm") {
                // Return to clean DRVM view
                systemController.navigateTo("drvm")
            } else if (mainWindow.previousScreenBeforeReverse && mainWindow.previousScreenBeforeReverse !== "") {
                systemController.navigateTo(mainWindow.previousScreenBeforeReverse)
            } else {
                systemController.navigateTo("home")
            }
        }
    }

    function openDrvmScreen(fromScreen) {
        mainWindow.previousScreenBeforeDrvm = fromScreen ? fromScreen : systemController.currentScreen
        systemController.isReverseGear = false
        systemController.navigateTo("drvm")
    }

    function resetAllScreensToDefault() {
        console.log("[Apex IVI] Direct navigation to Menu -> Resetting all pages to default")
        systemController.isReverseGear = false
        if (typeof deviceConnScreen !== "undefined" && typeof deviceConnScreen.resetToDefault === "function") deviceConnScreen.resetToDefault()
        if (typeof btConnScreen !== "undefined" && typeof btConnScreen.resetToDefault === "function") btConnScreen.resetToDefault()
        if (typeof displaySettingsScreen !== "undefined" && typeof displaySettingsScreen.resetToDefault === "function") displaySettingsScreen.resetToDefault()
        if (typeof soundSettingsScreen !== "undefined" && typeof soundSettingsScreen.resetToDefault === "function") soundSettingsScreen.resetToDefault()
        if (typeof buttonSettingsScreen !== "undefined" && typeof buttonSettingsScreen.resetToDefault === "function") buttonSettingsScreen.resetToDefault()
        if (typeof generalSettingsScreen !== "undefined" && typeof generalSettingsScreen.resetToDefault === "function") generalSettingsScreen.resetToDefault()
        if (typeof allMenusScreen !== "undefined" && typeof allMenusScreen.resetToDefault === "function") allMenusScreen.resetToDefault()
        if (typeof editHomeIconsScreen !== "undefined" && typeof editHomeIconsScreen.resetToDefault === "function") editHomeIconsScreen.resetToDefault()
        if (typeof phoneScreen !== "undefined" && typeof phoneScreen.resetToDefault === "function") phoneScreen.resetToDefault()
        if (typeof editWidgetScreen !== "undefined" && typeof editWidgetScreen.resetToDefault === "function") editWidgetScreen.resetToDefault()
        if (typeof quietModeScreen !== "undefined" && typeof quietModeScreen.resetToDefault === "function") quietModeScreen.resetToDefault()
        if (typeof mediaSelectScreen !== "undefined" && typeof mediaSelectScreen.resetToDefault === "function") mediaSelectScreen.resetToDefault()
        if (typeof voiceMemoScreen !== "undefined" && typeof voiceMemoScreen.resetToDefault === "function") voiceMemoScreen.resetToDefault()
        if (typeof radioScreen !== "undefined" && typeof radioScreen.resetToDefault === "function") radioScreen.resetToDefault()
        phoneProjectionDialog.visible = false
        noPhoneDialog.visible = false
        homeMenuDropdown.visible = false
    }

    function handlePhoneNavigation(fromScreen) {
        if (fromScreen) {
            mainWindow.previousScreenBeforePhone = fromScreen
        } else if (systemController.currentScreen === "all_menus" || systemController.currentScreen === "home") {
            mainWindow.previousScreenBeforePhone = systemController.currentScreen
        }

        var isConnected = systemController.hasHandsFreeDevice
        if (!isConnected) {
            console.log("[Main] Phone app requested but no hands-free phone is connected -> displaying noPhoneDialog")
            noPhoneDialog.visible = true
            return
        }

        systemController.navigateTo("phone")
    }

    function handleMediaNavigation(fromScreen) {
        if (fromScreen) {
            mainWindow.previousScreenBeforeMedia = fromScreen
        } else if (systemController.currentScreen === "all_menus" || systemController.currentScreen === "home") {
            mainWindow.previousScreenBeforeMedia = systemController.currentScreen
        }

        // When accessed from All Menus -> ALWAYS show Media Selection screen (FM, AM, Bluetooth, USB, etc.)
        if (fromScreen === "all_menus" || mainWindow.previousScreenBeforeMedia === "all_menus") {
            console.log("[Apex IVI] Navigating to Media Selection from All Menus")
            systemController.navigateTo("media_select")
            return
        }

        // On Main Screen (Home):
        // Only show Media Selection once when starting media (if no media is currently active)
        // If media is already active/playing, go directly to the active media player screen
        if (systemController.selectedMediaSource === "bluetooth" || systemController.selectedMediaSource === "usb") {
            systemController.navigateTo("bluetooth_audio")
        } else if (systemController.selectedMediaSource === "fm" || systemController.selectedMediaSource === "am") {
            mainWindow.previousScreenBeforeRadio = mainWindow.previousScreenBeforeMedia
            systemController.navigateTo("radio")
        } else {
            // When starting the media (no media selected/active yet), open the Media Selection Screen
            systemController.navigateTo("media_select")
        }
    }

    Connections {
        target: systemController
        function onScreenChanged() {
            homeMenuDropdown.visible = false
            persistentTopBar.menuOpen = false
            if (systemController.currentScreen !== "manual") {
                mainWindow.previousScreenBeforeManual = systemController.currentScreen
            }
            if (systemController.currentScreen === "home" || systemController.currentScreen === "all_menus") {
                mainWindow.resetAllScreensToDefault()
            } else if (systemController.currentScreen === "settings") {
                if (typeof deviceConnScreen !== "undefined" && typeof deviceConnScreen.resetToDefault === "function") deviceConnScreen.resetToDefault()
                if (typeof btConnScreen !== "undefined" && typeof btConnScreen.resetToDefault === "function") btConnScreen.resetToDefault()
                if (typeof displaySettingsScreen !== "undefined" && typeof displaySettingsScreen.resetToDefault === "function") displaySettingsScreen.resetToDefault()
                if (typeof soundSettingsScreen !== "undefined" && typeof soundSettingsScreen.resetToDefault === "function") soundSettingsScreen.resetToDefault()
                if (typeof buttonSettingsScreen !== "undefined" && typeof buttonSettingsScreen.resetToDefault === "function") buttonSettingsScreen.resetToDefault()
                if (typeof generalSettingsScreen !== "undefined" && typeof generalSettingsScreen.resetToDefault === "function") generalSettingsScreen.resetToDefault()
            }
        }

        function onBluetoothDeviceListChanged() {
            if (!systemController.hasHandsFreeDevice) {
                if (systemController.currentScreen === "phone") {
                    console.log("[Main] No HandsFree device connected while on Phone screen -> closing Phone and showing noPhoneDialog")
                    systemController.navigateTo(mainWindow.previousScreenBeforePhone || "home")
                    noPhoneDialog.visible = true
                }
            }
        }

        function onPhoneConnectionChanged() {
            if (!systemController.hasHandsFreeDevice) {
                if (systemController.currentScreen === "phone") {
                    console.log("[Main] Phone disconnected while on Phone screen -> closing Phone and showing noPhoneDialog")
                    systemController.navigateTo(mainWindow.previousScreenBeforePhone || "home")
                    noPhoneDialog.visible = true
                }
            }
        }

        function onBluetoothConnectionChanged() {
            if (!systemController.isBluetoothConnected || !systemController.hasHandsFreeDevice) {
                if (systemController.currentScreen === "phone") {
                    console.log("[Main] Bluetooth disconnected while on Phone screen -> closing Phone and showing noPhoneDialog")
                    systemController.navigateTo(mainWindow.previousScreenBeforePhone || "home")
                    noPhoneDialog.visible = true
                }
            }
        }

        function onPairingPromptChanged() {
            if (systemController.isPairingPromptActive) {
                if (systemController.currentScreen !== "bluetooth_connections") {
                    mainWindow.previousScreenBeforeBt = systemController.currentScreen
                    systemController.navigateTo("bluetooth_connections")
                }
            }
        }

        function onRemoteCallStarted(name, number, status) {
            if (status === "incoming") {
                incomingCallPopup.reset()
            }
        }

        function onRemoteCallStatusChanged(status) {
            if (status !== "incoming") {
                incomingCallPopup.reset()
            }
        }

        function onRemoteCallEnded() {
            incomingCallPopup.reset()
        }

        function onQuickReplyFinished(success, message) {
            incomingCallPopup.feedbackText = message
            mainWindow.incomingQuickReplyFeedback = message
            quickReplyFeedbackTimer.restart()
            if (!success) {
                incomingCallPopup.actionPending = false
            }
        }
    }

    // ====================================================
    // 2. MAIN SLIDING VIEWPORT (Below Top Bar)
    // ====================================================
    Item {
        id: screenViewport
        anchors.top: persistentTopBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_9) {
                console.log("[Apex IVI] Key 9 pressed -> Toggle Play/Pause")
                systemController.toggleRadio()
                event.accepted = true
            } else if (event.key === Qt.Key_0) {
                console.log("[Apex IVI] Key 0 pressed -> Current screen:", systemController.currentScreen)
                if (systemController.currentScreen === "home" || systemController.currentScreen === "all_menus") {
                    console.log("[Apex IVI] On main screen -> Turning off media completely")
                    systemController.turnOffMedia()
                } else {
                    console.log("[Apex IVI] Inside media screen -> Stopping playback only")
                    systemController.stopRadio()
                }
                event.accepted = true
            } else if (event.key === Qt.Key_Up) {
                console.log("[Apex IVI] Key Up pressed -> Volume Up")
                systemController.increaseVolume()
                mainWindow.showVolumeBar()
                event.accepted = true
            } else if (event.key === Qt.Key_Down) {
                console.log("[Apex IVI] Key Down pressed -> Volume Down")
                systemController.decreaseVolume()
                mainWindow.showVolumeBar()
                event.accepted = true
            } else if (event.key === Qt.Key_R) {
                console.log("[Apex IVI] Key R pressed -> Toggle Reverse Gear")
                mainWindow.toggleReverseGear()
                event.accepted = true
            }
        }

        // A. HOME CONTENT CONTAINER (Home Cards + Bottom Dock)
        ColumnLayout {
            id: homeContentContainer
            width: parent.width
            height: parent.height
            spacing: 0

            // Slide out to the left whenever any sub-screen is active
            x: (systemController.currentScreen === "home") ? 0 : -parent.width

            Behavior on x {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }

            // Center Split Cards (Radio/Media Off | Phone Projection)
            HomeScreen {
                id: homeContent
                Layout.fillWidth: true
                Layout.fillHeight: true

                onRadioClicked: {
                    console.log("[Apex IVI] Radio clicked from Home Card -> Always opening FM/AM Radio")
                    mainWindow.previousScreenBeforeRadio = "home"
                    if (systemController.bluetoothPlaybackStatus === "playing" || systemController.selectedMediaSource === "bluetooth") {
                        systemController.selectMediaSource("fm")
                    } else if (systemController.selectedMediaSource !== "fm" && systemController.selectedMediaSource !== "am") {
                        systemController.selectMediaSource("fm")
                    }
                    systemController.navigateTo("radio")
                }

                onProjectionClicked: {
                    console.log("[Apex IVI] Projection clicked -> Showing Phone projection dialog")
                    phoneProjectionDialog.visible = true
                }
            }

            // Bottom Dock (All menus | Phone | Media | Settings)
            BottomDock {
                Layout.fillWidth: true
                Layout.preferredHeight: 104

                onAllMenusClicked: {
                    console.log("[Apex IVI] All Menus Clicked")
                    systemController.navigateTo("all_menus")
                }

                onPhoneClicked: {
                    console.log("[Apex IVI] Phone Clicked")
                    mainWindow.handlePhoneNavigation("home")
                }

                onMediaClicked: {
                    console.log("[Apex IVI] Media Clicked from Bottom Dock")
                    mainWindow.handleMediaNavigation("home")
                }

                onSettingsClicked: {
                    console.log("[Apex IVI] Settings Clicked -> Sliding into Settings")
                    mainWindow.previousScreenBeforeSettings = systemController.currentScreen
                    systemController.navigateTo("settings")
                }

                onProjectionClicked: {
                    console.log("[Apex IVI] Projection Clicked from Bottom Dock")
                    phoneProjectionDialog.visible = true
                }

                onRadioClicked: {
                    console.log("[Apex IVI] Radio Clicked from Bottom Dock -> Always opening FM/AM Radio")
                    mainWindow.previousScreenBeforeRadio = "home"
                    if (systemController.bluetoothPlaybackStatus === "playing" || systemController.selectedMediaSource === "bluetooth") {
                        systemController.selectMediaSource("fm")
                    } else if (systemController.selectedMediaSource !== "fm" && systemController.selectedMediaSource !== "am") {
                        systemController.selectMediaSource("fm")
                    }
                    systemController.navigateTo("radio")
                }

                onManualClicked: {
                    console.log("[Apex IVI] Manual Clicked from Bottom Dock")
                    mainWindow.previousScreenBeforeManual = "home"
                    systemController.navigateTo("manual")
                }

                onVoiceMemoClicked: {
                    console.log("[Apex IVI] Voice memo Clicked from Bottom Dock")
                    mainWindow.previousScreenBeforeVoiceMemo = systemController.currentScreen
                    systemController.navigateTo("voice_memo")
                }

                onDrvmClicked: {
                    console.log("[Apex IVI] DRVM Clicked from Bottom Dock")
                    mainWindow.openDrvmScreen("home")
                }

                onQuietModeClicked: {
                    console.log("[Apex IVI] Quiet mode Clicked from Bottom Dock")
                    mainWindow.previousScreenBeforeQuietMode = systemController.currentScreen
                    systemController.navigateTo("quiet_mode")
                }
            }
        }

        // B. ALL MENUS SCREEN (Slides in sideways from right to left)
        AllMenusScreen {
            id: allMenusScreen
            width: parent.width
            height: parent.height

            x: {
                if (systemController.currentScreen === "all_menus") return 0
                if (systemController.currentScreen === "home") return parent.width
                if (systemController.currentScreen === "phone") {
                    return (mainWindow.previousScreenBeforePhone === "all_menus") ? -parent.width : parent.width
                }
                if (systemController.currentScreen === "manual") {
                    return (mainWindow.previousScreenBeforeManual === "all_menus") ? -parent.width : parent.width
                }
                if (systemController.currentScreen === "edit_home_icons") {
                    return (mainWindow.previousScreenBeforeEditHome === "all_menus") ? -parent.width : parent.width
                }
                if (systemController.currentScreen === "quiet_mode") {
                    return (mainWindow.previousScreenBeforeQuietMode === "all_menus") ? -parent.width : parent.width
                }
                if (systemController.currentScreen === "media_select") {
                    return (mainWindow.previousScreenBeforeMedia === "all_menus") ? -parent.width : parent.width
                }
                if (systemController.currentScreen === "radio") {
                    return (mainWindow.previousScreenBeforeRadio === "all_menus") ? -parent.width : parent.width
                }
                if (systemController.currentScreen === "voice_memo") {
                    return (mainWindow.previousScreenBeforeVoiceMemo === "all_menus") ? -parent.width : parent.width
                }
                if (systemController.currentScreen === "drvm") {
                    return (mainWindow.previousScreenBeforeDrvm === "all_menus" || mainWindow.previousScreenBeforeReverse === "all_menus") ? -parent.width : parent.width
                }
                if (systemController.currentScreen === "settings" ||
                    systemController.currentScreen === "device_connection" ||
                    systemController.currentScreen === "bluetooth_connections" ||
                    systemController.currentScreen === "sound_settings" ||
                    systemController.currentScreen === "display_settings" ||
                    systemController.currentScreen === "button_settings" ||
                    systemController.currentScreen === "general_settings" ||
                    systemController.currentScreen === "rearrange_settings" ||
                    systemController.currentScreen === "media") {
                    return -parent.width
                }
                return parent.width
            }

            Behavior on x {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }

            onBackToHomeClicked: {
                console.log("[Apex IVI] Back from All Menus -> Sliding out to right")
                systemController.navigateTo("home")
            }

            onSettingsClicked: {
                console.log("[Apex IVI] Settings clicked from All Menus -> Sliding into Settings")
                systemController.navigateTo("settings")
            }

            onPhoneClicked: {
                console.log("[Apex IVI] Phone clicked from All Menus")
                mainWindow.handlePhoneNavigation("all_menus")
            }

            onProjectionClicked: {
                console.log("[Apex IVI] Projection clicked from All Menus -> Showing Phone projection dialog")
                phoneProjectionDialog.visible = true
            }

            onRadioClicked: {
                console.log("[Apex IVI] FM/AM clicked from All Menus -> Always opening FM/AM Radio")
                mainWindow.previousScreenBeforeRadio = "all_menus"
                if (systemController.bluetoothPlaybackStatus === "playing" || systemController.selectedMediaSource === "bluetooth") {
                    systemController.selectMediaSource("fm")
                } else if (systemController.selectedMediaSource !== "fm" && systemController.selectedMediaSource !== "am") {
                    systemController.selectMediaSource("fm")
                }
                systemController.navigateTo("radio")
            }

            onMediaClicked: {
                console.log("[Apex IVI] Media clicked from All Menus")
                mainWindow.handleMediaNavigation("all_menus")
            }

            onManualClicked: {
                console.log("[Apex IVI] Manual clicked from All Menus")
                mainWindow.previousScreenBeforeManual = "all_menus"
                systemController.navigateTo("manual")
            }

            onEditHomeIconsClicked: {
                console.log("[Apex IVI] Edit Home Icons clicked from All Menus")
                mainWindow.previousScreenBeforeEditHome = "all_menus"
                systemController.navigateTo("edit_home_icons")
            }

            onQuietModeClicked: {
                console.log("[Apex IVI] Quiet mode clicked from All Menus")
                mainWindow.previousScreenBeforeQuietMode = "all_menus"
                systemController.navigateTo("quiet_mode")
            }

            onVoiceMemoClicked: {
                console.log("[Apex IVI] Voice memo clicked from All Menus")
                mainWindow.previousScreenBeforeVoiceMemo = "all_menus"
                systemController.navigateTo("voice_memo")
            }

            onDrvmClicked: {
                console.log("[Apex IVI] DRVM clicked from All Menus")
                mainWindow.openDrvmScreen("all_menus")
            }
        }

        // C. SETTINGS SCREEN (Slides in sideways from right to left)
        SettingsScreen {
            id: settingsScreen
            width: parent.width
            height: parent.height
            z: 20
            enabled: (systemController.currentScreen === "settings")

            // Slide in from right when settings is active, stay if deeper screen opened, slide left when navigating deeper settings
            x: (systemController.currentScreen === "settings" ||
                (systemController.currentScreen === "manual" && mainWindow.previousScreenBeforeManual === "settings")) ? 0 :
               ((systemController.currentScreen === "device_connection" || systemController.currentScreen === "bluetooth_connections" || systemController.currentScreen === "sound_settings" || systemController.currentScreen === "display_settings" || systemController.currentScreen === "button_settings" || systemController.currentScreen === "general_settings" || systemController.currentScreen === "rearrange_settings") ? -parent.width : parent.width)

            Behavior on x {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }

            onBackToHomeClicked: {
                if (mainWindow.previousScreenBeforeSettings === "radio") {
                    console.log("[Apex IVI] Back from Settings -> Returning to Radio")
                    systemController.navigateTo("radio")
                } else {
                    console.log("[Apex IVI] Back to Home -> Sliding out to right")
                    systemController.navigateTo("home")
                }
            }

            onDeviceConnectionClicked: {
                console.log("[Apex IVI] Device Connection Clicked -> Sliding into Device Connection Settings")
                systemController.navigateTo("device_connection")
            }

            onSoundClicked: {
                console.log("[Apex IVI] Sound Clicked -> Sliding into Sound settings")
                mainWindow.previousScreenBeforeSound = "settings"
                systemController.navigateTo("sound_settings")
            }

            onDisplayClicked: {
                console.log("[Apex IVI] Display Clicked -> Sliding into Display settings")
                mainWindow.previousScreenBeforeDisplay = "settings"
                systemController.navigateTo("display_settings")
            }

            onButtonClicked: {
                console.log("[Apex IVI] Button Clicked -> Sliding into Button settings")
                systemController.navigateTo("button_settings")
            }

            onGeneralClicked: {
                console.log("[Apex IVI] General Clicked -> Sliding into General settings")
                systemController.navigateTo("general_settings")
            }

            onRearrangeIconsClicked: {
                console.log("[Apex IVI] Rearrange Icons clicked -> Sliding into Rearrange settings screen")
                systemController.navigateTo("rearrange_settings")
            }

            onManualClicked: {
                console.log("[Apex IVI] Manual clicked from Settings -> Opening Manual QR screen")
                mainWindow.previousScreenBeforeManual = "settings"
                systemController.navigateTo("manual")
            }
        }

        // B2. SOUND SETTINGS SCREEN (Slides in sideways from right to left)
        SoundSettingsScreen {
            id: soundSettingsScreen
            width: parent.width
            height: parent.height
            z: 20
            enabled: (systemController.currentScreen === "sound_settings")

            x: (systemController.currentScreen === "sound_settings" ||
                (systemController.currentScreen === "manual" && mainWindow.previousScreenBeforeManual === "sound_settings")) ? 0 : parent.width

            Behavior on x {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }

            onBackClicked: {
                console.log("[Apex IVI] Back from Sound Settings -> Returning to:", mainWindow.previousScreenBeforeSound)
                systemController.navigateTo(mainWindow.previousScreenBeforeSound)
            }

            onManualClicked: {
                console.log("[Apex IVI] Manual clicked from Sound Settings -> Opening Manual Screen")
                mainWindow.previousScreenBeforeManual = "sound_settings"
                systemController.navigateTo("manual")
            }
        }

        // B3. DISPLAY SETTINGS SCREEN (Slides in sideways from right to left)
        DisplaySettingsScreen {
            id: displaySettingsScreen
            width: parent.width
            height: parent.height

            x: (systemController.currentScreen === "display_settings") ? 0 : ((systemController.currentScreen === "manual" && mainWindow.previousScreenBeforeManual === "display_settings") ? -parent.width : parent.width)

            Behavior on x {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }

            onBackClicked: {
                console.log("[Apex IVI] Back from Display Settings -> Returning to:", mainWindow.previousScreenBeforeDisplay)
                systemController.navigateTo(mainWindow.previousScreenBeforeDisplay)
            }
        }

        // B4. BUTTON SETTINGS SCREEN (Slides in sideways from right to left)
        ButtonSettingsScreen {
            id: buttonSettingsScreen
            width: parent.width
            height: parent.height

            x: (systemController.currentScreen === "button_settings") ? 0 : ((systemController.currentScreen === "manual" && mainWindow.previousScreenBeforeManual === "button_settings") ? -parent.width : parent.width)

            Behavior on x {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }

            onBackClicked: {
                console.log("[Apex IVI] Back from Button Settings -> Sliding out to Settings")
                systemController.navigateTo("settings")
            }

            onManualClicked: {
                console.log("[Apex IVI] Manual clicked from Button Settings -> Opening Manual screen")
                mainWindow.previousScreenBeforeManual = "button_settings"
                systemController.navigateTo("manual")
            }
        }

        // B5. GENERAL SETTINGS SCREEN (Slides in sideways from right to left)
        GeneralSettingsScreen {
            id: generalSettingsScreen
            width: parent.width
            height: parent.height

            x: (systemController.currentScreen === "general_settings") ? 0 : ((systemController.currentScreen === "manual" && mainWindow.previousScreenBeforeManual === "general_settings") ? -parent.width : parent.width)

            Behavior on x {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }

            onBackClicked: {
                console.log("[Apex IVI] Back from General Settings -> Sliding out to Settings")
                systemController.navigateTo("settings")
            }

            onManualClicked: {
                console.log("[Apex IVI] Manual clicked from General Settings -> Opening Manual screen")
                mainWindow.previousScreenBeforeManual = "general_settings"
                systemController.navigateTo("manual")
            }
        }

        // B6. REARRANGE SETTINGS SCREEN (Slides in sideways from right to left)
        RearrangeSettingsScreen {
            id: rearrangeSettingsScreen
            width: parent.width
            height: parent.height

            x: (systemController.currentScreen === "rearrange_settings") ? 0 : parent.width

            Behavior on x {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }

            onBackClicked: {
                console.log("[Apex IVI] Back from Rearrange Settings -> Returning to Settings")
                systemController.navigateTo("settings")
            }
        }

        // C. DEVICE CONNECTION SCREEN (Slides in sideways from right to left)
        DeviceConnectionScreen {
            id: deviceConnScreen
            width: parent.width
            height: parent.height

            x: (systemController.currentScreen === "device_connection") ? 0 : ((systemController.currentScreen === "bluetooth_connections" || (systemController.currentScreen === "manual" && mainWindow.previousScreenBeforeManual === "device_connection")) ? -parent.width : parent.width)

            Behavior on x {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }

            onBackClicked: {
                console.log("[Apex IVI] Back to Settings -> Sliding out to right")
                systemController.navigateTo("settings")
            }

            onMenuClicked: {
                console.log("[Apex IVI] Menu clicked in Device Connection")
            }

            onBluetoothConnectionsClicked: {
                console.log("[Apex IVI] Bluetooth Connections Clicked -> Sliding into Bluetooth Connections")
                mainWindow.previousScreenBeforeBt = "device_connection"
                btConnScreen.returnScreenAfterAdd = "list"
                btConnScreen.currentView = "list"
                systemController.navigateTo("bluetooth_connections")
            }
        }

        // D. BLUETOOTH CONNECTIONS SCREEN (Slides in sideways from right to left)
        BluetoothConnectionsScreen {
            id: btConnScreen
            width: parent.width
            height: parent.height

            x: (systemController.currentScreen === "bluetooth_connections") ? 0 : parent.width

            Behavior on x {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }

            onBackClicked: {
                console.log("[Apex IVI] Back from Bluetooth Connections -> Returning to:", mainWindow.previousScreenBeforeBt)
                systemController.navigateTo(mainWindow.previousScreenBeforeBt)
            }

            onMenuClicked: {
                console.log("[Apex IVI] Menu clicked in Bluetooth Connections")
            }

            onDevicePairingCompleted: function(returnScreen) {
                console.log("[Apex IVI] Device pairing completed, returning to:", returnScreen)
                systemController.navigateTo(returnScreen)
            }
        }

        // E. EDIT WIDGET SCREEN (Slides in sideways from right to left)
        EditWidgetScreen {
            id: editWidgetScreen
            width: parent.width
            height: parent.height

            x: (systemController.currentScreen === "edit_widget") ? 0 : parent.width

            Behavior on x {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }

            onBackClicked: {
                console.log("[Apex IVI] Back from Edit Widget -> Sliding out to right")
                systemController.navigateTo("home")
            }
        }

        // F. PHONE SCREEN (Slides in sideways from right to left)
        PhoneScreen {
            id: phoneScreen
            width: parent.width
            height: parent.height

            x: (systemController.currentScreen === "phone") ? 0 : ((systemController.currentScreen === "manual" && mainWindow.previousScreenBeforeManual === "phone") ? -parent.width : parent.width)

            Behavior on x {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }


            onMenuClicked: {
                console.log("[Apex IVI] Menu clicked in Phone")
            }

            onAddDeviceRequested: {
                console.log("[Apex IVI] Add device requested from Phone screen")
                mainWindow.previousScreenBeforeBt = "phone"
                btConnScreen.returnScreenAfterAdd = "phone"
                systemController.navigateTo("bluetooth_connections")
                btConnScreen.startAddNewDeviceFlow()
            }

            onBluetoothSettingsRequested: {
                console.log("[Apex IVI] Bluetooth settings requested from Phone screen")
                mainWindow.previousScreenBeforeBt = "phone"
                btConnScreen.returnScreenAfterAdd = "phone"
                btConnScreen.currentView = "list"
                systemController.navigateTo("bluetooth_connections")
            }

            onBackClicked: {
                console.log("[Apex IVI] Back from Phone -> Sliding out to right, returning to:", mainWindow.previousScreenBeforePhone)
                systemController.navigateTo(mainWindow.previousScreenBeforePhone)
            }
        }

        // G. EDIT HOME ICONS SCREEN (Slides in sideways from right to left)
        EditHomeIconsScreen {
            id: editHomeIconsScreen
            width: parent.width
            height: parent.height

            x: (systemController.currentScreen === "edit_home_icons") ? 0 : ((systemController.currentScreen === "manual" && mainWindow.previousScreenBeforeManual === "edit_home_icons") ? -parent.width : parent.width)

            Behavior on x {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }

            onBackClicked: {
                console.log("[Apex IVI] Back from Edit Home Icons -> Sliding out to right, returning to:", mainWindow.previousScreenBeforeEditHome)
                systemController.navigateTo(mainWindow.previousScreenBeforeEditHome)
            }
        }

        // H. MANUAL SCREEN (Slides in sideways from right to left, matching photo media_1788548873253.png)
        ManualScreen {
            id: manualScreen
            width: parent.width
            height: parent.height
            z: 30
            enabled: (systemController.currentScreen === "manual")

            sectionTitle: (mainWindow.previousScreenBeforeManual === "voice_memo") ? "Voice memo" : ((mainWindow.previousScreenBeforeManual === "all_menus") ? "All menus" : ((mainWindow.previousScreenBeforeManual === "edit_home_icons") ? "Edit Home icons" : ((mainWindow.previousScreenBeforeManual === "phone") ? "Phone" : ((mainWindow.previousScreenBeforeManual === "sound_settings") ? "Sound" : ((mainWindow.previousScreenBeforeManual === "button_settings") ? "Button" : ((mainWindow.previousScreenBeforeManual === "general_settings") ? "General" : ((mainWindow.previousScreenBeforeManual === "quiet_mode") ? "Quiet mode" : ((mainWindow.previousScreenBeforeManual === "radio") ? "FM/AM" : ((mainWindow.previousScreenBeforeManual === "media_select") ? "Media" : ((mainWindow.previousScreenBeforeManual === "settings") ? "Settings" : "Home"))))))))))

            x: (systemController.currentScreen === "manual") ? 0 : parent.width

            Behavior on x {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }

            onBackClicked: {
                console.log("[Apex IVI] Back from Manual -> Sliding out to right, returning to:", mainWindow.previousScreenBeforeManual)
                systemController.navigateTo(mainWindow.previousScreenBeforeManual)
            }
        }

        // I. QUIET MODE SCREEN (Slides in sideways from right to left, matching photo)
        QuietModeScreen {
            id: quietModeScreen
            width: parent.width
            height: parent.height

            x: (systemController.currentScreen === "quiet_mode") ? 0 : ((systemController.currentScreen === "manual" && mainWindow.previousScreenBeforeManual === "quiet_mode") ? -parent.width : parent.width)

            Behavior on x {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }

            onBackClicked: {
                console.log("[Apex IVI] Back from Quiet Mode -> Sliding out to right, returning to:", mainWindow.previousScreenBeforeQuietMode)
                systemController.navigateTo(mainWindow.previousScreenBeforeQuietMode)
            }

            onManualClicked: {
                console.log("[Apex IVI] Manual clicked from Quiet Mode -> Opening Manual Screen")
                mainWindow.previousScreenBeforeManual = "quiet_mode"
                systemController.navigateTo("manual")
            }
        }

        // J. MEDIA SELECT SCREEN (Matching Genuine IVI Photo 1)
        MediaSelectScreen {
            id: mediaSelectScreen
            width: parent.width
            height: parent.height

            x: (systemController.currentScreen === "media_select") ? 0 : (((systemController.currentScreen === "radio" && mainWindow.previousScreenBeforeRadio === "media_select") || (systemController.currentScreen === "manual" && mainWindow.previousScreenBeforeManual === "media_select")) ? -parent.width : parent.width)

            Behavior on x {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }

            onCloseClicked: {
                console.log("[Apex IVI] Close clicked from Media Select -> Returning to:", mainWindow.previousScreenBeforeMedia)
                systemController.navigateTo(mainWindow.previousScreenBeforeMedia)
            }

            onFmSelected: {
                console.log("[Apex IVI] FM selected from Media Select -> Configuring media to FM and launching Radio")
                systemController.selectMediaSource("fm")
                mainWindow.previousScreenBeforeRadio = "media_select"
                systemController.navigateTo("radio")
            }

            onAmSelected: {
                console.log("[Apex IVI] AM selected from Media Select -> Configuring media to AM and launching Radio")
                systemController.selectMediaSource("am")
                mainWindow.previousScreenBeforeRadio = "media_select"
                systemController.navigateTo("radio")
            }

            onBluetoothSelected: {
                console.log("[Apex IVI] Bluetooth selected from Media Select -> Configuring media to Bluetooth and launching Bluetooth Audio")
                systemController.selectMediaSource("bluetooth")
                mainWindow.previousScreenBeforeMedia = "media_select"
                systemController.navigateTo("bluetooth_audio")
            }

            onUsbSelected: {
                console.log("[Apex IVI] USB selected from Media Select -> Configuring media to USB and launching Bluetooth Audio")
                systemController.selectMediaSource("usb")
                mainWindow.previousScreenBeforeMedia = "media_select"
                systemController.navigateTo("bluetooth_audio")
            }
        }

        // K. RADIO SCREEN (Matching Genuine IVI Photo 2 with live Indian FM audio streams)
        RadioScreen {
            id: radioScreen
            width: parent.width
            height: parent.height
            z: 10
            enabled: (systemController.currentScreen === "radio")

            x: (systemController.currentScreen === "radio" ||
                (systemController.currentScreen === "sound_settings" && mainWindow.previousScreenBeforeSound === "radio") ||
                (systemController.currentScreen === "settings" && mainWindow.previousScreenBeforeSettings === "radio") ||
                (systemController.currentScreen === "manual" && mainWindow.previousScreenBeforeManual === "radio")) ? 0 :
               ((systemController.currentScreen === "media_select" && mainWindow.previousScreenBeforeMedia === "radio") ? -parent.width : parent.width)

            Behavior on x {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }

            onBackClicked: {
                console.log("[Apex IVI] Back clicked from Radio Screen -> Returning to:", mainWindow.previousScreenBeforeRadio)
                systemController.navigateTo(mainWindow.previousScreenBeforeRadio)
            }

            onManualClicked: {
                console.log("[Apex IVI] Manual clicked from Radio Screen")
                mainWindow.previousScreenBeforeManual = "radio"
                systemController.navigateTo("manual")
            }

            onMediaSelectClicked: {
                console.log("[Apex IVI] Menu/Select Media clicked from Radio Screen")
                mainWindow.previousScreenBeforeMedia = "radio"
                systemController.navigateTo("media_select")
            }

            onSoundSettingsClicked: {
                console.log("[Apex IVI] Sound settings clicked from Radio Menu -> Navigating to Sound settings")
                soundSettingsScreen.selectedTab = "premium_sound"
                mainWindow.previousScreenBeforeSound = "radio"
                systemController.navigateTo("sound_settings")
            }

            onRadioNoiseClicked: {
                console.log("[Apex IVI] Radio noise control clicked from Radio Menu -> Navigating directly to Sound Settings (radio_noise tab)")
                soundSettingsScreen.selectedTab = "radio_noise"
                mainWindow.previousScreenBeforeSound = "radio"
                systemController.navigateTo("sound_settings")
            }
        }

        // K2. BLUETOOTH AUDIO SCREEN (Matching Reference Photo with Live Track Info & Dynamic Artwork)
        BluetoothAudioScreen {
            id: bluetoothAudioScreen
            width: parent.width
            height: parent.height
            z: 10
            enabled: (systemController.currentScreen === "bluetooth_audio")

            x: (systemController.currentScreen === "bluetooth_audio") ? 0 :
               ((systemController.currentScreen === "media_select" && mainWindow.previousScreenBeforeMedia === "bluetooth_audio") ? -parent.width : parent.width)

            Behavior on x {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }

            onBackClicked: {
                systemController.navigateTo(mainWindow.previousScreenBeforeMedia || "home")
            }

            onSwitchDeviceClicked: {
                mainWindow.previousScreenBeforeBt = "bluetooth_audio"
                systemController.navigateTo("bluetooth_connections")
            }
        }

        // L. VOICE MEMO SCREEN (Matching Genuine IVI Photo with real audio recording)
        VoiceMemoScreen {
            id: voiceMemoScreen
            width: parent.width
            height: parent.height
            z: 10
            enabled: (systemController.currentScreen === "voice_memo")

            x: (systemController.currentScreen === "voice_memo") ? 0 :
               ((systemController.currentScreen === "manual" && mainWindow.previousScreenBeforeManual === "voice_memo") ? -parent.width : parent.width)

            Behavior on x {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }

            onBackClicked: {
                console.log("[Apex IVI] Back from Voice Memo -> Returning to:", mainWindow.previousScreenBeforeVoiceMemo)
                voiceMemoScreen.resetToDefault()
                systemController.navigateTo(mainWindow.previousScreenBeforeVoiceMemo)
            }

            onManualClicked: {
                console.log("[Apex IVI] Manual clicked from Voice Memo -> Opening Manual Screen")
                mainWindow.previousScreenBeforeManual = "voice_memo"
                systemController.navigateTo("manual")
            }
        }
    }

    // Global incoming-call surface: remains visible over Home, Media, Settings,
    // DRVM, and Phone. It is driven only by a real HFP incoming-call state.
    IncomingCallPopup {
        id: incomingCallPopup
        anchors.fill: parent
        z: 1200
        visible: systemController.bluetoothCallActive
                 && systemController.bluetoothCallStatus === "incoming"
        callerName: systemController.bluetoothCallName
        callerNumber: systemController.bluetoothCallNumber
        privacyMode: systemController.privacyMode

        onAccepted: {
            mainWindow.previousScreenBeforePhone = systemController.currentScreen
            systemController.answerCall()
            systemController.navigateTo("phone")
        }

        onRejected: systemController.hangUpCall()
        onPrivacyToggled: systemController.togglePrivacyMode()
        onQuickReplySelected: function(text) {
            systemController.sendQuickReply(systemController.bluetoothCallNumber, text)
        }
    }

    Rectangle {
        id: quickReplyToast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 34
        z: 1300
        visible: mainWindow.incomingQuickReplyFeedback.length > 0
        width: Math.min(780, quickReplyToastText.implicitWidth + 56)
        height: 56
        radius: 7
        color: "#14283B"
        border.color: "#4E82AD"
        border.width: 1

        Text {
            id: quickReplyToastText
            anchors.centerIn: parent
            text: mainWindow.incomingQuickReplyFeedback
            color: "#FFFFFF"
            font.family: "Roboto"
            font.pixelSize: 18
        }
    }

    // ====================================================
    // M. DRVM & REVERSE CAMERA SCREEN (Full-screen Rear Camera, Photo 1 & Photo 2)
    // ====================================================
    DrvmScreen {
        id: drvmScreen
        anchors.fill: parent
        z: 35
        visible: (systemController.currentScreen === "drvm")

        onHomeClicked: {
            console.log("[Apex IVI] Home clicked from DRVM/Reverse -> Returning to Home")
            systemController.isReverseGear = false
            systemController.navigateTo("home")
        }

        onSettingsClicked: {
            console.log("[Apex IVI] Settings clicked from DRVM/Reverse -> Opening Display Settings")
            systemController.isReverseGear = false
            mainWindow.previousScreenBeforeDisplay = "drvm"
            systemController.navigateTo("display_settings")
        }
    }

    // ====================================================
    // 3. PHONE PROJECTION DIALOG MODAL (Matching Genuine IVI Photo)
    // ====================================================
    Rectangle {
        id: phoneProjectionDialog
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.68)
        visible: false
        z: 95

        MouseArea {
            anchors.fill: parent
            onClicked: {} // block background click
        }

        Rectangle {
            id: projDialogBox
            anchors.centerIn: parent
            width: 780
            height: 310
            color: "#121824"
            border.color: "#2C394C"
            border.width: 1.5
            radius: 4

            Column {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 18

                // Blue Info "i" Badge
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 56
                    height: 56
                    radius: 28
                    color: "#3CA9F8"

                    Text {
                        anchors.centerIn: parent
                        text: "i"
                        color: "#FFFFFF"
                        font.pixelSize: 36
                        font.weight: Font.Bold
                        font.family: "Roboto"
                    }
                }

                // Message Text
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 40
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    lineHeight: 1.25
                    text: "Please connect a phone that supports Android Auto\nor Apple CarPlay via an approved USB cable."
                    color: "#FFFFFF"
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                }

                Item { width: 1; height: 4 }

                // OK Button
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 16
                    height: 58
                    radius: 3
                    color: okMouse.pressed ? "#389BFF" : (okMouse.containsMouse ? "#2A4E74" : "#1D3650")
                    border.color: okMouse.pressed ? "#80D8FF" : "#325780"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: "OK"
                        color: "#FFFFFF"
                        font.pixelSize: 24
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                        scale: okMouse.pressed ? 0.95 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }
                    }

                    MouseArea {
                        id: okMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            console.log("[PhoneProjection] OK clicked -> Dismissing dialog")
                            phoneProjectionDialog.visible = false
                        }
                    }
                }
            }
        }
    }

    // Modal Dialog: No Bluetooth Phone Connected (Add new device prompt)
    Rectangle {
        id: noPhoneDialog
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.70)
        visible: false
        opacity: visible ? 1.0 : 0.0
        z: 96

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

        MouseArea {
            anchors.fill: parent
            onClicked: {} // Block touches from passing through
        }

        Rectangle {
            id: noPhoneBox
            anchors.centerIn: parent
            width: 720
            height: 310
            color: "#121824"
            border.color: "#2C394C"
            border.width: 1.5
            radius: 6
            scale: noPhoneDialog.opacity > 0.0 ? 1.0 : 0.94

            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Column {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 16

                // Bluetooth Phone Icon Badge
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 54
                    height: 54
                    radius: 27
                    color: "#1D3650"
                    border.color: "#3CA9F8"
                    border.width: 1.5

                    Image {
                        anchors.centerIn: parent
                        width: 32
                        height: 32
                        source: "qrc:/assets/apps/icon_all_phone.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }
                }

                // Message Text
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No Bluetooth phone is connected."
                        color: "#FFFFFF"
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: (systemController.bluetoothDeviceList.length === 0) ? "Would you like to add a new device?" : "Would you like to connect a device?"
                        color: "#94A3B8"
                        font.pixelSize: 18
                        font.family: "Roboto"
                    }
                }

                Item { width: 1; height: 6 }

                // Action Buttons Row (Yes / No)
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 24
                    height: 54
                    spacing: 16

                    // Yes Button
                    Rectangle {
                        width: (parent.width - 16) / 2
                        height: parent.height
                        radius: 4
                        color: yesMouse.pressed ? "#1B5291" : (yesMouse.containsMouse ? "#2870C2" : "#205FA6")
                        border.color: yesMouse.pressed ? "#80D8FF" : "#3CA9F8"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Yes"
                            color: "#FFFFFF"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                            scale: yesMouse.pressed ? 0.96 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: yesMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[NoPhoneDialog] Yes clicked -> Opening Bluetooth Connections")
                                noPhoneDialog.visible = false
                                mainWindow.previousScreenBeforeBt = mainWindow.previousScreenBeforePhone
                                btConnScreen.returnScreenAfterAdd = mainWindow.previousScreenBeforePhone
                                systemController.navigateTo("bluetooth_connections")
                                if (systemController.bluetoothDeviceList.length === 0) {
                                    btConnScreen.startAddNewDeviceFlow()
                                } else {
                                    btConnScreen.currentView = "list"
                                }
                            }
                        }
                    }

                    // No Button
                    Rectangle {
                        width: (parent.width - 16) / 2
                        height: parent.height
                        radius: 4
                        color: noMouse.pressed ? "#101622" : (noMouse.containsMouse ? "#1E2738" : "#161E2D")
                        border.color: noMouse.pressed ? "#50637F" : "#2C394C"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "No"
                            color: "#CBD5E1"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                            scale: noMouse.pressed ? 0.96 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: noMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[NoPhoneDialog] No clicked -> Dismissing dialog")
                                noPhoneDialog.visible = false
                            }
                        }
                    }
                }
            }
        }
    }

    // ====================================================
    // Modal Dialog: Bluetooth Pairing Request (Passkey Confirmation)
    // ====================================================
    Rectangle {
        id: pairingRequestDialog
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.78)
        visible: systemController.isPairingPromptActive
        z: 98

        MouseArea {
            anchors.fill: parent
            onClicked: {} // Block touches from passing through
        }

        Rectangle {
            id: pairingBox
            anchors.centerIn: parent
            width: 700
            height: 380
            color: "#121824"
            border.color: "#2C394C"
            border.width: 1.5
            radius: 8

            Column {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 14

                // Header Icon & Title
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 22
                        color: "#1D3650"
                        border.color: "#3CA9F8"
                        border.width: 1.5

                        Image {
                            anchors.centerIn: parent
                            width: 26
                            height: 26
                            source: "qrc:/assets/apps/icon_all_phone.png"
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Bluetooth Pairing Request"
                        color: "#FFFFFF"
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }
                }

                // Device Name Text
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: systemController.incomingPairingDeviceName ? systemController.incomingPairingDeviceName : "Bluetooth Device"
                    color: "#8FAABF"
                    font.pixelSize: 18
                    font.family: "Roboto"
                }

                // Passkey Box Display
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 340
                    height: 64
                    color: "#0A1017"
                    border.color: "#389BFF"
                    border.width: 1.5
                    radius: 6

                    Text {
                        anchors.centerIn: parent
                        text: systemController.incomingPairingPasskey ? systemController.incomingPairingPasskey : "000000"
                        color: "#38B6FF"
                        font.pixelSize: 36
                        font.weight: Font.Bold
                        font.letterSpacing: 6
                        font.family: "Roboto"
                    }
                }

                // Subtitle Instructions
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: "Confirm that this passkey matches the code shown on your phone."
                    color: "#94A3B8"
                    font.pixelSize: 17
                    font.family: "Roboto"
                }

                Item { width: 1; height: 6 }

                // Action Buttons: [ Pair ] and [ Cancel ]
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 24
                    height: 52
                    spacing: 16

                    // Pair Button
                    Rectangle {
                        width: (parent.width - 16) / 2
                        height: parent.height
                        radius: 4
                        color: pairBtnMouse.pressed ? "#1B5291" : (pairBtnMouse.containsMouse ? "#2870C2" : "#205FA6")
                        border.color: "#3CA9F8"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Pair"
                            color: "#FFFFFF"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        MouseArea {
                            id: pairBtnMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[Main] User tapped Pair on IVI")
                                systemController.confirmPairing()
                            }
                        }
                    }

                    // Cancel Button
                    Rectangle {
                        width: (parent.width - 16) / 2
                        height: parent.height
                        radius: 4
                        color: cancelPairMouse.pressed ? "#224A75" : (cancelPairMouse.containsMouse ? "#1A3654" : "#132130")
                        border.color: "#3D5B7D"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: "#FFFFFF"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                            font.family: "Roboto"
                        }

                        MouseArea {
                            id: cancelPairMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[Main] User tapped Cancel on IVI")
                                systemController.rejectPairing()
                            }
                        }
                    }
                }
            }
        }
    }

    // Backdrop to dismiss on outside click
    MouseArea {
        id: homeMenuBackdrop
        anchors.fill: parent
        z: 89
        visible: homeMenuDropdown.visible
        onClicked: {
            homeMenuDropdown.visible = false
            persistentTopBar.menuOpen = false
        }
    }

    // ====================================================
    // 4. HOME SCREEN MENU DROPDOWN (Directly beneath Menu button)
    // ====================================================
    Item {
        id: homeMenuDropdown
        anchors.top: persistentTopBar.bottom
        anchors.left: parent.left
        anchors.leftMargin: 6
        width: 480
        height: 240
        visible: false
        z: 90

        // Dropdown Panel Box
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

                // 1. Edit left widget
                MenuRow {
                    title: "Edit left widget"
                    onClicked: {
                        homeMenuDropdown.visible = false
                        persistentTopBar.menuOpen = false
                        systemController.openWidgetEditor("left")
                    }
                }

                // 2. Edit right widget
                MenuRow {
                    title: "Edit right widget"
                    onClicked: {
                        homeMenuDropdown.visible = false
                        persistentTopBar.menuOpen = false
                        systemController.openWidgetEditor("right")
                    }
                }

                // 3. Edit Home icons
                MenuRow {
                    title: "Edit Home icons"
                    onClicked: {
                        homeMenuDropdown.visible = false
                        persistentTopBar.menuOpen = false
                        mainWindow.previousScreenBeforeEditHome = "home"
                        systemController.navigateTo("edit_home_icons")
                    }
                }

                // 4. Manual
                MenuRow {
                    title: "Manual"
                    isLast: true
                    onClicked: {
                        homeMenuDropdown.visible = false
                        persistentTopBar.menuOpen = false
                        mainWindow.previousScreenBeforeManual = systemController.currentScreen
                        systemController.navigateTo("manual")
                    }
                }
            }
        }
    }

    // Component for Menu Row item
    component MenuRow: Rectangle {
        id: rowItem
        property string title: ""
        property bool isLast: false
        signal clicked()

        width: parent.width
        height: 60
        color: rowMouse.pressed ? "#D0DFEE" : (rowMouse.containsMouse ? "#E1EBF5" : "transparent")

        Behavior on color { ColorAnimation { duration: 80 } }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 28
            anchors.verticalCenter: parent.verticalCenter
            text: rowItem.title
            color: "#223344"
            font.pixelSize: 24
            font.weight: Font.Normal
            font.family: "Roboto"
        }

        // Divider
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: "#D6E0EC"
            visible: !rowItem.isLast
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: rowItem.clicked()
        }
    }

    // ====================================================
    // 5. MANUAL MODAL DIALOG
    // ====================================================
    Rectangle {
        id: manualDialog
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.68)
        visible: false
        z: 96

        MouseArea {
            anchors.fill: parent
            onClicked: {} // block background click
        }

        Rectangle {
            anchors.centerIn: parent
            width: 700
            height: 320
            color: "#121824"
            border.color: "#2C394C"
            border.width: 1.5
            radius: 4

            Column {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 20

                Text {
                    text: "User's Manual on Web"
                    color: "#FFFFFF"
                    font.pixelSize: 26
                    font.weight: Font.DemiBold
                    font.family: "Roboto"
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "Scan the QR code with your smartphone or visit https://github.com/skrehanahamed/Apex_MidEnd_IVI to view the full User's Manual on the web."
                    color: "#A0B2C6"
                    font.pixelSize: 20
                    lineHeight: 1.3
                    font.family: "Roboto"
                }

                Item { width: 1; height: 8 }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 180
                    height: 48
                    color: manualOkMouse.pressed ? "#1E88E5" : (manualOkMouse.containsMouse ? "#3A6C9B" : "#2E5B84")
                    border.color: manualOkMouse.pressed ? "#66D9FF" : "#3F74A3"
                    border.width: 1
                    radius: 4

                    Text {
                        anchors.centerIn: parent
                        text: "OK"
                        color: "#FFFFFF"
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                        font.family: "Roboto"
                    }

                    MouseArea {
                        id: manualOkMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: manualDialog.visible = false
                    }
                }
            }
        }
    }

    // ====================================================
    // 5B. BLUE LIGHT FILTER WARMTH TINT OVERLAY
    // ====================================================
    Rectangle {
        id: blueLightOverlay
        anchors.fill: parent
        color: "#FFA834"
        opacity: systemController.blueLightFilterEnabled ? (0.04 + (systemController.blueLightWarmth / 10.0) * 0.12) : 0.0
        visible: opacity > 0.0
        z: 85
        enabled: false // Let mouse events pass through to UI

        Behavior on opacity {
            NumberAnimation { duration: 250 }
        }
    }

    // ====================================================
    // 5C. DISPLAY OFF / SCREENSAVER OVERLAY (Tap to wake)
    // ====================================================
    Rectangle {
        id: displayOffOverlay
        anchors.fill: parent
        color: "#000000"
        z: 98
        visible: systemController.displayOff
        opacity: systemController.displayOff ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
        }

        // 1. Screensaver wallpaper background
        Image {
            id: screensaverWallpaper
            anchors.fill: parent
            source: "qrc:/assets/image.png"
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
        }

        // 2. Subtle dark scrim to provide optimal contrast for clocks & text
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.35
        }

        // 3. Analogue clock screensaver (centered with animated seconds clock & radar sweep)
        Item {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -40
            width: 310
            height: 310
            visible: systemController.screensaverType === "analog"

            AnalogueClockFace {
                anchors.fill: parent
                clockStyle: systemController.analogueClockIndex
                animated: true
            }
        }

        // 4. Digital clock screensaver (clean large digital time matching vehicle photo)
        Row {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -40
            spacing: 14
            visible: systemController.screensaverType === "digital"

            Text {
                anchors.baseline: amPmText.baseline
                text: systemController.currentTime
                color: "#FFFFFF"
                font.pixelSize: 104
                font.weight: Font.DemiBold
                font.family: "Roboto"
                style: Text.Outline
                styleColor: "#80000000"
            }
            Text {
                id: amPmText
                text: systemController.currentAmPm
                color: "#D6E4F0"
                font.pixelSize: 42
                font.weight: Font.DemiBold
                font.family: "Roboto"
                style: Text.Outline
                styleColor: "#80000000"
            }
        }

        // 5. Date anchored at bottom matching vehicle photos: "Sunday, 15/02/2026"
        Text {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 55
            anchors.horizontalCenter: parent.horizontalCenter
            text: systemController.fullDate
            color: "#FFFFFF"
            font.pixelSize: 26
            font.weight: Font.DemiBold
            font.family: "Roboto"
            style: Text.Outline
            styleColor: "#60000000"
            visible: systemController.screensaverType !== "none"
        }

        MouseArea {
            anchors.fill: parent
            enabled: systemController.displayOff
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                console.log("[Apex IVI] Screen tapped while Display Off -> Waking up display")
                systemController.setDisplayOff(false)
            }
        }
    }

    // ====================================================
    // 5. OEM BOTTOM VOLUME BAR (Appears on volume adjustment, stays 3s, then vanishes)
    // ====================================================
    Rectangle {
        id: bottomVolumeBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 52
        color: "#080F17"
        z: 95
        visible: opacity > 0 && (systemController.currentScreen !== "drvm" && !systemController.displayOff)
        opacity: mainWindow.volumeBarVisible ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
        }

        // Top separator line
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: "#182E47"
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 36
            spacing: 24

            // Left: Current Media Source Name (e.g. "FM", "AM", "Bluetooth", "USB", or "Media")
            Text {
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignVCenter
                text: {
                    if (systemController.radioPlaying) {
                        return systemController.radioBand.toUpperCase()
                    }
                    if (systemController.selectedMediaSource === "fm") {
                        return "FM"
                    }
                    if (systemController.selectedMediaSource === "am") {
                        return "AM"
                    }
                    if (systemController.selectedMediaSource === "bluetooth" || systemController.selectedMediaSource === "bluetooth_audio") {
                        return "Bluetooth"
                    }
                    if (systemController.selectedMediaSource === "usb" || systemController.selectedMediaSource === "usb_music") {
                        return "USB"
                    }
                    if (systemController.selectedMediaSource === "carplay") {
                        return "CarPlay"
                    }
                    if (systemController.selectedMediaSource === "android_auto") {
                        return "Android Auto"
                    }
                    return "Media"
                }
                color: "#FFFFFF"
                font.pixelSize: 22
                font.weight: Font.DemiBold
                font.family: "Roboto"
            }

            // Right: Volume Section [ 🔊 ]  29  [ ━━━━━━━━━ ]
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 16

                // Transparent Speaker Icon Provided by User
                Image {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    source: "qrc:/assets/ui/icon_volume_speaker.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }

                // Volume Number (e.g. 29)
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 42
                    text: systemController.volume
                    color: "#3CA9F8"
                    font.pixelSize: 24
                    font.weight: Font.Bold
                    font.family: "Roboto"
                }

                // Volume Blue Horizontal Line Bar
                Item {
                    id: volumeTrackItem
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    Layout.alignment: Qt.AlignVCenter

                    // Background dark track
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 5
                        radius: 2.5
                        color: "#182E47"

                        // Active blue progress line
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.max(0, Math.min(parent.width, parent.width * (systemController.volume / systemController.maxVolume)))
                            radius: 2.5
                            color: "#38A8F8"
                        }
                    }

                    // Direct touch/drag interactive mousearea
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: function(mouse) {
                            if (pressed) {
                                var frac = Math.max(0.0, Math.min(1.0, mouse.x / width))
                                systemController.setVolume(Math.round(frac * systemController.maxVolume))
                                mainWindow.showVolumeBar()
                            }
                        }
                        onPressed: function(mouse) {
                            var frac = Math.max(0.0, Math.min(1.0, mouse.x / width))
                            systemController.setVolume(Math.round(frac * systemController.maxVolume))
                            mainWindow.showVolumeBar()
                        }
                    }
                }
            }
        }
    }

    // ====================================================
    // 6. INITIAL BOOT SCREEN: APEX METALLIC SHINE
    // (Destroyed from memory upon completion)
    // ====================================================
    Loader {
        id: splashLoader
        anchors.fill: parent
        z: 100
        sourceComponent: splashComponent
    }

    Component {
        id: splashComponent
        ApexLoadingScreen {
            onFinished: {
                console.log("[Apex IVI] Splash completed -> Unloading splash screen completely")
                splashLoader.sourceComponent = undefined
                systemController.navigateTo("home")
            }
        }
    }
}
