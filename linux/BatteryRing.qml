import QtQuick 2.15
import QtQuick.Controls 2.15

// A single circular battery indicator, styled like the AirPods popup on iPhone.
//
// Two independent concepts, don't confuse them:
//  - `hasData`: have we EVER received a real battery reading for this slot
//    in this app session? If false, the ring is just an empty grey track
//    and NOTHING is shown below it (no "--", no badge) - we simply don't
//    know yet. Once true, it stays true for the rest of the session even
//    if the pod briefly drops out, so the number never disappears.
//  - `bright`: is this slot currently "in use" (in the ear / charging)?
//    Purely a dim/bright toggle for an already-known percentage - the
//    number and ring stay visible, they just go grey instead of colored.
Item {
    id: root

    property real size: 56
    property real percentage: 0        // 0-100, meaningless while !hasData
    property bool charging: false
    property bool hasData: true        // false -> never had a reading this session
    property bool bright: true         // false -> known, but dimmed (not in ear / not charging)
    property string indicator: ""      // "L" / "R" badge shown next to the %, "" = none

    SystemPalette { id: palette }
    readonly property bool darkMode: palette.window.hslLightness < palette.windowText.hslLightness

    readonly property bool lowBattery: percentage <= 25
    readonly property color activeColor: lowBattery
                                          ? (darkMode ? "#FC4244" : "#FE373C")
                                          : (darkMode ? "#2ED158" : "#35C759")
    readonly property color dimArcColor: darkMode ? "#8E8E93" : "#AEAEB2"
    readonly property color trackColor: darkMode ? "#3A3A3C" : "#E3E3E8"
    readonly property color dimColor: darkMode ? "#2C2C2E" : "#D1D1D6"
    readonly property color ringForeground: !hasData ? "transparent" : (bright ? activeColor : dimArcColor)

    implicitWidth: size
    implicitHeight: size + 22

    property real animatedPercentage: percentage
    Behavior on animatedPercentage {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    // --- progress ring (thin track always visible so the slot never "vanishes") ---
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
            var r = Math.min(width, height) / 2 - 5
            var startAngle = -Math.PI / 2

            // background track - dimmer when we don't even know the level yet
            ctx.beginPath()
            ctx.lineWidth = 4
            ctx.lineCap = "round"
            ctx.strokeStyle = root.hasData ? root.trackColor : root.dimColor
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.stroke()

            if (root.hasData) {
                var pct = Math.max(0, Math.min(100, root.animatedPercentage)) / 100
                var endAngle = startAngle + pct * Math.PI * 2
                ctx.beginPath()
                ctx.lineWidth = 4
                ctx.lineCap = "round"
                ctx.strokeStyle = root.ringForeground
                ctx.arc(cx, cy, r, startAngle, endAngle, false)
                ctx.stroke()
            }
        }

        Component.onCompleted: requestPaint()
    }

    onAnimatedPercentageChanged: ring.requestPaint()
    onHasDataChanged: ring.requestPaint()
    onRingForegroundChanged: { ring.requestPaint(); boltCanvas.requestPaint() }

    // --- lightning bolt while charging ---
    // Drawn by hand on a Canvas instead of using the SF Symbols font glyph:
    // that glyph is a macOS-only private-use codepoint and doesn't reliably
    // render on Linux/Qt, so "charging" could become true (case png swaps
    // correctly) while the bolt inside the ring stayed invisible.
    Item {
        id: bolt
        anchors.centerIn: ring
        width: root.size * 0.34
        height: root.size * 0.34
        visible: root.hasData && root.charging
        scale: root.hasData && root.charging ? 1 : 0.4
        opacity: root.hasData && root.charging ? 1 : 0

        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Canvas {
            id: boltCanvas
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.fillStyle = root.ringForeground
                var w = width
                var h = height
                ctx.beginPath()
                ctx.moveTo(w * 0.62, h * 0.02)
                ctx.lineTo(w * 0.26, h * 0.58)
                ctx.lineTo(w * 0.47, h * 0.58)
                ctx.lineTo(w * 0.36, h * 1.0)
                ctx.lineTo(w * 0.76, h * 0.40)
                ctx.lineTo(w * 0.53, h * 0.40)
                ctx.closePath()
                ctx.fill()
            }

            Component.onCompleted: requestPaint()
        }

        onWidthChanged: boltCanvas.requestPaint()
        onHeightChanged: boltCanvas.requestPaint()
    }

    // --- caption: [optional L/R badge]  percentage - only exists once we
    // actually know something; otherwise this whole row stays hidden but
    // the layout height doesn't change, so nothing jumps around ---
    Row {
        anchors.top: ring.bottom
        anchors.topMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4
        visible: root.hasData

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.indicator.length > 0
            width: 15
            height: 15
            radius: width / 2
            color: root.bright ? palette.text : "#8E8E93"

            Text {
                anchors.centerIn: parent
                text: root.indicator
                color: palette.window
                font.pixelSize: 9
                font.bold: true
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.percentage) + "%"
            color: root.bright ? palette.text : "#8E8E93"
            font.pixelSize: 15
            font.bold: false
        }
    }
}
