// RADIOPORT-style player panel (layout inspired by the game, our palette, original design)
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
Scope {
    id: root
    property bool open: false
    property int pick: 0
    IpcHandler { target: "radio"; function toggle(): void { root.open = !root.open } }

    readonly property var players: Mpris.players.values
    readonly property var p: players.length > 0 ? players[Math.min(pick, players.length - 1)] : null
    function freq(i) { return (88.3 + i * 3.6).toFixed(1) }
    function fmt(s) { s = Math.max(0, Math.floor(s || 0)); return Math.floor(s / 60) + ":" + ("0" + s % 60).slice(-2) }

    property var levels: []
    Process {
        running: root.open && root.p !== null
        command: ["sh", "-c", "exec cava -p \"$HOME/.config/cava/netrun.conf\" 2>/dev/null"]
        stdout: SplitParser { onRead: data => root.levels = data.split(";").filter(s => s.length).map(Number) }
    }

    PanelWindow {
        visible: root.open
        anchors { top: true; bottom: true; left: true; right: true }
        color: "#d9050a14"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "netrun-radio"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        Timer { interval: 1000; running: root.open && root.p !== null && root.p.isPlaying; repeat: true; onTriggered: root.p.positionChanged() }

        MouseArea { anchors.fill: parent; onClicked: root.open = false }
        Item { focus: true; Keys.onEscapePressed: root.open = false; Keys.onSpacePressed: if (root.p) root.p.togglePlaying()
               Keys.onRightPressed: if (root.p) root.p.next(); Keys.onLeftPressed: if (root.p) root.p.previous() }

        Item {
            id: panel
            x: 90; anchors.verticalCenter: parent.verticalCenter
            width: 560; height: 470
            MouseArea { anchors.fill: parent }

            // header bar
            Item {
                id: head
                width: parent.width; height: 40
                Shape {
                    anchors.fill: parent; preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        fillColor: "#e60e1a30"; strokeColor: Theme.accent; strokeWidth: 1
                        startX: 0; startY: 0
                        PathLine { x: head.width - 18; y: 0 } PathLine { x: head.width; y: 18 } PathLine { x: head.width; y: head.height }
                        PathLine { x: 0; y: head.height } PathLine { x: 0; y: 0 }
                    }
                }
                Rectangle { width: 4; height: parent.height; color: Theme.accent }
                Row {
                    x: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                    Text { text: "RADIOPORT"; color: Theme.fg; font.family: Theme.ui; font.pixelSize: 20; font.bold: true; font.letterSpacing: 3 }
                    Text { text: "ラジオ"; color: Theme.dim; font.family: Theme.text; font.pixelSize: 12; anchors.baseline: parent.children[0].baseline }
                }
                Text { anchors { right: parent.right; rightMargin: 26; verticalCenter: parent.verticalCenter }
                       text: root.p ? (root.p.isPlaying ? "RX.ONLINE  ●" : "RX.HOLD") : "NO SIGNAL"
                       color: root.p && root.p.isPlaying ? Theme.accent : Theme.dim; font.family: Theme.mono; font.pixelSize: 11; font.letterSpacing: 1 }
            }

            // body
            Rectangle {
                id: body
                anchors { top: head.bottom; topMargin: 8; left: parent.left; right: parent.right }
                height: 220; color: "#e6081020"; border.color: Theme.line; border.width: 1

                // cover
                Rectangle {
                    id: cover
                    x: 16; y: 16; width: 150; height: 150
                    color: "#0b1424"; border.color: Theme.accent; border.width: 1
                    Image { anchors.fill: parent; anchors.margins: 3; fillMode: Image.PreserveAspectCrop; asynchronous: true
                            source: root.p && root.p.trackArtUrl ? root.p.trackArtUrl : "" }
                    Text { anchors.centerIn: parent; visible: !root.p || !root.p.trackArtUrl; text: ""; color: Theme.dim; font.family: Theme.mono; font.pixelSize: 40 }
                }
                // visualizer under the cover
                Row {
                    x: 16; y: cover.y + cover.height + 8; height: 30; spacing: 2
                    Repeater { model: 28
                        Rectangle { width: 3.3; anchors.bottom: parent.bottom; height: Math.max(1, (root.levels[index] || 0) / 100 * 30); color: Theme.accent; opacity: 0.4 + 0.6 * ((root.levels[index] || 0) / 100) } }
                }

                Column {
                    x: cover.x + cover.width + 18; y: 14; width: body.width - x - 16; spacing: 4
                    Text { text: root.p ? ((root.p.identity || "PLAYER").toUpperCase() + "  //  " + root.freq(root.pick) + " FM") : "NO STATION"
                           color: Theme.accent; font.family: Theme.ui; font.pixelSize: 12; font.bold: true; font.letterSpacing: 2 }
                    Text { width: parent.width; elide: Text.ElideRight; text: root.p ? (root.p.trackTitle || "UNKNOWN TRACK") : "—"
                           color: "#ffffff"; font.family: Theme.text; font.pixelSize: 20; font.weight: Font.DemiBold }
                    Text { width: parent.width; elide: Text.ElideRight; text: root.p ? (root.p.trackArtist || "") : ""
                           color: Theme.fg; font.family: Theme.text; font.pixelSize: 14 }
                    Text { width: parent.width; elide: Text.ElideRight; text: root.p && root.p.trackAlbum ? root.p.trackAlbum.toUpperCase() : ""
                           color: Theme.dim; font.family: Theme.text; font.pixelSize: 11; font.letterSpacing: 1 }
                    Item { width: 1; height: 8 }
                    // progress
                    Row {
                        spacing: 8
                        Text { text: root.p ? root.fmt(root.p.position) : "0:00"; color: Theme.muted; font.family: Theme.mono; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                        Seg { count: 26; value: root.p && root.p.length > 0 ? root.p.position / root.p.length * 100 : 0; on: Theme.accent }
                        Text { text: root.p ? root.fmt(root.p.length) : "0:00"; color: Theme.dim; font.family: Theme.mono; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                    }
                    Item { width: 1; height: 6 }
                    // controls
                    Row {
                        spacing: 10
                        Repeater {
                            model: [ { g: "󰒮", a: "prev" }, { g: root.p && root.p.isPlaying ? "󰏤" : "󰐊", a: "play" }, { g: "󰒭", a: "next" } ]
                            Rectangle {
                                required property var modelData
                                width: 38; height: 30; color: cm.containsMouse ? "#294fa3ae" : "transparent"
                                border.color: modelData.a === "play" ? Theme.accent : Theme.line; border.width: 1
                                Text { anchors.centerIn: parent; text: modelData.g; color: Theme.fg; font.family: Theme.mono; font.pixelSize: 16 }
                                MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { if (!root.p) return; if (modelData.a === "prev") root.p.previous(); else if (modelData.a === "next") root.p.next(); else root.p.togglePlaying() } }
                            }
                        }
                        Item { width: 10; height: 1 }
                        Text { text: "VOL"; color: Theme.muted; font.family: Theme.ui; font.pixelSize: 12; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                        Item {
                            width: volSeg.implicitWidth; height: 30
                            Seg { id: volSeg; count: 10; value: root.p && root.p.volumeSupported ? root.p.volume * 100 : 100; on: Theme.accent }
                            MouseArea { anchors.fill: parent
                                onWheel: w => { if (root.p && root.p.volumeSupported) root.p.volume = Math.max(0, Math.min(1, root.p.volume + (w.angleDelta.y > 0 ? 0.05 : -0.05))) } }
                        }
                        Text { text: root.p && root.p.volumeSupported ? Math.round(root.p.volume * 100) + "%" : "--"; color: Theme.accent; font.family: Theme.mono; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }

            // stations = active players
            Text { id: stTitle; anchors { top: body.bottom; topMargin: 14 } text: "◆  STATIONS  //  局"; color: Theme.muted; font.family: Theme.ui; font.pixelSize: 12; font.bold: true; font.letterSpacing: 2 }
            Column {
                anchors { top: stTitle.bottom; topMargin: 8; left: parent.left; right: parent.right }
                spacing: 6
                Repeater {
                    model: root.players
                    Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool cur: index === Math.min(root.pick, root.players.length - 1)
                        width: parent.width; height: 34
                        color: cur ? "#244fa3ae" : (sm.containsMouse ? "#144fa3ae" : "#cc0b1424")
                        border.color: cur ? Theme.accent : Theme.line; border.width: 1
                        Rectangle { visible: parent.cur; width: 3; height: parent.height; color: Theme.accent }
                        Text { x: 14; anchors.verticalCenter: parent.verticalCenter; text: root.freq(index); color: parent.cur ? Theme.accent : Theme.dim; font.family: Theme.mono; font.pixelSize: 13; font.bold: true }
                        Text { x: 70; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 170; elide: Text.ElideRight
                               text: (modelData.identity || "PLAYER").toUpperCase() + (modelData.trackTitle ? "  —  " + modelData.trackTitle : "")
                               color: parent.cur ? "#ffffff" : Theme.fg; font.family: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold }
                        Text { anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                               text: modelData.isPlaying ? "ON AIR" : "IDLE"; color: modelData.isPlaying ? Theme.accent : Theme.dim; font.family: Theme.ui; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1 }
                        MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.pick = index }
                    }
                }
                Text { visible: root.players.length === 0; text: "NO ACTIVE STATIONS — START SPOTIFY OR A BROWSER TAB"; color: Theme.dim; font.family: Theme.mono; font.pixelSize: 10 }
            }
            Text { anchors.bottom: parent.bottom; text: "[SPACE] PLAY/PAUSE   [← →] TRACK   [WHEEL] VOLUME   [ESC] CLOSE"; color: Theme.dim; font.family: Theme.mono; font.pixelSize: 10; font.letterSpacing: 1 }
        }
    }
}
