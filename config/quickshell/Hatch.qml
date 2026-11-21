// diagonal hazard-stripe fill
import QtQuick
Canvas {
    id: root
    property color stripe: Theme.accent
    property real gap: 6
    property real lineWidth: 1
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onStripeChanged: requestPaint()
    onPaint: {
        const c = getContext("2d"); c.reset()
        c.strokeStyle = stripe; c.lineWidth = lineWidth
        c.beginPath()
        for (let x = -height; x < width; x += gap) { c.moveTo(x, height); c.lineTo(x + height, 0) }
        c.stroke()
    }
}
