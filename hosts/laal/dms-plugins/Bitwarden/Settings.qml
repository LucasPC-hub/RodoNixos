import "DmsUi"
import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
PluginSettings {
    id: root
    pluginId: "bitwarden"
    // Registered by Daemon.qml; DMS 1.4.6 does not publish daemon instances.
    readonly property var vault: PluginService.globalVars["bitwarden"]?.vault ?? null
    StringSetting {
        settingKey: "defaultServerUrl"
        label: Tr.text("Default server URL")
        description: Tr.text("Server the login form starts on when the Bitwarden CLI has none configured, e.g. a Vaultwarden instance. A server already configured in the CLI takes precedence.")
        placeholder: "https://vault.example.com"
        defaultValue: ""
    }
    DankButton {
        text: Tr.text("Open Bitwarden settings")
        iconName: "settings"
        enabled: root.vault !== null
        onClicked: {
            if (root.vault) { root.vault.open(); root.vault.openSettings(); }
        }
    }
}
