pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// LUNANA BACKING (R4) — weather over Omarchy's own source pattern.
//
// Source (copied from /usr/share/omarchy/shell/plugins/panels/weather):
// location comes from ~/.local/state/omarchy/settings/weather.json
// (owned by omarchy-weather-location; read-only here), falling back to
// geo.omarchy.org auto-detect, exactly like Omarchy's Panel.qml. Conditions
// come from wttr.in ?format=j1, air quality from open-meteo — the same two
// providers inir uses, but without inir's Config/Network/GPS machinery.
//
// Output shape mirrors inir's refined `data` (temp/tempFeelsLike/humidity/
// wind/windDir/uv/press/visib/precip/sunrise/sunset/wCode/forecast) so the
// Waffle widgets render unchanged. Metric-only; Network.online is still a
// stub (always false), so fetches are NOT gated on it — see note in commit.
// Empty-safe: data starts {} (weather sections hide), airQuality.available
// stays false until the AQI fetch succeeds.
Singleton {
    id: root

    property var data: ({})
    property var location: ({ valid: false, lat: 0, lon: 0, name: "" })
    property var airQuality: ({ available: false })
    property double lastUpdated: 0

    readonly property bool hasData: lastUpdated > 0
    readonly property string visibleCity: root.location?.name ?? ""
    readonly property bool showVisibleCity: root.visibleCity.length > 0
    readonly property string updatedLabel: {
        if (!root.hasData) return "--:--"
        const then = new Date(root.lastUpdated)
        const time = Qt.formatTime(then, "hh:mm")
        return then.toDateString() === new Date().toDateString()
            ? time : Qt.formatDate(then, "ddd") + " " + time
    }

    function isNightNow(): bool {
        const h = new Date().getHours()
        return h < 6 || h >= 18
    }

    // Local lunar phase from the synodic cycle (same math as inir).
    property int _clockTick: 0
    Timer { interval: 60000; repeat: true; running: true; onTriggered: root._clockTick++ }
    readonly property real moonAge: {
        root._clockTick
        const now = new Date()
        const ref = Date.UTC(2000, 0, 6, 18, 14, 0)
        const synodic = 29.530588853
        let age = ((now.getTime() - ref) / 86400000) % synodic
        if (age < 0) age += synodic
        return age
    }
    readonly property real moonIllumination: (1 - Math.cos(2 * Math.PI * (root.moonAge / 29.530588853))) / 2
    readonly property string moonPhaseName: {
        const age = root.moonAge
        if (age < 1.84566) return Translation.tr("New Moon")
        if (age < 5.53699) return Translation.tr("Waxing Crescent")
        if (age < 9.22831) return Translation.tr("First Quarter")
        if (age < 12.91963) return Translation.tr("Waxing Gibbous")
        if (age < 16.61096) return Translation.tr("Full Moon")
        if (age < 20.30228) return Translation.tr("Waning Gibbous")
        if (age < 23.99361) return Translation.tr("Last Quarter")
        if (age < 27.68493) return Translation.tr("Waning Crescent")
        return Translation.tr("New Moon")
    }

    function describeWeather(code, night): string {
        const weatherCode = String(code ?? "113")
        if (weatherCode === "113" && night === true) return Translation.tr("Clear")
        const descriptions = {
            "113": Translation.tr("Sunny"), "116": Translation.tr("Partly cloudy"),
            "119": Translation.tr("Cloudy"), "122": Translation.tr("Overcast"),
            "143": Translation.tr("Mist"), "176": Translation.tr("Light rain"),
            "179": Translation.tr("Light sleet"), "182": Translation.tr("Light sleet"),
            "185": Translation.tr("Light sleet"), "200": Translation.tr("Thunderstorm"),
            "227": Translation.tr("Light snow"), "230": Translation.tr("Heavy snow"),
            "248": Translation.tr("Fog"), "260": Translation.tr("Fog"),
            "263": Translation.tr("Light drizzle"), "266": Translation.tr("Light drizzle"),
            "281": Translation.tr("Freezing drizzle"), "284": Translation.tr("Freezing drizzle"),
            "293": Translation.tr("Light rain"), "296": Translation.tr("Light rain"),
            "299": Translation.tr("Moderate rain"), "302": Translation.tr("Heavy rain"),
            "305": Translation.tr("Heavy rain"), "308": Translation.tr("Heavy rain"),
            "311": Translation.tr("Freezing rain"), "314": Translation.tr("Freezing rain"),
            "317": Translation.tr("Sleet"), "320": Translation.tr("Light snow"),
            "323": Translation.tr("Light snow"), "326": Translation.tr("Light snow"),
            "329": Translation.tr("Moderate snow"), "332": Translation.tr("Moderate snow"),
            "335": Translation.tr("Heavy snow"), "338": Translation.tr("Heavy snow"),
            "350": Translation.tr("Ice pellets"), "353": Translation.tr("Light showers"),
            "356": Translation.tr("Moderate showers"), "359": Translation.tr("Heavy showers"),
            "362": Translation.tr("Sleet showers"), "365": Translation.tr("Sleet showers"),
            "368": Translation.tr("Snow showers"), "371": Translation.tr("Snow showers"),
            "374": Translation.tr("Ice pellets"), "377": Translation.tr("Ice pellets"),
            "386": Translation.tr("Thunderstorm"), "389": Translation.tr("Thunderstorm"),
            "392": Translation.tr("Thunderstorm"), "395": Translation.tr("Snow storm")
        }
        return descriptions[weatherCode] ?? Translation.tr("Unknown")
    }

    // -- location: Omarchy's weather.json, same shape Omarchy's Panel parses.
    FileView {
        id: locationFile
        path: Quickshell.env("HOME") + "/.local/state/omarchy/settings/weather.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root._applyLocationFile(text())
        onLoadFailed: root._applyLocationFile("")
    }

    function _applyLocationFile(raw): void {
        let name = "", lat = 0, lon = 0, valid = false
        try {
            const parsed = JSON.parse(String(raw || ""))
            if (parsed && typeof parsed === "object") {
                name = typeof parsed.name === "string" ? parsed.name.trim() : ""
                const la = parseFloat(parsed.latitude), lo = parseFloat(parsed.longitude)
                if (!isNaN(la) && !isNaN(lo)) { lat = la; lon = lo; valid = true }
                else if (name.length > 0) valid = true
            }
        } catch (e) {}
        const changed = root.location.name !== name || root.location.lat !== lat || root.location.lon !== lon
        root.location = { valid: valid, lat: lat, lon: lon, name: name }
        if (!valid) {
            root._detectLocation()
        } else if (changed) {
            root._fetchWeather()
        }
    }

    // Omarchy's own fallback: where geo.omarchy.org places this network.
    Process {
        id: geoProc
        command: ["curl", "-fsS", "--max-time", "4", "https://geo.omarchy.org/"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                let name = "", lat = 0, lon = 0
                try {
                    const parsed = JSON.parse(String(text || ""))
                    if (parsed && typeof parsed === "object") {
                        name = typeof parsed.name === "string" ? parsed.name.trim() : ""
                        const la = parseFloat(parsed.latitude), lo = parseFloat(parsed.longitude)
                        if (!isNaN(la) && !isNaN(lo)) { lat = la; lon = lo }
                    }
                } catch (e) {}
                if (name.length > 0 || (lat !== 0 && lon !== 0)) {
                    root.location = { valid: true, lat: lat, lon: lon, name: name }
                    root._fetchWeather()
                }
            }
        }
    }
    function _detectLocation(): void {
        if (!geoProc.running) geoProc.running = true
    }

    function _query(): string {
        if ((root.location.lat !== 0 || root.location.lon !== 0))
            return root.location.lat + "," + root.location.lon
        const name = (root.location.name ?? "").trim()
        return name.length > 0 ? encodeURIComponent(name.split(",")[0].trim()) : ""
    }

    // -- conditions: wttr.in j1, refined into inir's data shape (metric).
    Process {
        id: fetcher
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const raw = String(text || "").trim()
                if (!raw) return
                try {
                    root._refine(JSON.parse(raw))
                } catch (e) {}
            }
        }
    }

    function _refine(apiData): void {
        const current = apiData?.current_condition?.[0]
        if (!current) return
        const astro = apiData?.weather?.[0]?.astronomy?.[0] ?? ({})
        let result = {}
        result.uv = current.uvIndex ?? "0"
        result.humidity = (current.humidity ?? "0") + "%"
        result.sunrise = astro.sunrise ?? "--:--"
        result.sunset = astro.sunset ?? "--:--"
        result.windDir = current.winddir16Point ?? "N"
        result.wCode = current.weatherCode ?? "113"
        result.description = root.describeWeather(result.wCode, root.isNightNow())
        result.city = root.location.name || "Unknown"
        result.temp = (current.temp_C ?? "--") + "°C"
        result.tempFeelsLike = (current.FeelsLikeC ?? "--") + "°C"
        result.wind = (current.windspeedKmph ?? "--") + " km/h"
        result.precip = (current.precipMM ?? "--") + " mm"
        result.visib = (current.visibility ?? "--") + " km"
        result.press = (current.pressure ?? "--") + " hPa"

        const days = Array.isArray(apiData.weather) ? apiData.weather : []
        let forecast = []
        for (let i = 0; i < days.length; i++) {
            const d = days[i]
            const hi = d.maxtempC, lo = d.mintempC
            const code = d?.hourly?.[4]?.weatherCode ?? d?.hourly?.[0]?.weatherCode ?? "113"
            forecast.push({
                dayName: i === 0 ? Translation.tr("Today") : Qt.formatDate(new Date(d.date + "T12:00:00"), "ddd"),
                code: String(code),
                hi: (hi ?? "--") + "°C", lo: (lo ?? "--") + "°C",
                hiVal: parseFloat(hi), loVal: parseFloat(lo)
            })
        }
        result.forecast = forecast
        if (forecast.length > 0) { result.tempMax = forecast[0].hi; result.tempMin = forecast[0].lo }

        let hourly = []
        const nowH = new Date().getHours()
        for (let di = 0; di < Math.min(2, days.length); di++) {
            const hrs = days[di]?.hourly ?? []
            for (let hi2 = 0; hi2 < hrs.length; hi2++) {
                const h = hrs[hi2]
                const hour = Math.floor(parseInt(h.time ?? "0", 10) / 100)
                if (di === 0 && hour < nowH - 1) continue
                hourly.push({
                    label: (hour < 10 ? "0" + hour : "" + hour) + ":00",
                    temp: (h.tempC ?? "--") + "°",
                    code: String(h.weatherCode ?? "113"),
                    isNight: hour < 6 || hour >= 19
                })
            }
        }
        result.hourly = hourly.slice(0, 8)

        result.lastRefresh = Qt.formatTime(new Date(), "hh:mm")
        root.data = result
        root.lastUpdated = Date.now()
        if (root.location.lat !== 0 && root.location.lon !== 0)
            root._fetchAirQuality()
    }

    // -- air quality: open-meteo (same provider inir uses), US EPA scale.
    Process {
        id: aqiFetcher
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    const api = JSON.parse(String(text || ""))
                    const cur = api?.current
                    if (!cur || cur.us_aqi === undefined || cur.us_aqi === null) return
                    const aqi = Math.round(parseFloat(cur.us_aqi))
                    const label = aqi <= 50 ? "Good" : aqi <= 100 ? "Moderate"
                        : aqi <= 150 ? "USG" : aqi <= 200 ? "Unhealthy"
                        : aqi <= 300 ? "Very Unhealthy" : "Hazardous"
                    root.airQuality = {
                        available: true, aqi: String(aqi), scale: "US EPA", label: label,
                        pm25: String(cur.pm2_5 ?? "--"), pm10: String(cur.pm10 ?? "--"),
                        ozone: String(cur.ozone ?? "--")
                    }
                } catch (e) {}
            }
        }
    }
    function _fetchAirQuality(): void {
        if (aqiFetcher.running) return
        aqiFetcher.command = ["/usr/bin/curl", "-s", "--max-time", "10",
            "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=" + root.location.lat
            + "&longitude=" + root.location.lon + "&current=us_aqi,pm2_5,pm10,ozone&timezone=auto"]
        aqiFetcher.running = true
    }

    function _fetchWeather(): void {
        if (fetcher.running) return
        fetcher.command = ["/usr/bin/bash", "-c",
            "curl -s --max-time 15 'https://wttr.in/" + root._query() + "?format=j1'"]
        fetcher.running = true
    }

    function getData(): void {
        if (root.location.valid) root._fetchWeather()
        else {
            locationFile.reload()
            if (!root.location.valid) root._detectLocation()
        }
    }

    Timer {
        interval: 15 * 60 * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.getData()
    }
}
