// icon for a window/app id with fallbacks, two letters if nothing is found
import QtQuick
import Quickshell
Item {
    id: root
    property string appId: ""
    property int size: 32
    width: size; height: size
    readonly property var entry: DesktopEntries.applications.values.find(e => e.id === appId || e.startupClass === appId) || DesktopEntries.heuristicLookup(appId)
    readonly property var cands: {
        const id = appId || "", e = entry ? entry.icon : ""
        const out = []
        for (const n of [e, id, id.toLowerCase(), id.split(".").pop().toLowerCase()]) {
            if (!n) continue
            if (n.startsWith("/")) { out.push("file://" + n); continue }
            out.push(Quickshell.iconPath(n, true))
            out.push("file:///usr/share/icons/hicolor/48x48/apps/" + n + ".png")
            out.push("file:///usr/share/icons/hicolor/scalable/apps/" + n + ".svg")
        }
        return out.filter(s => s && s !== "")
    }
    property int ci: 0
    Image { id: img; anchors.fill: parent; sourceSize: Qt.size(size * 2, size * 2); asynchronous: true; smooth: true
            source: root.ci < root.cands.length ? root.cands[root.ci] : ""; visible: status === Image.Ready
            onStatusChanged: if (status === Image.Error) root.ci++ }
    Text { anchors.centerIn: parent; visible: root.ci >= root.cands.length; text: (appId || "?").split(".").pop().slice(0, 2).toUpperCase()
           color: Theme.muted; font.family: Theme.ui; font.pixelSize: root.size * 0.4; font.bold: true }
}
