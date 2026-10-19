// "Mostrar ícones ocultos" do Windows: uma setinha na DankBar que abre uma
// grade com todas as ferramentas do hub (catálogo do NordHub) e, embaixo, os
// apps em segundo plano da bandeja do sistema. Ferramentas do tipo "widget"
// têm host desligado na barra; o `widget toggle` do DMS carrega sob demanda.
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "../NordHub/Ferramentas.js" as Ferramentas

PluginComponent {
    id: root

    readonly property string dmsBin: "/run/current-system/sw/bin/dms"
    readonly property int colunas: 5
    readonly property int larguraCelula: 76
    readonly property int alturaCelula: 64
    readonly property int celulaBandeja: 44

    // Sobe com os sinais do registro de widgets/plugins pra reavaliar a lista.
    property int revisao: 0
    readonly property var disponiveis: {
        revisao;
        return Ferramentas.lista.filter(t => Ferramentas.motivoIndisponivel(t, {
                BarWidgetService,
                PluginService,
                SettingsData
            }) === "");
    }

    function iconeDaBandeja(item) {
        const icon = item?.icon ?? "";
        if (icon.includes("?path=")) {
            const [nome, caminho] = icon.split("?path=");
            return `file://${caminho}/${nome.substring(nome.lastIndexOf("/") + 1)}`;
        }
        return icon;
    }

    Connections {
        target: BarWidgetService
        function onWidgetRegistered() {
            root.revisao++;
        }
        function onWidgetUnregistered() {
            root.revisao++;
        }
    }

    Connections {
        target: PluginService
        function onPluginLoaded() {
            root.revisao++;
        }
        function onPluginUnloaded() {
            root.revisao++;
        }
    }

    // O PluginPopout já põe margem em volta do conteúdo; aqui só as grades.
    popoutWidth: colunas * larguraCelula + (colunas - 1) * Theme.spacingS + 2 * Theme.spacingL + 8
    popoutHeight: 0

    horizontalBarPill: Component {
        Item {
            implicitWidth: root.iconSize
            implicitHeight: root.widgetThickness
            DankIcon {
                anchors.centerIn: parent
                name: "expand_less"
                size: root.iconSize
                color: Theme.widgetIconColor
            }
        }
    }

    verticalBarPill: Component {
        Item {
            implicitWidth: root.widgetThickness
            implicitHeight: root.iconSize
            DankIcon {
                anchors.centerIn: parent
                name: "chevron_left"
                size: root.iconSize
                color: Theme.widgetIconColor
            }
        }
    }

    popoutContent: Component {
        Column {
            spacing: Theme.spacingS

            StyledText {
                text: "Ferramentas"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            Grid {
                columns: root.colunas
                spacing: Theme.spacingS

                Repeater {
                    model: root.disponiveis
                    delegate: Rectangle {
                        required property var modelData
                        width: root.larguraCelula
                        height: root.alturaCelula
                        radius: Theme.cornerRadius
                        color: ferramentaMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                        Column {
                            anchors.centerIn: parent
                            width: parent.width - Theme.spacingXS * 2
                            spacing: 2

                            DankIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                name: modelData.icon
                                size: Theme.iconSize
                                color: Theme.surfaceText
                            }
                            StyledText {
                                width: parent.width
                                text: modelData.name
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }
                        }
                        MouseArea {
                            id: ferramentaMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.closePopout();
                                Quickshell.execDetached([root.dmsBin, "ipc", "call"].concat(modelData.ipc));
                            }
                        }
                    }
                }
            }

            StyledText {
                visible: SystemTray.items.values.length > 0
                topPadding: Theme.spacingS
                text: "Em segundo plano"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            Flow {
                width: parent.width
                spacing: Theme.spacingS

                // Apps em segundo plano (bandeja do sistema).
                Repeater {
                    model: SystemTray.items
                    delegate: Rectangle {
                        id: celulaBandeja
                        required property var modelData
                        width: root.celulaBandeja
                        height: root.celulaBandeja
                        radius: Theme.cornerRadius
                        color: bandejaMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: Theme.iconSize
                            source: root.iconeDaBandeja(celulaBandeja.modelData)
                        }
                        QsMenuAnchor {
                            id: menuBandeja
                            menu: celulaBandeja.modelData.menu
                            anchor.item: celulaBandeja
                        }
                        MouseArea {
                            id: bandejaMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                const item = celulaBandeja.modelData;
                                if (mouse.button === Qt.RightButton || item.onlyMenu) {
                                    if (item.hasMenu)
                                        menuBandeja.open();
                                } else {
                                    item.activate();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
