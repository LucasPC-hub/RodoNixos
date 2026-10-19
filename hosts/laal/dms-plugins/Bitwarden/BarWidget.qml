// laal: botão do Bitwarden na DankBar. A versão do Matheus é só daemon
// (abre por IPC/atalho); este pill abre o mesmo painel do Daemon.qml.
import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    readonly property var vault: PluginService.pluginDaemonInstances[pluginId]
        || PluginService.getGlobalVar(pluginId, "vault", null)
    readonly property string iconName: vault?.status === "unlocked" ? "shield" : "lock"
    readonly property color iconColor: vault?.colorizeIcon ? Theme.primary : Theme.widgetIconColor

    // Clique abre/fecha o cofre; botão direito tranca se estiver aberto.
    pillClickAction: () => { if (vault) vault.toggle(); }
    pillRightClickAction: () => {
        if (!vault)
            return;
        if (vault.status === "unlocked")
            vault.lockVault();
        else
            vault.open();
    }

    horizontalBarPill: Component {
        Item {
            implicitWidth: root.iconSize
            implicitHeight: root.widgetThickness
            DankIcon {
                anchors.centerIn: parent
                name: root.iconName
                size: root.iconSize
                color: root.iconColor
            }
        }
    }

    verticalBarPill: Component {
        Item {
            implicitWidth: root.widgetThickness
            implicitHeight: root.iconSize
            DankIcon {
                anchors.centerIn: parent
                name: root.iconName
                size: root.iconSize
                color: root.iconColor
            }
        }
    }
}
