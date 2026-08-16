import QtQuick 2.15

// Left / Right / Case, always laid out, never removed.
//
// - Left & Right MERGE into one shared ring by default. They SPLIT apart
//   only when:
//     1. their charge levels diverge by 5% or more, or
//     2. exactly one of them is sitting in the case and the other isn't
//        (both in the case, or both out, still counts as "the same"
//        and stays merged).
//   Ear status alone (one in the ear, one not) never splits or dims them -
//   the ring only greys out when the pod (or case) is actually
//   disconnected over Bluetooth / not reporting battery.
// - When BOTH pods are fully disconnected (no AirPods connected at all),
//   they default back to the merged view too, so you get one grey
//   placeholder slot instead of two.
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

    // Two different things dim things here - don't mix them up:
    //  - "InEar" bright -> dims the pod ICON ONLY, when that pod isn't
    //    currently worn (out of the ear, or sitting in the case). This is
    //    the behavior that's already right, untouched.
    //  - "Connected" bright -> colors the RING (arc + %/L/R text) only.
    //    It stays colored as long as the pod/case is actually reachable
    //    over Bluetooth and reporting a level; it does NOT grey out just
    //    because the pod is out of the ear - only full disconnect does.
    readonly property bool leftEarBright: leftAvail && deviceInfo.leftPodInEar
    readonly property bool rightEarBright: rightAvail && deviceInfo.rightPodInEar
    readonly property bool leftConnected: leftAvail
    readonly property bool rightConnected: rightAvail
    readonly property bool caseBright: caseAvail

    // The rules for splitting Left/Right apart - see the note at the top
    // of the file. Both-disconnected is checked first since in that case
    // leftAvail/rightAvail are both false and we still want the merged
    // (single placeholder) view, not two empty separate slots.
    readonly property bool bothDisconnected: !leftAvail && !rightAvail
    readonly property bool leftInCase: deviceInfo.leftPodInCase
    readonly property bool rightInCase: deviceInfo.rightPodInCase
    readonly property bool oneInCaseOnly: leftInCase !== rightInCase
    readonly property bool canMerge: bothDisconnected || (leftAvail && rightAvail && !oneInCaseOnly && Math.abs(leftLevel - rightLevel) < 5)
    readonly property real mergedLevel: (leftCachedLevel + rightCachedLevel) / 2
    readonly property bool mergedCharging: battery.leftPodCharging || battery.rightPodCharging
    readonly property bool mergedConnected: leftConnected || rightConnected

    // earbud pngs aren't visually centered in their own canvas (the model
    // itself sits off-center in each asset), compensate so it looks
    // centered under the ring
    readonly property real podIconSize: 64
    readonly property real podCenterCorrection: podIconSize * 0.07
    readonly property real ringSize: 48

    // Shared height for the icon area of every slot (pods + case), sized to
    // the biggest icon (the case, now 2x the pod icons). Every slot centers
    // its icon(s) inside a box of this same height, so - no matter how tall
    // the icon actually is - the ring underneath always lands on the exact
    // same line as the case's ring.
    readonly property real iconAreaHeight: podIconSize * 2

    // --- Merged Left+Right ---
    Column {
        visible: root.canMerge
        spacing: 8

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: childrenRect.width
            height: root.iconAreaHeight

            Row {
                anchors.centerIn: parent
                spacing: root.podIconSize / 5

                Image {
                    source: "qrc:/icons/assets/" + deviceInfo.leftPodIcon
                    width: root.podIconSize
                    height: root.podIconSize
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    opacity: root.leftEarBright ? 1.0 : 0.35
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
                Image {
                    source: "qrc:/icons/assets/" + deviceInfo.rightPodIcon
                    width: root.podIconSize
                    height: root.podIconSize
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    opacity: root.rightEarBright ? 1.0 : 0.35
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }
        }

        BatteryRing {
            anchors.horizontalCenter: parent.horizontalCenter
            size: root.ringSize
            percentage: root.mergedLevel
            charging: root.mergedCharging
            hasData: root.leftHasData && root.rightHasData
            bright: root.mergedConnected
        }
    }

    // --- Separate Left ---
    Column {
        visible: !root.canMerge
        spacing: 8

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.podIconSize
            height: root.iconAreaHeight

            Image {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -root.podCenterCorrection
                source: "qrc:/icons/assets/" + deviceInfo.leftPodIcon
                width: root.podIconSize
                height: root.podIconSize
                fillMode: Image.PreserveAspectFit
                mipmap: true
                opacity: root.leftEarBright ? 1.0 : 0.35
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }

        BatteryRing {
            anchors.horizontalCenter: parent.horizontalCenter
            size: root.ringSize
            percentage: root.leftCachedLevel
            charging: root.battery.leftPodCharging
            hasData: root.leftHasData
            bright: root.leftConnected
            indicator: "L"
        }
    }

    // --- Separate Right ---
    Column {
        visible: !root.canMerge
        spacing: 8

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.podIconSize
            height: root.iconAreaHeight

            Image {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: root.podCenterCorrection
                source: "qrc:/icons/assets/" + deviceInfo.rightPodIcon
                width: root.podIconSize
                height: root.podIconSize
                fillMode: Image.PreserveAspectFit
                mipmap: true
                opacity: root.rightEarBright ? 1.0 : 0.35
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }

        BatteryRing {
            anchors.horizontalCenter: parent.horizontalCenter
            size: root.ringSize
            percentage: root.rightCachedLevel
            charging: root.battery.rightPodCharging
            hasData: root.rightHasData
            bright: root.rightConnected
            indicator: "R"
        }
    }

    // --- Case: always separate, never merges with anything ---
    Column {
        spacing: 8

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.podIconSize * 2
            height: root.iconAreaHeight

            Image {
                anchors.centerIn: parent
                source: "qrc:/icons/assets/" + deviceInfo.caseIcon
                width: root.podIconSize * 2
                height: root.podIconSize * 2
                fillMode: Image.PreserveAspectFit
                mipmap: true
                opacity: root.caseBright ? 1.0 : 0.35
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }

        BatteryRing {
            anchors.horizontalCenter: parent.horizontalCenter
            size: root.ringSize
            percentage: root.caseCachedLevel
            charging: root.battery.caseCharging
            hasData: root.caseHasData
            bright: root.caseBright
        }
    }
}
