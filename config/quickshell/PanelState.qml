pragma Singleton
import QtQuick
QtObject {
    property bool netOpen: false
    property bool btOpen: false
    property bool volOpen: false
    function toggleNet() { btOpen = false; volOpen = false; netOpen = !netOpen }
    function toggleBt()  { netOpen = false; volOpen = false; btOpen = !btOpen }
    function toggleVol() { netOpen = false; btOpen = false; volOpen = !volOpen }
    function closeAll()  { netOpen = false; btOpen = false; volOpen = false }
}
