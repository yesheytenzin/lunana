pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../common"
import "../../atoll/style"

Singleton {
    id: root

    readonly property bool atoll: (Config.options?.panelFamily ?? "drift") === "atoll"

    readonly property color colOnLayer0: root.atoll ? AtollStyle.text : Appearance.colors.colOnLayer0
    readonly property color colOnLayer1: root.atoll ? AtollStyle.text : Appearance.colors.colOnLayer1
    readonly property color colOnLayer2: root.atoll ? AtollStyle.text : Appearance.colors.colOnLayer2
    readonly property color colOnLayer3: root.atoll ? AtollStyle.text : Appearance.colors.colOnLayer3
    readonly property color colOnSurface: root.atoll ? AtollStyle.text : Appearance.colors.colOnSurface
    readonly property color colSubtext: root.atoll ? AtollStyle.textSecondary : Appearance.colors.colSubtext

    readonly property color colLayer0: root.atoll ? AtollStyle.bodySurface : Appearance.colors.colLayer0
    readonly property color colSurfaceContainer: root.atoll ? AtollStyle.bodySurface : Appearance.colors.colSurfaceContainer
    readonly property color colLayer1Hover: root.atoll ? AtollStyle.fillHover : Appearance.colors.colLayer1Hover
    readonly property color colLayer2: root.atoll ? AtollStyle.fill : Appearance.colors.colLayer2
    readonly property color colLayer2Hover: root.atoll ? AtollStyle.fillHover : Appearance.colors.colLayer2Hover
    readonly property color colLayer2Active: root.atoll ? AtollStyle.fillActive : Appearance.colors.colLayer2Active
    readonly property color colLayer3: root.atoll ? AtollStyle.fill : Appearance.colors.colLayer3
    readonly property color colLayer3Hover: root.atoll ? AtollStyle.fillHover : Appearance.colors.colLayer3Hover
    readonly property color colLayer3Active: root.atoll ? AtollStyle.fillActive : Appearance.colors.colLayer3Active

    readonly property color colPrimary: root.atoll ? AtollStyle.accent : Appearance.colors.colPrimary
    readonly property color colPrimaryContainer: root.atoll ? AtollStyle.tintFill(AtollStyle.accent) : Appearance.colors.colPrimaryContainer
    readonly property color colPrimaryContainerHover: root.atoll ? AtollStyle.tintFillHover(AtollStyle.accent) : Appearance.colors.colPrimaryContainerHover
    readonly property color colPrimaryContainerActive: root.atoll ? AtollStyle.tintFillHover(AtollStyle.accent) : Appearance.colors.colPrimaryContainerActive
    readonly property color colOnPrimaryContainer: root.atoll ? AtollStyle.accent : Appearance.colors.colOnPrimaryContainer
    readonly property color colSecondaryContainer: root.atoll ? AtollStyle.fill : Appearance.colors.colSecondaryContainer
    readonly property color colRecessed: root.atoll ? AtollStyle.fillQuiet : Appearance.colors.colSecondaryContainer

    readonly property color colError: root.atoll ? AtollStyle.danger : Appearance.colors.colError
    readonly property color colErrorActive: root.atoll ? AtollStyle.tintFillHover(AtollStyle.danger) : Appearance.colors.colErrorActive
    readonly property color colErrorContainer: root.atoll ? AtollStyle.tintFill(AtollStyle.danger) : Appearance.colors.colErrorContainer
    readonly property color colOnErrorContainer: root.atoll ? AtollStyle.danger : Appearance.colors.colOnErrorContainer

    readonly property real roundingSmall: root.atoll ? AtollStyle.radiusRow : Appearance.rounding.small
    readonly property real roundingNormal: root.atoll ? AtollStyle.radiusTile : Appearance.rounding.normal
    readonly property string fontNumbers: root.atoll ? AtollStyle.fontNumbers : Appearance.font.family.numbers

    readonly property var titles: ({
        crosshair: "Crosshair", fpsLimiter: "FPS limiter", floatingImage: "Floating image", recorder: "Recorder",
        resources: "Resources", gamePerformance: "Game Performance", notes: "Notes", discord: "Discord", volumeMixer: "Volume mixer", notifications: "Notifications"
    })
}
