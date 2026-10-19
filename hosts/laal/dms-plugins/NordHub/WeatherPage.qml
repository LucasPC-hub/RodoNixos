import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.DankDash

// Native DankDash weather view (hourly/daily forecast, sun/moon arc), fed by
// the shared WeatherService poller and its configured location.
Item {
    id: page

    Component.onCompleted: WeatherService.addRef()
    Component.onDestruction: WeatherService.removeRef()

    Column {
        anchors.centerIn: parent
        spacing: Theme.spacingS
        visible: !SettingsData.weatherEnabled

        DankIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: "cloud_off"
            size: Theme.iconSizeLarge
            color: Theme.surfaceVariantText
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Clima desativado nas configurações do DMS"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }
    }

    Loader {
        anchors.fill: parent
        active: SettingsData.weatherEnabled
        sourceComponent: WeatherTab {}
    }
}
