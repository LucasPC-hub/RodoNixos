import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets

// "Meus Comandos": desktop card listing the same catalog as the `help`/`ajuda`
// shell command. commands.py (next to this file) only reads local files and
// prints JSON; nothing listed here is ever executed. Copy goes through
// `dms cl copy` as argv, so the copied text is never interpreted by a shell.
Item {
    id: root

    // Injected by DesktopPluginWrapper.
    property var pluginService: null
    property string pluginId: ""
    property string instanceId: ""
    property var instanceData: null
    property real widgetWidth: 430
    property real widgetHeight: 245

    property real defaultWidth: 430
    property real defaultHeight: 245
    property real minWidth: 380
    property real minHeight: 230
    property bool acceptsKeyboardFocus: true

    readonly property real backgroundOpacity: instanceData?.config?.transparency ?? 0.85
    readonly property real pad: Theme.spacingS + 2
    readonly property string helperPath: decodeURIComponent(Qt.resolvedUrl("commands.py").toString().replace(/^file:\/\//, ""))

    readonly property var kindLabels: ({
            "alias": "alias",
            "function": "função",
            "script": "script",
            "system-alias": "alias do sistema",
            "ssh": "host SSH",
            "shortcut": "atalho"
        })
    readonly property var kindIcons: ({
            "alias": "terminal",
            "function": "function",
            "script": "code",
            "system-alias": "deployed_code",
            "ssh": "dns",
            "shortcut": "keyboard"
        })

    // Catalog state.
    property var categories: []
    property var commands: []
    property var warnings: []
    property bool loaded: false
    property bool loading: false
    property string loadError: ""
    property bool _loadExited: false
    property bool _loadStdoutDone: false
    property int _loadExitCode: 0

    // Filter state.
    property string query: ""
    property string selectedCategory: ""
    property string expandedId: ""

    readonly property var queryTerms: fold(query).split(/\s+/).filter(term => term.length > 0)
    readonly property var queryMatches: commands.filter(cmd => queryTerms.every(term => cmd.searchKey.indexOf(term) !== -1))
    readonly property var visibleCommands: selectedCategory === "" ? queryMatches : queryMatches.filter(cmd => cmd.category === selectedCategory)
    readonly property var matchCounts: {
        const counts = {
            "": queryMatches.length
        };
        for (const cmd of queryMatches)
            counts[cmd.category] = (counts[cmd.category] || 0) + 1;
        return counts;
    }
    readonly property bool filtering: queryTerms.length > 0 || selectedCategory !== ""
    readonly property var chipModel: [
        {
            "id": "",
            "title": "Todos",
            "icon": "apps"
        }
    ].concat(categories)

    // Copy feedback state.
    property string copyingId: ""
    property string copyingText: ""
    property bool _copyExited: false
    property string feedbackId: ""
    property bool feedbackOk: false
    property string feedbackText: ""
    property bool feedbackVisible: false

    function fold(value) {
        let text = String(value ?? "");
        if (typeof text.normalize === "function")
            text = text.normalize("NFD");
        return text.replace(/[\u0300-\u036f]/g, "").toLowerCase();
    }

    function str(value) {
        return value === undefined || value === null ? "" : String(value);
    }

    function copyTextFor(cmd) {
        return cmd.command !== "" ? cmd.command : cmd.name;
    }

    function kindLabel(kind) {
        return kindLabels[kind] ?? kind;
    }

    function refresh() {
        if (loading)
            return;
        loading = true;
        _loadExited = false;
        _loadStdoutDone = false;
        _loadExitCode = 0;
        loadProc.running = true;
    }

    function _finishLoad() {
        if (!loading || !_loadExited || !_loadStdoutDone)
            return;
        loading = false;
        if (_loadExitCode !== 0) {
            const reason = loadStderr.text.trim().split("\n").pop();
            loadError = "commands.py saiu com código " + _loadExitCode + (reason ? ": " + reason : "");
            return;
        }
        applyCatalog(loadStdout.text);
    }

    function _checkLoadStart() {
        if (loading && !_loadExited && !loadProc.running) {
            loading = false;
            loadError = "Não foi possível executar python3";
        }
    }

    function applyCatalog(text) {
        let data;
        try {
            data = JSON.parse(text);
        } catch (e) {
            loadError = "Resposta inválida do commands.py";
            return;
        }
        if (!data || data.version !== 1 || !Array.isArray(data.categories) || !Array.isArray(data.commands)) {
            loadError = "Formato de catálogo não reconhecido";
            return;
        }

        const cats = [];
        const titles = {};
        for (const raw of data.categories) {
            const id = str(raw?.id);
            if (id === "" || id in titles)
                continue;
            titles[id] = str(raw.title) || id;
            cats.push({
                "id": id,
                "title": titles[id],
                "icon": str(raw.icon) || "label"
            });
        }

        const cmds = [];
        const seen = {};
        data.commands.forEach((raw, index) => {
            if (!raw || typeof raw !== "object")
                return;
            const name = str(raw.name);
            const command = str(raw.command);
            if (name === "" && command === "")
                return;
            const category = str(raw.category);
            let uid = str(raw.id) || (category + ":" + name);
            if (uid in seen)
                uid += "#" + index;
            seen[uid] = true;
            const cmd = {
                "uid": uid,
                "category": category,
                "categoryTitle": titles[category] ?? category,
                "name": name || command,
                "command": command,
                "detail": str(raw.detail),
                "description": str(raw.description),
                "kind": str(raw.kind),
                "source": str(raw.source)
            };
            cmd.searchKey = fold([cmd.name, cmd.command, cmd.description, cmd.detail, cmd.categoryTitle, cmd.category, kindLabel(cmd.kind)].join(" "));
            cmds.push(cmd);
        });

        categories = cats;
        commands = cmds;
        warnings = Array.isArray(data.warnings) ? data.warnings.map(w => str(w)) : [];
        loadError = "";
        loaded = true;
        if (selectedCategory !== "" && !(selectedCategory in titles))
            selectedCategory = "";
    }

    function copy(cmd) {
        if (!cmd || copyProc.running)
            return;
        const text = copyTextFor(cmd);
        copyingId = cmd.uid;
        copyingText = text;
        if (text === "") {
            finishCopy(false, "nada para copiar");
            return;
        }
        _copyExited = false;
        // "--" keeps texts starting with "-" from being parsed as dms flags.
        copyProc.command = ["dms", "cl", "copy", "--", text];
        copyProc.running = true;
    }

    function finishCopy(ok, reason) {
        feedbackId = copyingId;
        feedbackOk = ok;
        feedbackText = ok ? copyingText : "Falha ao copiar" + (reason ? ": " + reason : "");
        copyingId = "";
        copyingText = "";
        feedbackVisible = true;
        feedbackTimer.restart();
    }

    function _checkCopyStart() {
        if (copyingId !== "" && !_copyExited && !copyProc.running)
            finishCopy(false, "comando dms indisponível");
    }

    function selectCategory(id) {
        selectedCategory = id;
    }

    function clearFilters() {
        searchField.text = "";
        selectedCategory = "";
    }

    function toggleExpanded(uid) {
        expandedId = expandedId === uid ? "" : uid;
    }

    function resetListPosition() {
        list.savedY = 0;
        list.positionViewAtBeginning();
        list.currentIndex = list.activeFocus && list.count > 0 ? 0 : -1;
    }

    onVisibleCommandsChanged: Qt.callLater(resetListPosition)
    Component.onCompleted: refresh()

    Process {
        id: loadProc

        command: ["python3", root.helperPath, "--json"]
        stdout: StdioCollector {
            id: loadStdout

            onStreamFinished: {
                root._loadStdoutDone = true;
                root._finishLoad();
            }
        }
        stderr: StdioCollector {
            id: loadStderr
        }
        onExited: (exitCode, exitStatus) => {
            root._loadExitCode = exitCode;
            root._loadExited = true;
            root._finishLoad();
        }
        onRunningChanged: {
            if (!running)
                Qt.callLater(root._checkLoadStart);
        }
    }

    Process {
        id: copyProc

        onExited: (exitCode, exitStatus) => {
            root._copyExited = true;
            root.finishCopy(exitCode === 0, exitCode === 0 ? "" : "dms saiu com código " + exitCode);
        }
        onRunningChanged: {
            if (!running)
                Qt.callLater(root._checkCopyStart);
        }
    }

    Timer {
        id: feedbackTimer

        interval: 1800
        onTriggered: root.feedbackVisible = false
    }

    component ShelfButton: Rectangle {
        id: button

        property string iconName: ""
        property int iconSize: 18
        property color iconColor: Theme.surfaceVariantText
        property string tooltipText: ""
        property bool spinning: false

        signal clicked

        width: 28
        height: 28
        radius: Theme.cornerRadius
        color: "transparent"
        activeFocusOnTab: true
        border.width: activeFocus ? 2 : 0
        border.color: Theme.primary
        opacity: enabled ? 1 : 0.45
        Accessible.role: Accessible.Button
        Accessible.name: tooltipText

        onSpinningChanged: {
            if (!spinning)
                buttonIcon.rotation = 0;
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                button.clicked();
                event.accepted = true;
            }
        }

        DankIcon {
            id: buttonIcon

            anchors.centerIn: parent
            name: button.iconName
            size: button.iconSize
            color: button.iconColor

            RotationAnimation on rotation {
                running: button.spinning
                from: 0
                to: 360
                duration: 900
                loops: Animation.Infinite
            }
        }

        StateLayer {
            disabled: !button.enabled
            stateColor: Theme.primary
            tooltipText: button.tooltipText || null
            onClicked: button.clicked()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius * 1.5
        color: Theme.withAlpha(Theme.surface, root.backgroundOpacity)
        border.width: 1
        border.color: Theme.withAlpha(Theme.outlineVariant, 0.8)
    }

    Item {
        id: header

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.pad
        height: 30

        Rectangle {
            id: badge

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            height: 30
            radius: Theme.cornerRadius
            color: Theme.withAlpha(Theme.primary, 0.18)

            DankIcon {
                anchors.centerIn: parent
                name: "terminal"
                size: 18
                color: Theme.primary
            }
        }

        Column {
            anchors.left: badge.right
            anchors.leftMargin: Theme.spacingS
            anchors.right: refreshButton.left
            anchors.rightMargin: Theme.spacingS
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            StyledText {
                width: parent.width
                text: "Meus Comandos"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
                wrapMode: Text.NoWrap
                maximumLineCount: 1
            }

            StyledText {
                width: parent.width
                textFormat: Text.PlainText
                wrapMode: Text.NoWrap
                maximumLineCount: 1
                font.pixelSize: Theme.fontSizeSmall - 1
                color: root.loadError !== "" ? Theme.error : Theme.surfaceVariantText
                text: {
                    let status;
                    if (!root.loaded)
                        status = root.loading ? "carregando…" : (root.loadError || "indisponível");
                    else if (root.filtering)
                        status = root.visibleCommands.length + " de " + root.commands.length + " comandos";
                    else
                        status = root.commands.length + (root.commands.length === 1 ? " comando" : " comandos");
                    if (root.loaded && root.warnings.length > 0)
                        status += " · " + root.warnings.length + (root.warnings.length === 1 ? " aviso" : " avisos");
                    if (root.loaded && root.loading)
                        status += " · atualizando…";
                    else if (root.loaded && root.loadError !== "")
                        status += " · falha ao atualizar: " + root.loadError;
                    return "help · ajuda · " + status;
                }
            }
        }

        ShelfButton {
            id: refreshButton

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            iconName: "refresh"
            tooltipText: "Recarregar catálogo"
            spinning: root.loading
            enabled: !root.loading
            onClicked: root.refresh()
        }
    }

    Item {
        id: searchKeys

        Keys.onPressed: event => {
            if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
                return;
            switch (event.key) {
            case Qt.Key_Escape:
                if (searchField.text !== "" || root.selectedCategory !== "") {
                    root.clearFilters();
                    event.accepted = true;
                }
                break;
            case Qt.Key_Down:
                if (list.count > 0) {
                    list.forceActiveFocus();
                    list.currentIndex = 0;
                    event.accepted = true;
                }
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (list.count > 0) {
                    root.copy(root.visibleCommands[0]);
                    event.accepted = true;
                }
                break;
            }
        }
    }

    DankTextField {
        id: searchField

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.leftMargin: root.pad
        anchors.rightMargin: root.pad
        anchors.topMargin: Theme.spacingS - 2
        height: 32
        topPadding: 4
        bottomPadding: 4
        font.pixelSize: Theme.fontSizeSmall + 1
        backgroundColor: Theme.withAlpha(Theme.surfaceContainerHigh, 0.6)
        leftIconName: "search"
        leftIconSize: 16
        showClearButton: true
        placeholderText: "Buscar nome, descrição ou categoria"
        keyForwardTargets: [searchKeys]
        onTextEdited: root.query = text
    }

    ListView {
        id: chips

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: searchField.bottom
        anchors.leftMargin: root.pad
        anchors.rightMargin: root.pad
        anchors.topMargin: Theme.spacingS - 2
        height: 26
        orientation: ListView.Horizontal
        spacing: 6
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        activeFocusOnTab: true
        keyNavigationEnabled: false
        model: root.chipModel
        currentIndex: Math.max(0, root.chipModel.findIndex(chip => chip.id === root.selectedCategory))
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

        function step(delta) {
            const next = Math.max(0, Math.min(count - 1, currentIndex + delta));
            root.selectCategory(root.chipModel[next].id);
        }

        Keys.onLeftPressed: chips.step(-1)
        Keys.onRightPressed: chips.step(1)
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Down && list.count > 0) {
                list.forceActiveFocus();
                list.currentIndex = 0;
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                searchField.forceActiveFocus();
                event.accepted = true;
            }
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                const delta = event.pixelDelta.x || event.pixelDelta.y || (event.angleDelta.y || event.angleDelta.x) / 2;
                const maxX = Math.max(chips.originX, chips.originX + chips.contentWidth - chips.width);
                chips.contentX = Math.max(chips.originX, Math.min(maxX, chips.contentX - delta));
                event.accepted = true;
            }
        }

        delegate: Rectangle {
            id: chip

            required property var modelData
            required property int index
            readonly property bool selected: modelData.id === root.selectedCategory
            readonly property int matches: root.matchCounts[modelData.id] ?? 0

            width: chipRow.implicitWidth + 18
            height: 26
            radius: 13
            color: selected ? Theme.withAlpha(Theme.primary, 0.22) : Theme.withAlpha(Theme.surfaceContainerHigh, chipArea.containsMouse ? 0.85 : 0.55)
            border.width: chips.activeFocus && ListView.isCurrentItem ? 2 : 1
            border.color: chips.activeFocus && ListView.isCurrentItem ? Theme.primary : (selected ? Theme.withAlpha(Theme.primary, 0.5) : Theme.withAlpha(Theme.outlineVariant, 0.6))
            opacity: matches > 0 || selected ? 1 : 0.55

            Row {
                id: chipRow

                anchors.centerIn: parent
                spacing: 4


                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    textFormat: Text.PlainText
                    wrapMode: Text.NoWrap
                    text: chip.modelData.title
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: chip.selected ? Font.Medium : Font.Normal
                    color: chip.selected ? Theme.primary : Theme.surfaceText
                }

            }

            MouseArea {
                id: chipArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    chips.forceActiveFocus();
                    root.selectCategory(chip.modelData.id);
                }
            }
        }
    }

    DankListView {
        id: list

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: chips.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.pad
        anchors.rightMargin: root.pad - 4
        anchors.topMargin: Theme.spacingS - 2
        anchors.bottomMargin: root.pad
        clip: true
        spacing: 3
        currentIndex: -1
        activeFocusOnTab: true
        keyNavigationEnabled: false
        highlightFollowsCurrentItem: false
        model: root.visibleCommands

        onActiveFocusChanged: {
            if (activeFocus && currentIndex < 0 && count > 0)
                currentIndex = 0;
        }

        Keys.onPressed: event => {
            const current = currentIndex >= 0 ? root.visibleCommands[currentIndex] : null;
            switch (event.key) {
            case Qt.Key_Up:
                if (currentIndex <= 0)
                    searchField.forceActiveFocus();
                else
                    decrementCurrentIndex();
                event.accepted = true;
                return;
            case Qt.Key_Down:
                incrementCurrentIndex();
                event.accepted = true;
                return;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                root.copy(current);
                event.accepted = true;
                return;
            case Qt.Key_Space:
                if (current)
                    root.toggleExpanded(current.uid);
                event.accepted = true;
                return;
            case Qt.Key_Escape:
                searchField.forceActiveFocus();
                event.accepted = true;
                return;
            }
            // Type-to-search: printable keys jump to the search field.
            if (event.text.length > 0 && event.text.trim().length > 0 && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
                searchField.forceActiveFocus();
                searchField.insertText(event.text);
                event.accepted = true;
            }
        }

        delegate: Rectangle {
            id: row

            required property var modelData
            required property int index
            readonly property bool expanded: root.expandedId === modelData.uid
            readonly property bool focused: list.activeFocus && ListView.isCurrentItem
            readonly property bool copying: root.copyingId === modelData.uid
            readonly property bool showFeedback: root.feedbackVisible && root.feedbackId === modelData.uid
            readonly property string copyText: root.copyTextFor(modelData)
            readonly property string secondary: modelData.description !== "" ? modelData.description : (modelData.detail !== "" ? modelData.detail : "Sem descrição")
            readonly property bool showDetail: modelData.detail !== "" && modelData.detail !== modelData.description && modelData.detail !== copyText

            width: list.width - 6
            height: content.implicitHeight + 10
            radius: Theme.cornerRadius
            color: rowArea.containsMouse || focused || expanded ? Theme.withAlpha(Theme.surfaceContainerHigh, 0.75) : Theme.withAlpha(Theme.surfaceContainerHigh, 0.32)
            border.width: focused ? 2 : 0
            border.color: Theme.primary

            MouseArea {
                id: rowArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    list.forceActiveFocus();
                    list.currentIndex = row.index;
                    root.toggleExpanded(row.modelData.uid);
                }
            }

            DankIcon {
                id: kindIcon

                x: 8
                y: 7
                name: root.kindIcons[row.modelData.kind] ?? "label"
                size: 16
                color: Theme.withAlpha(Theme.primary, 0.85)
            }

            Column {
                id: content

                anchors.left: kindIcon.right
                anchors.leftMargin: 8
                anchors.right: copyButton.left
                anchors.rightMargin: 6
                y: 5
                spacing: 1

                StyledText {
                    width: parent.width
                    isMonospace: true
                    textFormat: Text.PlainText
                    wrapMode: row.expanded ? Text.WrapAnywhere : Text.NoWrap
                    maximumLineCount: row.expanded ? 3 : 1
                    text: row.modelData.name
                    font.pixelSize: Theme.fontSizeSmall + 1
                    font.weight: Font.Medium
                    color: Theme.primary
                }

                StyledText {
                    width: parent.width
                    textFormat: Text.PlainText
                    wrapMode: row.expanded ? Text.Wrap : Text.NoWrap
                    maximumLineCount: row.expanded ? 4 : 1
                    text: row.secondary
                    font.pixelSize: Theme.fontSizeSmall
                    color: row.modelData.description !== "" ? Theme.surfaceText : Theme.surfaceVariantText
                }

                Column {
                    width: parent.width
                    visible: row.expanded
                    spacing: 2
                    topPadding: 3

                    StyledText {
                        width: parent.width
                        isMonospace: true
                        textFormat: Text.PlainText
                        wrapMode: Text.WrapAnywhere
                        maximumLineCount: 3
                        text: "copia: " + row.copyText
                        font.pixelSize: Theme.fontSizeSmall - 1
                        color: Theme.surfaceText
                    }

                    StyledText {
                        width: parent.width
                        visible: row.showDetail && row.modelData.description !== ""
                        isMonospace: true
                        textFormat: Text.PlainText
                        wrapMode: Text.WrapAnywhere
                        maximumLineCount: 3
                        text: row.modelData.detail
                        font.pixelSize: Theme.fontSizeSmall - 1
                        color: Theme.surfaceVariantText
                    }

                    StyledText {
                        width: parent.width
                        textFormat: Text.PlainText
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        elide: Text.ElideMiddle
                        text: [root.kindLabel(row.modelData.kind), row.modelData.categoryTitle, row.modelData.source].filter(part => part !== "").join(" · ")
                        font.pixelSize: Theme.fontSizeSmall - 2
                        color: Theme.surfaceVariantText
                    }
                }
            }

            ShelfButton {
                id: copyButton

                anchors.right: parent.right
                anchors.rightMargin: 4
                y: 3
                activeFocusOnTab: false
                iconSize: 16
                iconName: row.showFeedback ? (root.feedbackOk ? "check" : "error") : (row.copying ? "hourglass_empty" : "content_copy")
                iconColor: row.showFeedback ? (root.feedbackOk ? Theme.success : Theme.error) : Theme.surfaceVariantText
                tooltipText: "Copiar " + row.copyText
                enabled: root.copyingId === ""
                onClicked: {
                    list.currentIndex = row.index;
                    root.copy(row.modelData);
                }
            }
        }
    }

    Column {
        id: emptyState

        anchors.centerIn: list
        width: list.width - Theme.spacingL * 2
        spacing: 4
        visible: list.count === 0

        readonly property string mode: {
            if (!root.loaded)
                return root.loading ? "loading" : "error";
            if (root.commands.length === 0)
                return "empty";
            return "nomatch";
        }

        DankIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: ({
                    "loading": "hourglass_empty",
                    "error": "error",
                    "empty": "inbox",
                    "nomatch": "search_off"
                })[emptyState.mode]
            size: 22
            color: emptyState.mode === "error" ? Theme.error : Theme.surfaceVariantText
        }

        StyledText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.PlainText
            wrapMode: Text.NoWrap
            maximumLineCount: 1
            font.pixelSize: Theme.fontSizeSmall + 1
            color: Theme.surfaceText
            text: ({
                    "loading": "Carregando comandos…",
                    "error": "Não foi possível ler o catálogo",
                    "empty": "Nenhum comando no catálogo",
                    "nomatch": "Nada encontrado"
                })[emptyState.mode]
        }

        StyledText {
            width: parent.width
            visible: text !== ""
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: 2
            font.pixelSize: Theme.fontSizeSmall - 1
            color: Theme.surfaceVariantText
            text: {
                switch (emptyState.mode) {
                case "error":
                    return root.loadError;
                case "empty":
                    return root.warnings.length > 0 ? root.warnings[0] : "";
                case "nomatch":
                    return root.query.trim() !== "" ? "Nenhum comando corresponde a “" + root.query.trim() + "”" : "Esta categoria está vazia";
                }
                return "";
            }
        }

        Rectangle {
            id: emptyAction

            anchors.horizontalCenter: parent.horizontalCenter
            visible: emptyState.mode === "error" || emptyState.mode === "nomatch"
            width: emptyActionLabel.implicitWidth + 24
            height: 26
            radius: 13
            color: Theme.withAlpha(Theme.primary, 0.18)
            activeFocusOnTab: visible
            border.width: activeFocus ? 2 : 0
            border.color: Theme.primary
            Accessible.role: Accessible.Button
            Accessible.name: emptyActionLabel.text

            function trigger() {
                if (emptyState.mode === "error")
                    root.refresh();
                else
                    root.clearFilters();
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    emptyAction.trigger();
                    event.accepted = true;
                }
            }

            StyledText {
                id: emptyActionLabel

                anchors.centerIn: parent
                wrapMode: Text.NoWrap
                text: emptyState.mode === "error" ? "Tentar de novo" : "Limpar filtros"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.primary
            }

            StateLayer {
                stateColor: Theme.primary
                onClicked: emptyAction.trigger()
            }
        }
    }

    Rectangle {
        id: toast

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.pad + 4
        width: Math.min(toastIcon.width + toastRow.spacing + toastLabel.implicitWidth + 24, parent.width - root.pad * 4)
        height: 28
        radius: 14
        color: Theme.surfaceContainerHighest
        border.width: 1
        border.color: Theme.withAlpha(root.feedbackOk ? Theme.success : Theme.error, 0.6)
        opacity: root.feedbackVisible ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.shortDuration
                easing.type: Theme.standardEasing
            }
        }

        Row {
            id: toastRow

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 12
            width: parent.width - 24
            spacing: 6

            DankIcon {
                id: toastIcon

                anchors.verticalCenter: parent.verticalCenter
                name: root.feedbackOk ? "check_circle" : "error"
                size: 16
                color: root.feedbackOk ? Theme.success : Theme.error
            }

            StyledText {
                id: toastLabel

                anchors.verticalCenter: parent.verticalCenter
                width: toastRow.width - toastIcon.width - toastRow.spacing
                textFormat: Text.PlainText
                wrapMode: Text.NoWrap
                maximumLineCount: 1
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                text: root.feedbackOk ? "Copiado: " + root.feedbackText : root.feedbackText
            }
        }
    }
}
