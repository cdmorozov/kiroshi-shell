// desktop now-playing card — mini RADIOPORT (our palette, original design)
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
Item {
    id: root
    width: 400; height: 172
    readonly property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    readonly property bool hasPlayer: player !== null
    visible: hasPlayer
    property var levels: []
    function fmt(s) { s = Math.max(0, Math.floor(s || 0)); return Math.floor(s / 60) + ":" + ("0" + s % 60).slice(-2) }
    function openRadio() { Quickshell.execDetached(["qs", "-p", Quickshell.env("HOME") + "/.config/quickshell", "ipc", "call", "radio", "toggle"]) }

    Process {
        id: cava
        running: root.hasPlayer
        command: ["sh", "-c", "exec cava -p \"$HOME/.config/cava/netrun.conf\" 2>/tmp/netrun-cava.err"]
        onExited: if (root.hasPlayer) restart.start()
        stdout: SplitParser { onRead: data => root.levels = data.split(";").filter(s => s.length).map(Number) }
    }
    Timer { id: restart; interval: 1500; onTriggered: cava.running = root.hasPlayer }
    Timer { interval: 1000; repeat: true; running: root.hasPlayer && root.player.isPlaying; onTriggered: root.player.positionChanged() }

    // ---- header strip ----
    Item {
        id: head
        width: parent.width; height: 26
        Shape {
            anchors.fill: parent; preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: "#e60e1a30"; strokeColor: Theme.accent; strokeWidth: 1
                startX: 0; startY: 0
                PathLine { x: head.width - 14; y: 0 } PathLine { x: head.width; y: 14 } PathLine { x: head.width; y: head.height }
                PathLine { x: 0; y: head.height } PathLine { x: 0; y: 0 }
            }
        }
        Rectangle { width: 3; height: parent.height; color: Theme.accent }
        Row {
            x: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 8
            Text { text: "RADIOPORT"; color: Theme.fg; font.family: Theme.ui; font.pixelSize: 13; font.bold: true; font.letterSpacing: 2 }
            Text { text: "ラジオ"; color: Theme.dim; font.family: Theme.text; font.pixelSize: 9; anchors.baseline: parent.children[0].baseline }
        }
        Row {
            anchors { right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter } spacing: 8
            Text { text: "88.3 FM"; color: Theme.muted; font.family: Theme.mono; font.pixelSize: 10 }
            Rectangle {
                width: 6; height: 6; anchors.verticalCenter: parent.verticalCenter
                color: root.player && root.player.isPlaying ? Theme.accent : Theme.dim
                SequentialAnimation on opacity { running: root.player && root.player.isPlaying; loops: Animation.Infinite
                    NumberAnimation { to: 0.25; duration: 600 } NumberAnimation { to: 1; duration: 600 } }
            }
        }
    }

    // ---- body ----
    Rectangle {
        id: body
        anchors { top: head.bottom; topMargin: 4; left: parent.left; right: parent.right; bottom: parent.bottom }
        color: "#e6081020"; border.color: Theme.line; border.width: 1
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.openRadio() }

        Rectangle {
            id: cover
            x: 10; y: 10; width: 76; height: 76
            color: "#0b1424"; border.color: Theme.accent; border.width: 1
            Image { anchors.fill: parent; anchors.margins: 2; fillMode: Image.PreserveAspectCrop; asynchronous: true
                    source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : "" }
            Text { anchors.centerIn: parent; visible: !root.player || !root.player.trackArtUrl; text: ""; color: Theme.dim; font.family: Theme.mono; font.pixelSize: 24 }
        }

        Column {
            x: cover.x + cover.width + 12; y: 8; width: body.width - x - 10; spacing: 2
            Text { text: root.player ? (root.player.identity || "PLAYER").toUpperCase() + "  //  " + (root.player.isPlaying ? "ON AIR" : "HOLD") : ""
                   color: Theme.accent; font.family: Theme.ui; font.pixelSize: 10; font.bold: true; font.letterSpacing: 2 }
            Text { width: parent.width; elide: Text.ElideRight; text: root.player ? (root.player.trackTitle || "UNKNOWN TRACK") : ""
                   color: "#ffffff"; font.family: Theme.text; font.pixelSize: 15; font.weight: Font.DemiBold }
            Text { width: parent.width; elide: Text.ElideRight; text: root.player ? (root.player.trackArtist || "") : ""
                   color: Theme.muted; font.family: Theme.text; font.pixelSize: 12 }
            Item { width: 1; height: 4 }
            Row {
                spacing: 6
                Text { text: root.player ? root.fmt(root.player.position) : ""; color: Theme.muted; font.family: Theme.mono; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter }
                Seg { count: 18; value: root.player && root.player.length > 0 ? root.player.position / root.player.length * 100 : 0; on: Theme.accent }
                Text { text: root.player ? root.fmt(root.player.length) : ""; color: Theme.dim; font.family: Theme.mono; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter }
            }
        }
        // controls
        Row {
            anchors { right: parent.right; rightMargin: 10; top: cover.bottom; topMargin: -26 }
            spacing: 6
            Repeater {
                model: [ { g: "󰒮", a: "prev" }, { g: root.player && root.player.isPlaying ? "󰏤" : "󰐊", a: "play" }, { g: "󰒭", a: "next" } ]
                Rectangle {
                    required property var modelData
                    width: 28; height: 22; color: cm.containsMouse ? "#294fa3ae" : "transparent"
                    border.color: modelData.a === "play" ? Theme.accent : Theme.line; border.width: 1
                    Text { anchors.centerIn: parent; text: modelData.g; color: Theme.fg; font.family: Theme.mono; font.pixelSize: 12 }
                    MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (!root.player) return; if (modelData.a === "prev") root.player.previous(); else if (modelData.a === "next") root.player.next(); else root.player.togglePlaying() } }
                }
            }
        }
        // visualizer across the bottom
        Row {
            x: 10; anchors { bottom: parent.bottom; bottomMargin: 8 } height: 34; spacing: 2
            Repeater {
                model: 28
                Rectangle {
                    width: (body.width - 20 - 27 * 2) / 28
                    height: Math.max(2, (root.levels[index] || 0) / 100 * 34)
                    anchors.bottom: parent.bottom
                    color: Theme.accent
                    opacity: 0.3 + 0.7 * ((root.levels[index] || 0) / 100)
                }
            }
        }
    }
}
