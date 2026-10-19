pragma Singleton
import QtQuick
import qs.Common
QtObject {
    function none() { return {width: 0, color: "transparent"}; }
    function top(s) { return s ? s.width : 0; }
    function right(s) { return top(s); }
    function bottom(s) { return top(s); }
    function left(s) { return top(s); }
    function color(s) { return s ? s.color : "transparent"; }
    function uniformWidth(s) { return top(s); }
    function canUseNative(s) { return true; }
    function needsOverlay(s) { return false; }
    function controlHasWidth(state) { return true; }
    function controlSpec(state, fg, accent) {
        return {width: 1, color: state === "focus" ? (accent || Theme.primary) : Theme.withAlpha(fg || Theme.outline, 0.25)};
    }
    function surfaceSpec(surface, role, c, w) { return {width: w || 1, color: c || Theme.outline}; }
    function localOrSurfaceSpec(surface, role, c, fallback, w) { return {width: w || 1, color: c || fallback}; }
}
