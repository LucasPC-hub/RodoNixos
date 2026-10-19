pragma Singleton
import QtQuick
import qs.Common
QtObject {
    function alpha(color, opacity) { return Theme.withAlpha(color, opacity); }
}
