pragma Singleton
import QtQuick
import Quickshell

// LUNANA STUB (not vendored from inir) — Wave-B load stub.
// WeatherButton reads visibleCity/data/describeWeather; widgets panels
// read moon/air-quality fields. Optional chaining + fallbacks in the UI
// make nulls safe. Real weather backing lands with the weather unit.
Singleton {
    property var data: null
    property string visibleCity: ""
    property bool showVisibleCity: false
    property string updatedLabel: ""
    property string moonPhaseName: ""
    property real moonIllumination: 0
    property var airQuality: ({})

    function getData() {}
    function isNightNow() { return false }
    function describeWeather(wCode) { return "" }
}
