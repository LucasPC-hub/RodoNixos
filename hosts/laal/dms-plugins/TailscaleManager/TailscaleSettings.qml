import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "tailscale"

    StyledText {
        width: parent.width
        text: "Tailscale Manager"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Manage your Tailscale VPN connection with peer list, SSH, and ping actions."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    SliderSetting {
        settingKey: "refreshInterval"
        label: "Refresh Interval"
        description: "How often to check Tailscale status (in seconds)."
        defaultValue: 5
        minimum: 1
        maximum: 60
        unit: "sec"
    }

    StyledText {
        width: parent.width
        text: "Display Options"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Bold
        color: Theme.surfaceText
        topPadding: Theme.spacingM
    }

    ToggleSetting {
        settingKey: "showIpAddress"
        label: "Show IP Address"
        description: "Display this device's Tailscale IP in the bar pill."
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "showPeerCount"
        label: "Show Peer Count"
        description: "Display connected device count in the popout header."
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "hideDisconnected"
        label: "Hide Disconnected Peers"
        description: "Only show online peers in the panel."
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "closeOnAction"
        label: "Close on Action"
        description: "Close the popout after SSH, ping, or admin console actions."
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "closeOnCopy"
        label: "Close on Copy"
        description: "Also close the popout after copying an IP or hostname."
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "allowConnectionToggle"
        label: "Allow Connect/Disconnect"
        description: "Show the Connect/Disconnect button and enable bar right-click toggle (runs tailscale up/down)."
        defaultValue: false
    }

    StyledText {
        width: parent.width
        text: "Terminal Configuration"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Bold
        color: Theme.surfaceText
        topPadding: Theme.spacingM
    }

    StyledText {
        width: parent.width
        text: "Required for SSH and ping actions. Set the terminal executable that supports -e (e.g. alacritty)."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StringSetting {
        settingKey: "terminalCommand"
        label: "Terminal Command"
        description: "Command to launch terminal for SSH/ping."
        defaultValue: ""
        placeholder: "alacritty"
    }

    StringSetting {
        settingKey: "sshUser"
        label: "SSH User"
        description: "Default SSH username. Leave empty to use your current user."
        defaultValue: ""
        placeholder: "root"
    }

    SliderSetting {
        settingKey: "pingCount"
        label: "Ping Count"
        description: "Number of ping packets to send."
        defaultValue: 5
        minimum: 1
        maximum: 20
        unit: "pkt"
    }

    StyledText {
        width: parent.width
        text: "Peer Click Action"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Bold
        color: Theme.surfaceText
        topPadding: Theme.spacingM
    }

    SelectionSetting {
        settingKey: "defaultPeerAction"
        label: "Default Action"
        description: "Action when clicking on a peer in the panel."
        defaultValue: "copy-ip"
        options: [
            { label: "Copy IP", value: "copy-ip" },
            { label: "SSH to host", value: "ssh" },
            { label: "Ping host", value: "ping" }
        ]
    }
}
