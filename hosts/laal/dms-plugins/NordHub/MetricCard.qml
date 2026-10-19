import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.DankDash.Overview as Overview

Overview.Card {
    id: root

    property string iconName: ""
    property string title: ""
    property string valueText: "--"
    property color valueColor: Theme.surfaceText
    property string detailText: ""
    property string footerText: ""
    property alias history: chart.values
    property alias historyMax: chart.maxValue
    property alias historyColor: chart.lineColor
    property alias revision: chart.revision

    Row {
        id: header

        width: parent.width
        spacing: Theme.spacingS

        DankIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.iconName
            size: Theme.iconSizeSmall + 2
            color: Theme.primary
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            width: header.width - Theme.iconSizeSmall - 2 - header.spacing
            elide: Text.ElideRight
            maximumLineCount: 1
            text: root.title
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: Theme.surfaceVariantText
        }
    }

    StyledText {
        id: valueLabel

        anchors.top: header.bottom
        anchors.topMargin: Theme.spacingXS
        text: root.valueText
        font.pixelSize: Theme.fontSizeXLarge + 2
        font.weight: Font.Medium
        color: root.valueColor
    }

    Column {
        anchors.top: valueLabel.top
        anchors.right: parent.right
        width: parent.width - valueLabel.width - Theme.spacingM
        spacing: 2

        StyledText {
            width: parent.width
            text: root.detailText
            visible: text !== ""
            horizontalAlignment: Text.AlignRight
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceText
            elide: Text.ElideLeft
        }

        StyledText {
            width: parent.width
            text: root.footerText
            visible: text !== ""
            horizontalAlignment: Text.AlignRight
            font.pixelSize: Theme.fontSizeSmall - 1
            color: Theme.surfaceVariantText
            elide: Text.ElideLeft
        }
    }

    Sparkline {
        id: chart

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: valueLabel.bottom
        anchors.topMargin: Theme.spacingS
    }
}
