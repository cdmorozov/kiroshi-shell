// clickable / draggable segmented slider
import QtQuick
Item {
    id: root
    property real value: 0          // 0..1
    property int count: 24
    property color on: Theme.accent
    property bool dim: false
    signal moved(real v)
    implicitWidth: 220; implicitHeight: 14
    Row {
        anchors.fill: parent; spacing: 2
        Repeater {
            model: root.count
            Rectangle {
                width: (root.width - (root.count - 1) * 2) / root.count; height: root.height
                color: index < Math.round(root.value * root.count) ? (root.dim ? Theme.dim : root.on) : Theme.line
            }
        }
    }
    MouseArea {
        anchors { fill: parent; topMargin: -6; bottomMargin: -6 }
        cursorShape: Qt.PointingHandCursor
        function setFrom(x) { root.moved(Math.max(0, Math.min(1, x / width))) }
        onPressed: m => setFrom(m.x)
        onPositionChanged: m => { if (pressed) setFrom(m.x) }
        onWheel: w => root.moved(Math.max(0, Math.min(1, root.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
