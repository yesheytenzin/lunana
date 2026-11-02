pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Widgets
import "../../../../services"
import "../../../common"
import "../../../common/functions"
import "../../../common/widgets"
import "../../../background/widgets"
import "../../../background/widgets/instrument"
import "../../style"
import "../../components"
import "../parts"

PreviewScene {
    id: widgetsRoot
    readonly property real naturalWidth: Math.round(620 * widgetsRoot.d)
    readonly property real naturalHeight: Math.round(260 * widgetsRoot.d)
    readonly property bool on: widgetsRoot.opt("atoll.modules.desktopWidgets", true)
    readonly property string design: DesktopWidgetDesign.current
    readonly property bool atoll: widgetsRoot.design === "atoll"
    readonly property bool instrument: widgetsRoot.design === "instrument"
    readonly property bool bare: widgetsRoot.instrument || widgetsRoot.design === "readout"
    readonly property string material: String(widgetsRoot.opt("atoll.widgets.material", "glass"))
    readonly property bool glass: widgetsRoot.atoll && widgetsRoot.material === "glass"
    readonly property bool clear: widgetsRoot.bare || (widgetsRoot.atoll && widgetsRoot.material === "clear")
    readonly property color ink: String(widgetsRoot.opt("atoll.widgets.tint", "wallpaper")) === "wallpaper" ? AtollStyle.wallpaperLight : AtollStyle.accent
    readonly property int weight: ({ light: Font.Light, regular: Font.Medium, bold: Font.Bold })[String(widgetsRoot.opt("atoll.widgets.weight", "regular"))] ?? Font.Medium
    readonly property real strength: Math.max(0.2, Math.min(1, Number(widgetsRoot.opt("atoll.widgets.opacity", 100)) / 100))
    readonly property string outline: String(widgetsRoot.opt("atoll.widgets.outline", "auto"))
    readonly property bool rimShown: !widgetsRoot.bare && widgetsRoot.atoll && (widgetsRoot.outline === "always"
        || (widgetsRoot.outline === "auto" && (!widgetsRoot.clear || Boolean(widgetsRoot.opt("atoll.widgets.rim", false)))))
    readonly property bool edgeLit: widgetsRoot.rimShown && (widgetsRoot.glass || AtollStyle.edgeLit) && (AtollStyle.glassEdgeLight > 0 || AtollStyle.glassEdgeLine > 0)
    readonly property real plateRadius: Math.round(Math.max(0, Math.min(40, Number(widgetsRoot.opt("atoll.widgets.radius", 22)))) * widgetsRoot.d)
    readonly property real unit: Math.round(170 * widgetsRoot.d)
    readonly property real wide: Math.round(250 * widgetsRoot.d)
    readonly property real gap: Math.round(16 * widgetsRoot.d)
    readonly property real plateX: Math.round((widgetsRoot.width - widgetsRoot.wide - widgetsRoot.gap - widgetsRoot.unit) / 2)
    readonly property real plateY: Math.round((widgetsRoot.height - widgetsRoot.unit) / 2)
    readonly property color plateColor: widgetsRoot.bare ? "transparent" : !widgetsRoot.atoll ? Appearance.colors.colLayer2 : widgetsRoot.glass || widgetsRoot.clear
        ? ColorUtils.applyAlpha(AtollStyle.surface, widgetsRoot.clear && !Boolean(widgetsRoot.opt("atoll.widgets.legibleAlways", false)) ? 0
            : AtollStyle.legibleVeil(widgetsRoot.material, 0, 0, 1)
                * (Boolean(widgetsRoot.opt("atoll.widgets.legibleAlways", false)) ? 1 : widgetsRoot.strength))
        : ColorUtils.applyAlpha(widgetsRoot.material === "tinted"
            ? ColorUtils.mix(AtollStyle.surface, Appearance.colors.colPrimary, 0.82) : AtollStyle.surface, widgetsRoot.strength)

    ShaderEffectSource {
        id: widgetsWall
        anchors.fill: parent
        visible: false
        sourceItem: widgetsRoot.glass ? widgetsRoot.wallpaperView.textureItem : null
        live: true
    }
    Repeater {
        model: widgetsRoot.on && widgetsRoot.glass ? [
            Qt.rect(widgetsRoot.plateX, widgetsRoot.plateY, widgetsRoot.wide, widgetsRoot.unit),
            Qt.rect(widgetsRoot.plateX + widgetsRoot.wide + widgetsRoot.gap, widgetsRoot.plateY, widgetsRoot.unit, widgetsRoot.unit)
        ] : []
        ClippingRectangle {
            id: frost
            required property rect modelData
            x: frost.modelData.x
            y: frost.modelData.y
            width: frost.modelData.width
            height: frost.modelData.height
            radius: widgetsRoot.plateRadius
            color: "transparent"
            MultiEffect {
                x: -frost.x
                y: -frost.y
                width: widgetsRoot.width
                height: widgetsRoot.height
                source: widgetsWall
                autoPaddingEnabled: false
                blurEnabled: true
                blur: AtollStyle.glassBlurAmount
                blurMax: AtollStyle.glassBlurMax
                saturation: AtollStyle.glassSaturation
            }
        }
    }

    Rectangle {
        visible: widgetsRoot.on
        x: widgetsRoot.plateX
        y: widgetsRoot.plateY
        width: widgetsRoot.wide
        height: widgetsRoot.unit
        radius: widgetsRoot.plateRadius
        color: widgetsRoot.plateColor
        border.width: widgetsRoot.rimShown && !widgetsRoot.edgeLit ? 1 : 0
        border.color: widgetsRoot.clear || AtollStyle.rim.a === 0 ? AtollStyle.clearRim : AtollStyle.rim
        AtollGlassEdge { anchors.fill: parent; visible: widgetsRoot.edgeLit; radius: parent.radius }
        InstrumentRing {
            anchors.fill: parent
            anchors.margins: Math.round(4 * widgetsRoot.d)
            visible: widgetsRoot.instrument
            fraction: DateTime.clock.date.getMinutes() / 60
            ink: AtollStyle.onMedia
            accent: widgetsRoot.ink
            accentSoft: AtollStyle.secondaryAccent
            showArc: false
            showComet: false
            animated: false
        }
        ColumnLayout {
            anchors.left: parent.left; anchors.bottom: parent.bottom
            anchors.margins: Math.round(18 * widgetsRoot.d)
            anchors.bottomMargin: widgetsRoot.instrument ? Math.round(44 * widgetsRoot.d) : Math.round(18 * widgetsRoot.d)
            anchors.leftMargin: widgetsRoot.instrument ? Math.round(60 * widgetsRoot.d) : Math.round(18 * widgetsRoot.d)
            spacing: 0
            AtollText { text: Translation.locale.toString(DateTime.clock.date, "dddd"); color: widgetsRoot.ink; font.weight: widgetsRoot.weight; font.pixelSize: AtollStyle.typeHeadline }
            AtollText {
                text: Translation.locale.toString(DateTime.clock.date, "hh:mm")
                font.family: AtollStyle.fontNumbers
                font.weight: widgetsRoot.weight
                font.pixelSize: (widgetsRoot.instrument ? 36 : 52) * AtollStyle.typeScale
                style: widgetsRoot.clear ? Text.Raised : Text.Normal
                styleColor: AtollStyle.plateShadow
            }
        }
    }
    Rectangle {
        visible: widgetsRoot.on
        x: widgetsRoot.plateX + widgetsRoot.wide + widgetsRoot.gap
        y: widgetsRoot.plateY
        width: widgetsRoot.unit
        height: widgetsRoot.unit
        radius: widgetsRoot.plateRadius
        color: widgetsRoot.plateColor
        border.width: widgetsRoot.rimShown && !widgetsRoot.edgeLit ? 1 : 0
        border.color: widgetsRoot.clear || AtollStyle.rim.a === 0 ? AtollStyle.clearRim : AtollStyle.rim
        AtollGlassEdge { anchors.fill: parent; visible: widgetsRoot.edgeLit; radius: parent.radius }
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(18 * widgetsRoot.d)
            spacing: Math.round(2 * widgetsRoot.d)
            MaterialSymbol { text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"; fill: 1; iconSize: Math.round(30 * widgetsRoot.d); color: widgetsRoot.ink }
            Item { Layout.fillHeight: true }
            AtollText { text: String(Weather.data?.temp ?? "18°"); font.family: AtollStyle.fontNumbers; font.weight: widgetsRoot.weight; font.pixelSize: 34 * AtollStyle.typeScale }
            AtollText { text: Weather.data?.city ?? Translation.tr("Weather"); color: AtollStyle.subtext; elide: Text.ElideRight; Layout.fillWidth: true }
        }
    }
    OffState { visible: !widgetsRoot.on; text: Translation.tr("Desktop widgets off") }
    Caption {
        glyph: widgetsRoot.bare ? "avg_pace" : widgetsRoot.glass ? "blur_on" : widgetsRoot.clear ? "select" : "square"
        text: !widgetsRoot.on ? ""
            : widgetsRoot.instrument ? Translation.tr("Dials, scales and ruled lists")
            : widgetsRoot.design === "readout" ? Translation.tr("Quiet figures and open lists")
            : !widgetsRoot.atoll ? Translation.tr("Each widget keeps its Material design")
            : widgetsRoot.glass && Boolean(widgetsRoot.opt("atoll.widgets.brightWallpapers", false)) ? Translation.tr("Frosted wallpaper · turns to frost over a bright wallpaper")
            : widgetsRoot.glass ? Translation.tr("Frosted wallpaper · darker only where the wallpaper is bright")
            : widgetsRoot.clear ? Translation.tr("Bare wallpaper · a veil only where text needs it")
            : widgetsRoot.material === "tinted" ? Translation.tr("Black material with a trace of the wallpaper hue")
            : Translation.tr("The Island's black material")
    }
}
