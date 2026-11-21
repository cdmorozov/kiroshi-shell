// segmented meter, like the in-game bars
import QtQuick
Row {
    id: root
    property int count: 10
    property real value: 0      // 0..100
    property color on: "#7fbcc5"
    property color off: Theme.line
    property bool hot: false
    spacing: 2
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    Repeater {
        model: root.count
        Rectangle {
            width: 5; height: 12
            color: index < Math.round(root.value / 100 * root.count) ? (root.hot ? Theme.alert : root.on) : root.off
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }
}
