import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import "Ferramentas.js" as Ferramentas

Item {
    id: page

    signal requestClose

    readonly property string dmsBin: "/run/current-system/sw/bin/dms"
    readonly property real gap: Theme.spacingS
    readonly property int columns: 4
    readonly property real cardHeight: 74

    // Bumped by registry/plugin signals so availability bindings re-evaluate.
    property int revision: 0
    property string category: "all"
    readonly property string query: searchField.text.trim().toLowerCase()

    readonly property var categories: [
        {
            "id": "all",
            "text": "Tudo"
        },
        {
            "id": "util",
            "text": "Utilitários"
        },
        {
            "id": "media",
            "text": "Mídia"
        },
        {
            "id": "wellbeing",
            "text": "Bem-estar"
        },
        {
            "id": "system",
            "text": "Sistema"
        },
        {
            "id": "desktop",
            "text": "Desktop"
        }
    ]

    readonly property var tools: Ferramentas.lista

    readonly property var filteredTools: {
        const q = page.query;
        const cat = page.category;
        return page.tools.filter(t => {
            if (cat !== "all" && t.category !== cat)
                return false;
            if (!q)
                return true;
            return (t.name + " " + t.desc + " " + t.keywords).toLowerCase().indexOf(q) !== -1;
        });
    }

    // Empty string when the tool can be launched, otherwise the reason it cannot.
    function unavailableReason(tool) {
        page.revision;
        return Ferramentas.motivoIndisponivel(tool, {
            BarWidgetService,
            PluginService,
            SettingsData
        });
    }

    function desktopState(tool) {
        if (tool.kind !== "desktop")
            return "";
        const instance = SettingsData.getDesktopWidgetInstance(tool.target);
        if (!instance)
            return "";
        return (instance.enabled ?? true) ? "Visível" : "Oculto";
    }

    function categoryColor(cat) {
        switch (cat) {
        case "media":
            return Theme.secondary;
        case "wellbeing":
            return Theme.info;
        case "system":
            return Theme.warning;
        default:
            return Theme.primary;
        }
    }

    function launch(tool) {
        if (!tool || page.unavailableReason(tool) !== "")
            return;
        const argv = [page.dmsBin, "ipc", "call"].concat(tool.ipc);
        page.requestClose();
        Quickshell.execDetached(argv);
    }

    function launchFirst() {
        const first = page.filteredTools.find(t => page.unavailableReason(t) === "");
        if (first)
            page.launch(first);
    }

    implicitWidth: 744
    implicitHeight: 410

    Connections {
        target: BarWidgetService
        function onWidgetRegistered() {
            page.revision++;
        }
        function onWidgetUnregistered() {
            page.revision++;
        }
    }

    Connections {
        target: PluginService
        function onPluginLoaded() {
            page.revision++;
        }
        function onPluginUnloaded() {
            page.revision++;
        }
    }

    Item {
        id: toolbar

        width: parent.width
        height: 36

        DankTextField {
            id: searchField

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 240
            height: parent.height
            placeholderText: "Buscar ferramenta"
            leftIconName: "search"
            leftIconSize: Theme.iconSizeSmall
            showClearButton: true
            onAccepted: page.launchFirst()
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingXS

            Repeater {
                model: page.categories

                Rectangle {
                    id: chip

                    required property var modelData
                    readonly property bool selected: page.category === modelData.id

                    width: chipLabel.implicitWidth + Theme.spacingM * 2
                    height: 28
                    radius: height / 2
                    color: selected ? Theme.withAlpha(Theme.primary, 0.18) : (chipArea.containsMouse ? Theme.surfaceTextHover : Theme.withAlpha(Theme.surfaceContainerHigh, 0.6))
                    border.width: 1
                    border.color: selected ? Theme.withAlpha(Theme.primary, 0.6) : Theme.outlineMedium

                    StyledText {
                        id: chipLabel

                        anchors.centerIn: parent
                        text: chip.modelData.text
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: chip.selected ? Font.Medium : Font.Normal
                        color: chip.selected ? Theme.primary : Theme.surfaceText
                    }

                    MouseArea {
                        id: chipArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.category = chip.modelData.id
                    }
                }
            }
        }
    }

    DankGridView {
        id: grid

        anchors.top: toolbar.bottom
        anchors.topMargin: Theme.spacingM
        anchors.bottom: footer.top
        anchors.bottomMargin: Theme.spacingS
        width: parent.width
        clip: true
        model: page.filteredTools
        cellWidth: width / page.columns
        cellHeight: page.cardHeight + page.gap

        delegate: Item {
            id: cell

            required property var modelData
            readonly property string reason: page.unavailableReason(modelData)
            readonly property bool available: reason === ""
            readonly property string stateText: page.desktopState(modelData)
            readonly property color accent: page.categoryColor(modelData.category)

            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                id: card

                x: 0
                y: 0
                width: parent.width - page.gap
                height: page.cardHeight
                radius: Theme.cornerRadius
                opacity: cell.available ? 1 : 0.5
                color: cell.available && cardArea.containsMouse ? Theme.withAlpha(cell.accent, 0.12) : Theme.withAlpha(Theme.surfaceContainerHigh, 0.6)
                border.width: 1
                border.color: cell.available && cardArea.containsMouse ? Theme.withAlpha(cell.accent, 0.6) : Theme.outlineMedium

                Rectangle {
                    id: iconBadge

                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 36
                    radius: 18
                    color: Theme.withAlpha(cell.accent, 0.16)

                    DankIcon {
                        anchors.centerIn: parent
                        name: cell.modelData.icon
                        size: Theme.iconSizeSmall + 2
                        color: cell.available ? cell.accent : Theme.surfaceVariantText
                        filled: cell.available && cardArea.containsMouse
                    }
                }

                Column {
                    anchors.left: iconBadge.right
                    anchors.leftMargin: Theme.spacingS
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacingS
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Row {
                        width: parent.width
                        spacing: Theme.spacingXS

                        StyledText {
                            id: titleLabel

                            width: Math.min(implicitWidth, parent.width - (stateBadge.visible ? stateBadge.width + parent.spacing : 0))
                            text: cell.modelData.name
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            font.pixelSize: Theme.fontSizeSmall + 1
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }

                        Rectangle {
                            id: stateBadge

                            anchors.verticalCenter: titleLabel.verticalCenter
                            visible: cell.stateText !== ""
                            width: stateLabel.implicitWidth + Theme.spacingS
                            height: stateLabel.implicitHeight + 2
                            radius: height / 2
                            color: cell.stateText === "Visível" ? Theme.withAlpha(Theme.primary, 0.18) : Theme.withAlpha(Theme.surfaceVariantText, 0.14)

                            StyledText {
                                id: stateLabel

                                anchors.centerIn: parent
                                text: cell.stateText
                                font.pixelSize: Theme.fontSizeSmall - 2
                                color: cell.stateText === "Visível" ? Theme.primary : Theme.surfaceVariantText
                            }
                        }
                    }

                    StyledText {
                        width: parent.width
                        text: cell.available ? cell.modelData.desc : cell.reason
                        wrapMode: Text.WordWrap
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        font.pixelSize: Theme.fontSizeSmall - 1
                        color: cell.available ? Theme.surfaceVariantText : Theme.warning
                    }
                }

                MouseArea {
                    id: cardArea

                    anchors.fill: parent
                    enabled: cell.available
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.launch(cell.modelData)
                }
            }
        }
    }

    Column {
        anchors.centerIn: grid
        spacing: Theme.spacingS
        visible: page.filteredTools.length === 0

        DankIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: "search_off"
            size: Theme.iconSizeLarge
            color: Theme.surfaceVariantText
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Nenhuma ferramenta encontrada"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }
    }

    StyledText {
        id: footer

        anchors.bottom: parent.bottom
        width: parent.width
        text: "Hydrate, System Monitor+ e plugins de captura de teclado exigem pílula na barra (opcionais). HiddenBar e QuickCapture são incompatíveis com DMS 1.4.6."
        elide: Text.ElideRight
        maximumLineCount: 1
        font.pixelSize: Theme.fontSizeSmall - 2
        color: Theme.surfaceVariantText
    }
}
