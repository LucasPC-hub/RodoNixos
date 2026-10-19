import QtQuick
import Quickshell
import qs.Common
import qs.Widgets as Dms

Item {
    id: root
    property Item anchorItem: null
    property var bar: null
    property var owner: null
    property bool open: false
    property Item focusTarget: null
    property real contentWidth: 450
    property real contentHeight: 640
    property var targetScreen: Quickshell.screens[0] ?? null
    default property alias contentData: holder.data

    function fittedContentWidth(value) {
        return Math.max(1, Math.min(value, (targetScreen?.width || 1920) - Theme.spacingL * 2));
    }
    function fittedContentHeight(value, maximum) {
        return Math.max(1, Math.min(value, maximum || value, (targetScreen?.height || 1080) - 100));
    }
    function setTriggerPosition(x, y, width, section, screen, position, thickness, spacing, config) {
        targetScreen = screen || Quickshell.screens[0];
        popup.setTriggerPosition(x, y, width, section, targetScreen, position, thickness, spacing, config);
    }
    function refocus() {
        Qt.callLater(function() { if (root.open && root.focusTarget) root.focusTarget.forceActiveFocus(); });
    }
    onFocusTargetChanged: { if (open) refocus(); }
    onOpenChanged: {
        if (open) { popup.open(); refocus(); }
        else popup.close();
    }

    Item {
        id: holder
        anchors.fill: parent
    }

    Dms.DankPopout {
        id: popup
        layerNamespace: "dms:bitwarden"
        screen: root.targetScreen
        popupWidth: root.contentWidth + Theme.spacingM * 2
        popupHeight: root.contentHeight + Theme.spacingM * 2
        contentHandlesKeys: true
        onBackgroundClicked: root.owner.close()
        onPopoutClosed: { if (root.open) root.owner.close(); }
        onOpened: root.refocus()
        content: Component {
            Item {
                implicitHeight: root.contentHeight + Theme.spacingM * 2
                Component.onCompleted: {
                    holder.parent = this;
                    holder.anchors.margins = Theme.spacingM;
                    root.refocus();
                }
                Component.onDestruction: holder.parent = root
            }
        }
    }
}
