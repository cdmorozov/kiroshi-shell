// window switcher: horizontal cards, Tab / arrows / Enter / numbers
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
Scope {
    id: root
    property bool open: false
    IpcHandler { target: "switcher"; function toggle(): void { root.open = !root.open } }
    readonly property var wins: ToplevelManager.toplevels.values
    function wsOf(t) {
        const w = Hyprland.workspaces.values.find(w => w.toplevels.values.some(x => x.wayland === t))
        return w ? w.id : "–"
    }
    PanelWindow {
        id: win
        visible: root.open
        anchors { top: true; bottom: true; left: true; right: true }
        color: "#cc050a14"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "netrun-switcher"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        property int sel: 0
        onVisibleChanged: if (visible) { sel = Math.min(1, Math.max(0, root.wins.length - 1)); keys.forceActiveFocus() }
        function go(i) { const t = root.wins[i]; root.open = false; if (t) t.activate() }
        MouseArea { anchors.fill: parent; onClicked: root.open = false }
        Item {
            id: keys; anchors.fill: parent; focus: true
            Keys.onEscapePressed: root.open = false
            Keys.onTabPressed: e => { const n = root.wins.length; if (n) win.sel = (win.sel + ((e.modifiers & Qt.ShiftModifier) ? n - 1 : 1)) % n }
            Keys.onBacktabPressed: { const n = root.wins.length; if (n) win.sel = (win.sel + n - 1) % n }
            Keys.onRightPressed: { const n = root.wins.length; if (n) win.sel = (win.sel + 1) % n }
            Keys.onLeftPressed: { const n = root.wins.length; if (n) win.sel = (win.sel + n - 1) % n }
            Keys.onReturnPressed: win.go(win.sel)
            Keys.onEnterPressed: win.go(win.sel)
            Keys.onPressed: e => { if (e.key >= Qt.Key_1 && e.key <= Qt.Key_9 && e.key - Qt.Key_1 < root.wins.length) { win.go(e.key - Qt.Key_1); e.accepted = true } }
        }
        Column {
            anchors.centerIn: parent; spacing: 22
            Column {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 4
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "//  ACTIVE PROCESSES  —  " + root.wins.length + " LINKED"; color: Theme.accent; font.family: Theme.mono; font.pixelSize: 11; font.letterSpacing: 3 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "LINK  接続"; color: Theme.fg; font.family: Theme.ui; font.pixelSize: 30; font.bold: true; font.letterSpacing: 4 }
            }
            Flow {
                id: flow
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(root.wins.length, 4) * 236 - 12
                spacing: 12
                Repeater {
                    model: root.wins
                    Item {
                        id: card
                        required property var modelData
                        required property int index
                        readonly property bool cur: index === win.sel
                        width: 224; height: 150
                        Shape {
                            anchors.fill: parent; preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                fillColor: card.cur ? "#244fa3ae" : "#e60b1424"; strokeColor: card.cur ? Theme.accent : Theme.line; strokeWidth: 1
                                startX: 0; startY: 0
                                PathLine { x: 208; y: 0 } PathLine { x: 224; y: 16 } PathLine { x: 224; y: 150 }
                                PathLine { x: 16; y: 150 } PathLine { x: 0; y: 134 } PathLine { x: 0; y: 0 }
                            }
                        }
                        Rectangle { visible: card.cur; width: parent.width - 16; height: 3; color: Theme.accent }
                        Rectangle { x: 12; y: 14; width: 24; height: 20; color: "transparent"; border.color: card.cur ? Theme.accent : Theme.dim
                                    Text { anchors.centerIn: parent; text: card.index + 1; color: card.cur ? Theme.fg : Theme.dim; font.family: Theme.mono; font.pixelSize: 11 } }
                        Text { anchors { right: parent.right; rightMargin: 24; top: parent.top; topMargin: 16 } text: "WS." + root.wsOf(card.modelData); color: Theme.dim; font.family: Theme.mono; font.pixelSize: 10 }
                        AppIcon { anchors.horizontalCenter: parent.horizontalCenter; y: 42; size: 48; appId: card.modelData.appId }
                        Text { x: 14; y: 104; width: parent.width - 28; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                               text: card.modelData.title || card.modelData.appId; color: card.cur ? "#ffffff" : Theme.fg
                               font.family: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold }
                        Text { x: 14; y: 124; width: parent.width - 28; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                               text: (card.modelData.appId || "").toUpperCase(); color: Theme.dim; font.family: Theme.ui; font.pixelSize: 10; font.letterSpacing: 2 }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onEntered: win.sel = card.index; onClicked: win.go(card.index) }
                    }
                }
            }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "[TAB / ← →] SELECT    [ENTER] FOCUS    [1-9] DIRECT    [ESC] CLOSE"; color: Theme.dim; font.family: Theme.mono; font.pixelSize: 10; font.letterSpacing: 1 }
        }
    }
}
