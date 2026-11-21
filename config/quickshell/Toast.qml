// one notification toast: slides in from the left, chamfered plate, game-like header
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
Item {
    id: root
    required property var notif
    readonly property bool critical: notif && notif.urgency === NotificationUrgency.Critical
    readonly property color edge: critical ? Theme.alert : Theme.accent
    width: 400
    height: plate.height
    x: -width - 40
    opacity: 0

    Component.onCompleted: { x = 0; opacity = 1 }
    Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 200 } }

    function close() { leave.start() }
    SequentialAnimation {
        id: leave
        ParallelAnimation {
            NumberAnimation { target: root; property: "x"; to: -root.width - 40; duration: 220; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "opacity"; to: 0; duration: 220 }
        }
        ScriptAction { script: root.notif.dismiss() }
    }
    Timer {
        interval: root.critical ? 12000 : (root.notif.expireTimeout > 0 ? root.notif.expireTimeout : 6500)
        running: !hover.containsMouse
        onTriggered: root.close()
    }

    // icon block
    Rectangle {
        id: iconBox
        width: 46; height: 46
        color: "#e6081020"
        border.color: root.edge; border.width: 1
        readonly property string src: root.notif.image !== "" ? root.notif.image
                                    : (root.notif.appIcon !== "" ? Quickshell.iconPath(root.notif.appIcon, true) : "")
        IconImage {
            anchors.centerIn: parent
            implicitSize: 28
            visible: parent.src !== ""
            source: parent.src
        }
        Text {
            anchors.centerIn: parent
            visible: parent.src === ""
            text: root.critical ? "\uf071" : "\uf0e0"
            color: root.edge
            font.family: Theme.mono; font.pixelSize: 20
        }
    }

    // chamfered plate
    Item {
        id: plate
        anchors { left: iconBox.right; leftMargin: 8; right: parent.right }
        height: col.implicitHeight + 20
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: "#eb081020"
                strokeColor: root.critical ? "#d9e60000" : "#b34fa3ae"
                strokeWidth: 1
                startX: 0; startY: 0
                PathLine { x: plate.width - 14; y: 0 }
                PathLine { x: plate.width; y: 14 }
                PathLine { x: plate.width; y: plate.height }
                PathLine { x: 0; y: plate.height }
                PathLine { x: 0; y: 0 }
            }
        }
        Rectangle { width: 3; height: parent.height; color: root.edge }
        Column {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 14; rightMargin: 18; topMargin: 9 }
            spacing: 3
            Text {
                text: (root.critical ? "PRIORITY ALERT  //  警告" : "NEW MESSAGE  //  通知")
                color: root.edge; font.family: Theme.ui; font.pixelSize: 11; font.bold: true; font.letterSpacing: 2
            }
            Text {
                width: parent.width; elide: Text.ElideRight
                text: (root.notif.appName || "SYSTEM").toUpperCase()
                color: Theme.muted; font.family: Theme.text; font.pixelSize: 11; font.weight: Font.DemiBold; font.letterSpacing: 1
            }
            Text {
                width: parent.width; elide: Text.ElideRight
                text: root.notif.summary
                color: Theme.fg; font.family: Theme.text; font.pixelSize: 15; font.weight: Font.DemiBold
            }
            Text {
                width: parent.width; visible: text !== ""
                text: root.notif.body; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight
                textFormat: Text.PlainText
                color: Theme.muted; font.family: Theme.text; font.pixelSize: 13; font.weight: Font.Normal
            }
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent; hoverEnabled: true
        onClicked: {
            const def = root.notif.actions.find(a => a.identifier === "default")
            if (def) def.invoke()
            root.close()
        }
    }
}
