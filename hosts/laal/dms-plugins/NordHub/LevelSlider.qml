import QtQuick
import qs.Common
import qs.Widgets

// Vertical level control: icon (click = secondary action), track, percentage.
Column {
    id: root

    property real value: 0
    property real minimum: 0
    property string iconName: ""
    property bool dimmed: false

    signal moved(real value)
    signal iconClicked

    spacing: Theme.spacingXS
    width: 36

    function _emit(v) {
        root.moved(Math.max(root.minimum, Math.min(1, v)));
    }

    Rectangle {
        width: 32
        height: 32
        radius: 16
        anchors.horizontalCenter: parent.horizontalCenter
        color: iconArea.containsMouse ? Theme.primaryHover : "transparent"

        DankIcon {
            anchors.centerIn: parent
            name: root.iconName
            size: Theme.iconSizeSmall + 2
            color: root.dimmed ? Theme.surfaceVariantText : Theme.primary
        }

        MouseArea {
            id: iconArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }

    Rectangle {
        id: track

        width: 14
        height: Math.max(60, root.height - 32 - percentText.height - root.spacing * 2)
        radius: width / 2
        anchors.horizontalCenter: parent.horizontalCenter
        color: Theme.withAlpha(Theme.surfaceContainerHighest, 0.9)

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: Math.max(parent.width, parent.height * Math.max(0, Math.min(1, root.value)))
            radius: parent.radius
            color: root.dimmed ? Theme.outline : Theme.primary
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            preventStealing: true
            onPressed: mouse => root._emit(1 - (mouse.y - 6) / track.height)
            onPositionChanged: mouse => {
                if (pressed)
                    root._emit(1 - (mouse.y - 6) / track.height);
            }
            onWheel: wheel => root._emit(root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))
        }
    }

    StyledText {
        id: percentText
        anchors.horizontalCenter: parent.horizontalCenter
        text: Math.round(root.value * 100) + "%"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }
}
