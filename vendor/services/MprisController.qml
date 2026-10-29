pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// LUNANA LIVE (R3) — backed by Quickshell.Services.Mpris.
//
// Replaces the Wave-A load stub: the exact ii bar (Media.qml) and the
// bar-anchored media popup (BarMediaPopup/PlayerControl/PlayerBase) drive
// playback through here. Member-for-member compatible with inir's
// MprisController for everything the bar/media tree touches; inir-only
// extras (YouTube hover-preview heuristics, PipeWire mixer routing,
// position-offset probing) are deliberately out — Audio stays untouched.
//
// YtMusic routing: MprisController.isYtMusicActive is always false here
// (see YtMusic.qml: no local API), so every YtMusic branch in the tree
// short-circuits to the plain MPRIS path below.
Singleton {
    id: root

    // --- player set (mirrors inir: prefer tracked, then playing, then first) ---
    readonly property var players: Mpris.players.values
    readonly property var displayPlayers: root.players
    property MprisPlayer trackedPlayer: null

    readonly property MprisPlayer activePlayer: {
        const ps = Mpris.players.values ?? [];
        if (root.trackedPlayer && ps.includes(root.trackedPlayer)) return root.trackedPlayer;
        for (let i = 0; i < ps.length; ++i) {
            if (ps[i] && ps[i].isPlaying) return ps[i];
        }
        return ps.length > 0 ? ps[0] : null;
    }

    readonly property bool isPlaying: !!(root.activePlayer && root.activePlayer.isPlaying)
    readonly property bool isYtMusicActive: false

    // --- metadata ---
    function titleOf(player): string { return String(player?.trackTitle ?? ""); }
    function artistOf(player): string { return String(player?.trackArtist ?? ""); }
    function artUrlOf(player): string { return String(player?.trackArtUrl ?? ""); }
    function effectiveArtUrl(player): string { return root.artUrlOf(player); }

    // --- position / length (seconds, MPRIS-native; no known-length cache) ---
    function lengthOf(player): real {
        if (!player || !player.lengthSupported) return 0;
        return Math.max(0, Number(player.length ?? 0));
    }
    function positionOf(player): real {
        if (!player) return 0;
        const len = root.lengthOf(player);
        const at = Number(player.position ?? 0);
        return Math.max(0, len > 0 ? Math.min(len, at) : at);
    }

    // --- volume (MPRIS-native; PipeWire mixer routing stays with Audio) ---
    // `volume` exists so Media.qml's `Connections { onVolumeChanged }`
    // attaches to a real notifier (inir parity).
    readonly property real volume: root.getVolume()
    readonly property bool canChangeVolume: !!(root.activePlayer && root.activePlayer.volumeSupported && root.activePlayer.canControl)
    function getVolume(): real {
        const p = root.activePlayer;
        if (!p || !p.volumeSupported || !p.canControl) return 0;
        return Math.max(0, Math.min(1, Number(p.volume ?? 0)));
    }
    function setVolume(vol: real): void {
        const p = root.activePlayer;
        if (!p || !p.volumeSupported || !p.canControl) return;
        p.volume = Math.max(0, Math.min(1, Number(vol ?? 0)));
    }

    // --- transport ---
    function togglePlaying(): void {
        const p = root.activePlayer;
        if (p && p.canTogglePlaying) p.togglePlaying();
    }
    function canGoPreviousForPlayer(player): bool { return !!(player && player.canGoPrevious); }
    function canGoNextForPlayer(player): bool { return !!(player && player.canGoNext); }
    readonly property bool canGoPrevious: root.canGoPreviousForPlayer(root.activePlayer)
    readonly property bool canGoNext: root.canGoNextForPlayer(root.activePlayer)
    function previousForPlayer(player): bool {
        if (root.canGoPreviousForPlayer(player)) { player.previous(); return true; }
        return false;
    }
    function nextForPlayer(player): bool {
        if (root.canGoNextForPlayer(player)) { player.next(); return true; }
        return false;
    }
    function previous(): bool { return root.previousForPlayer(root.activePlayer); }
    function next(): bool { return root.nextForPlayer(root.activePlayer); }

    // --- misc (inir parity for PlayerBase/selection callers) ---
    function seek(player, seconds: real): void {
        if (!player) return;
        player.position = Math.max(0, Number(seconds ?? 0));
    }
    function setActivePlayer(player): void { root.trackedPlayer = player; }
    function _isYtMusicMpv(player): bool { return false; }
    // Empty: PipeWire app-node mixing stays with the Audio service (untouched).
    property var mixerAppNodes: []
}
