import QtQuick
import qs.Services
Item {
    id: root
    property string pluginId: "bitwarden"
    property var pluginService: null
    readonly property string status: service.status
    readonly property bool colorizeIcon: service.colorizeIcon
    function toggle() { view.toggle() }
    function open() { view.open() }
    function close() { view.close() }
    function lockVault() { service.lockVault() }
    function openSettings() { service.openSettings() }
    // DMS 1.4.6 does not publish daemon instances; the settings page finds
    // this one through the plugin's in-memory global variable.
    Component.onCompleted: PluginService.setGlobalVar(pluginId, "vault", root)
    Component.onDestruction: {
        if (PluginService.getGlobalVar(pluginId, "vault", null) === root)
            PluginService.setGlobalVar(pluginId, "vault", null)
    }
    Service { id: service; pluginId: root.pluginId; pluginService: root.pluginService }
    Panel { id: view; vault: service }
}
