pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects as GE
import Quickshell
import "../../.."
import "../../../services"
import "../../common"
import "../../atoll/style"
import "../../atoll/components" as Atoll
import "../../common/functions"
import "../../common/widgets"
import "../../common/widgets/widgetCanvas"

Rectangle {
    id: root

    property real padding: OverlayLook.atoll ? Math.round(6 * AtollStyle.density) : 8

    opacity: GlobalStates.overlayOpen ? 1 : 0
    implicitWidth: contentRow.implicitWidth + (padding * 2)
    implicitHeight: contentRow.implicitHeight + (padding * 2)
    color: OverlayLook.atoll ? AtollStyle.bodySurface
        : Appearance.angelEverywhere || Appearance.regaliaEverywhere ? "transparent"
        : Appearance.lunanaEverywhere ? Appearance.lunana.colLayer1
        : Appearance.colors.colSurfaceContainer
    radius: OverlayLook.atoll ? height / 2
        : Appearance.regaliaEverywhere ? Appearance.regalia.roundLarge
        : Appearance.angelEverywhere ? Appearance.angel.roundingNormal
        : Appearance.lunanaEverywhere ? Appearance.lunana.roundingNormal
        : Appearance.rounding.large
    border.color: OverlayLook.atoll ? AtollStyle.border
        : Appearance.regaliaEverywhere ? "transparent"
        : Appearance.angelEverywhere ? Appearance.angel.colBorder
        : Appearance.lunanaEverywhere ? Appearance.lunana.colBorder
        : Appearance.colors.colOutlineVariant
    border.width: Appearance.regaliaEverywhere ? 0
        : Appearance.angelEverywhere ? Appearance.angel.cardBorderWidth : 1
    clip: true

    layer.enabled: Appearance.angelEverywhere
    layer.effect: GE.OpacityMask {
        maskSource: Rectangle {
            width: root.width
            height: root.height
            radius: root.radius
        }
    }

    // Wallpaper blur for angel style
    Image {
        id: taskbarBlurWallpaper
        x: -root.x
        y: -root.y
        width: Quickshell.screens[0]?.width ?? 1920
        height: Quickshell.screens[0]?.height ?? 1080
        visible: Appearance.angelEverywhere
        source: visible ? Wallpapers.effectiveWallpaperUrl : ""
        fillMode: Image.PreserveAspectCrop
        cache: true
        sourceSize.width: Quickshell.screens[0]?.width ?? 1920
        sourceSize.height: Quickshell.screens[0]?.height ?? 1080
        asynchronous: true
        layer.enabled: Appearance.effectsEnabled && Appearance.angelEverywhere
        layer.effect: MultiEffect {
            source: taskbarBlurWallpaper
            anchors.fill: source
            saturation: Appearance.angel.blurSaturation * Appearance.angel.colorStrength
            blurEnabled: Appearance.effectsEnabled
            blurMax: 64
            blur: Appearance.effectsEnabled ? Appearance.angel.blurIntensity : 0
        }
    }
    Rectangle {
        anchors.fill: parent
        visible: Appearance.angelEverywhere
        color: ColorUtils.transparentize(Appearance.colors.colLayer0Base, Appearance.angel.overlayOpacity)
    }

    RegaliaPlate {
        anchors.fill: parent
        visible: Appearance.regaliaEverywhere
        fillColor: Appearance.regalia.bg2
        radius: root.radius
        inset: Appearance.regalia.controlInset
        elevated: true
        glassEnabled: true
    }

    AngelPartialBorder {
        targetRadius: root.radius
        visible: Appearance.angelEverywhere
    }

    Behavior on opacity {
        animation: NumberAnimation {
            duration: OverlayLook.atoll ? AtollStyle.emergeDuration : Appearance.animation.elementMoveFast.duration
            easing.type: OverlayLook.atoll ? Easing.BezierSpline : Appearance.animation.elementMoveFast.type
            easing.bezierCurve: OverlayLook.atoll ? AtollStyle.emergeCurve : Appearance.animation.elementMoveFast.bezierCurve
        }
    }

    RowLayout {
        id: contentRow
        anchors {
            fill: parent
            margins: root.padding
        }
        spacing: OverlayLook.atoll ? Math.round(4 * AtollStyle.density) : 6

        Row {
            spacing: OverlayLook.atoll ? Math.round(2 * AtollStyle.density) : 4
            Repeater {
                model: ScriptModel {
                    values: OverlayContext.availableWidgets
                }
                delegate: WidgetButton {
                    required property var modelData
                    identifier: modelData.identifier
                    materialSymbol: modelData.materialSymbol
                }
            }
        }

        Separator {}
        TimeWidget { visible: !OverlayLook.atoll }
        Atoll.AtollClock {
            visible: OverlayLook.atoll
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: Math.round(8 * AtollStyle.density)
            Layout.rightMargin: Math.round(6 * AtollStyle.density)
            pixelSize: 18 * AtollStyle.typeScale
        }
        Separator {
            visible: Battery.available
        }
        BatteryWidget {
            visible: Battery.available
        }
    }

    component Separator: Rectangle {
        implicitWidth: 1
        color: OverlayLook.atoll ? AtollStyle.hairlineStrong
            : Appearance.angelEverywhere ? Appearance.angel.colBorderSubtle
            : Appearance.lunanaEverywhere ? Appearance.lunana.colBorderSubtle
            : Appearance.colors.colOutlineVariant
        Layout.fillHeight: true
        Layout.topMargin: 10
        Layout.bottomMargin: 10
    }

    component TimeWidget: StyledText {
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 8
        Layout.rightMargin: 6

        text: DateTime.time
        color: Appearance.colors.colOnSurface
        font {
            family: Appearance.font.family.numbers
            variableAxes: Appearance.font.variableAxes.numbers
            pixelSize: 22
        }
    }
    
    component BatteryWidget: Row {
        id: batteryWidget
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        spacing: 2
        property color colText: Battery.isLowAndNotCharging ? OverlayLook.colError : OverlayLook.colOnSurface

        MaterialSymbol {
            id: boltIcon
            anchors.verticalCenter: parent.verticalCenter
            fill: 1
            text: Battery.isCharging ? "bolt" : "battery_android_full"
            color: batteryWidget.colText
            iconSize: OverlayLook.atoll ? 20 : 24
            animateChange: true
        }
        
        StyledText {
            id: batteryText
            anchors.verticalCenter: parent.verticalCenter
            Binding on font.weight { when: OverlayLook.atoll; value: Font.DemiBold }
            text: Math.round(Battery.percentage * 100) + "%"
            color: batteryWidget.colText
            font {
                family: OverlayLook.fontNumbers
                variableAxes: Appearance.font.variableAxes.numbers
                pixelSize: OverlayLook.atoll ? 14 * AtollStyle.typeScale : 18
            }
        }
    }

    component WidgetButton: RippleButton {
        id: widgetButton
        required property string identifier
        required property string materialSymbol

        Layout.alignment: Qt.AlignVCenter

        toggled: Persistent.states.overlay.open.includes(identifier)
        onClicked: {
            if (widgetButton.toggled) {
                Persistent.states.overlay.open = Persistent.states.overlay.open.filter(type => type !== identifier);
            } else {
                Persistent.states.overlay.open.push(identifier);
            }
        }
        implicitWidth: implicitHeight

        Binding on colBackground { when: OverlayLook.atoll; value: ColorUtils.applyAlpha(AtollStyle.fill, 0) }
        Binding on colBackgroundHover { when: OverlayLook.atoll; value: AtollStyle.fillHover }
        Binding on colRipple { when: OverlayLook.atoll; value: AtollStyle.fillActive }
        colBackgroundToggled: OverlayLook.atoll ? AtollStyle.tintFill(AtollStyle.accent)
            : Appearance.regaliaEverywhere ? Appearance.regalia.primaryPlate
            : Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover
            : Appearance.colors.colSecondaryContainer
        colBackgroundToggledHover: OverlayLook.atoll ? AtollStyle.tintFillHover(AtollStyle.accent)
            : Appearance.regaliaEverywhere ? Appearance.regalia.primaryPlateHover
            : Appearance.angelEverywhere ? Appearance.angel.colGlassCardActive
            : Appearance.colors.colSecondaryContainerHover
        colRippleToggled: OverlayLook.atoll ? AtollStyle.tintFillHover(AtollStyle.accent)
            : Appearance.regaliaEverywhere ? Appearance.regalia.primaryPlateActive
            : Appearance.angelEverywhere ? Appearance.angel.colGlassCardActive
            : Appearance.colors.colSecondaryContainerActive

        buttonRadius: OverlayLook.atoll ? height / 2 : root.radius - (root.height - height) / 2

        contentItem: Item {
            anchors.centerIn: parent
            implicitWidth: OverlayLook.atoll ? Math.round(30 * AtollStyle.density) : 32
            implicitHeight: OverlayLook.atoll ? Math.round(30 * AtollStyle.density) : 32
            MaterialSymbol {
                id: iconWidget
                anchors.centerIn: parent
                iconSize: OverlayLook.atoll ? Math.round(19 * AtollStyle.density) : 24
                fill: OverlayLook.atoll && widgetButton.toggled ? 1 : 0
                text: widgetButton.identifier === "recorder" && RecorderStatus.isRecording ? "radio_button_checked" : widgetButton.materialSymbol
                color: widgetButton.identifier === "recorder" && RecorderStatus.isRecording
                        ? OverlayLook.colError
                        : OverlayLook.atoll ? (widgetButton.toggled ? AtollStyle.accent : widgetButton.buttonHovered ? AtollStyle.text : AtollStyle.textSecondary)
                        : (widgetButton.toggled
                            ? (Appearance.regaliaEverywhere ? Appearance.regalia.primaryPlateInk
                                : Appearance.angelEverywhere ? Appearance.angel.colPrimary : Appearance.colors.colOnSecondaryContainer)
                            : (Appearance.regaliaEverywhere ? Appearance.regalia.onMuted
                                : Appearance.angelEverywhere ? Appearance.angel.colText : Appearance.colors.colOnSurfaceVariant))
            }
        }

        StyledToolTip {
            text: widgetButton.identifier === "crosshair" ? Translation.tr("Crosshair overlay")
                  : widgetButton.identifier === "fpsLimiter" ? Translation.tr("FPS limiter")
                  : widgetButton.identifier === "floatingImage" ? Translation.tr("Floating image")
                  : widgetButton.identifier === "recorder" ? Translation.tr("Recorder")
                  : widgetButton.identifier === "resources" ? Translation.tr("Resources")
                  : widgetButton.identifier === "gamePerformance" ? Translation.tr("Game performance")
                  : widgetButton.identifier === "notes" ? Translation.tr("Notes")
                  : widgetButton.identifier === "discord" ? Translation.tr("Discord control")
                  : widgetButton.identifier === "volumeMixer" ? Translation.tr("Volume mixer")
                  : widgetButton.identifier
        }
    }
}
