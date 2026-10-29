pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-A load stub.
// The exact ii bar and media popup drive playback through here; null-safe
// callers (`?.`, `?? ""`) render "No media" until the live-mpris unit backs
// this with Quickshell.Services.Mpris.
Singleton {
    property var activePlayer: null
    property var displayPlayers: []
    property bool isPlaying: false
    property bool isYtMusicActive: false
    function artistOf(player) { return "" }
    function canChangeVolume(player) { return false }
    function canGoNextForPlayer(player) { return false }
    function canGoPreviousForPlayer(player) { return false }
    function effectiveArtUrl(player) { return "" }
    function getVolume(player) { return 0 }
    function lengthOf(player) { return 0 }
    function next() {}
    function nextForPlayer(player) {}
    function positionOf(player) { return 0 }
    function previous() {}
    function previousForPlayer(player) {}
    function seek(player, position) {}
    function setActivePlayer(player) {}
    function setVolume(player, volume) {}
    function titleOf(player) { return "" }
    property var trackedPlayer: null
    function _isYtMusicMpv(player) { return false }
}
