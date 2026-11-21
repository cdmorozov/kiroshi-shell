// small ON/OFF toggle
import QtQuick
Rectangle {
    id: root
    property bool on: false
    property string label: ""
    signal toggled()
    width: lbl.implicitWidth + 44; height: 22
    color: "transparent"; border.color: on ? Theme.accent : Theme.line; border.width: 1
    Text { id: lbl; x: 8; anchors.verticalCenter: parent.verticalCenter; text: root.label; color: Theme.muted; font.family: Theme.ui; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1 }
    Rectangle {
        anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
        width: 26; height: 14; color: root.on ? Theme.accent : Theme.line
        Text { anchors.centerIn: parent; text: root.on ? "ON" : "OFF"; color: root.on ? Theme.bg : Theme.dim; font.family: Theme.ui; font.pixelSize: 9; font.bold: true }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggled() }
}
