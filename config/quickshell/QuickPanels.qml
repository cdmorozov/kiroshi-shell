// drop-down Wi-Fi and Bluetooth panels under the top bar
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
Scope {
    id: root
    IpcHandler {
        target: "panels"
        function net(): void { PanelState.toggleNet() }
        function bt(): void { PanelState.toggleBt() }
        function close(): void { PanelState.closeAll() }
    }

    // ---------------- Wi-Fi data ----------------
    property var nets: []
    property bool wifiOn: true
    property string status: ""
    property string askPass: ""          // SSID waiting for a password
    function splitNm(line) {             // nmcli -t escapes ':' as '\:'
        const out = []; let cur = ""
        for (let i = 0; i < line.length; i++) {
            if (line[i] === "\\" && i + 1 < line.length) { cur += line[++i]; continue }
            if (line[i] === ":") { out.push(cur); cur = ""; continue }
            cur += line[i]
        }
        out.push(cur); return out
    }
    Process {
        id: scan
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "dev", "wifi", "list", "--rescan", "auto"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {}
                for (const l of text.split("\n")) {
                    if (!l) continue
                    const p = root.splitNm(l); const ssid = p.slice(3).join(":")
                    if (!ssid) continue
                    const n = { ssid: ssid, signal: +p[1], secure: p[2] !== "" && p[2] !== "--", active: p[0] === "*" }
                    if (!seen[ssid] || seen[ssid].signal < n.signal || n.active) seen[ssid] = Object.assign(seen[ssid] || {}, n, { active: !!(n.active || (seen[ssid] && seen[ssid].active)) })
                }
                root.nets = Object.values(seen).sort((a, b) => (b.active - a.active) || (b.signal - a.signal)).slice(0, 9)
            }
        }
    }
    Process { id: radio; command: ["nmcli", "radio", "wifi"]; stdout: StdioCollector { onStreamFinished: root.wifiOn = text.trim() === "enabled" } }

    Process {
        id: act
        property string ssid: ""
        stdout: StdioCollector { id: actOut }
        stderr: StdioCollector { id: actErr }
        onExited: code => {
            const msg = (actOut.text + actErr.text).toLowerCase()
            if (code === 0) { root.status = "LINKED  //  " + ssid.toUpperCase(); root.askPass = "" }
            else if (msg.includes("secret") || msg.includes("password") || msg.includes("802-11-wireless-security")) { root.status = "ACCESS KEY REQUIRED"; root.askPass = ssid }
            else root.status = "LINK FAILED"
            scan.running = true
        }
    }
    function connect(n) {
        if (n.active) { act.ssid = n.ssid; root.status = "DISCONNECTING..."; act.command = ["nmcli", "con", "down", "id", n.ssid]; act.running = true; return }
        act.ssid = n.ssid; root.status = "LINKING  //  " + n.ssid.toUpperCase()
        act.command = ["nmcli", "dev", "wifi", "connect", n.ssid]; act.running = true
    }
    function connectWith(pw) {
        act.ssid = root.askPass; root.status = "LINKING  //  " + root.askPass.toUpperCase()
        act.command = ["nmcli", "dev", "wifi", "connect", root.askPass, "password", pw]; act.running = true
    }

    // ---------------- Bluetooth data ----------------
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devs: adapter ? adapter.devices.values.slice().sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || (a.name || "").localeCompare(b.name || "")).slice(0, 9) : []

    // ---------------- window ----------------
    PanelWindow {
        visible: PanelState.netOpen || PanelState.btOpen
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "netrun-panels"
        WlrLayershell.keyboardFocus: root.askPass !== "" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand
        onVisibleChanged: if (!visible) { root.askPass = ""; root.status = "" }
        Timer {
            interval: 6000; repeat: true; triggeredOnStart: true
            running: PanelState.netOpen
            onTriggered: { radio.running = true; scan.running = true }
        }

        MouseArea { anchors.fill: parent; onClicked: PanelState.closeAll() }
        Item { focus: true; Keys.onEscapePressed: PanelState.closeAll() }

        // ===== Wi-Fi =====
        HudFrame {
            visible: PanelState.netOpen
            title: "NET.LINK"; kanji: "網"
            anchors { right: parent.right; rightMargin: 230; top: parent.top; topMargin: 56 }
            width: 420; height: 140 + root.nets.length * 38 + (root.askPass !== "" ? 50 : 0)
            MouseArea { anchors.fill: parent; z: -1 }
            headerRight: [
                HudSwitch { label: "WIFI"; on: root.wifiOn; onToggled: { Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifiOn ? "off" : "on"]); root.wifiOn = !root.wifiOn } }
            ]
            Column {
                width: parent.width; spacing: 6
                Text { text: root.status !== "" ? root.status : (root.wifiOn ? "SCANNING LOCAL NETWORKS" : "RADIO OFFLINE"); color: root.status.includes("FAIL") || root.status.includes("REQUIRED") ? Theme.warn : Theme.dim; font.family: Theme.mono; font.pixelSize: 10; font.letterSpacing: 1 }
                Repeater {
                    model: root.nets
                    Rectangle {
                        required property var modelData
                        id: netRow
                        readonly property int sig: modelData.signal
                        width: parent.width; height: 32
                        color: ma.containsMouse ? "#1f4fa3ae" : (modelData.active ? "#144fa3ae" : "transparent")
                        border.color: modelData.active ? Theme.accent : Theme.line; border.width: 1
                        Row {
                            x: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 2; height: 14
                            Repeater { model: 4; Rectangle { width: 4; height: 5 + index * 3; anchors.bottom: parent.bottom; color: netRow.sig > index * 25 ? Theme.accent : Theme.line } }
                        }
                        Text { x: 40; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 150; elide: Text.ElideRight
                               text: modelData.ssid; color: modelData.active ? "#ffffff" : Theme.fg; font.family: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                        Row {
                            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter } spacing: 8
                            Text { visible: modelData.secure; text: ""; color: Theme.dim; font.family: Theme.mono; font.pixelSize: 11 }
                            Text { text: modelData.signal + "%"; color: Theme.muted; font.family: Theme.mono; font.pixelSize: 11 }
                            Rectangle { visible: modelData.active; width: lk.implicitWidth + 8; height: 14; color: Theme.accent
                                Text { id: lk; anchors.centerIn: parent; text: "LINKED"; color: Theme.bg; font.family: Theme.ui; font.pixelSize: 9; font.bold: true } }
                        }
                        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.connect(modelData) }
                    }
                }
                // password prompt
                Rectangle {
                    visible: root.askPass !== ""
                    width: parent.width; height: 40; color: "#0b1424"; border.color: Theme.warn; border.width: 1
                    Text { x: 10; anchors.verticalCenter: parent.verticalCenter; text: "KEY ›"; color: Theme.warn; font.family: Theme.ui; font.pixelSize: 12; font.bold: true }
                    TextInput {
                        id: pass
                        x: 60; width: parent.width - 70; anchors.verticalCenter: parent.verticalCenter
                        echoMode: TextInput.Password; color: Theme.fg; font.family: Theme.mono; font.pixelSize: 13
                        focus: root.askPass !== ""
                        onVisibleChanged: if (visible) { text = ""; forceActiveFocus() }
                        Keys.onReturnPressed: root.connectWith(text)
                        Keys.onEnterPressed: root.connectWith(text)
                        Keys.onEscapePressed: root.askPass = ""
                    }
                }
                Text {
                    text: "[CLICK] LINK / UNLINK      [⚙] ADVANCED"
                    color: Theme.dim; font.family: Theme.mono; font.pixelSize: 10; font.letterSpacing: 1
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Quickshell.execDetached(["nm-connection-editor"]); PanelState.closeAll() } }
                }
            }
        }

        // ===== Bluetooth =====
        HudFrame {
            visible: PanelState.btOpen
            title: "BT.LINK"; kanji: "藍牙"
            anchors { right: parent.right; rightMargin: 120; top: parent.top; topMargin: 56 }
            width: 400; height: 130 + Math.max(1, root.devs.length) * 38
            MouseArea { anchors.fill: parent; z: -1 }
            headerRight: [
                HudSwitch { label: "SCAN"; on: root.adapter ? root.adapter.discovering : false; onToggled: if (root.adapter) root.adapter.discovering = !root.adapter.discovering },
                HudSwitch { label: "BT"; on: root.adapter ? root.adapter.enabled : false; onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled }
            ]
            Column {
                width: parent.width; spacing: 6
                Text { text: !root.adapter ? "NO ADAPTER" : (!root.adapter.enabled ? "RADIO OFFLINE" : (root.adapter.discovering ? "SCANNING..." : root.devs.length + " DEVICES KNOWN")); color: Theme.dim; font.family: Theme.mono; font.pixelSize: 10; font.letterSpacing: 1 }
                Repeater {
                    model: root.devs
                    Rectangle {
                        required property var modelData
                        width: parent.width; height: 32
                        color: bm.containsMouse ? "#1f4fa3ae" : (modelData.connected ? "#144fa3ae" : "transparent")
                        border.color: modelData.connected ? Theme.accent : Theme.line; border.width: 1
                        Text { x: 10; anchors.verticalCenter: parent.verticalCenter; text: modelData.connected ? "󰂱" : "󰂯"; color: modelData.connected ? Theme.accent : Theme.dim; font.family: Theme.mono; font.pixelSize: 14 }
                        Text { x: 34; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 150; elide: Text.ElideRight
                               text: modelData.name || modelData.address; color: modelData.connected ? "#ffffff" : Theme.fg; font.family: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                        Row {
                            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter } spacing: 8
                            Text { visible: modelData.batteryAvailable; text: Math.round(modelData.battery * 100) + "%"; color: Theme.muted; font.family: Theme.mono; font.pixelSize: 11 }
                            Rectangle {
                                width: st.implicitWidth + 8; height: 14
                                color: modelData.connected ? Theme.accent : "transparent"; border.color: modelData.connected ? Theme.accent : Theme.dim; border.width: 1
                                Text { id: st; anchors.centerIn: parent; text: modelData.connected ? "LINKED" : (modelData.pairing ? "PAIRING" : (modelData.paired ? "PAIRED" : "FOUND"))
                                       color: modelData.connected ? Theme.bg : Theme.dim; font.family: Theme.ui; font.pixelSize: 9; font.bold: true }
                            }
                        }
                        MouseArea {
                            id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.connected) modelData.disconnect()
                                else if (modelData.paired) modelData.connect()
                                else { modelData.trusted = true; modelData.pair() }
                            }
                        }
                    }
                }
            }
        }
    }
}
