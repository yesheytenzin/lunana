pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../../services"
import "../style"
import "../../background/widgets"

Singleton {
    id: root

    readonly property var galleryEntries: [
        { key: "clock", glyph: "schedule", english: "Clock", label: Translation.tr("Clock"), tint: AtollStyle.identity.orange },
        { key: "weather", glyph: "partly_cloudy_day", english: "Weather", label: Translation.tr("Weather"), tint: AtollStyle.identity.blue },
        { key: "mediaControls", glyph: "music_note", english: "Now Playing", label: Translation.tr("Now Playing"), tint: AtollStyle.identity.pink },
        { key: "controls", glyph: "toggle_on", english: "Controls", label: Translation.tr("Controls"), tint: AtollStyle.identity.blue },
        { key: "monthCalendar", glyph: "calendar_month", english: "Calendar", label: Translation.tr("Calendar"), tint: AtollStyle.identity.red },
        { key: "calendarUpcoming", glyph: "event_upcoming", english: "Up next", label: Translation.tr("Up next"), tint: AtollStyle.identity.red },
        { key: "todo", glyph: "checklist", english: "Tasks", label: Translation.tr("Tasks"), tint: AtollStyle.identity.orange },
        { key: "notes", glyph: "sticky_note_2", english: "Notes", label: Translation.tr("Notes"), tint: AtollStyle.identity.yellow },
        { key: "timers", glyph: "timer", english: "Timers", label: Translation.tr("Timers"), tint: AtollStyle.identity.orange },
        { key: "screenTime", glyph: "hourglass_bottom", english: "Screen Time", label: Translation.tr("Screen Time"), tint: AtollStyle.identity.indigo },
        { key: "systemMonitor", glyph: "monitor_heart", english: "Vitals", label: Translation.tr("Vitals"), tint: AtollStyle.identity.green },
        { key: "battery", glyph: "battery_full", english: "Batteries", label: Translation.tr("Batteries"), tint: AtollStyle.identity.green },
        { key: "worldClock", glyph: "public", english: "World clock", label: Translation.tr("World clock"), tint: AtollStyle.identity.orange },
        { key: "dayProgress", glyph: "wb_twilight", english: "Day", label: Translation.tr("Day"), tint: AtollStyle.identity.orange },
        { key: "dateBadge", glyph: "today", english: "Date", label: Translation.tr("Date"), tint: AtollStyle.identity.red },
        { key: "userCard", glyph: "account_circle", english: "Profile", label: Translation.tr("Profile"), tint: AtollStyle.identity.blue },
        { key: "uptime", glyph: "timelapse", english: "Uptime", label: Translation.tr("Uptime"), tint: AtollStyle.identity.indigo },
        { key: "newsTicker", glyph: "newspaper", english: "News", label: Translation.tr("News"), tint: AtollStyle.identity.teal }
    ]

    // Widgets without an Atoll face, listed wherever the set is: they count on the desktop and can be taken away.
    readonly property var otherEntries: [
        { key: "visualizer", glyph: DesktopWidgetIdentity.glyph("visualizer"), english: "Visualizer", label: Translation.tr("Visualizer"), tint: DesktopWidgetIdentity.tint("visualizer") },
        { key: "editorial", glyph: DesktopWidgetIdentity.glyph("editorial"), english: "Editorial", label: Translation.tr("Editorial"), tint: DesktopWidgetIdentity.tint("editorial") },
        { key: "mascot", glyph: DesktopWidgetIdentity.glyph("mascot"), english: "Mascot", label: Translation.tr("Mascot"), tint: DesktopWidgetIdentity.tint("mascot") },
        { key: "japaneseTypography", glyph: DesktopWidgetIdentity.glyph("japaneseTypography"), english: "Japanese Typography", label: Translation.tr("Japanese Typography"), tint: DesktopWidgetIdentity.tint("japaneseTypography") },
        { key: "customImage", glyph: DesktopWidgetIdentity.glyph("customImage"), english: "Image", label: Translation.tr("Image"), tint: DesktopWidgetIdentity.tint("customImage") },
        { key: "imageConverter", glyph: DesktopWidgetIdentity.glyph("imageConverter"), english: "Image converter", label: Translation.tr("Image converter"), tint: DesktopWidgetIdentity.tint("imageConverter") },
        { key: "shape", glyph: DesktopWidgetIdentity.glyph("shape"), english: "Shape", label: Translation.tr("Shape"), tint: DesktopWidgetIdentity.tint("shape") }
    ]

    function capitalized(text: string): string {
        const value = String(text ?? "")
        return value.length > 0 ? value.charAt(0).toUpperCase() + value.slice(1) : value
    }

    function eventDate(event: var): var {
        return new Date(event?.dateTime ?? event?.startDate ?? 0)
    }

    function upcomingEvents(from: var, days: int): var {
        const now = new Date(from)
        const local = Array.from(Events.getUpcomingEvents(days) ?? [])
        const external = Array.from(CalendarSync.getUpcomingEvents(days) ?? [])
        const today = new Date(now)
        today.setHours(0, 0, 0, 0)
        const allDay = Array.from(CalendarSync.getEventsForDate(today) ?? []).filter(event => event.allDay)
        return local.concat(external, allDay.filter(event => !external.includes(event)))
            .sort((a, b) => root.eventDate(a) - root.eventDate(b))
    }

    function hasEvents(date: var): bool {
        return (Events.getEventsForDate(date) ?? []).length > 0
            || (CalendarSync.getEventsForDate(date) ?? []).length > 0
    }

    function eventTitle(event: var): string {
        return String(event?.title || event?.summary || Translation.tr("Event"))
    }

    function eventTint(event: var, fallback: color): color {
        const tint = String(event?.sourceColor ?? "")
        return tint.length > 0 ? tint : fallback
    }

    function eventWhen(event: var, now: var): string {
        if (!event)
            return ""
        const when = root.eventDate(event)
        const today = new Date(now)
        today.setHours(0, 0, 0, 0)
        const day = new Date(when)
        day.setHours(0, 0, 0, 0)
        const days = Math.round((day.getTime() - today.getTime()) / 86400000)
        const time = event.allDay ? Translation.tr("All day")
            : Qt.locale().toString(when, Qt.locale().timeFormat(Locale.ShortFormat))
        const minutes = Math.round((when.getTime() - new Date(now).getTime()) / 60000)
        if (!event.allDay && minutes >= 0 && minutes < 60)
            return minutes < 1 ? Translation.tr("Now") : Translation.tr("In %1 min").arg(minutes)
        if (days === 0)
            return time
        if (days === 1)
            return Translation.tr("Tomorrow · %1").arg(time)
        return root.capitalized(Translation.locale.toString(when, "dddd")) + " · " + time
    }
}
