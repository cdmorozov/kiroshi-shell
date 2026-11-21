// top-left telemetry block: glowing header rule, streaming disassembly dump,
// live readouts, footer and wire lines to an operator tag. Our palette.
import QtQuick
import Quickshell.Io
Item {
    id: root
    width: 560; height: 470
    property int cpu: 0
    property int mem: 0
    property int bat: 100
    property int disk: 0
    property string batState: ""
    readonly property string node: "AK-07"

    Process {
        id: stat
        command: ["sh", "-c", "$HOME/.config/quickshell/sysstat.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(" ")
                if (p.length >= 4) { root.cpu = +p[0]; root.mem = +p[1]; root.bat = +p[2]; root.disk = +p[3]; root.batState = p[4] || "" }
            }
        }
    }
    Timer { interval: 2000; running: root.visible; repeat: true; triggeredOnStart: true; onTriggered: stat.running = true }

    // ---- disassembly generator ----
    readonly property var ops: ["MOV", "XOR", "JMP", "CALL", "PUSH", "POP", "LEA", "CMP", "SHL", "AND", "RET", "NOP", "INT"]
    function hx(n) { let s = ""; for (let i = 0; i < n; i++) s += "0123456789ABCDEF"[Math.floor(Math.random() * 16)]; return s }
    function asm() {
        const op = ops[Math.floor(Math.random() * ops.length)]
        const pad = ["", "  ", "    ", "      "][Math.floor(Math.random() * 4)]
        let s = pad + hx(4) + "  " + (op + "    ").slice(0, 5) + hx(2)
        if (Math.random() > 0.35) s += "   " + hx(4) + " " + hx(4)
        return s
    }
    ListModel { id: dump }
    Component.onCompleted: { for (let i = 0; i < 16; i++) dump.append({ t: asm() }) }
    Timer {
        interval: 380; running: root.visible; repeat: true
        onTriggered: { dump.append({ t: root.asm() }); if (dump.count > 16) dump.remove(0) }
    }

    // ---- header: slanted glowing rule ----
    Text {
        x: 4; y: 0
        text: "SYS.CORE  //  NODE " + root.node + "  //  LIVE TELEMETRY"
        color: Theme.muted; font.family: Theme.mono; font.pixelSize: 10; font.letterSpacing: 2
    }
    Canvas {
        id: rule
        x: 0; y: 14; width: root.width; height: 18
        onPaint: {
            const c = getContext("2d"); c.reset()
            for (const [w, a] of [[7, 0.10], [3, 0.30], [1.2, 1.0]]) {
                const g = c.createLinearGradient(0, 0, width, 0)
                g.addColorStop(0, Qt.rgba(0.31, 0.64, 0.68, a)); g.addColorStop(0.7, Qt.rgba(0.31, 0.64, 0.68, a * 0.6)); g.addColorStop(1, Qt.rgba(0.31, 0.64, 0.68, 0))
                c.strokeStyle = g; c.lineWidth = w
                c.beginPath(); c.moveTo(0, 4); c.lineTo(width, 13); c.stroke()
            }
        }
    }

    // ---- main dump panel ----
    Rectangle {
        id: panel
        x: 0; y: 34; width: 330; height: 300
        clip: true
        color: "#b3081020"
        border.color: Qt.rgba(0.31, 0.64, 0.68, 0.55); border.width: 1
        Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top } height: 2; color: Theme.accent; opacity: 0.8 }
        Column {
            anchors { left: parent.left; top: parent.top; leftMargin: 10; topMargin: 10 }
            spacing: 2
            Repeater {
                model: dump
                Text {
                    text: model.t
                    color: index === dump.count - 1 ? Theme.fg : Qt.rgba(0.31, 0.64, 0.68, 0.45 + 0.5 * index / dump.count)
                    font.family: Theme.mono; font.pixelSize: 11
                }
            }
        }
    }

    // ---- live readouts to the right of the panel ----
    Column {
        x: panel.width + 16; y: panel.y + 4
        spacing: 6
        Repeater {
            model: [
                { k: "CPU", v: () => root.cpu,  hot: () => root.cpu > 85 },
                { k: "MEM", v: () => root.mem,  hot: () => root.mem > 85 },
                { k: "BAT", v: () => root.bat,  hot: () => root.bat < 20 },
                { k: "DSK", v: () => root.disk, hot: () => root.disk > 90 }
            ]
            Row {
                spacing: 7
                Rectangle { width: 8; height: 8; anchors.verticalCenter: parent.verticalCenter; color: "transparent"; border.width: 1; border.color: modelData.hot() ? Theme.alert : Theme.accent }
                Text { text: modelData.k; color: Theme.muted; font.family: Theme.ui; font.pixelSize: 13; font.bold: true; width: 30 }
                Text {
                    text: (modelData.v() + "").padStart(3, " ") + (modelData.k === "BAT" && root.batState === "Charging" ? " +" : "")
                    color: modelData.hot() ? Theme.alert : Theme.fg
                    font.family: Theme.mono; font.pixelSize: 13; font.bold: true
                }
            }
        }
    }

    // ---- footer under the panel ----
    Column {
        x: 6; y: panel.y + panel.height + 8
        spacing: 3
        Text { text: "LOCAL NODE  //  " + root.node + "-" + "4F" + (root.disk * 37 % 4096).toString(16).toUpperCase().padStart(3, "0"); color: Theme.dim; font.family: Theme.mono; font.pixelSize: 10; font.letterSpacing: 1 }
        Text { text: "ARRAY INTEGRITY  " + (100 - root.cpu * 0.4).toFixed(1) + "%"; color: root.cpu > 85 ? Theme.alert : Theme.dim; font.family: Theme.mono; font.pixelSize: 10; font.letterSpacing: 1 }
    }

    // ---- wires from the panel down to the operator tag ----
    Canvas {
        anchors.fill: parent
        onPaint: {
            const c = getContext("2d"); c.reset()
            c.strokeStyle = Qt.rgba(0.31, 0.64, 0.68, 0.55); c.lineWidth = 1
            const bx = 150, by = panel.y + panel.height, tx = tag.x, ty = tag.y + tag.height / 2
            c.beginPath(); c.moveTo(bx, by); c.lineTo(tx, ty); c.stroke()
            c.beginPath(); c.moveTo(bx + 26, by); c.lineTo(tx, ty - 10); c.stroke()
            c.beginPath(); c.moveTo(panel.width, panel.y + 40); c.lineTo(panel.width, by + 40); c.lineTo(tx, ty + 6); c.stroke()
        }
    }

    // ---- operator tag ----
    Rectangle {
        id: tag
        x: 380; y: 404; width: 170; height: 54
        color: Qt.rgba(0.31, 0.64, 0.68, 0.88)
        Text { x: 12; y: 6; text: "OPERATOR"; color: Theme.bg; font.family: Theme.ui; font.pixelSize: 19; font.bold: true; font.letterSpacing: 2 }
        Text { x: 12; y: 30; text: "GHOST  //  NETRUNNER"; color: "#0e1a30"; font.family: Theme.ui; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1 }
    }
}
