import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.DankDash.Overview as Overview

Item {
    id: page

    signal requestClose
    signal requestWeather

    readonly property real gap: Theme.spacingM
    readonly property real leftWidth: 200
    readonly property real rightWidth: 96
    readonly property real centerWidth: width - leftWidth - rightWidth - gap * 2

    property MprisPlayer player: MprisController.activePlayer
    readonly property bool playing: player?.playbackState === MprisPlaybackState.Playing

    // Default https handler as configured in xdg-mime (resolved when the menu opens).
    property string browserDesktopId: ""

    readonly property var launchers: {
        const list = [
            {
                "name": "Terminal",
                "desktopId": "Alacritty",
                "argv": ["alacritty"],
                "icon": "terminal"
            },
            {
                "name": "Arquivos",
                "desktopId": "org.kde.dolphin",
                "argv": ["dolphin"],
                "icon": "folder"
            }
        ];
        if (browserDesktopId)
            list.push({
                "name": "Navegador",
                "desktopId": browserDesktopId,
                "argv": [],
                "icon": "language"
            });
        list.push({
            "name": "Aplicativos",
            "action": "launcher",
            "icon": "apps"
        });
        list.push({
            "name": "Configurações",
            "action": "settings",
            "icon": "settings"
        });
        return list;
    }

    function desktopEntryFor(launcher) {
        return launcher.desktopId ? DesktopEntries.heuristicLookup(launcher.desktopId) : null;
    }

    function launch(launcher) {
        page.requestClose();
        if (launcher.action === "launcher") {
            PopoutService.openDankLauncherV2();
            return;
        }
        if (launcher.action === "settings") {
            PopoutService.openSettings();
            return;
        }
        const entry = desktopEntryFor(launcher);
        if (entry) {
            SessionService.launchDesktopEntry(entry, false);
            return;
        }
        if (launcher.argv && launcher.argv.length > 0)
            Quickshell.execDetached(launcher.argv);
    }

    function formatTime(seconds) {
        if (!seconds || seconds < 0)
            return "0:00";
        const s = Math.floor(seconds);
        const m = Math.floor(s / 60);
        const rest = s % 60;
        return m + ":" + (rest < 10 ? "0" : "") + rest;
    }

    Component.onCompleted: {
        WeatherService.addRef();
        Proc.runCommand("nordHub.defaultBrowser", ["xdg-mime", "query", "default", "x-scheme-handler/https"], (stdout, exitCode) => {
            if (exitCode === 0)
                page.browserDesktopId = stdout.trim().replace(/\.desktop$/, "");
        }, 0);
    }
    Component.onDestruction: WeatherService.removeRef()

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Timer {
        interval: 1000
        repeat: true
        running: page.playing && (page.player?.positionSupported ?? false)
        onTriggered: page.player.positionChanged()
    }

    // ---------------------------------------------------------------- media
    Overview.Card {
        id: mediaCard

        x: 0
        y: 0
        width: page.leftWidth
        height: page.height - launcherCard.height - page.gap

        Column {
            anchors.centerIn: parent
            spacing: Theme.spacingS
            visible: !page.player

            DankIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: "music_off"
                size: Theme.iconSizeLarge
                color: Theme.surfaceVariantText
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Nada tocando"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
        }

        Column {
            anchors.fill: parent
            spacing: Theme.spacingS
            visible: !!page.player

            Item {
                width: parent.width
                height: 132

                Rectangle {
                    id: artFrame
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 132
                    height: 132
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh

                    DankIcon {
                        anchors.centerIn: parent
                        visible: art.status !== Image.Ready
                        name: "album"
                        size: 48
                        color: Theme.surfaceVariantText
                    }

                    Image {
                        id: art
                        anchors.fill: parent
                        source: page.player?.trackArtUrl ?? ""
                        sourceSize.width: 264
                        sourceSize.height: 264
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                    }

                    Rectangle {
                        id: artMask
                        anchors.fill: parent
                        radius: parent.radius
                        visible: false
                        layer.enabled: true
                    }

                    MultiEffect {
                        anchors.fill: parent
                        visible: art.status === Image.Ready
                        source: art
                        maskEnabled: true
                        maskSource: artMask
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 2

                StyledText {
                    width: parent.width
                    text: page.player?.trackTitle || "Sem título"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    maximumLineCount: 1
                }

                StyledText {
                    width: parent.width
                    text: page.player?.trackArtist || page.player?.identity || ""
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    maximumLineCount: 1
                }
            }

            DankSeekbar {
                width: parent.width
                height: 20
                activePlayer: page.player
                visible: (page.player?.length ?? 0) > 0
            }

            StyledText {
                width: parent.width
                visible: (page.player?.length ?? 0) > 0
                text: page.formatTime(page.player?.position ?? 0) + " / " + page.formatTime(page.player?.length ?? 0)
                font.pixelSize: Theme.fontSizeSmall - 1
                color: Theme.surfaceVariantText
                horizontalAlignment: Text.AlignHCenter
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingM

                DankActionButton {
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: "skip_previous"
                    buttonSize: 32
                    enabled: page.player?.canGoPrevious ?? false
                    opacity: enabled ? 1 : 0.4
                    onClicked: page.player.previous()
                }

                Rectangle {
                    width: 40
                    height: 40
                    radius: 20
                    color: playArea.containsMouse ? Qt.lighter(Theme.primary, 1.08) : Theme.primary

                    DankIcon {
                        anchors.centerIn: parent
                        name: page.playing ? "pause" : "play_arrow"
                        size: 22
                        color: Theme.primaryText
                        filled: true
                    }

                    MouseArea {
                        id: playArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: page.player?.canTogglePlaying ?? false
                        onClicked: page.player.togglePlaying()
                    }
                }

                DankActionButton {
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: "skip_next"
                    buttonSize: 32
                    enabled: page.player?.canGoNext ?? false
                    opacity: enabled ? 1 : 0.4
                    onClicked: page.player.next()
                }
            }
        }
    }

    // ------------------------------------------------------------ launchers
    Overview.Card {
        id: launcherCard

        x: 0
        anchors.bottom: parent.bottom
        width: page.leftWidth
        height: 52
        pad: Theme.spacingS

        Row {
            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: page.launchers

                Rectangle {
                    id: launcherButton

                    required property var modelData
                    readonly property var entry: page.desktopEntryFor(modelData)
                    readonly property string iconPath: entry && entry.icon ? Quickshell.iconPath(entry.icon, true) : ""

                    width: 34
                    height: 34
                    radius: 17
                    color: launcherArea.containsMouse ? Theme.primaryHover : "transparent"

                    Image {
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        sourceSize.width: 44
                        sourceSize.height: 44
                        source: launcherButton.iconPath
                        visible: launcherButton.iconPath !== "" && status === Image.Ready
                        asynchronous: true
                    }

                    DankIcon {
                        anchors.centerIn: parent
                        visible: launcherButton.iconPath === ""
                        name: launcherButton.modelData.icon
                        size: 20
                        color: Theme.surfaceText
                    }

                    MouseArea {
                        id: launcherArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.launch(launcherButton.modelData)
                    }

                    DankTooltipV2 {
                        id: launcherTip
                    }

                    Connections {
                        target: launcherArea
                        function onContainsMouseChanged() {
                            if (launcherArea.containsMouse)
                                launcherTip.show(launcherButton.modelData.name, launcherButton, 0, 0, "bottom");
                            else
                                launcherTip.hide();
                        }
                    }
                }
            }
        }
    }

    // ------------------------------------------------------- clock + weather
    Overview.Card {
        id: clockCard

        x: page.leftWidth + page.gap
        y: 0
        width: (page.centerWidth - page.gap) / 2
        height: 104

        Column {
            anchors.centerIn: parent
            spacing: 2

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: clock.date.toLocaleTimeString(Qt.locale(), SettingsData.use24HourClock ? "HH:mm" : "h:mm AP")
                font.pixelSize: Theme.fontSizeXLarge * 1.6
                font.weight: Font.Light
                color: Theme.surfaceText
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: clock.date.toLocaleDateString(Qt.locale(), "dd.MM.yy") + " · " + clock.date.toLocaleDateString(Qt.locale(), "ddd")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
        }
    }

    Overview.Card {
        id: weatherCard

        x: clockCard.x + clockCard.width + page.gap
        y: 0
        width: clockCard.width
        height: 104

        readonly property var weather: WeatherService.weather

        StyledText {
            anchors.centerIn: parent
            visible: !SettingsData.weatherEnabled
            text: "Clima desativado"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }

        Column {
            anchors.centerIn: parent
            spacing: Theme.spacingXS
            visible: SettingsData.weatherEnabled && !weatherCard.weather.available

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: weatherCard.weather.loading ? "Carregando clima…" : "Clima indisponível"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            DankActionButton {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !weatherCard.weather.loading
                iconName: "refresh"
                buttonSize: 28
                onClicked: WeatherService.forceRefresh()
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: Theme.spacingM
            visible: SettingsData.weatherEnabled && weatherCard.weather.available

            DankIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: WeatherService.getWeatherIcon(weatherCard.weather.wCode, weatherCard.weather.isDay)
                size: 40
                color: Theme.primary
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                StyledText {
                    text: WeatherService.formatTemp(weatherCard.weather.temp)
                    font.pixelSize: Theme.fontSizeXLarge
                    color: Theme.warning
                }

                StyledText {
                    width: Math.min(implicitWidth, weatherCard.width - 40 - Theme.spacingM * 3)
                    text: WeatherService.getWeatherCondition(weatherCard.weather.wCode)
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    elide: Text.ElideRight
                }

                StyledText {
                    width: Math.min(implicitWidth, weatherCard.width - 40 - Theme.spacingM * 3)
                    visible: !!weatherCard.weather.city
                    text: weatherCard.weather.city
                    font.pixelSize: Theme.fontSizeSmall - 1
                    color: Theme.outline
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: SettingsData.weatherEnabled && weatherCard.weather.available
            cursorShape: Qt.PointingHandCursor
            onClicked: page.requestWeather()
        }
    }

    // ------------------------------------------------------------- calendar
    Overview.CalendarOverviewCard {
        x: clockCard.x
        y: clockCard.height + page.gap
        width: page.centerWidth
        height: page.height - y
        // laal: no DMS 1.7 o CalendarOverviewCard não tem mais o sinal
        // closeDash (o original fazia onCloseDash: page.requestClose()).
    }

    // ------------------------------------------------- levels + shell access
    Overview.Card {
        id: controlsCard

        x: page.width - page.rightWidth
        y: 0
        width: page.rightWidth
        height: page.height
        pad: Theme.spacingS

        readonly property var sink: AudioService.sink
        readonly property bool hasSink: !!sink?.audio

        Row {
            id: levels

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height - shellButtons.height - Theme.spacingM
            spacing: Theme.spacingXS

            LevelSlider {
                height: levels.height
                visible: DisplayService.brightnessAvailable
                iconName: "light_mode"
                minimum: 0.01
                value: DisplayService.brightnessLevel / 100
                onMoved: v => DisplayService.setBrightness(Math.round(v * 100), "", true)
                onIconClicked: {
                    page.requestClose();
                    BarWidgetService.getBarWindowOnFocusedScreen()?.triggerControlCenter();
                }
            }

            LevelSlider {
                height: levels.height
                visible: controlsCard.hasSink
                iconName: !controlsCard.hasSink || controlsCard.sink.audio.muted ? "volume_off" : "volume_up"
                dimmed: controlsCard.hasSink && controlsCard.sink.audio.muted
                value: controlsCard.hasSink ? Math.min(1, controlsCard.sink.audio.volume) : 0
                onMoved: v => {
                    SessionData.suppressOSDTemporarily();
                    AudioService.setVolume(Math.round(v * 100));
                }
                onIconClicked: {
                    SessionData.suppressOSDTemporarily();
                    AudioService.toggleMute();
                }
            }
        }

        Column {
            id: shellButtons

            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spacingXS

            DankActionButton {
                iconName: "tune"
                buttonSize: 36
                tooltipText: "Central de controle"
                tooltipSide: "left"
                onClicked: {
                    page.requestClose();
                    if (!BarWidgetService.triggerWidgetPopout("controlCenterButton"))
                        BarWidgetService.getBarWindowOnFocusedScreen()?.triggerControlCenter();
                }
            }

            DankActionButton {
                iconName: NotificationService.notifications.length > 0 ? "notifications_unread" : "notifications"
                buttonSize: 36
                tooltipText: "Notificações"
                tooltipSide: "left"
                onClicked: {
                    page.requestClose();
                    BarWidgetService.triggerWidgetPopout("notificationButton");
                }
            }

            DankActionButton {
                iconName: "power_settings_new"
                iconColor: Theme.error
                buttonSize: 36
                tooltipText: "Energia"
                tooltipSide: "left"
                onClicked: {
                    page.requestClose();
                    PopoutService.openPowerMenu();
                }
            }
        }
    }
}
