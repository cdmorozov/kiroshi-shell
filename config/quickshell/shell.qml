//@ pragma IconTheme Papirus-Dark
// Night City HUD layer — above the wallpaper, below windows.
// Shown only on an empty workspace; fades out as soon as a window opens there.
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

ShellRoot {
    Notifications {}
    Launcher {}
    Osd {}
    Switcher {}
    PowerMenu {}
    QuickPanels {}
    SoundPanel {}
    RadioPort {}

    Variants {
        model: Quickshell.screens

        Scope {
            id: scr
            required property var modelData
            readonly property var mon: Hyprland.monitorFor(modelData)

            TopBar { screenRef: scr.modelData }
            readonly property bool desktopEmpty: !mon || !mon.activeWorkspace
                                                 || mon.activeWorkspace.toplevels.values.length === 0

            // click-through layer: vitals + scrolling panels
            PanelWindow {
                screen: scr.modelData
                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.namespace: "netrun-hud"
                mask: Region {}

                Item {
                    anchors.fill: parent
                    opacity: scr.desktopEmpty ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    Telemetry { x: 28; y: 70 }

                    Column {
                        anchors { right: parent.right; rightMargin: 28; top: parent.top; topMargin: 74 }
                        spacing: 14
                        HudPanel { width: 450; height: 210; title: "NET.TRACE // 追跡"; tag: "SUB 144"; lines: 10; speed: 520 }
                        HudPanel { width: 450; height: 170; title: "ICE.MONITOR // 防壁"; tag: "07-A"; lines: 7; speed: 900 }
                        HudPanel { width: 450; height: 150; title: "DAEMON.LOG // 記録"; tag: "LIVE"; lines: 6; speed: 1400 }
                    }
                }
            }

            // music card needs clicks, so it lives in its own small layer window
            PanelWindow {
                screen: scr.modelData
                anchors { bottom: true; left: true }
                margins { left: 28; bottom: 28 }
                implicitWidth: 400; implicitHeight: 172
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.namespace: "netrun-music"
                visible: music.hasPlayer && (scr.desktopEmpty || music.opacity > 0)
                Music {
                    id: music
                    opacity: scr.desktopEmpty ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}
