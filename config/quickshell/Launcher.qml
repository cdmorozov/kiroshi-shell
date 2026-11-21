// App launcher in the spirit of CyberArch's numbered list — our palette.
// Window dim/blur and the fly-in come from Hyprland; everything inside is animated here.
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
Scope {
    id: root
    property bool open: false
    property real intro: 0
    onOpenChanged: { if (open) { intro = 0; introAnim.restart() } else { introAnim.stop(); intro = 0 } }
    NumberAnimation { id: introAnim; target: root; property: "intro"; from: 0; to: 1; duration: 650; easing.type: Easing.OutCubic }
    IpcHandler {
        target: "launcher"
        function toggle(): void { root.open = !root.open }
        function show(): void { root.open = true }
        function hide(): void { root.open = false }
    }

    PanelWindow {
        id: win
        visible: root.open
        anchors { top: true; bottom: true; left: true; right: true }
        color: "#d9050a14"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "netrun-launcher"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        property string query: ""
        property int sel: 0
        readonly property var apps: {
            const q = query.toLowerCase().trim()
            let list = DesktopEntries.applications.values.filter(e => !e.noDisplay)
            if (q !== "") list = list.filter(e => (e.name + " " + (e.genericName || "") + " " + (e.keywords || []).join(" ") + " " + (e.comment || "")).toLowerCase().includes(q))
            return list.sort((a, b) => {
                if (q !== "") { const as = a.name.toLowerCase().startsWith(q), bs = b.name.toLowerCase().startsWith(q); if (as !== bs) return as ? -1 : 1 }
                return a.name.localeCompare(b.name)
            })
        }
        onAppsChanged: sel = 0
        onVisibleChanged: if (visible) { query = ""; input.text = ""; sel = 0; input.forceActiveFocus() }

        function launch(i) { const e = apps[i]; if (!e) return; e.execute(); root.open = false }
        function pad(n) { return (n < 10 ? "00" : n < 100 ? "0" : "") + n }
        // where the entry runs from
        function srcOf(e) { const c = (e.command || [])[0] || ""; return e.runInTerminal ? "TTY" : c.endsWith("flatpak") ? "FLATPAK" : "NATIVE" }
        // one kanji per category, shown on the row
        readonly property var kanji: ({ Game: "遊", Network: "網", AudioVideo: "音", Audio: "音", Video: "映", Development: "開", Graphics: "画",
                                        Office: "事", Settings: "設", System: "系", Utility: "具", Education: "学", Science: "科", Accessibility: "助", Security: "防" })
        function kanjiOf(e) { for (const c of (e.categories || [])) if (kanji[c]) return kanji[c]; return "他" }

        MouseArea { anchors.fill: parent; onClicked: root.open = false }

        Item {
            id: panel
            x: 90; width: 640; height: 640
            anchors.verticalCenter: parent.verticalCenter
            MouseArea { anchors.fill: parent }   // swallow clicks

            // left edge: bar that draws itself down, hatch cap on top
            Rectangle { x: -20; y: 0; width: 3; height: panel.height * Math.min(1, root.intro * 1.5); color: Theme.accent; opacity: 0.85 }
            Hatch { x: -20; y: -12; width: 52; height: 9; gap: 5; opacity: 0.75 * Math.min(1, root.intro * 3) }

            // status line
            Row {
                id: sys
                spacing: 12; opacity: Math.min(1, root.intro * 3)
                Text { text: "//  NETRUNNER.OS  —  RUNNING"; color: Theme.accent; font.family: Theme.mono; font.pixelSize: 11; font.letterSpacing: 2 }
                Text { text: "稼働中"; color: Theme.dim; font.family: Theme.text; font.pixelSize: 11 }
            }
            Row {
                anchors.right: rule.right; spacing: 10; opacity: Math.min(1, root.intro * 3)
                Text { text: "SLOT " + win.pad(Math.min(win.sel + 1, 999)) + " / " + win.pad(win.apps.length); color: Theme.dim; font.family: Theme.mono; font.pixelSize: 11; font.letterSpacing: 2 }
                Text { text: "接続"; color: Theme.dim; font.family: Theme.text; font.pixelSize: 11 }
            }
            Row {
                id: head
                anchors { top: sys.bottom; topMargin: 10 }
                spacing: 14
                Text { text: "APPS"; color: Theme.fg; font.family: Theme.ui; font.pixelSize: 32; font.bold: true; font.letterSpacing: 3
                       opacity: Math.min(1, root.intro * 4); x: -(1 - Math.min(1, root.intro * 3)) * 24 }
                Text { text: "アプリ"; color: Theme.dim; font.family: Theme.text; font.pixelSize: 13; anchors.baseline: parent.children[0].baseline; opacity: Math.min(1, root.intro * 3) }
                Row {
                    anchors.baseline: parent.children[0].baseline
                    spacing: 6
                    Text { text: "›"; color: Theme.accent; font.family: Theme.mono; font.pixelSize: 15 }
                    TextInput {
                        id: input
                        width: 340
                        color: Theme.fg; font.family: Theme.text; font.pixelSize: 15
                        selectionColor: "#334fa3ae"
                        onTextChanged: win.query = text
                        Keys.onEscapePressed: root.open = false
                        Keys.onDownPressed: win.sel = Math.min(win.sel + 1, win.apps.length - 1)
                        Keys.onUpPressed: win.sel = Math.max(win.sel - 1, 0)
                        Keys.onReturnPressed: win.launch(win.sel)
                        Keys.onEnterPressed: win.launch(win.sel)
                        Keys.onPressed: e => {
                            if (e.key === Qt.Key_PageDown) { win.sel = Math.min(win.sel + 8, win.apps.length - 1); e.accepted = true }
                            else if (e.key === Qt.Key_PageUp) { win.sel = Math.max(win.sel - 8, 0); e.accepted = true }
                            else if (text === "" && e.key >= Qt.Key_1 && e.key <= Qt.Key_9 && (e.modifiers & Qt.AltModifier)) { win.launch(list.topIdx + e.key - Qt.Key_1); e.accepted = true }
                        }
                        Text { visible: !parent.text; text: "SEARCH_"; color: Theme.dim; font: parent.font }
                    }
                }
            }
            // rule draws itself, ruler ticks follow
            Rectangle { id: rule; anchors { top: head.bottom; topMargin: 8 } width: 540 * Math.min(1, root.intro * 1.8); height: 1; color: Theme.accent; opacity: 0.6 }
            Repeater {
                model: 55
                Rectangle {
                    required property int index
                    x: index * 10; y: rule.y + 1; width: 1; height: index % 5 === 0 ? 6 : 3
                    color: Theme.accent; opacity: x < rule.width ? 0.5 : 0
                }
            }

            // vertical kanji ribbon on the right of the list
            Column {
                x: 600; y: rule.y + 22; spacing: 8
                Repeater {
                    model: ["起", "動", "準", "備", "完", "了"]
                    Text {
                        required property var modelData
                        required property int index
                        text: modelData; color: Theme.dim; font.family: Theme.text; font.pixelSize: 17
                        opacity: Math.max(0, Math.min(1, (root.intro - 0.25 - index * 0.06) / 0.3)) * 0.8
                    }
                }
            }
            Rectangle { x: 586; y: rule.y + 22; width: 1; height: 170 * Math.min(1, root.intro * 1.4); color: Theme.dim; opacity: 0.6 }

            ListView {
                id: list
                anchors { top: rule.bottom; topMargin: 16; left: parent.left; bottom: foot.top; bottomMargin: 16 }
                width: 580
                clip: true
                spacing: 8
                model: win.apps
                highlightFollowsCurrentItem: false
                Behavior on contentY { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }
                function ensure(i) {
                    const top = i * 48, bottom = top + 40
                    if (top < contentY) contentY = top
                    else if (bottom > contentY + height) contentY = bottom - height
                }
                Connections { target: win; function onSelChanged() { list.ensure(win.sel) } }
                readonly property int topIdx: indexAt(10, contentY + 4) < 0 ? 0 : indexAt(10, contentY + 4)
                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool cur: index === win.sel
                    readonly property int vis: index - list.topIdx
                    width: list.width; height: 40
                    // staircase offset, like the in-game list
                    readonly property int shiftTarget: [24, 14, 6, 0, 0, 4, 10, 20, 30][Math.max(0, Math.min(8, vis))]
                    property real shift: shiftTarget
                    Behavior on shift { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }
                    // staggered entry: rows lower on screen arrive a beat later
                    readonly property real prog: Math.max(0, Math.min(1, (root.intro - 0.04 - Math.max(0, vis) * 0.045) / 0.4))

                    Item {
                        width: parent.width; height: parent.height
                        x: (1 - row.prog) * -90
                        opacity: row.prog
                        Rectangle {
                            id: num
                            x: row.shift; width: 26; height: 26; anchors.verticalCenter: parent.verticalCenter
                            color: "transparent"; border.color: row.cur ? Theme.accent : Theme.line; border.width: 1
                            Text { anchors.centerIn: parent; text: (row.index + 1); color: row.cur ? Theme.fg : Theme.dim; font.family: Theme.mono; font.pixelSize: 12 }
                        }
                        Item {
                            id: plate
                            x: num.x + num.width + 10 + (row.cur ? 12 : 0); width: 440; height: parent.height
                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Shape {
                                anchors.fill: parent
                                preferredRendererType: Shape.CurveRenderer
                                ShapePath {
                                    fillColor: row.cur ? "#294fa3ae" : "#cc0b1424"
                                    strokeColor: row.cur ? Theme.accent : "#4d4fa3ae"; strokeWidth: 1
                                    startX: 0; startY: 0
                                    PathLine { x: plate.width - 12; y: 0 }
                                    PathLine { x: plate.width; y: 12 }
                                    PathLine { x: plate.width; y: plate.height }
                                    PathLine { x: 0; y: plate.height }
                                    PathLine { x: 0; y: 0 }
                                }
                            }
                            Rectangle { visible: row.cur; width: 3; height: parent.height; color: Theme.accent }
                            // hatch tail on the selected row
                            Hatch { visible: row.cur; x: plate.width - 96; y: plate.height - 8; width: 56; height: 5; gap: 4; opacity: 0.55 }
                            Text {
                                x: 16; y: 5; width: parent.width - 150; elide: Text.ElideRight
                                text: row.modelData.name
                                color: row.cur ? "#ffffff" : Theme.fg; font.family: Theme.text; font.pixelSize: 14; font.weight: Font.DemiBold
                            }
                            Rectangle {
                                x: 16; y: 24; width: rdy.implicitWidth + 10; height: 12
                                color: "transparent"; border.color: row.cur ? Theme.accent : Theme.dim; border.width: 1
                                Text { id: rdy; anchors.centerIn: parent; text: win.srcOf(row.modelData); color: row.cur ? Theme.accent : Theme.dim; font.family: Theme.ui; font.pixelSize: 8; font.bold: true; font.letterSpacing: 1 }
                            }
                            Text {
                                anchors { right: kj.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                                text: (row.modelData.genericName || "").toUpperCase().slice(0, 20)
                                color: Theme.dim; font.family: Theme.text; font.pixelSize: 9; font.letterSpacing: 1
                            }
                            // category kanji
                            Rectangle {
                                id: kj
                                anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                                width: 22; height: 22; color: row.cur ? Theme.accent : "transparent"
                                border.color: row.cur ? Theme.accent : Theme.dim; border.width: 1
                                Text { anchors.centerIn: parent; text: win.kanjiOf(row.modelData); color: row.cur ? Theme.bg : Theme.muted; font.family: Theme.text; font.pixelSize: 13 }
                            }
                        }
                        MouseArea {
                            anchors.fill: plate; hoverEnabled: true
                            onEntered: win.sel = row.index
                            onClicked: win.launch(row.index)
                        }
                    }
                }
            }

            Text {
                id: foot
                anchors.bottom: parent.bottom
                opacity: Math.min(1, root.intro * 2)
                text: "[入力] SEARCH    [↑ ↓] NAVIGATE    [実行] LAUNCH    [終了] CLOSE        " + win.apps.length + " ENTRIES  項目"
                color: Theme.dim; font.family: Theme.mono; font.pixelSize: 10; font.letterSpacing: 1
            }
        }
    }
}
