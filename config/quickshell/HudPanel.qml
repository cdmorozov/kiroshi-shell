// framed HUD panel with self-generated scrolling diagnostics (original text)
import QtQuick
Item {
    id: root
    property string title: "PANEL"
    property string tag: "00"
    property int lines: 9
    property real tilt: -8
    layer.enabled: true; layer.smooth: true; layer.samples: 4
    layer.textureSize: Qt.size(width * 2, height * 2)
    transform: Rotation { origin.x: root.width; origin.y: root.height / 2; axis { x: 0; y: 1; z: 0 } angle: root.tilt }
    property int speed: 650
    property var vocab: ["SYNC", "TRACE", "ICE.SCAN", "HANDSHAKE", "PKT", "BUF", "NODE", "ROUTE", "CACHE", "DAEMON", "LINK", "AUTH"]
    property var states: ["OK", "OK", "OK", "ACK", "IDLE", "OK", "PASS", "LOCKED"]

    function hex(n) { let s = ""; for (let i = 0; i < n; i++) s += "0123456789ABCDEF"[Math.floor(Math.random() * 16)]; return s }
    function line() {
        const v = vocab[Math.floor(Math.random() * vocab.length)]
        const st = states[Math.floor(Math.random() * states.length)]
        return "0x" + hex(4) + "  " + (v + "            ").slice(0, 10) + hex(2) + ":" + hex(2) + "  " + (st + "      ").slice(0, 7) + (root.width > 420 ? hex(4) + "-" + hex(4) : "")
    }
    ListModel { id: feed }
    Component.onCompleted: { for (let i = 0; i < lines; i++) feed.append({ t: line() }) }
    Timer {
        interval: root.speed; running: true; repeat: true
        onTriggered: { feed.append({ t: root.line() }); if (feed.count > root.lines) feed.remove(0) }
    }

    // depth slabs (thickness toward the screen centre)
    Repeater {
        model: 2
        Rectangle {
            required property int index
            x: -(index + 1) * 3; y: (index + 1) * 2; width: root.width; height: root.height
            color: "transparent"; border.color: Theme.accent; border.width: 1; opacity: 0.24 - index * 0.07
        }
    }
    // frame: thin border + bright corner ticks
    Rectangle { anchors.fill: parent; color: "#990b1424"; border.color: Theme.line; border.width: 1 }
    Repeater {
        model: 4
        Item {
            width: 14; height: 14
            x: (index % 2) ? root.width - width : 0
            y: (index > 1) ? root.height - height : 0
            Rectangle { width: 14; height: 2; color: Theme.accent; y: index > 1 ? 12 : 0 }
            Rectangle { width: 2; height: 14; color: Theme.accent; x: (index % 2) ? 12 : 0 }
        }
    }
    // header strip
    Rectangle {
        id: head
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
        height: 22; color: "#cc0e1a30"
        Text { anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter } text: root.title; color: Theme.muted; font.family: Theme.ui; font.pixelSize: 13; font.bold: true; font.letterSpacing: 1 }
        Text { anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter } text: root.tag; color: Theme.accent; font.family: Theme.mono; font.pixelSize: 11 }
    }
    Column {
        anchors { left: parent.left; right: parent.right; top: head.bottom; margins: 10 }
        spacing: 3
        Repeater {
            model: feed
            Text {
                text: model.t
                color: index === feed.count - 1 ? Theme.fg : Theme.dim
                font.family: Theme.mono; font.pixelSize: 11
            }
        }
    }
}
