// power menu: five tiles, keyboard + mouse, confirm on destructive ones
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
Scope {
    id: root
    property bool open: false
    IpcHandler { target: "power"; function toggle(): void { root.open = !root.open } }
    readonly property var items: [
        { key: "L", label: "LOCK",     jp: "施錠", glyph: "", cmd: "hyprlock", danger: false },
        { key: "E", label: "JACK OUT", jp: "離脱", glyph: "", cmd: "hyprctl dispatch exit", danger: false },
        { key: "U", label: "SUSPEND",  jp: "休止", glyph: "", cmd: "systemctl suspend", danger: false },
        { key: "R", label: "REBOOT",   jp: "再起", glyph: "", cmd: "systemctl reboot", danger: true },
        { key: "S", label: "FLATLINE", jp: "停止", glyph: "", cmd: "systemctl poweroff", danger: true }
    ]
    PanelWindow {
        id: win
        visible: root.open
        anchors { top: true; bottom: true; left: true; right: true }
        color: "#e6050a14"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "netrun-power"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        property int sel: 0
        property int armed: -1
        onVisibleChanged: if (visible) { sel = 0; armed = -1; keys.forceActiveFocus() }
        function run(i) {
            const it = root.items[i]
            if (it.danger && armed !== i) { armed = i; sel = i; return }
            root.open = false
            Quickshell.execDetached(["sh", "-c", it.cmd])
        }
        MouseArea { anchors.fill: parent; onClicked: root.open = false }
        Item {
            id: keys; anchors.fill: parent; focus: true
            Keys.onEscapePressed: root.open = false
            Keys.onLeftPressed: { win.sel = (win.sel + 4) % 5; win.armed = -1 }
            Keys.onRightPressed: { win.sel = (win.sel + 1) % 5; win.armed = -1 }
            Keys.onReturnPressed: win.run(win.sel)
            Keys.onEnterPressed: win.run(win.sel)
            Keys.onPressed: e => { for (let i = 0; i < 5; i++) if (e.text.toUpperCase() === root.items[i].key) { win.sel = i; win.run(i); e.accepted = true } }
        }
        Column {
            anchors.centerIn: parent; spacing: 28
            Column {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 6
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "//  SESSION CONTROL  —  AWAITING COMMAND"; color: Theme.accent; font.family: Theme.mono; font.pixelSize: 11; font.letterSpacing: 3 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "POWER  電源"; color: Theme.fg; font.family: Theme.ui; font.pixelSize: 34; font.bold: true; font.letterSpacing: 4 }
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 16
                Repeater {
                    model: root.items
                    Item {
                        id: tile
                        required property var modelData
                        required property int index
                        readonly property bool cur: index === win.sel
                        readonly property bool armed: index === win.armed
                        width: 180; height: 220
                        readonly property color edge: armed || (cur && modelData.danger) ? Theme.alert : (cur ? Theme.accent : Theme.line)
                        Shape {
                            anchors.fill: parent; preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                fillColor: tile.armed ? "#33e60000" : (tile.cur ? "#244fa3ae" : "#e60b1424")
                                strokeColor: tile.edge; strokeWidth: 1
                                startX: 0; startY: 0
                                PathLine { x: 164; y: 0 } PathLine { x: 180; y: 16 } PathLine { x: 180; y: 220 }
                                PathLine { x: 16; y: 220 } PathLine { x: 0; y: 204 } PathLine { x: 0; y: 0 }
                            }
                        }
                        Rectangle { width: parent.width - 16; height: 3; color: tile.edge }
                        Text { x: 14; y: 14; text: "[" + modelData.key + "]"; color: tile.cur ? Theme.accent : Theme.dim; font.family: Theme.mono; font.pixelSize: 12 }
                        Text { anchors.centerIn: parent; anchors.verticalCenterOffset: -22; text: modelData.glyph
                               color: tile.armed ? Theme.alert : (tile.cur ? Theme.fg : Theme.muted); font.family: Theme.mono; font.pixelSize: 54 }
                        Text { anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 54 } text: tile.armed ? "CONFIRM ?" : modelData.label
                               color: tile.armed ? Theme.alert : Theme.fg; font.family: Theme.ui; font.pixelSize: 20; font.bold: true; font.letterSpacing: 3 }
                        Text { anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 30 } text: modelData.jp
                               color: Theme.dim; font.family: Theme.text; font.pixelSize: 12 }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onEntered: { win.sel = tile.index; if (win.armed !== tile.index) win.armed = -1 }
                                    onClicked: win.run(tile.index) }
                    }
                }
            }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "[← →] SELECT    [ENTER] EXECUTE    [L E U R S] DIRECT    [ESC] ABORT"
                   color: Theme.dim; font.family: Theme.mono; font.pixelSize: 10; font.letterSpacing: 1 }
        }
    }
}
