import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property int currentTab: 0
    readonly property var tabModes: ["dashboard", "performance", "weather", "tools"]

    readonly property bool weatherReady: SettingsData.weatherEnabled && WeatherService.weather.available
    readonly property string temperatureText: {
        const w = WeatherService.weather;
        const temp = SettingsData.useFahrenheit ? w.tempF : w.temp;
        return temp + "°" + (SettingsData.useFahrenheit ? "F" : "C");
    }

    property var _popout: null
    readonly property bool popoutOpen: _popout ? _popout.shouldBeVisible : false

    function tabForMode(mode) {
        const idx = tabModes.indexOf(String(mode || "").toLowerCase());
        return idx >= 0 ? idx : 0;
    }

    // Reached through `dms ipc call widget openWith nordHub <mode>`.
    function openWithMode(mode) {
        currentTab = tabForMode(mode);
        if (!popoutOpen)
            triggerPopout();
    }

    // Reached through `dms ipc call widget toggleWith nordHub <mode>`.
    function toggleWithMode(mode) {
        const tab = tabForMode(mode);
        if (popoutOpen && tab === currentTab) {
            closePopout();
            return;
        }
        currentTab = tab;
        if (!popoutOpen)
            triggerPopout();
    }

    Component.onCompleted: {
        for (let i = 0; i < root.data.length; i++) {
            const obj = root.data[i];
            if (obj && obj.pluginContent !== undefined && obj.shouldBeVisible !== undefined) {
                _popout = obj;
                break;
            }
        }
    }

    Ref {
        service: WeatherService
    }

    // laal: sem as "ilhas" atrás das seções da barra que o original desenha;
    // a barra mantém o estilo dela.

    popoutWidth: 760
    popoutHeight: 472

    popoutContent: Component {
        HubPanel {
            hub: root
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "space_dashboard"
                size: root.iconSize
                color: root.popoutOpen ? Theme.primary : Theme.widgetIconColor
                filled: root.popoutOpen
            }

            DankIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.weatherReady
                name: WeatherService.getWeatherIcon(WeatherService.weather.wCode, WeatherService.weather.isDay)
                size: root.iconSize
                color: Theme.widgetIconColor
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.weatherReady
                text: root.temperatureText
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                color: Theme.widgetTextColor
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 1

            DankIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: "space_dashboard"
                size: root.iconSize
                color: root.popoutOpen ? Theme.primary : Theme.widgetIconColor
                filled: root.popoutOpen
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.weatherReady
                text: SettingsData.useFahrenheit ? WeatherService.weather.tempF : WeatherService.weather.temp
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                color: Theme.widgetTextColor
            }
        }
    }
}
