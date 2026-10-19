import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: panel

    required property var hub
    // Injected by PluginPopout.
    property var closePopout: null

    readonly property real pageHeight: 410
    readonly property var tabs: [
        {
            "icon": "space_dashboard",
            "text": "Painel"
        },
        {
            "icon": "monitoring",
            "text": "Desempenho"
        },
        {
            "icon": "partly_cloudy_day",
            "text": "Clima"
        },
        {
            "icon": "apps",
            "text": "Ferramentas"
        }
    ]

    function close() {
        if (typeof closePopout === "function")
            closePopout();
    }

    width: parent ? parent.width : 744
    implicitHeight: tabRow.height + Theme.spacingM + pageHeight

    Row {
        id: tabRow

        width: parent.width
        height: 34
        spacing: Theme.spacingS

        Repeater {
            model: panel.tabs

            Rectangle {
                id: tab

                required property var modelData
                required property int index
                readonly property bool selected: panel.hub.currentTab === index

                width: (tabRow.width - tabRow.spacing * (panel.tabs.length - 1)) / panel.tabs.length
                height: tabRow.height
                radius: Theme.cornerRadius
                color: selected ? Theme.withAlpha(Theme.primary, 0.18) : (tabArea.containsMouse ? Theme.surfaceTextHover : Theme.withAlpha(Theme.surfaceContainerHigh, 0.6))
                border.width: 1
                border.color: selected ? Theme.withAlpha(Theme.primary, 0.6) : Theme.outlineMedium

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacingXS

                    DankIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: tab.modelData.icon
                        size: Theme.iconSizeSmall
                        color: tab.selected ? Theme.primary : Theme.surfaceVariantText
                        filled: tab.selected
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: tab.modelData.text
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: tab.selected ? Font.Medium : Font.Normal
                        color: tab.selected ? Theme.primary : Theme.surfaceText
                    }
                }

                MouseArea {
                    id: tabArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: panel.hub.currentTab = tab.index
                }
            }
        }
    }

    Loader {
        id: pageLoader

        anchors.top: tabRow.bottom
        anchors.topMargin: Theme.spacingM
        width: parent.width
        height: panel.pageHeight
        sourceComponent: {
            switch (panel.hub.currentTab) {
            case 1:
                return performanceComponent;
            case 2:
                return weatherComponent;
            case 3:
                return toolsComponent;
            default:
                return dashboardComponent;
            }
        }
    }

    Component {
        id: dashboardComponent

        DashboardPage {
            onRequestClose: panel.close()
            onRequestWeather: panel.hub.currentTab = 2
        }
    }

    Component {
        id: performanceComponent

        PerformancePage {
            onRequestClose: panel.close()
        }
    }

    Component {
        id: weatherComponent

        WeatherPage {}
    }

    Component {
        id: toolsComponent

        ToolsPage {
            onRequestClose: panel.close()
        }
    }
}
