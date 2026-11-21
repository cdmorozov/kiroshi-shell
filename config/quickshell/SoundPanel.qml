// sound drop-down under the VOL plate: master, outputs, per-app volumes, microphone
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
Scope {
    id: root
    IpcHandler { target: "sound"; function toggle(): void { PanelState.toggleVol() } }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var allNodes: Pipewire.nodes.values
    readonly property var sinks: allNodes.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var streams: allNodes.filter(n => n.isSink && n.isStream && n.audio)
    PwObjectTracker { objects: root.allNodes }
    function pct(n) { return n && n.audio ? Math.round(n.audio.volume * 100) : 0 }
    function nm(n) { return n.properties["application.name"] || n.nickname || n.description || n.name }

    PanelWindow {
        visible: PanelState.volOpen
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "netrun-panels"
        WlrLayershell.keyboardFocus: PanelState.volOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        MouseArea { anchors.fill: parent; onClicked: PanelState.closeAll() }
        Item { focus: true; Keys.onEscapePressed: PanelState.closeAll() }

        HudFrame {
            title: "AUDIO.MIX"; kanji: "音響"
            anchors { right: parent.right; rightMargin: 330; top: parent.top; topMargin: 56 }
            width: 440; height: 250 + root.sinks.length * 34 + Math.max(1, root.streams.length) * 46
            MouseArea { anchors.fill: parent; z: -1 }
            headerRight: [ HudSwitch { label: "MUTE"; on: root.sink && root.sink.audio ? root.sink.audio.muted : false
                                       onToggled: if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted } ]
            Column {
                width: parent.width; spacing: 8
                // master
                Text { text: "MASTER  //  " + (root.sink ? (root.sink.description || root.sink.name) : "NO DEVICE"); color: Theme.dim; font.family: Theme.mono; font.pixelSize: 10; elide: Text.ElideRight; width: parent.width }
                Row { spacing: 10
                    HudSlider { width: parent.parent.width - 58; height: 16; count: 30; value: root.sink && root.sink.audio ? root.sink.audio.volume : 0
                                dim: root.sink && root.sink.audio && root.sink.audio.muted
                                onMoved: v => { if (root.sink && root.sink.audio) root.sink.audio.volume = v } }
                    Text { text: root.pct(root.sink); color: Theme.fg; font.family: Theme.mono; font.pixelSize: 15; font.bold: true; anchors.verticalCenter: parent.verticalCenter } }

                Text { text: "◆ OUTPUT  //  出力"; color: Theme.muted; font.family: Theme.ui; font.pixelSize: 12; font.bold: true; font.letterSpacing: 2; topPadding: 8 }
                Repeater {
                    model: root.sinks
                    Rectangle {
                        required property var modelData
                        readonly property bool cur: root.sink && modelData.id === root.sink.id
                        width: parent.width; height: 28
                        color: om.containsMouse ? "#1f4fa3ae" : (cur ? "#144fa3ae" : "transparent"); border.color: cur ? Theme.accent : Theme.line
                        Text { x: 10; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 90; elide: Text.ElideRight
                               text: modelData.description || modelData.nickname || modelData.name; color: cur ? "#ffffff" : Theme.fg; font.family: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold }
                        Text { anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter } text: cur ? "ACTIVE" : ""; color: Theme.accent; font.family: Theme.ui; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1 }
                        MouseArea { id: om; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Pipewire.preferredDefaultAudioSink = modelData }
                    }
                }

                Text { text: "◆ APPLICATIONS  //  応用"; color: Theme.muted; font.family: Theme.ui; font.pixelSize: 12; font.bold: true; font.letterSpacing: 2; topPadding: 8 }
                Text { visible: root.streams.length === 0; text: "NO ACTIVE STREAMS"; color: Theme.dim; font.family: Theme.mono; font.pixelSize: 10 }
                Repeater {
                    model: root.streams
                    Column {
                        required property var modelData
                        width: parent.width; spacing: 3
                        Text { text: root.nm(modelData).toUpperCase(); color: Theme.fg; font.family: Theme.ui; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1; elide: Text.ElideRight; width: parent.width }
                        Row { spacing: 10
                            HudSlider { width: parent.parent.width - 48; height: 10; count: 28; value: modelData.audio.volume; dim: modelData.audio.muted; onMoved: v => modelData.audio.volume = v }
                            Text { text: Math.round(modelData.audio.volume * 100); color: Theme.muted; font.family: Theme.mono; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter } }
                    }
                }

                Text { text: "◆ INPUT  //  入力"; color: Theme.muted; font.family: Theme.ui; font.pixelSize: 12; font.bold: true; font.letterSpacing: 2; topPadding: 8 }
                Row { spacing: 10
                    HudSlider { width: parent.parent.width - 96; height: 10; count: 24; value: root.source && root.source.audio ? root.source.audio.volume : 0
                                dim: root.source && root.source.audio && root.source.audio.muted
                                onMoved: v => { if (root.source && root.source.audio) root.source.audio.volume = v } }
                    Text { text: root.source && root.source.audio ? Math.round(root.source.audio.volume * 100) : "--"; color: Theme.muted; font.family: Theme.mono; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                    HudSwitch { label: "MIC"; on: root.source && root.source.audio ? !root.source.audio.muted : false
                                onToggled: if (root.source && root.source.audio) root.source.audio.muted = !root.source.audio.muted } }
            }
        }
    }
}
