import QtQuick
import QtQuick.Effects
import Quickshell.Services.Mpris
import qs.Common
import qs.Services
import qs.Widgets

// Desktop media card: lives on the wlr "bottom" layer (behind windows) via
// DesktopPluginWrapper. Right-drag moves it, the corner handle resizes it.
Item {
    id: root

    // Injected by DesktopPluginWrapper.
    property var pluginService: null
    property string pluginId: ""
    property string instanceId: ""
    property var instanceData: null
    property real widgetWidth: 440
    property real widgetHeight: 150

    property real defaultWidth: 440
    property real defaultHeight: 150
    property real minWidth: 320
    property real minHeight: 120

    readonly property real backgroundOpacity: instanceData?.config?.transparency ?? 0.85

    property MprisPlayer player: MprisController.activePlayer
    readonly property bool hasPlayer: !!player
    readonly property bool playing: player?.playbackState === MprisPlaybackState.Playing
    readonly property real length: player?.length ?? 0
    readonly property real position: player?.position ?? 0
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0
    readonly property real pad: Theme.spacingM + 2

    function formatTime(seconds) {
        if (!seconds || seconds < 0)
            return "0:00";
        const s = Math.floor(seconds);
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const rest = s % 60;
        const mm = h > 0 && m < 10 ? "0" + m : "" + m;
        return (h > 0 ? h + ":" : "") + mm + ":" + (rest < 10 ? "0" : "") + rest;
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.visible && root.playing && (root.player?.positionSupported ?? false)
        onTriggered: root.player.positionChanged()
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius * 1.5
        color: Theme.withAlpha(Theme.surface, root.backgroundOpacity)
        border.width: 1
        border.color: Theme.withAlpha(Theme.outlineVariant, 0.8)
    }

    Rectangle {
        id: artFrame

        x: root.pad
        y: root.pad
        width: root.height - root.pad * 2
        height: width
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        DankIcon {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            name: root.hasPlayer ? "album" : "music_note"
            size: parent.width * 0.4
            color: Theme.surfaceVariantText
        }

        Image {
            id: art
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            sourceSize.width: 256
            sourceSize.height: 256
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }

        Rectangle {
            id: artMask
            anchors.fill: parent
            radius: parent.radius
            visible: false
            layer.enabled: true
        }

        MultiEffect {
            anchors.fill: parent
            visible: art.status === Image.Ready
            source: art
            maskEnabled: true
            maskSource: artMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
    }

    Item {
        id: body

        anchors.left: artFrame.right
        anchors.leftMargin: root.pad
        anchors.right: parent.right
        anchors.rightMargin: root.pad
        anchors.top: artFrame.top
        anchors.bottom: artFrame.bottom

        Column {
            anchors.left: parent.left
            anchors.right: playButton.left
            anchors.rightMargin: Theme.spacingS
            anchors.top: parent.top
            spacing: 2

            StyledText {
                width: parent.width
                text: root.hasPlayer ? (root.player.trackTitle || "Sem título") : "Nada tocando"
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Medium
                color: Theme.surfaceText
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            StyledText {
                width: parent.width
                text: root.hasPlayer ? (root.player.trackArtist || root.player.identity || "") : "Nenhum player MPRIS ativo"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            StyledText {
                visible: root.hasPlayer && root.length > 0
                text: root.formatTime(root.position) + " / " + root.formatTime(root.length)
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
        }

        Rectangle {
            id: playButton

            anchors.right: parent.right
            anchors.top: parent.top
            width: 48
            height: 48
            radius: Theme.cornerRadius + 4
            visible: root.hasPlayer
            color: playArea.containsMouse ? Qt.lighter(Theme.primaryContainer, 1.12) : Theme.primaryContainer

            DankIcon {
                anchors.centerIn: parent
                name: root.playing ? "pause" : "play_arrow"
                size: 26
                filled: true
                color: Theme.surfaceText
            }

            MouseArea {
                id: playArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: root.player?.canTogglePlaying ?? false
                onClicked: root.player.togglePlaying()
            }
        }

        Row {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 28
            spacing: Theme.spacingS
            visible: root.hasPlayer

            DankActionButton {
                anchors.verticalCenter: parent.verticalCenter
                iconName: "skip_previous"
                buttonSize: 28
                enabled: root.player?.canGoPrevious ?? false
                opacity: enabled ? 1 : 0.4
                onClicked: root.player.previous()
            }

            Item {
                id: seek

                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 28 * 2 - parent.spacing * 2
                height: 20

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Theme.withAlpha(Theme.surfaceVariant, 0.9)
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * root.progress
                    height: 4
                    radius: 2
                    color: Theme.primary
                }

                Rectangle {
                    visible: root.length > 0
                    x: parent.width * root.progress - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 4
                    height: 14
                    radius: 2
                    color: Theme.primary
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: (root.player?.canSeek ?? false) && root.length > 0
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: mouse => {
                        const ratio = Math.max(0, Math.min(1, mouse.x / width));
                        root.player.position = Math.min(ratio * root.length, root.length * 0.99);
                    }
                }
            }

            DankActionButton {
                anchors.verticalCenter: parent.verticalCenter
                iconName: "skip_next"
                buttonSize: 28
                enabled: root.player?.canGoNext ?? false
                opacity: enabled ? 1 : 0.4
                onClicked: root.player.next()
            }
        }
    }
}
