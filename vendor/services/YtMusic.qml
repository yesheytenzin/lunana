pragma Singleton
import QtQuick
import Quickshell

// LUNANA STUB, KEPT (R3 decision) — no local API exists.
// YtMusic is inir's in-process mpv-backed YouTube Music client (mpv socket,
// Config resume state, network search): not a system service queryable over
// D-Bus/IPC, and vendoring it would drag Config+mpv machinery in against
// the no-whole-modules constraint. The bar tree only reads `isPlaying`
// (visualizer spectrum gate) plus mpvPlayer-gated branches that
// short-circuit when mpvPlayer is null — `false` degrades gracefully to
// Mpris-only detection via MprisController.isPlaying.
Singleton {
    property var mpvPlayer: null
    property bool isPlaying: false
    property string currentVideoId: ""
    property string currentArtist: ""
    property string currentTitle: ""
    property string currentThumbnail: ""
    function togglePlaying() {}
}
