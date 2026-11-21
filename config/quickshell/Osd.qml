// volume / brightness popup — segmented, bottom centre
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
Scope {
    id: root
    property string kind: "VOL"
    property real level: 0
    property bool muted: false
    property bool armed: false
    Timer { interval: 2500; running: true; onTriggered: root.armed = true }   // ignore startup events

    function show(k, v, m) { kind = k; level = v; muted = !!m; if (armed) { hideT.restart(); win.shown = true } }

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }
    Connections {
        target: root.sink ? root.sink.audio : null
        function onVolumeChanged() { root.show("VOL", root.sink.audio.volume * 100, root.sink.audio.muted) }
        function onMutedChanged()  { root.show("VOL", root.sink.audio.volume * 100, root.sink.audio.muted) }
    }
    Process {
        id: bri; command: ["brightnessctl", "-m"]
        stdout: StdioCollector { onStreamFinished: { const p = text.trim().split(","); if (p.length >= 4) root.show("BRT", parseInt(p[3]), false) } }
    }
    IpcHandler { target: "osd"; function brightness(): void { bri.running = true } }
    Timer { id: hideT; interval: 1500; onTriggered: win.shown = false }

    PanelWindow {
        id: win
        property bool shown: false
        visible: shown || card.opacity > 0
        anchors { bottom: true }
        margins { bottom: 90 }
        implicitWidth: 400; implicitHeight: 64
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "netrun-osd"
        mask: Region {}

        Item {
            id: card
            anchors.fill: parent
            opacity: win.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160 } }
            Shape {
                anchors.fill: parent; preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: "#f2081020"; strokeColor: "#994fa3ae"; strokeWidth: 1
                    startX: 0; startY: 0
                    PathLine { x: 388; y: 0 } PathLine { x: 400; y: 12 } PathLine { x: 400; y: 64 }
                    PathLine { x: 12; y: 64 } PathLine { x: 0; y: 52 } PathLine { x: 0; y: 0 }
                }
            }
            Rectangle { width: 3; height: 52; color: root.muted ? Theme.alert : Theme.accent }
            Text { x: 20; y: 10; text: root.kind === "VOL" ? "AUDIO.OUT  音量" : "DISPLAY  輝度"; color: Theme.muted; font.family: Theme.ui; font.pixelSize: 11; font.bold: true; font.letterSpacing: 2 }
            Text { anchors { right: parent.right; rightMargin: 22; top: parent.top; topMargin: 6 }
                   text: root.muted ? "MUTE" : Math.round(root.level); color: root.muted ? Theme.alert : Theme.fg
                   font.family: Theme.mono; font.pixelSize: 18; font.bold: true }
            Seg { x: 20; y: 36; count: 32; value: root.muted ? 0 : root.level; on: Theme.accent }
        }
    }
}
