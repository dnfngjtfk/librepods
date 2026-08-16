import QtQuick 2.15

// A single circular battery indicator:
//  - green progress ring for the charge level
//  - lightning bolt in the middle while charging
//  - percentage text in the middle while not charging
//  - greys itself out (ring + text) when `available` is false, but stays
//    laid out (doesn't collapse/disappear) so the slot never jumps around
Item {
    id: root

    property real size: 90
    property real percentage: 0        // 0-100
    property bool charging: false
    property bool available: true      // false -> dimmed placeholder state
    property string label: ""          // optional caption under the ring, e.g. "L" / "Case"

    property color activeColor: "#34C759"  // Apple-style green
    property color trackColor: "#3A3A3C"   // ring track when available
    property color dimColor: "#2C2C2E"     // ring track/fill when unavailable

    implicitWidth: size
    implicitHeight: size + (label.length > 0 ? 22 : 0)

    // --- progress ring ---
    Canvas {
        id: ring
        width: root.size
        height: root.size
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var cx = width / 2
            var cy = height / 2
            var r = Math.min(width, height) / 2 - 6
            var startAngle = -Math.PI / 2

            // background track
            ctx.beginPath()
            ctx.lineWidth = 6
            ctx.strokeStyle = root.available ? root.trackColor : root.dimColor
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.stroke()

            // foreground progress (only when we actually have data)
            if (root.available) {
                var pct = Math.max(0, Math.min(100, root.percentage)) / 100
                var endAngle = startAngle + pct * Math.PI * 2
                ctx.beginPath()
                ctx.lineWidth = 6
                ctx.lineCap = "round"
                ctx.strokeStyle = root.activeColor
                ctx.arc(cx, cy, r, startAngle, endAngle, false)
                ctx.stroke()
            }
        }

        Component.onCompleted: requestPaint()
    }

    onPercentageChanged: ring.requestPaint()
    onAvailableChanged: ring.requestPaint()

    // --- lightning bolt (shown instead of the % text while charging) ---
    Canvas {
        id: bolt
        width: root.size * 0.28
        height: root.size * 0.32
        anchors.centerIn: ring
        visible: root.available && root.charging

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.fillStyle = root.activeColor
            ctx.beginPath()
            ctx.moveTo(width * 0.55, 0)
            ctx.lineTo(width * 0.12, height * 0.58)
            ctx.lineTo(width * 0.42, height * 0.58)
            ctx.lineTo(width * 0.30, height)
            ctx.lineTo(width * 0.88, height * 0.38)
            ctx.lineTo(width * 0.55, height * 0.38)
            ctx.closePath()
            ctx.fill()
        }
        Component.onCompleted: requestPaint()
    }

    // --- percentage text ---
    Text {
        anchors.centerIn: ring
        visible: !bolt.visible
        text: root.available ? Math.round(root.percentage) + "%" : "--"
        color: root.available ? "white" : "#8E8E93"
        font.pixelSize: root.size * 0.2
        font.bold: true
    }

    // --- caption ---
    Text {
        anchors.top: ring.bottom
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.label.length > 0
        text: root.label
        color: root.available ? "#AEAEB2" : "#636366"
        font.pixelSize: 13
    }
}
