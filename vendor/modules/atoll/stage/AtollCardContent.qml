pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Bluetooth
import Quickshell.Widgets
import "../../.."
import "../../../services"
import "../../../services/deferred"
import "../../common"
import "../../common/functions"
import "../../common/widgets"
import "../style"
import "../components"
import "../pieces"
import "../bar"
import "../bar/island"
import "../sidebar"

Item {
    id: root

    property string kind: ""
    property string screenName: ""
    property bool contentActive: true
    readonly property real d: AtollStyle.density
    readonly property bool bleeds: ["weather", "notifications", "media", "visualizer"].includes(root.kind)
        || root.kind === "media" || root.kind === "calendar"
    readonly property real contentHeight: body.item?.implicitHeight ?? 0
    readonly property color light: {
        switch (root.kind) {
        case "weather": return AtollStyle.skyLight(Icons.getWeatherIcon(Weather.data.wCode, Weather.isNightNow()) ?? "")
        case "sound": return AtollStyle.identity.indigo
        case "mic": return AtollStyle.identity.orange
        case "tools": return AtollStyle.secondaryAccent
        case "tray": return AtollStyle.identity.teal
        case "calendar": return AtollStyle.identity.red
        case "media":
        case "visualizer": return "transparent"
        case "network": return AtollStyle.identity.blue
        case "bluetooth": return AtollStyle.identity.sky
        case "vitals": return AtollStyle.identity.teal
        case "workspaces": return AtollStyle.identity.purple
        case "updates": return AtollStyle.secondaryAccent
        case "anime": return AtollStyle.identity.pink
        case "watching": return AtollStyle.identity.pink
        case "shellUpdate": return AtollStyle.secondaryAccent
        case "vpn": return AtollStyle.identity.green
        default: return AtollStyle.wallpaperLight
        }
    }
    signal navigate()
    function close(): void { root.navigate() }

    implicitHeight: root.contentHeight

    Loader {
        id: body
        width: root.width
        active: root.kind.length > 0
        sourceComponent: {
            switch (root.kind) {
            case "weather": return weatherCard
            case "notifications": return notificationsCard
            case "calendar": return calendarCard
            case "sound": return soundCard
            case "mic": return micCard
            case "tools": return toolsCard
            case "tray": return trayCard
            case "media":
            case "visualizer": return mediaCard
            case "network": return networkCard
            case "bluetooth": return bluetoothCard
            case "vitals": return vitalsCard
            case "workspaces": return workspacesCard
            case "updates": return updatesCard
            case "anime": return animeCard
            case "watching": return watchingCard
            case "shellUpdate": return shellUpdateCard
            case "vpn": return vpnCard
            default: return null
            }
        }
    }

    component VpnRow: MouseArea {
        id: vpnRow
        property string label: ""
        property string detail: ""
        property bool on: false
        signal toggled()
        implicitHeight: Math.round(42 * root.d)
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        enabled: !Vpn.busy
        Accessible.role: Accessible.CheckBox
        Accessible.name: vpnRow.label
        Accessible.checked: vpnRow.on
        onClicked: vpnRow.toggled()
        Rectangle {
            anchors.fill: parent
            radius: AtollStyle.radiusTile
            color: vpnRow.containsMouse ? AtollStyle.fillHover : AtollStyle.fillQuiet
            Behavior on color { ColorAnimation { duration: AtollStyle.duration(120); easing.type: AtollStyle.feedbackEasing } }
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Math.round(12 * root.d)
            anchors.rightMargin: Math.round(10 * root.d)
            spacing: 10 * root.d
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                AtollText {
                    Layout.fillWidth: true
                    text: vpnRow.label
                    elide: Text.ElideRight
                    font.pixelSize: AtollStyle.typeLabel
                    font.weight: vpnRow.on ? Font.DemiBold : Font.Normal
                }
                AtollText {
                    Layout.fillWidth: true
                    visible: vpnRow.detail.length > 0
                    text: vpnRow.detail
                    color: AtollStyle.muted
                    elide: Text.ElideRight
                    font.pixelSize: AtollStyle.typeFootnote
                }
            }
            Rectangle {
                implicitWidth: Math.round(38 * root.d)
                implicitHeight: Math.round(22 * root.d)
                radius: height / 2
                color: vpnRow.on ? AtollStyle.identity.green : AtollStyle.fillHover
                Behavior on color { ColorAnimation { duration: AtollStyle.duration(140); easing.type: AtollStyle.feedbackEasing } }
                Rectangle {
                    y: Math.round(3 * root.d)
                    x: vpnRow.on ? parent.width - width - Math.round(3 * root.d) : Math.round(3 * root.d)
                    width: parent.height - Math.round(6 * root.d)
                    height: width
                    radius: width / 2
                    color: AtollStyle.onTint
                    Behavior on x { NumberAnimation { duration: AtollStyle.duration(140); easing.type: AtollStyle.feedbackEasing } }
                }
            }
        }
    }

    // One fact of a connection: its name quiet on the left, the value on the right; a tap copies it.
    component VpnFact: MouseArea {
        id: fact
        property string label: ""
        property string value: ""
        property string shown: fact.value
        property string glyph: "content_copy"
        signal copy(string value)
        implicitHeight: Math.round(28 * root.d)
        hoverEnabled: true
        cursorShape: fact.value.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
        visible: fact.value.length > 0
        onClicked: fact.copy(fact.value)
        Accessible.role: Accessible.Button
        Accessible.name: fact.label + " " + fact.shown
        Rectangle {
            anchors.fill: parent
            radius: AtollStyle.radiusRow
            color: fact.containsMouse ? AtollStyle.fillHover : ColorUtils.applyAlpha(AtollStyle.fillHover, 0)
            Behavior on color { ColorAnimation { duration: AtollStyle.duration(120); easing.type: AtollStyle.feedbackEasing } }
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Math.round(10 * root.d)
            anchors.rightMargin: Math.round(8 * root.d)
            spacing: Math.round(8 * root.d)
            AtollText {
                text: fact.label
                color: AtollStyle.muted
                font.pixelSize: AtollStyle.typeMeta
            }
            AtollText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: fact.shown
                elide: Text.ElideMiddle
                font.pixelSize: AtollStyle.typeMeta
                font.features: ({ "tnum": 1 })
            }
            MaterialSymbol {
                visible: fact.glyph.length > 0
                text: fact.glyph
                iconSize: Math.round(14 * root.d)
                color: AtollStyle.muted
                opacity: fact.containsMouse ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: AtollStyle.duration(120); easing.type: AtollStyle.feedbackEasing } }
            }
        }
    }
    // A connection's facts rest on one quiet fill under its row.
    component VpnFacts: Rectangle {
        default property alias facts: factColumn.data
        implicitHeight: factColumn.implicitHeight + Math.round(8 * root.d)
        radius: AtollStyle.radiusTile
        color: AtollStyle.fillQuiet
        ColumnLayout {
            id: factColumn
            anchors.fill: parent
            anchors.margins: Math.round(4 * root.d)
            spacing: 0
        }
    }

    component SectionCard: AtollSidebarSection {
        bare: true
        expanded: true
        contentActive: root.contentActive
        onNavigate: root.close()
    }


    readonly property var cardOptions: Config.options?.atoll?.appearance?.surfaces?.cards ?? ({})
    component LevelCard: ColumnLayout {
        id: level
        property bool input: false
        readonly property bool muted: level.input ? Audio.micMuted : (Audio.sink?.audio?.muted ?? false)
        readonly property real value: Math.min(1, (level.input ? Audio.micVolume : Audio.value) ?? 0)
        spacing: 12 * root.d
        CardHeader {
            visible: root.cardOptions?.header ?? true
            glyph: level.input ? "mic" : "volume_up"
            tint: level.input ? AtollStyle.identity.orange : AtollStyle.identity.indigo
            title: level.input ? Translation.tr("Microphone") : Translation.tr("Sound")
            detail: Audio.friendlyDeviceName(level.input ? Audio.source : Audio.defaultSink)
            AtollNumber {
                text: Math.round(level.value * 100) + "%"
                color: AtollStyle.subtext
                pixelSize: AtollStyle.typeLabel
                weight: Font.DemiBold
            }
        }
        AtollCapsuleSlider {
            Layout.fillWidth: true
            implicitHeight: Math.round(48 * root.d)
            muted: level.muted
            icon: level.input ? (level.muted ? "mic_off" : "mic")
                : level.muted ? "volume_off" : level.value < 0.34 ? "volume_mute" : level.value < 0.67 ? "volume_down" : "volume_up"
            value: level.value
            Accessible.name: level.input ? Translation.tr("Microphone") : Translation.tr("Volume")
            onMoved: next => level.input ? Audio.setSourceVolume(next) : Audio.setSinkVolume(next)
            onIconClicked: level.input ? Audio.toggleMicMute() : Audio.toggleMute()
        }
        AtollDeviceList {
            visible: root.cardOptions?.devices ?? true
            Layout.fillWidth: true
            Layout.leftMargin: -6 * root.d
            Layout.rightMargin: -6 * root.d
            outputs: !level.input
            inputs: level.input
        }
    }

    Component {
        id: weatherCard
        SectionCard { kind: "weather" }
    }
    Component {
        id: notificationsCard
        SectionCard { kind: "notifications" }
    }
    Component {
        id: calendarCard
        SectionCard { kind: "calendar" }
    }
    Component {
        id: soundCard
        ColumnLayout {
            spacing: 6 * root.d
            LevelCard { Layout.fillWidth: true }
            SectionCard {
                visible: root.cardOptions?.mixer ?? true
                Layout.fillWidth: true
                Layout.leftMargin: -14 * root.d
                Layout.rightMargin: -14 * root.d
                kind: "mixer"
            }
        }
    }
    Component {
        id: micCard
        LevelCard { input: true }
    }
    Component {
        id: toolsCard
        ColumnLayout {
            spacing: 14 * root.d
            CardHeader {
                glyph: "timer"
                tint: AtollStyle.identity.orange
                title: Translation.tr("Timers")
                detail: TimerService.countdownRunning || TimerService.pomodoroRunning || TimerService.stopwatchRunning
                    ? Translation.tr("Running") : Translation.tr("Tap a dial to start, scroll to adjust")
            }
            AtollTools {
                Layout.fillWidth: true
                onActivityRequested: { root.close(); GlobalStates.atollIslandPageRequest = "activity" }
            }
        }
    }
    Component {
        id: trayCard
        ColumnLayout {
            id: tray
            readonly property var items: SystemTray.items.values.filter(item => item && item.id
                && (!(Config.options?.atoll?.tray?.hidePassive ?? false) || item.status !== Status.Passive))
            spacing: 12 * root.d
            CardHeader {
                glyph: "apps"
                tint: AtollStyle.identity.teal
                title: Translation.tr("Tray")
                detail: tray.items.length > 0 ? Translation.tr("%1 background apps").arg(tray.items.length) : Translation.tr("Background apps")
            }
            AtollTray { Layout.fillWidth: true; showHeader: false; items: tray.items }
        }
    }

    Component {
        id: networkCard
        ColumnLayout {
            spacing: 10 * root.d
            CardHeader {
                glyph: Network.ethernet ? "lan" : Network.wifiEnabled ? "wifi" : "wifi_off"
                tint: AtollStyle.identity.blue
                title: Translation.tr("Network")
                detail: Network.ethernet ? Translation.tr("Ethernet")
                    : !Network.wifiEnabled ? Translation.tr("Wi-Fi off")
                    : Network.networkName.length > 0 ? Network.networkName : Translation.tr("Not connected")
                AtollIconButton {
                    materialIcon: "refresh"
                    enabled: Network.wifiEnabled
                    Accessible.name: Translation.tr("Scan for networks")
                    onClicked: Network.rescanWifi()
                }
                AtollIconButton {
                    materialIcon: Network.wifiEnabled ? "wifi" : "wifi_off"
                    selected: Network.wifiEnabled
                    Accessible.name: Translation.tr("Wi-Fi")
                    onClicked: Network.toggleWifi()
                }
            }
            AtollNetworkList {
                Layout.fillWidth: true
                Layout.leftMargin: -6 * root.d
                Layout.rightMargin: -6 * root.d
            }
        }
    }
    Component {
        id: bluetoothCard
        ColumnLayout {
            spacing: 10 * root.d
            CardHeader {
                glyph: BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                tint: AtollStyle.identity.sky
                title: Translation.tr("Bluetooth")
                detail: BluetoothStatus.activeDeviceSummary() || (BluetoothStatus.enabled
                    ? Translation.tr("Nothing connected") : Translation.tr("Off"))
                AtollIconButton {
                    materialIcon: BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                    selected: BluetoothStatus.enabled
                    enabled: BluetoothStatus.available
                    Accessible.name: Translation.tr("Bluetooth")
                    onClicked: if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                }
            }
            AtollBluetoothList {
                Layout.fillWidth: true
                Layout.leftMargin: -6 * root.d
                Layout.rightMargin: -6 * root.d
            }
        }
    }
    Component {
        id: vitalsCard
        ColumnLayout {
            id: vitalsBody
            spacing: 10 * root.d
            ResourceUsageMonitor { target: vitalsBody; active: root.contentActive }
            CardHeader {
                glyph: "monitoring"
                tint: AtollStyle.identity.teal
                title: Translation.tr("Vitals")
                detail: Translation.tr("What this machine is doing")
            }
            Repeater {
                model: [
                    { label: Translation.tr("Processor"), glyph: "memory", level: ResourceUsage.cpuUsage, value: Math.round(ResourceUsage.cpuUsage * 100), unit: "%", warn: 0.85 },
                    { label: Translation.tr("Memory"), glyph: "memory_alt", level: ResourceUsage.memoryUsedPercentage, value: Math.round(ResourceUsage.memoryUsedPercentage * 100), unit: "%", warn: 0.85 },
                    { label: Translation.tr("Heat"), glyph: "device_thermostat", level: ResourceUsage.tempPercentage, value: ResourceUsage.maxTemp, unit: "°", warn: ResourceUsage.tempWarningThreshold / 100 },
                    { label: Translation.tr("Disk"), glyph: "hard_drive", level: ResourceUsage.diskUsedPercentage, value: Math.round(ResourceUsage.diskUsedPercentage * 100), unit: "%", warn: 0.9 }
                ]
                RowLayout {
                    id: vital
                    required property var modelData
                    readonly property real level: Math.max(0, Math.min(1, Number(vital.modelData.level) || 0))
                    readonly property color tint: vital.level >= vital.modelData.warn ? AtollStyle.danger : AtollStyle.accent
                    Layout.fillWidth: true
                    spacing: 10 * root.d
                    Accessible.name: vital.modelData.label + ", " + vital.modelData.value + vital.modelData.unit
                    Item {
                        Layout.preferredWidth: Math.round(30 * root.d)
                        Layout.preferredHeight: Layout.preferredWidth
                        ProgressRing {
                            anchors.fill: parent
                            stroke: Math.max(2, 2.4 * root.d)
                            tint: vital.tint
                            progress: vital.level
                            Behavior on progress { NumberAnimation { duration: AtollStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: AtollStyle.moveCurve } }
                        }
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: vital.modelData.glyph
                            fill: 1
                            iconSize: Math.round(13 * root.d)
                            color: vital.tint
                        }
                    }
                    AtollText {
                        Layout.fillWidth: true
                        text: vital.modelData.label
                        elide: Text.ElideRight
                    }
                    Metric {
                        value: vital.modelData.value
                        unit: vital.modelData.unit
                        pixelSize: AtollStyle.typeHeadline
                        weight: Font.Bold
                        color: vital.tint
                    }
                }
            }
        }
    }
    Component {
        id: workspacesCard
        ColumnLayout {
            id: workspaceBody
            readonly property var workspaces: (NiriService.allWorkspaces ?? [])
                .filter(ws => ws.output === root.screenName && !MinimizedWindows.isStashWorkspace(ws.id))
                .slice().sort((a, b) => Number(a.idx ?? 0) - Number(b.idx ?? 0))
            readonly property var windows: (NiriService.windows ?? [])
                .filter(window => workspaceBody.workspaces.some(ws => ws.id === window.workspace_id))
            spacing: 10 * root.d
            CardHeader {
                glyph: "grid_view"
                tint: AtollStyle.identity.purple
                title: Translation.tr("Workspaces")
                detail: Translation.tr("%1 workspaces · %2 windows").arg(workspaceBody.workspaces.length).arg(workspaceBody.windows.length)
                AtollIconButton {
                    materialIcon: "space_dashboard"
                    Accessible.name: Translation.tr("Open overview")
                    onClicked: { root.close(); NiriService.toggleOverview() }
                }
            }
            Repeater {
                model: workspaceBody.workspaces
                RowLayout {
                    id: workspaceRow
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 8 * root.d
                    Rectangle {
                        Layout.preferredWidth: Math.round(44 * root.d)
                        Layout.preferredHeight: Layout.preferredWidth
                        radius: AtollStyle.iconRadius(width)
                        color: workspaceRow.modelData.is_active ? AtollStyle.tintFill(AtollStyle.accent) : AtollStyle.fillQuiet
                        border.width: workspaceRow.modelData.is_active ? 0 : 1
                        border.color: AtollStyle.border
                        AtollText {
                            anchors.centerIn: parent
                            text: workspaceRow.modelData.idx ?? "–"
                            color: workspaceRow.modelData.is_active ? AtollStyle.accent : AtollStyle.text
                            font.family: AtollStyle.fontNumbers
                            font.features: ({ "tnum": 1 })
                            font.pixelSize: AtollStyle.typeBody
                            font.weight: AtollStyle.weight(Font.Bold)
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.close()
                                NiriService.switchToWorkspaceById(workspaceRow.modelData.id)
                            }
                        }
                    }
                    AtollColumnStrip {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.round(44 * root.d)
                        workspaceId: workspaceRow.modelData.id
                        windows: workspaceBody.windows
                        outputName: root.screenName
                        active: workspaceRow.modelData.is_active ?? false
                        onWindowActivated: windowId => { root.close(); NiriService.focusWindow(windowId) }
                    }
                }
            }
        }
    }
    Component {
        id: updatesCard
        ColumnLayout {
            spacing: 10 * root.d
            CardHeader {
                glyph: Updates.count > 0 ? "deployed_code_update" : "task_alt"
                tint: Updates.count > 0 ? AtollStyle.secondaryAccent : AtollStyle.identity.green
                title: Translation.tr("Updates")
                detail: Updates.count > 0
                    ? Translation.tr("%1 packages waiting").arg(Updates.count)
                    : Translation.tr("Everything is up to date")
                AtollIconButton {
                    materialIcon: "refresh"
                    Accessible.name: Translation.tr("Check again")
                    onClicked: Updates.refresh()
                }
            }
            AtollNumber {
                Layout.alignment: Qt.AlignHCenter
                text: Updates.count
                pixelSize: 44 * AtollStyle.typeScale
                weight: Font.Bold
                color: Updates.count > 0 ? AtollStyle.secondaryAccent : AtollStyle.identity.green
            }
            AtollButton {
                Layout.fillWidth: true
                visible: Updates.count > 0
                text: Translation.tr("Update now")
                buttonRadius: AtollStyle.radiusTile
                implicitHeight: Math.round(38 * root.d)
                onClicked: {
                    root.close()
                    PackageSearch.runConfiguredUpdate()
                }
            }
        }
    }
    Component {
        id: vpnCard
        ColumnLayout {
            id: vpn
            spacing: 8 * root.d
            Component.onCompleted: Vpn.keepAlive()
            Component.onDestruction: Vpn.releaseKeepAlive()
            // Hides addresses and the account for a screenshot; the values still copy whole.
            property bool masked: true
            property bool copied: false
            // A window the card hands off to (a file chooser, NetworkManager's editor, a terminal) opens with the card gone.
            Connections {
                target: Vpn
                function onHandOff(): void { GlobalStates.atollBubbleCard = null }
            }
            Timer { id: copiedTimer; interval: 1400; onTriggered: vpn.copied = false }
            function copy(value: string): void {
                Quickshell.clipboardText = value
                vpn.copied = true
                copiedTimer.restart()
            }
            function hide(value: string): string {
                if (!vpn.masked || value.length === 0) return value
                if (/^\d+\.\d+\.\d+\.\d+/.test(value)) return value.replace(/^(\d+\.\d+)\.\d+\.\d+/, "$1.•••.•••")
                if (value.includes("@")) return value.slice(0, 2) + "•••" + value.slice(value.indexOf("@"))
                if (value.includes(":")) return value.split(":")[0] + ":••••:••••"
                return value.split(".")[0] + ".•••"
            }
            function rate(bytes: real): string {
                return bytes >= 1048576 ? (bytes / 1048576).toFixed(1) + " MB/s"
                    : bytes >= 1024 ? (bytes / 1024).toFixed(1) + " KB/s" : Math.round(bytes) + " B/s"
            }
            function traffic(dev: string): string {
                const r = Vpn.rates[dev]
                return r ? "↓ " + vpn.rate(r.down) + "   ↑ " + vpn.rate(r.up) : ""
            }
            CardHeader {
                glyph: Vpn.connected ? "vpn_lock" : "vpn_key_off"
                tint: Vpn.connected ? AtollStyle.identity.green : AtollStyle.muted
                title: Translation.tr("VPN")
                detail: vpn.copied ? Translation.tr("Copied")
                    : Vpn.busy ? Translation.tr("Working…")
                    : Vpn.connected ? Translation.tr("On through %1").arg(Vpn.activeName)
                    : Translation.tr("Not connected")
                AtollIconButton {
                    visible: Vpn.details
                    materialIcon: vpn.masked ? "visibility_off" : "visibility"
                    selected: vpn.masked
                    Accessible.name: vpn.masked ? Translation.tr("Show addresses") : Translation.tr("Hide addresses")
                    onClicked: vpn.masked = !vpn.masked
                }
                AtollIconButton {
                    materialIcon: "info"
                    selected: Vpn.details
                    Accessible.name: Vpn.details ? Translation.tr("Hide details") : Translation.tr("Show details")
                    onClicked: Vpn.setDetails(!Vpn.details)
                }
                AtollIconButton {
                    materialIcon: "refresh"
                    Accessible.name: Translation.tr("Check again")
                    onClicked: Vpn.refresh()
                }
            }
            AtollText {
                Layout.fillWidth: true
                visible: Vpn.profiles.length === 0
                text: Vpn.available
                    ? Translation.tr("OpenVPN and WireGuard profiles you add in NetworkManager show up here too.")
                    : Translation.tr("No VPN yet. Add an OpenVPN or WireGuard profile in NetworkManager, or install Tailscale.")
                color: AtollStyle.muted
                wrapMode: Text.WordWrap
                font.pixelSize: AtollStyle.typeMeta
            }
            VpnRow {
                Layout.fillWidth: true
                visible: Vpn.tailscaleInstalled
                label: "Tailscale"
                detail: Vpn.tailscaleUp ? vpn.hide(Vpn.tailscaleAddress)
                    : Vpn.tailscaleSignedOut ? Translation.tr("Signed out") : Translation.tr("Off")
                on: Vpn.tailscaleUp
                onToggled: Vpn.toggleTailscale()
            }
            AtollButton {
                Layout.fillWidth: true
                visible: Vpn.tailscaleSignedOut
                enabled: !Vpn.signingIn
                emphasized: true
                text: Vpn.signingIn ? Translation.tr("Finish in your browser…") : Translation.tr("Sign in to Tailscale")
                buttonRadius: AtollStyle.radiusTile
                implicitHeight: Math.round(34 * root.d)
                onClicked: Vpn.signInTailscale()
            }
            VpnFacts {
                Layout.fillWidth: true
                visible: Vpn.details && Vpn.tailscaleInstalled && Vpn.tailscaleAddress.length > 0
                VpnFact { Layout.fillWidth: true; label: Translation.tr("IPv4"); value: Vpn.tailscaleAddress; shown: vpn.hide(value); onCopy: value => vpn.copy(value) }
                VpnFact { Layout.fillWidth: true; label: Translation.tr("IPv6"); value: Vpn.tailscaleAddress6; shown: vpn.hide(value); onCopy: value => vpn.copy(value) }
                VpnFact { Layout.fillWidth: true; label: Translation.tr("Name"); value: Vpn.tailscaleDns; shown: vpn.hide(value); onCopy: value => vpn.copy(value) }
                VpnFact { Layout.fillWidth: true; label: Translation.tr("Account"); value: Vpn.tailscaleAccount; shown: vpn.hide(value); onCopy: value => vpn.copy(value) }
                VpnFact { Layout.fillWidth: true; label: Translation.tr("Exit node"); value: Vpn.tailscaleExitName.length > 0 ? Vpn.tailscaleExitName : Translation.tr("None, direct"); onCopy: value => vpn.copy(value) }
                VpnFact { Layout.fillWidth: true; label: Translation.tr("Traffic"); value: Vpn.tailscaleUp ? vpn.traffic("tailscale0") : ""; onCopy: value => vpn.copy(value) }
            }
            ColumnLayout {
                Layout.fillWidth: true
                visible: Vpn.details && Vpn.tailscaleDevices.length > 0
                spacing: Math.round(2 * root.d)
                AtollText {
                    Layout.leftMargin: Math.round(4 * root.d)
                    Layout.topMargin: Math.round(4 * root.d)
                    text: Translation.tr("Devices · %1 of %2 online").arg(Vpn.tailscaleOnline).arg(Vpn.tailscaleDevices.length)
                    color: AtollStyle.muted
                    font.pixelSize: AtollStyle.typeFootnote
                    font.weight: AtollStyle.weight(Font.Medium)
                }
                Repeater {
                    model: Vpn.tailscaleDevices.slice(0, 6)
                    MouseArea {
                        id: device
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: Math.round(36 * root.d)
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: vpn.copy(device.modelData.address)
                        Accessible.role: Accessible.Button
                        Accessible.name: device.modelData.name
                        Rectangle {
                            anchors.fill: parent
                            radius: AtollStyle.radiusRow
                            color: device.containsMouse ? AtollStyle.fillHover : ColorUtils.applyAlpha(AtollStyle.fillHover, 0)
                            Behavior on color { ColorAnimation { duration: AtollStyle.duration(120); easing.type: AtollStyle.feedbackEasing } }
                        }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Math.round(10 * root.d)
                            anchors.rightMargin: Math.round(8 * root.d)
                            spacing: Math.round(10 * root.d)
                            Rectangle {
                                implicitWidth: Math.round(8 * root.d)
                                implicitHeight: implicitWidth
                                radius: width / 2
                                color: device.modelData.online ? AtollStyle.identity.green : AtollStyle.fillActive
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                AtollText {
                                    Layout.fillWidth: true
                                    text: device.modelData.name
                                    elide: Text.ElideRight
                                    font.pixelSize: AtollStyle.typeLabel
                                    color: device.modelData.online ? AtollStyle.text : AtollStyle.textSecondary
                                }
                                AtollText {
                                    Layout.fillWidth: true
                                    text: [vpn.hide(device.modelData.address), device.modelData.os].filter(part => part.length > 0).join(" · ")
                                    elide: Text.ElideRight
                                    color: AtollStyle.muted
                                    font.pixelSize: AtollStyle.typeFootnote
                                    font.features: ({ "tnum": 1 })
                                }
                            }
                            AtollChip {
                                visible: Vpn.tailscaleUp && (device.modelData.exitOption || device.modelData.exitNode)
                                selected: device.modelData.exitNode
                                glyph: "logout"
                                label: device.modelData.exitNode ? Translation.tr("Exit node") : Translation.tr("Use as exit")
                                Accessible.name: device.modelData.exitNode ? Translation.tr("Stop using %1 as exit node").arg(device.modelData.name)
                                    : Translation.tr("Send traffic through %1").arg(device.modelData.name)
                                onClicked: Vpn.setExitNode(device.modelData.exitNode ? "" : device.modelData.address)
                            }
                        }
                    }
                }
                AtollText {
                    Layout.leftMargin: Math.round(10 * root.d)
                    visible: Vpn.tailscaleDevices.length > 6
                    text: Translation.tr("+%1 more").arg(Vpn.tailscaleDevices.length - 6)
                    color: AtollStyle.muted
                    font.pixelSize: AtollStyle.typeFootnote
                }
            }
            Repeater {
                model: Vpn.profiles
                ColumnLayout {
                    id: profile
                    required property var modelData
                    readonly property var facts: Vpn.profileDetails[profile.modelData.uuid] ?? null
                    Layout.fillWidth: true
                    spacing: Math.round(4 * root.d)
                    VpnRow {
                        Layout.fillWidth: true
                        label: profile.modelData.name
                        detail: profile.modelData.active && profile.facts?.address ? profile.modelData.type + " · " + vpn.hide(profile.facts.address) : profile.modelData.type
                        on: profile.modelData.active
                        onToggled: Vpn.toggleProfile(profile.modelData.uuid)
                    }
                    VpnFacts {
                        Layout.fillWidth: true
                        visible: Vpn.details && profile.modelData.active && profile.facts !== null
                        VpnFact { Layout.fillWidth: true; label: Translation.tr("Address"); value: profile.facts?.address ?? ""; shown: vpn.hide(value); onCopy: value => vpn.copy(value) }
                        VpnFact { Layout.fillWidth: true; label: Translation.tr("Gateway"); value: profile.facts?.gateway ?? ""; shown: vpn.hide(value); onCopy: value => vpn.copy(value) }
                        VpnFact { Layout.fillWidth: true; label: Translation.tr("DNS"); value: profile.facts?.dns ?? ""; shown: vpn.hide(value); onCopy: value => vpn.copy(value) }
                        VpnFact { Layout.fillWidth: true; label: Translation.tr("Interface"); value: profile.facts?.device ?? ""; onCopy: value => vpn.copy(value) }
                        VpnFact { Layout.fillWidth: true; label: Translation.tr("Traffic"); value: vpn.traffic(profile.facts?.device ?? ""); onCopy: value => vpn.copy(value) }
                    }
                    VpnFacts {
                        Layout.fillWidth: true
                        visible: Vpn.details
                        VpnFact {
                            Layout.fillWidth: true
                            label: Translation.tr("Connect automatically")
                            glyph: ""
                            value: profile.modelData.autoconnect ? Translation.tr("On") : Translation.tr("Off")
                            onCopy: Vpn.setAutoconnect(profile.modelData.uuid, !profile.modelData.autoconnect)
                        }
                        VpnFact {
                            Layout.fillWidth: true
                            visible: Vpn.canCreate
                            label: Translation.tr("Settings")
                            glyph: "open_in_new"
                            value: Vpn.hasEditor ? Translation.tr("NetworkManager") : "nmtui"
                            onCopy: Vpn.editProfile(profile.modelData.uuid)
                        }
                    }
                }
            }
            AtollText {
                Layout.fillWidth: true
                visible: Vpn.errorText.length > 0
                text: Vpn.errorText
                color: AtollStyle.danger
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                font.pixelSize: AtollStyle.typeMeta
            }
            AtollText {
                Layout.fillWidth: true
                visible: Vpn.hasNmcli && !Vpn.canCreate
                text: Vpn.missingEditorText
                color: AtollStyle.muted
                wrapMode: Text.WordWrap
                font.pixelSize: AtollStyle.typeMeta
            }
            AtollActionRow {
                Layout.fillWidth: true
                visible: Vpn.hasNmcli
                spacing: Math.round(6 * root.d)
                AtollButton {
                    Layout.fillWidth: true
                    visible: Vpn.canCreate
                    enabled: !Vpn.busy
                    text: Vpn.hasEditor ? Translation.tr("New WireGuard…") : Translation.tr("New VPN…")
                    buttonRadius: AtollStyle.radiusTile
                    onClicked: Vpn.newProfile("wireguard")
                }
                AtollButton {
                    Layout.fillWidth: true
                    visible: Vpn.hasEditor && Vpn.hasVpnPlugins
                    enabled: !Vpn.busy
                    text: Translation.tr("Other VPN…")
                    buttonRadius: AtollStyle.radiusTile
                    onClicked: Vpn.newProfile("vpn")
                }
                AtollButton {
                    Layout.fillWidth: true
                    enabled: !Vpn.busy
                    text: Translation.tr("Import a file…")
                    buttonRadius: AtollStyle.radiusTile
                    onClicked: Vpn.chooseProfileFile()
                }
            }
            AtollButton {
                Layout.fillWidth: true
                visible: Vpn.needsTailscaleOperator
                enabled: !Vpn.busy
                text: Translation.tr("Let me control Tailscale")
                buttonRadius: AtollStyle.radiusTile
                implicitHeight: Math.round(34 * root.d)
                onClicked: Vpn.fixTailscaleOperator()
            }
        }
    }
    Component {
        id: shellUpdateCard
        ColumnLayout {
            id: updateCard
            readonly property var changes: ShellUpdates.commitLog.split("\n").filter(l => l.length > 0)
                .map(l => l.split("|")[1] ?? l)
            spacing: 10 * root.d
            CardHeader {
                glyph: "rocket_launch"
                tint: AtollStyle.secondaryAccent
                title: ShellUpdates.remoteVersion.length > 0
                    ? Translation.tr("Lunana %1").arg(ShellUpdates.remoteVersion) : Translation.tr("New Lunana")
                detail: ShellUpdates.repoDiverged
                    ? Translation.tr("Upstream history changed; your local work is kept")
                    : ShellUpdates.commitsBehind > 0
                        ? Translation.tr("%1 commits behind").arg(ShellUpdates.commitsBehind)
                        : Translation.tr("Ready to update")
            }
            AtollText {
                Layout.fillWidth: true
                visible: text.length > 0
                text: updateCard.changes.length > 0
                    ? updateCard.changes.slice(0, 5).map(s => "• " + s).join("\n")
                        + (updateCard.changes.length > 5 ? "\n" + Translation.tr("+%1 more").arg(updateCard.changes.length - 5) : "")
                    : ShellUpdates.latestMessage
                color: AtollStyle.subtext
                wrapMode: Text.WordWrap
                maximumLineCount: 9
                elide: Text.ElideRight
                font.pixelSize: AtollStyle.typeMeta
            }
            AtollButton {
                Layout.fillWidth: true
                visible: ShellUpdates.selfUpdateSupported
                enabled: !ShellUpdates.isUpdating
                text: ShellUpdates.isUpdating ? Translation.tr("Updating…")
                    : ShellUpdates.repoDiverged ? Translation.tr("Repair & Update") : Translation.tr("Update now")
                buttonRadius: AtollStyle.radiusTile
                implicitHeight: Math.round(38 * root.d)
                onClicked: { root.close(); ShellUpdates.performUpdate() }
            }
            AtollButton {
                Layout.fillWidth: true
                quiet: true
                text: Translation.tr("Not now")
                buttonRadius: AtollStyle.radiusTile
                implicitHeight: Math.round(32 * root.d)
                onClicked: { root.close(); ShellUpdates.dismiss() }
            }
        }
    }
    Component {
        id: animeCard
        ColumnLayout {
            id: airing
            readonly property var shows: AtollPieces.animeUpcoming.slice(0,
                Math.max(3, Math.min(8, Number(Config.options?.atoll?.anime?.shows ?? 5))))
            readonly property var next: AtollPieces.animeNext
            spacing: 8 * root.d
            Component.onCompleted: AnimeService.fetchTopAiring()
            CardHeader {
                glyph: AtollPieces.glyphOf("anime", "")
                tint: AtollStyle.identity.pink
                title: Translation.tr("Airing")
                detail: airing.next
                    ? Translation.tr("Ep %1 in %2").arg(airing.next.nextEpisode).arg(AtollPieces.animeWait(airing.next.airingAt))
                    : !Network.online ? Network.offlineReason
                    : AnimeService.lastError.length > 0 && !AnimeService.loading ? Translation.tr("AniList didn't answer (´・ω・`)")
                    : Translation.tr("Nothing scheduled yet")
                AtollIconButton {
                    enabled: Network.online
                    materialIcon: "refresh"
                    Accessible.name: Translation.tr("Check again")
                    onClicked: { AnimeService.invalidateTopCache(); AnimeService.fetchTopAiring() }
                }
            }
            Repeater {
                model: airing.shows
                MouseArea {
                    id: showRow
                    required property var modelData
                    readonly property bool followed: AtollPieces.animeFollows(showRow.modelData.id)
                    Layout.fillWidth: true
                    implicitHeight: Math.round(46 * root.d)
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    Accessible.role: Accessible.CheckBox
                    Accessible.checked: showRow.followed
                    Accessible.name: Translation.tr("Follow %1").arg(showRow.modelData.title)
                    onClicked: AtollPieces.animeToggleFollow(showRow.modelData.id)
                    Rectangle {
                        anchors.fill: parent
                        radius: AtollStyle.radiusTile
                        color: showRow.containsMouse ? AtollStyle.fillHover : "transparent"
                        Behavior on color { ColorAnimation { duration: AtollStyle.duration(120); easing.type: AtollStyle.feedbackEasing } }
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(6 * root.d)
                        anchors.rightMargin: Math.round(8 * root.d)
                        spacing: 10 * root.d
                        ClippingRectangle {
                            implicitWidth: Math.round(28 * root.d)
                            implicitHeight: Math.round(38 * root.d)
                            radius: AtollStyle.iconRadius(width)
                            color: AtollStyle.fillQuiet
                            AtollImage {
                                anchors.fill: parent
                                source: String(showRow.modelData.imageSmall ?? showRow.modelData.image ?? "")
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            AtollText {
                                Layout.fillWidth: true
                                text: showRow.modelData.title
                                elide: Text.ElideRight
                                font.pixelSize: AtollStyle.typeLabel
                                font.weight: showRow.followed ? Font.DemiBold : Font.Normal
                            }
                            AtollText {
                                Layout.fillWidth: true
                                text: Translation.tr("Ep %1").arg(showRow.modelData.nextEpisode)
                                color: AtollStyle.muted
                                elide: Text.ElideRight
                                font.pixelSize: AtollStyle.typeFootnote
                            }
                        }
                        AtollText {
                            text: AtollPieces.animeWait(showRow.modelData.airingAt)
                            color: showRow.followed ? AtollStyle.identity.pink : AtollStyle.subtext
                            font.family: AtollStyle.fontNumbers
                            font.features: ({ "tnum": 1 })
                            font.pixelSize: AtollStyle.typeMeta
                            font.weight: AtollStyle.weight(Font.DemiBold)
                        }
                        MaterialSymbol {
                            opacity: showRow.followed ? 1 : showRow.containsMouse ? 0.5 : 0
                            text: "bookmark"
                            fill: showRow.followed ? 1 : 0
                            iconSize: Math.round(15 * root.d)
                            color: showRow.followed ? AtollStyle.identity.pink : AtollStyle.subtext
                            Behavior on opacity { NumberAnimation { duration: AtollStyle.duration(120); easing.type: AtollStyle.feedbackEasing } }
                        }
                    }
                }
            }
            AtollText {
                Layout.fillWidth: true
                visible: airing.shows.length > 0
                text: AtollPieces.animeFollowing.length > 0
                    ? Translation.tr("The bubble shows what you follow first")
                    : Translation.tr("Tap a show to follow it")
                color: AtollStyle.muted
                font.pixelSize: AtollStyle.typeMeta
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
    Component {
        id: watchingCard
        AtollWatchingCard {
            onCloseRequested: root.close()
        }
    }
    Component {
        id: mediaCard
        Item {
            id: player
            ColorQuantizer {
                id: tintQuantizer
                source: MediaArtwork.displaySource
                depth: 2
                rescaleSize: 48
            }
            readonly property color tint: AtollStyle.artTintOf(tintQuantizer.colors)
            // The artwork is the card's material, edge to edge in its own contour; the player sits on it at the card's margin.
            readonly property real inset: Math.max(0, AtollStyle.cardPad - Math.round(14 * root.d))
            implicitHeight: card.implicitHeight + player.inset * 2
            Rectangle {
                anchors.fill: parent
                color: AtollStyle.surfaceHigh
                visible: !artLoader.active
            }
            Loader {
                id: artLoader
                anchors.fill: parent
                active: (Config.options?.atoll?.player?.artworkBackground ?? true)
                    && MediaArtwork.displaySource.length > 0
                sourceComponent: Item {
                    AtollMediaBackdrop { anchors.fill: parent; source: MediaArtwork.displaySource; strength: 0.9 }
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: AtollStyle.tintFill(player.tint) }
                            GradientStop { position: 1; color: "transparent" }
                        }
                    }
                }
            }
            AtollMediaCard {
                id: card
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: player.inset
                showBackground: false
                active: root.contentActive
                tint: player.tint
            }
        }
    }
}
