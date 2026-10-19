pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

// The plugin's own catalogue: DMS 1.4.6 has no per-plugin translations, so
// translations/<locale>.json is read here, trying the same locale candidates
// as DMS's I18n (full tag, hyphenated tag, language). English, the source
// language, needs no file; DMS's shell catalogue is the fallback.
Singleton {
    id: root

    readonly property string context: "bitwarden"
    readonly property var candidates: {
        const raw = Qt.locale().name;
        const lang = raw.split(/[_-]/)[0];
        return [raw, raw.replace("_", "-"), lang].filter((c, i, all) => c && c !== "en" && c !== "C" && all.indexOf(c) === i);
    }
    property int candidateIndex: 0
    property var table: ({})

    FileView {
        path: root.candidateIndex < root.candidates.length
            ? Qt.resolvedUrl("../translations/" + root.candidates[root.candidateIndex] + ".json") : ""
        printErrors: false
        onLoaded: {
            try {
                root.table = JSON.parse(text()) || ({});
            } catch (e) {
                console.warn("bitwarden: unreadable translation catalogue", path, e.message);
                root.table = ({});
            }
        }
        onLoadFailed: root.candidateIndex += 1
    }

    function lookup(term) {
        const bucket = table[context];
        if (bucket && bucket[term])
            return bucket[term];
        for (const c in table) {
            if (table[c] && table[c][term])
                return table[c][term];
        }
        return "";
    }

    function text(term) {
        const source = term || "";
        return lookup(source) || I18n.tr(source, context);
    }

    function format(term, ...values) {
        return text(term).replace(/%([1-9][0-9]*)/g, (match, index) => {
            const value = values[Number(index) - 1];
            return value === undefined ? match : String(value);
        });
    }
}
