pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-A load stub.
// PlayerControl checks `YtMusic.mpvPlayer` to route playback; null renders
// the plain Mpris path until the live-media unit vendors the real service.
Singleton {
    property var mpvPlayer: null
    property bool isPlaying: false
    property string currentVideoId: ""
    property string currentArtist: ""
    property string currentTitle: ""
    property string currentThumbnail: ""
    function togglePlaying() {}
}
