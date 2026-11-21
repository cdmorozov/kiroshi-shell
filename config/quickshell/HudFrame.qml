// chamfered panel frame used by the drop-down panels
import QtQuick
import QtQuick.Shapes
Item {
    id: root
    default property alias content: body.data
    property string title: ""
    property string kanji: ""
    property alias headerRight: hr.data
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: "#081020"; strokeColor: "#994fa3ae"; strokeWidth: 1
            startX: 0; startY: 0
            PathLine { x: root.width - 16; y: 0 }
            PathLine { x: root.width; y: 16 }
            PathLine { x: root.width; y: root.height }
            PathLine { x: 16; y: root.height }
            PathLine { x: 0; y: root.height - 16 }
            PathLine { x: 0; y: 0 }
        }
    }
    Rectangle { width: parent.width - 16; height: 2; color: Theme.accent }
    Row {
        x: 16; y: 14; spacing: 10
        Text { text: root.title; color: Theme.fg; font.family: Theme.ui; font.pixelSize: 18; font.bold: true; font.letterSpacing: 2 }
        Text { text: root.kanji; color: Theme.dim; font.family: Theme.text; font.pixelSize: 12; anchors.baseline: parent.children[0].baseline }
    }
    Row { id: hr; anchors { right: parent.right; rightMargin: 22; top: parent.top; topMargin: 14 } spacing: 8 }
    Item { id: body; anchors { fill: parent; topMargin: 50; leftMargin: 16; rightMargin: 16; bottomMargin: 14 } }
}
