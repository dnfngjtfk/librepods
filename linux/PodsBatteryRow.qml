import QtQuick 2.15

// Replaces the old linear "Battery Indicator Row" (PodColumn + BatteryIndicator)
// with circular rings:
//  - if L and R are within `mergeThreshold` percent of each other, show ONE
//    combined "Pods" ring with the average charge (both earbud icons above it)
//  - otherwise show separate L and R rings
//  - the Case ring is ALWAYS present; it just dims when unavailable instead
//    of being removed from the layout
Row {
    id: root
    spacing: 20

    property var battery: airPodsTrayApp.deviceInfo.battery
    property int mergeThreshold: 10 // percentage points allowed before splitting L/R

    readonly property bool bothPodsAvailable: battery.leftPodAvailable && battery.rightPodAvailable
    readonly property bool podsClose: bothPodsAvailable
                                       && Math.abs(battery.leftPodLevel - battery.rightPodLevel) <= mergeThreshold
    readonly property real podsAverage: (battery.leftPodLevel + battery.rightPodLevel) / 2
    readonly property bool podsChargingCombined: battery.leftPodCharging || battery.rightPodCharging

    // --- Combined pods: both icons + one shared ring ---
    Column {
        visible: root.podsClose
        spacing: 5

        Row {
            spacing: -10
            anchors.horizontalCenter: parent.horizontalCenter

            Image {
                source: "qrc:/icons/assets/" + airPodsTrayApp.deviceInfo.leftPodIcon
                width: 48
                height: 48
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }
            Image {
                source: "qrc:/icons/assets/" + airPodsTrayApp.deviceInfo.rightPodIcon
                width: 48
                height: 48
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }
        }

        BatteryRing {
            anchors.horizontalCenter: parent.horizontalCenter
            size: 80
            percentage: root.podsAverage
            charging: root.podsChargingCombined
            available: root.bothPodsAvailable
            label: qsTr("Pods")
        }
    }

    // --- Separate Left (shown when diverging from Right, or only Left present) ---
    Column {
        visible: !root.podsClose && root.battery.leftPodAvailable
        spacing: 5

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: "qrc:/icons/assets/" + airPodsTrayApp.deviceInfo.leftPodIcon
            width: 48
            height: 48
            fillMode: Image.PreserveAspectFit
            mipmap: true
        }
        BatteryRing {
            anchors.horizontalCenter: parent.horizontalCenter
            size: 80
            percentage: root.battery.leftPodLevel
            charging: root.battery.leftPodCharging
            available: root.battery.leftPodAvailable
            label: qsTr("L")
        }
    }

    // --- Separate Right ---
    Column {
        visible: !root.podsClose && root.battery.rightPodAvailable
        spacing: 5

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: "qrc:/icons/assets/" + airPodsTrayApp.deviceInfo.rightPodIcon
            width: 48
            height: 48
            fillMode: Image.PreserveAspectFit
            mipmap: true
        }
        BatteryRing {
            anchors.horizontalCenter: parent.horizontalCenter
            size: 80
            percentage: root.battery.rightPodLevel
            charging: root.battery.rightPodCharging
            available: root.battery.rightPodAvailable
            label: qsTr("R")
        }
    }

    // --- Case: always in the layout, just dims when unavailable ---
    Column {
        spacing: 5

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: "qrc:/icons/assets/" + airPodsTrayApp.deviceInfo.caseIcon
            width: 48
            height: 48
            fillMode: Image.PreserveAspectFit
            mipmap: true
            opacity: root.battery.caseAvailable ? 1.0 : 0.35
        }
        BatteryRing {
            anchors.horizontalCenter: parent.horizontalCenter
            size: 80
            percentage: root.battery.caseLevel
            charging: root.battery.caseCharging
            available: root.battery.caseAvailable
            label: qsTr("Case")
        }
    }
}
