// Relógio da DankBar no formato da barra de tarefas do Windows: hora em cima,
// data embaixo, centralizadas. Clique abre o painel do DMS (calendário).
import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property date agora: new Date()

    // As duas linhas precisam caber dentro da pílula (widgetThickness, que o
    // "padding interno" da barra controla), com folga em cima e embaixo. A
    // largura já recebe o "padding do widget" pelo BarPill do DMS.
    // O tamanho sai da altura visível dos dígitos, não da caixa da linha
    // (que tem espaço vazio de ascent/descent e não caberia duas vezes).
    readonly property real folgaVertical: Math.max(2, root.widgetThickness * 0.1)
    readonly property real entreLinhas: Math.max(1, root.widgetThickness * 0.08)
    readonly property real alturaUtil: root.widgetThickness - 2 * folgaVertical - entreLinhas
    readonly property real digitoPorPx: medidaFonte.tightBoundingRect("0").height / 100
    readonly property real ascentPorPx: medidaFonte.ascent / 100
    readonly property int tamanhoHora: Math.min(Math.round(root.textSize * 1.4), Math.floor(alturaUtil * (1.2 / 2.25) / digitoPorPx))
    readonly property int tamanhoData: Math.min(Math.round(root.textSize * 1.2), Math.floor(alturaUtil * (1.05 / 2.25) / digitoPorPx))

    FontMetrics {
        id: medidaFonte
        font.family: Theme.fontFamily
        font.pixelSize: 100
    }

    // Uma linha recortada na altura dos dígitos: o texto sobe até o topo do
    // dígito encostar no topo da caixa.
    component LinhaDigitos: Item {
        id: linha
        property alias text: rotulo.text
        property int tamanho: 12
        property int peso: Font.Normal
        property real opacidade: 1
        implicitWidth: rotulo.implicitWidth
        implicitHeight: Math.ceil(root.digitoPorPx * tamanho)

        StyledText {
            id: rotulo
            y: -Math.round((root.ascentPorPx - root.digitoPorPx) * linha.tamanho)
            font.pixelSize: linha.tamanho
            font.weight: linha.peso
            color: Theme.widgetTextColor
            opacity: linha.opacidade
        }
    }

    Timer {
        // Acorda no começo de cada segundo pra virar o minuto na hora certa.
        interval: 1000 - (new Date().getMilliseconds())
        running: true
        repeat: true
        onTriggered: {
            root.agora = new Date();
            interval = 1000;
        }
    }

    pillClickAction: () => Quickshell.execDetached(["dms", "ipc", "call", "dash", "toggle", "overview"])

    horizontalBarPill: Component {
        Column {
            spacing: root.entreLinhas

            LinhaDigitos {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(root.agora, "HH:mm")
                tamanho: root.tamanhoHora
                peso: Font.Medium
            }
            LinhaDigitos {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(root.agora, "dd/MM/yyyy")
                tamanho: root.tamanhoData
                opacidade: 0.85
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 0
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(root.agora, "HH\nmm")
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: root.textSize
                color: Theme.widgetTextColor
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(root.agora, "dd/MM")
                font.pixelSize: Math.round(root.textSize * 0.8)
                color: Theme.widgetTextColor
                opacity: 0.85
            }
        }
    }
}
