import QtQuick 2.15

// Left / Right / Case, always laid out, never removed.
//
// - Left & Right MERGE into one shared ring when both are currently
//   reporting battery AND their levels are within 5% of each other.
//   This only reacts to the actual battery % (which changes slowly), NOT
//   to ear-detection - that's what used to make the layout jump around
//   every time one pod was taken out of the ear.
// - Each slot remembers the last real percentage it ever saw this session
//   (`...HasData` / `...CachedLevel`), so briefly losing the "in ear"/
//   "available" signal never blanks the number - it just dims it.
Row {
    id: root
    spacing: 32

    property var battery: airPodsTrayApp.deviceInfo.battery
    property var deviceInfo: airPodsTrayApp.deviceInfo

    // --- live values from the backend ---
    property int leftLevel: battery.leftPodLevel
    property bool leftAvail: battery.leftPodAvailable
    property int rightLevel: battery.rightPodLevel
    property bool rightAvail: battery.rightPodAvailable
    property int caseLevelLive: battery.caseLevel
    property bool caseAvail: battery.caseAvailable

    // --- sticky "we've seen real data this session" cache ---
    property real leftCachedLevel: 0
    property bool leftHasData: false
    property real rightCachedLevel: 0
    property bool rightHasData: false
    property real caseCachedLevel: 0
    property bool caseHasData: false

    function syncLeft() { if (leftAvail) { leftCachedLevel = leftLevel; leftHasData = true } }
    function syncRight() { if (rightAvail) { rightCachedLevel = rightLevel; rightHasData = true } }
    function syncCase() { if (caseAvail) { caseCachedLevel = caseLevelLive; caseHasData = true } }

    onLeftLevelChanged: syncLeft()
    onLeftAvailChanged: syncLeft()
    onRightLevelChanged: syncRight()
    onRightAvailChanged: syncRight()
    onCaseLevelLiveChanged: syncCase()
    onCaseAvailChanged: syncCase()
    Component.onCompleted: { syncLeft(); syncRight(); syncCase() }

    // "bright" = currently in the ear or charging (dims otherwise, but the
    // number stays visible as long as hasData is true)
    readonly property bool leftBright: leftAvail && (deviceInfo.leftPodInEar || battery.leftPodCharging)
    readonly property bool rightBright: rightAvail && (deviceInfo.rightPodInEar || battery.rightPodCharging)
    readonly property bool caseBright: caseAvail

    readonly property bool canMerge: leftAvail && rightAvail && Math.abs(leftLevel - rightLevel) < 5
    readonly property real mergedLevel: (leftCachedLevel + rightCachedLevel) / 2
    readonly property bool mergedCharging: battery.leftPodCharging || battery.rightPodCharging
    readonly property bool mergedBright: leftBright || rightBright

    // earbud pngs aren't visually centered in their own canvas (the model
    // itself sits ~13% off-center in each asset), compensate so it looks
    // centered under the ring
    readonly property real podIconSize: 64
    readonly property real podCenterCorrection: podIconSize * 0.13

    // --- Merged Left+Right ---
    Column {
        visible: root.canMerge
        spacing: 8

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.podIconSize / 5

            Image {
                source: "qrc:/icons/assets/" + deviceInfo.leftPodIcon
                width: root.podIconSize
                height: root.podIconSize
                fillMode: Image.PreserveAspectFit
                mipmap: true
                opacity: root.mergedBright ? 1.0 : 0.35
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
            Image {
                source: "qrc:/icons/assets/" + deviceInfo.rightPodIcon
                width: root.podIconSize
                height: root.podIconSize
                fillMode: Image.PreserveAspectFit
                mipmap: true
                opacity: root.mergedBright ? 1.0 : 0.35
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }

        BatteryRing {
            anchors.horizontalCenter: parent.horizontalCenter
            size: 56
            percentage: root.mergedLevel
            charging: root.mergedCharging
            hasData: root.leftHasData && root.rightHasData
            bright: root.mergedBright
        }
    }

    // --- Separate Left ---
    Column {
        visible: !root.canMerge
        spacing: 8

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: -root.podCenterCorrection
            source: "qrc:/icons/assets/" + deviceInfo.leftPodIcon
            width: root.podIconSize
            height: root.podIconSize
            fillMode: Image.PreserveAspectFit
            mipmap: true
            opacity: root.leftBright ? 1.0 : 0.35
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        BatteryRing {
            anchors.horizontalCenter: parent.horizontalCenter
            size: 56
            percentage: root.leftCachedLevel
            charging: root.battery.leftPodCharging
            hasData: root.leftHasData
            bright: root.leftBright
            indicator: "L"
        }
    }

    // --- Separate Right ---
    Column {
        visible: !root.canMerge
        spacing: 8

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: root.podCenterCorrection
            source: "qrc:/icons/assets/" + deviceInfo.rightPodIcon
            width: root.podIconSize
            height: root.podIconSize
            fillMode: Image.PreserveAspectFit
            mipmap: true
            opacity: root.rightBright ? 1.0 : 0.35
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        BatteryRing {
            anchors.horizontalCenter: parent.horizontalCenter
            size: 56
            percentage: root.rightCachedLevel
            charging: root.battery.rightPodCharging
            hasData: root.rightHasData
            bright: root.rightBright
            indicator: "R"
        }
    }

    // --- Case: always separate, never merges with anything ---
    Column {
        spacing: 8

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: "qrc:/icons/assets/" + deviceInfo.caseIcon
            width: root.podIconSize
            height: root.podIconSize
            fillMode: Image.PreserveAspectFit
            mipmap: true
            opacity: root.caseBright ? 1.0 : 0.35
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        BatteryRing {
            anchors.horizontalCenter: parent.horizontalCenter
            size: 56
            percentage: root.caseCachedLevel
            charging: root.battery.caseCharging
            hasData: root.caseHasData
            bright: root.caseBright
        }
    }
}
