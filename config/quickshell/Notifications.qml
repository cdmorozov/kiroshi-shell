// notification server + toast stack (replaces swaync)
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick.Shapes
Scope {
    id: root
    property bool historyOpen: false
    ListModel { id: history }
    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: false
        onNotification: n => {
            n.tracked = true
            history.insert(0, { app: (n.appName || "SYSTEM").toUpperCase(), summary: n.summary, body: n.body, time: Qt.formatDateTime(new Date(), "HH:mm"), crit: n.urgency === NotificationUrgency.Critical })
            if (history.count > 40) history.remove(40)
        }
    }
    IpcHandler {
        target: "notifs"
        function clear(): void { for (const n of server.trackedNotifications.values.slice()) n.dismiss() }
        function history(): void { root.historyOpen = !root.historyOpen }
    }
    PanelWindow {
        anchors { left: true; top: true }
        margins { left: 24; top: 560 }
        implicitWidth: 440; implicitHeight: 520
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "netrun-notify"
        mask: Region { item: stack }
        visible: server.trackedNotifications.values.length > 0
        Column {
            id: stack
            width: 440
            spacing: 10
            Repeater {
                model: server.trackedNotifications
                Toast { required property var modelData; notif: modelData }
            }
        }
    }

    // ---------- history panel ----------
    PanelWindow {
        visible: root.historyOpen
        anchors { top: true; bottom: true; left: true; right: true }
        color: "#8c050a14"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "netrun-history"
        WlrLayershell.keyboardFocus: root.historyOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        MouseArea { anchors.fill: parent; onClicked: root.historyOpen = false }
        Item { focus: true; Keys.onEscapePressed: root.historyOpen = false }
        Item {
            id: hp
            anchors { left: parent.left; leftMargin: 24; top: parent.top; topMargin: 70; bottom: parent.bottom; bottomMargin: 30 }
            width: 420
            MouseArea { anchors.fill: parent }
            Shape {
                anchors.fill: parent; preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: "#f2081020"; strokeColor: "#994fa3ae"; strokeWidth: 1
                    startX: 0; startY: 0
                    PathLine { x: hp.width - 16; y: 0 } PathLine { x: hp.width; y: 16 } PathLine { x: hp.width; y: hp.height }
                    PathLine { x: 16; y: hp.height } PathLine { x: 0; y: hp.height - 16 } PathLine { x: 0; y: 0 }
                }
            }
            Rectangle { width: parent.width - 16; height: 2; color: Theme.accent }
            Row { x: 18; y: 14; spacing: 10
                Text { text: "MESSAGE.LOG"; color: Theme.fg; font.family: Theme.ui; font.pixelSize: 18; font.bold: true; font.letterSpacing: 2 }
                Text { text: "通知履歴"; color: Theme.dim; font.family: Theme.text; font.pixelSize: 12; anchors.baseline: parent.children[0].baseline } }
            Rectangle {
                anchors { right: parent.right; rightMargin: 24; top: parent.top; topMargin: 12 }
                width: clr.implicitWidth + 16; height: 22; color: "transparent"; border.color: cm.containsMouse ? Theme.accent : Theme.line
                Text { id: clr; anchors.centerIn: parent; text: "CLEAR"; color: Theme.muted; font.family: Theme.ui; font.pixelSize: 11; font.bold: true; font.letterSpacing: 2 }
                MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: history.clear() }
            }
            ListView {
                anchors { fill: parent; topMargin: 52; leftMargin: 14; rightMargin: 14; bottomMargin: 36 }
                clip: true; spacing: 8; model: history
                delegate: Rectangle {
                    required property var model
                    width: ListView.view.width; height: col2.implicitHeight + 16
                    color: "#cc0b1424"; border.color: Theme.line
                    Rectangle { width: 3; height: parent.height; color: model.crit ? Theme.alert : Theme.accent }
                    Column { id: col2; x: 14; y: 8; width: parent.width - 28; spacing: 2
                        Row { spacing: 8
                            Text { text: model.time; color: Theme.dim; font.family: Theme.mono; font.pixelSize: 10 }
                            Text { text: model.app; color: model.crit ? Theme.alert : Theme.accent; font.family: Theme.ui; font.pixelSize: 11; font.bold: true; font.letterSpacing: 2 } }
                        Text { width: parent.width; elide: Text.ElideRight; text: model.summary; color: Theme.fg; font.family: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                        Text { width: parent.width; visible: text !== ""; text: model.body; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight; color: Theme.muted; font.family: Theme.text; font.pixelSize: 11 } }
                }
            }
            Text { visible: history.count === 0; anchors.centerIn: parent; text: "NO MESSAGES"; color: Theme.dim; font.family: Theme.mono; font.pixelSize: 11; font.letterSpacing: 2 }
            Text { anchors { bottom: parent.bottom; bottomMargin: 12; left: parent.left; leftMargin: 18 } text: history.count + " ENTRIES    [ESC] CLOSE"; color: Theme.dim; font.family: Theme.mono; font.pixelSize: 10 }
        }
    }
}
