import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.DankDash.Overview as Overview

Item {
    id: page

    signal requestClose

    readonly property var modules: ["cpu", "memory", "network", "disk", "diskmounts", "system"]
    readonly property real gap: Theme.spacingM
    readonly property real cardWidth: (width - gap) / 2
    readonly property real cardHeight: 150
    property int sample: 0

    readonly property var rootMount: {
        const mounts = DgopService.diskMounts || [];
        return mounts.find(m => m.mount === "/") || mounts[0] || null;
    }
    readonly property var homeMount: (DgopService.diskMounts || []).find(m => m.mount === "/home") || null

    function formatRate(bytesPerSecond) {
        const v = bytesPerSecond || 0;
        if (v >= 1024 * 1024)
            return (v / (1024 * 1024)).toFixed(1) + " MB/s";
        if (v >= 1024)
            return (v / 1024).toFixed(0) + " KB/s";
        return v.toFixed(0) + " B/s";
    }

    function usageColor(percent, warn, danger) {
        if (percent >= danger)
            return Theme.error;
        if (percent >= warn)
            return Theme.warning;
        return Theme.surfaceText;
    }

    Component.onCompleted: DgopService.addRef(modules)
    Component.onDestruction: DgopService.removeRef(modules)

    Connections {
        target: DgopService
        function onIsUpdatingChanged() {
            if (!DgopService.isUpdating)
                page.sample++;
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: Theme.spacingS
        visible: !DgopService.dgopAvailable

        DankIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: "monitoring"
            size: Theme.iconSizeLarge
            color: Theme.surfaceVariantText
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "dgop não encontrado: métricas indisponíveis"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }
    }

    Item {
        anchors.fill: parent
        visible: DgopService.dgopAvailable

        MetricCard {
            x: 0
            y: 0
            width: page.cardWidth
            height: page.cardHeight
            iconName: "memory"
            title: "CPU" + (DgopService.cpuModel ? " · " + DgopService.cpuModel : "")
            valueText: DgopService.cpuUsage.toFixed(0) + "%"
            valueColor: page.usageColor(DgopService.cpuUsage, 60, 85)
            detailText: [DgopService.cpuTemperature > 0 ? DgopService.cpuTemperature + " °C" : "", DgopService.cpuFrequency > 0 ? (DgopService.cpuFrequency / 1000).toFixed(2) + " GHz" : ""].filter(s => s).join(" · ")
            footerText: DgopService.cpuCores + " núcleos"
            history: DgopService.cpuHistory
            historyMax: 100
            revision: page.sample
        }

        MetricCard {
            x: page.cardWidth + page.gap
            y: 0
            width: page.cardWidth
            height: page.cardHeight
            iconName: "developer_board"
            title: "Memória"
            valueText: DgopService.memoryUsage.toFixed(0) + "%"
            valueColor: page.usageColor(DgopService.memoryUsage, 75, 90)
            detailText: DgopService.formatSystemMemory(DgopService.usedMemoryKB) + " / " + DgopService.formatSystemMemory(DgopService.totalMemoryKB)
            footerText: DgopService.totalSwapKB > 0 ? "swap " + DgopService.formatSystemMemory(DgopService.usedSwapKB) + " / " + DgopService.formatSystemMemory(DgopService.totalSwapKB) : "sem swap"
            history: DgopService.memoryHistory
            historyMax: 100
            historyColor: Theme.secondary
            revision: page.sample
        }

        MetricCard {
            x: 0
            y: page.cardHeight + page.gap
            width: page.cardWidth
            height: page.cardHeight
            iconName: "swap_vert"
            title: "Rede"
            valueText: "↓ " + page.formatRate(DgopService.networkRxRate)
            detailText: "↑ " + page.formatRate(DgopService.networkTxRate)
            footerText: "histórico de download"
            history: DgopService.networkHistory.rx
            historyMax: 0
            historyColor: Theme.info
            revision: page.sample
        }

        MetricCard {
            x: page.cardWidth + page.gap
            y: page.cardHeight + page.gap
            width: page.cardWidth
            height: page.cardHeight
            iconName: "hard_drive"
            title: "Disco" + (page.rootMount ? " · " + page.rootMount.mount : "")
            valueText: page.rootMount ? page.rootMount.percent : "--"
            valueColor: page.usageColor(page.rootMount ? parseFloat(page.rootMount.percent) || 0 : 0, 80, 92)
            detailText: page.rootMount ? (page.rootMount.used + " / " + page.rootMount.size) : ""
            footerText: "leitura " + page.formatRate(DgopService.diskReadRate) + " · escrita " + page.formatRate(DgopService.diskWriteRate) + (page.homeMount ? " · /home " + page.homeMount.percent : "")
            history: DgopService.diskHistory.read
            historyMax: 0
            historyColor: Theme.warning
            revision: page.sample
        }

        Overview.Card {
            x: 0
            y: (page.cardHeight + page.gap) * 2
            width: page.width
            height: page.height - y
            pad: Theme.spacingS

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacingS
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingL

                Repeater {
                    model: [
                        {
                            "icon": "schedule",
                            "text": DgopService.shortUptime ? DgopService.shortUptime.replace(/^up\s*/, "ligado há ") : "--"
                        },
                        {
                            "icon": "speed",
                            "text": DgopService.loadAverage ? "carga " + DgopService.loadAverage : "--"
                        },
                        {
                            "icon": "account_tree",
                            "text": DgopService.processCount + " processos · " + DgopService.threadCount + " threads"
                        }
                    ]

                    Row {
                        required property var modelData
                        spacing: Theme.spacingXS

                        DankIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: parent.modelData.icon
                            size: Theme.iconSizeSmall
                            color: Theme.primary
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.modelData.text
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacingXS
                anchors.verticalCenter: parent.verticalCenter
                width: processRow.implicitWidth + Theme.spacingL * 2
                height: 34
                radius: Theme.cornerRadius
                color: processArea.containsMouse ? Theme.primaryPressed : Theme.primaryHover

                Row {
                    id: processRow
                    anchors.centerIn: parent
                    spacing: Theme.spacingXS

                    DankIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "list_alt"
                        size: Theme.iconSizeSmall
                        color: Theme.primary
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Processos"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: Theme.primary
                    }
                }

                MouseArea {
                    id: processArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        page.requestClose();
                        PopoutService.showProcessListModal();
                    }
                }
            }
        }
    }
}
