// chamfered plate (cut top-right + bottom-left corners) with a thin accent edge
import QtQuick
import QtQuick.Shapes
Item {
    id: root
    default property alias content: row.data
    property int pad: 12
    property color fill: "#e00e1a30"
    property color stroke: Theme.line
    property color edge: Theme.accent
    property int cut: 9
    signal clicked(var mouse)
    signal wheeled(var wheel)
    property bool interactive: false
    implicitWidth: row.implicitWidth + pad * 2
    implicitHeight: 36
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.fill; strokeColor: root.stroke; strokeWidth: 1
            startX: 0; startY: 0
            PathLine { x: root.width - root.cut; y: 0 }
            PathLine { x: root.width; y: root.cut }
            PathLine { x: root.width; y: root.height }
            PathLine { x: root.cut; y: root.height }
            PathLine { x: 0; y: root.height - root.cut }
            PathLine { x: 0; y: 0 }
        }
    }
    Rectangle { width: 2; height: parent.height - root.cut; color: root.edge }
    Row { id: row; anchors.centerIn: parent; spacing: 8 }
    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: m => root.clicked(m)
        onWheel: w => root.wheeled(w)
    }
}
