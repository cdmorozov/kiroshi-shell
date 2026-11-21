// Night City top bar (variant 1: navy + teal), replaces Waybar
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Bluetooth
PanelWindow {
    id: bar
    required property var screenRef
    screen: screenRef
    anchors { top: true; left: true; right: true }
    implicitHeight: 52
    exclusiveZone: 50
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "netrun-bar"

    readonly property color val: "#7fbcc5"
    readonly property var kanjiDays: ["日曜日", "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日"]

    // ---------- data ----------
    property int cpu: 0; property int mem: 0; property int bat: 100; property string batState: ""
    Process {
        id: stat; command: ["sh", "-c", "$HOME/.config/quickshell/sysstat.sh"]
        stdout: StdioCollector { onStreamFinished: { const p = text.trim().split(" "); if (p.length >= 4) { bar.cpu = +p[0]; bar.mem = +p[1]; bar.bat = +p[2]; bar.batState = p[4] || "" } } }
    }
    Timer { interval: 2500; running: true; repeat: true; triggeredOnStart: true; onTriggered: stat.running = true }

    property string ssid: ""; property int signal: 0; property bool wired: false
    Process {
        id: net
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi 2>/dev/null | grep '^yes' | head -1; nmcli -t -f TYPE,STATE dev 2>/dev/null | grep -q '^ethernet:connected' && echo WIRED"]
        stdout: StdioCollector {
            onStreamFinished: {
                bar.wired = text.indexOf("WIRED") >= 0
                const l = text.split("\n").find(s => s.startsWith("yes:"))
                if (l) { const p = l.split(":"); bar.signal = +p[1]; bar.ssid = p.slice(2).join(":") } else { bar.signal = 0; bar.ssid = "" }
            }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: net.running = true }

    property string lang: "EN"
    Process { id: langP; command: ["sh", "-c", "$HOME/.config/waybar/lang.sh"]; stdout: StdioCollector { onStreamFinished: bar.lang = text.trim() } }
    Timer { interval: 800; running: true; repeat: true; triggeredOnStart: true; onTriggered: langP.running = true }

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [bar.sink] }
    readonly property int vol: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    SystemClock { id: clock; precision: SystemClock.Seconds }

    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }

    // ---------- small text helpers ----------
    component K: Text { color: Theme.muted; font.family: Theme.ui; font.pixelSize: 12; font.bold: true; font.letterSpacing: 2; anchors.verticalCenter: parent.verticalCenter }
    component J: Text { color: Theme.dim; font.family: Theme.text; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
    component V: Text { color: bar.val; font.family: Theme.mono; font.pixelSize: 14; font.bold: true; anchors.verticalCenter: parent.verticalCenter }

    Item {
        anchors { fill: parent; topMargin: 8; leftMargin: 12; rightMargin: 12; bottomMargin: 8 }

        // ===== left =====
        Row {
            id: leftRow
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            spacing: 8
            Plate {
                fill: Theme.accent; stroke: Theme.accent; edge: Theme.accent; pad: 16
                interactive: true; onClicked: bar.run("qs -p ~/.config/quickshell ipc call launcher toggle")
                Text { text: "NC//"; color: Theme.bg; font.family: Theme.ui; font.pixelSize: 16; font.bold: true; font.letterSpacing: 2 }
            }
            Plate {
                pad: 8
                Repeater {
                    model: {
                        let max = 4
                        for (const w of Hyprland.workspaces.values) if (w.id > max && w.id < 100) max = w.id
                        return Array.from({ length: max }, (_, i) => i + 1)
                    }
                    Item {
                        required property int modelData
                        readonly property var ws: Hyprland.workspaces.values.find(w => w.id === modelData)
                        readonly property bool on: !!(ws && ws.focused)
                        readonly property bool has: !!(ws && ws.toplevels.values.length > 0)
                        width: 30; height: 24; anchors.verticalCenter: parent.verticalCenter
                        Rectangle { anchors.fill: parent; color: parent.on ? Theme.accent : "transparent"; border.color: parent.on ? Theme.accent : Theme.line; border.width: 1 }
                        Text { anchors.centerIn: parent; text: (modelData < 10 ? "0" : "") + modelData; font.family: Theme.ui; font.pixelSize: 13; font.bold: true
                               color: parent.on ? Theme.bg : (parent.has ? Theme.muted : Theme.dim) }
                        Rectangle { visible: !!(ws && ws.urgent); anchors { right: parent.right; top: parent.top } width: 5; height: 5; color: Theme.alert }
                        MouseArea { anchors.fill: parent; onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData + " })") }
                    }
                }
            }
            Plate {
                visible: ToplevelManager.toplevels.values.length > 0
                K { text: "LINK" } J { text: "接続" }
                Repeater {
                    model: ToplevelManager.toplevels
                    Item {
                        required property var modelData
                        width: 22; height: 26; anchors.verticalCenter: parent.verticalCenter
                        readonly property var entry: DesktopEntries.applications.values.find(e => e.id === modelData.appId || e.startupClass === modelData.appId) || DesktopEntries.heuristicLookup(modelData.appId)
                        // try icon candidates one by one; fall back to two letters
                        readonly property var cands: {
                            const id = modelData.appId || "", e = entry ? entry.icon : ""
                            const out = []
                            for (const n of [e, id, id.toLowerCase(), id.split(".").pop().toLowerCase()]) {
                                if (!n) continue
                                if (n.startsWith("/")) { out.push("file://" + n); continue }
                                out.push(Quickshell.iconPath(n, true))
                                out.push("file:///usr/share/icons/hicolor/48x48/apps/" + n + ".png")
                                out.push("file:///usr/share/icons/hicolor/scalable/apps/" + n + ".svg")
                            }
                            return out.filter(s => s && s !== "")
                        }
                        property int ci: 0
                        Image {
                            id: ico
                            anchors.centerIn: parent
                            width: 18; height: 18; sourceSize: Qt.size(36, 36)
                            smooth: true; asynchronous: true
                            source: parent.ci < parent.cands.length ? parent.cands[parent.ci] : ""
                            visible: status === Image.Ready
                            opacity: modelData.activated ? 1 : 0.6
                            onStatusChanged: if (status === Image.Error) parent.ci++
                        }
                        Text {
                            anchors.centerIn: parent; visible: parent.ci >= parent.cands.length
                            text: (modelData.appId || "?").split(".").pop().slice(0, 2).toUpperCase()
                            color: Theme.muted; font.family: Theme.ui; font.pixelSize: 11; font.bold: true
                        }
                        Rectangle { visible: modelData.activated; anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter } width: 14; height: 2; color: bar.val }
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                    onClicked: m => m.button === Qt.MiddleButton ? modelData.close() : modelData.activate() }
                    }
                }
            }
        }

        // ===== center: clock =====
        Item {
            anchors { left: leftRow.right; right: rightRow.left; top: parent.top; bottom: parent.bottom }
        Plate {
            id: clockPlate
            anchors.centerIn: parent
            Text { text: Qt.formatDateTime(clock.date, "HH:mm"); color: "#ffffff"; font.family: Theme.ui; font.pixelSize: 20; font.bold: true; font.letterSpacing: 2; anchors.verticalCenter: parent.verticalCenter }
            Text { text: Qt.formatDateTime(clock.date, "ddd dd.MM").toUpperCase() + "  //  " + bar.kanjiDays[clock.date.getDay()]
                   color: Theme.muted; font.family: Theme.text; font.pixelSize: 11; font.letterSpacing: 1; anchors.verticalCenter: parent.verticalCenter }
        }
        }

        // ===== right =====
        Row {
            id: rightRow
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 8
            Plate {
                visible: SystemTray.items.values.length > 0; pad: 10
                K { text: "SYS" } J { text: "常駐" }
                Repeater {
                    model: SystemTray.items
                    Item {
                        id: trayItem
                        required property var modelData
                        width: 18; height: 24; anchors.verticalCenter: parent.verticalCenter
                        IconImage { anchors.centerIn: parent; implicitSize: 16; source: trayItem.modelData.icon }
                        QsMenuAnchor {
                            id: trayMenu
                            menu: trayItem.modelData.menu
                            anchor.item: trayItem
                            anchor.edges: Edges.Bottom
                            anchor.gravity: Edges.Bottom
                        }
                        MouseArea {
                            anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: m => {
                                if (m.button === Qt.MiddleButton) trayItem.modelData.secondaryActivate()
                                else if (m.button === Qt.RightButton || trayItem.modelData.onlyMenu) { if (trayItem.modelData.hasMenu) trayMenu.open() }
                                else trayItem.modelData.activate()
                            }
                        }
                    }
                }
            }
            Plate {
                K { text: "CPU" } J { text: "演算" }
                Seg { count: 8; value: bar.cpu; on: bar.val; hot: bar.cpu > 85 }
                V { text: bar.cpu; color: bar.cpu > 85 ? Theme.alert : bar.val }
            }
            Plate {
                K { text: "MEM" } J { text: "記憶" }
                Seg { count: 8; value: bar.mem; on: bar.val; hot: bar.mem > 85 }
                V { text: bar.mem; color: bar.mem > 85 ? Theme.alert : bar.val }
            }
            Plate {
                interactive: true
                onClicked: m => m.button === Qt.RightButton ? (bar.sink.audio.muted = !bar.sink.audio.muted) : PanelState.toggleVol()
                onWheeled: w => { if (bar.sink && bar.sink.audio) bar.sink.audio.volume = Math.max(0, Math.min(1, bar.sink.audio.volume + (w.angleDelta.y > 0 ? 0.05 : -0.05))) }
                K { text: "VOL" }
                Seg { count: 8; value: bar.muted ? 0 : bar.vol; on: bar.val }
                V { text: bar.muted ? "--" : bar.vol }
            }
            Plate {
                interactive: true; onClicked: PanelState.toggleNet()
                K { text: "NET" } J { text: "網" }
                Row {
                    spacing: 2; anchors.verticalCenter: parent.verticalCenter; height: 14
                    Repeater {
                        model: 4
                        Rectangle {
                            width: 4; height: 5 + index * 3; anchors.bottom: parent.bottom
                            color: (bar.wired || bar.signal > index * 25) ? bar.val : Theme.line
                        }
                    }
                }
                V { text: bar.ssid !== "" ? bar.ssid.toUpperCase().slice(0, 10) : (bar.wired ? "WIRED" : "OFFLINE"); color: (bar.ssid !== "" || bar.wired) ? bar.val : Theme.dim }
            }
            Plate {   // BT.PLATE
                interactive: true; onClicked: PanelState.toggleBt()
                K { text: "BT" } J { text: "藍" }
                V {
                    readonly property var ad: Bluetooth.defaultAdapter
                    readonly property int linked: ad ? ad.devices.values.filter(d => d.connected).length : 0
                    text: !ad || !ad.enabled ? "OFF" : (linked > 0 ? linked + " LINK" : "ON")
                    color: !ad || !ad.enabled ? Theme.dim : bar.val
                }
            }
            Plate {
                K { text: "BAT" }
                Seg { count: 8; value: bar.bat; on: bar.batState === "Charging" ? Theme.warn : bar.val; hot: bar.bat < 20 }
                V { text: bar.bat + (bar.batState === "Charging" ? "+" : ""); color: bar.bat < 20 ? Theme.alert : bar.val }
            }
            Plate {
                interactive: true; onClicked: bar.run("hyprctl switchxkblayout all next")
                K { text: "LNG" } V { text: bar.lang }
            }
            Plate {
                pad: 12; edge: Theme.alert
                interactive: true; onClicked: bar.run("qs -p ~/.config/quickshell ipc call power toggle")
                Text { text: "⏻"; color: Theme.alert; font.family: Theme.mono; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}
