pragma Singleton
import QtQuick
import Quickshell
// LUNANA SHIM — inir's per-output wallpaper URL provider (used by glass widgets).
// isVideoPath/isGifPath mirror inir's WallpaperListener; the animated-paper
// unit (mpvpaper detection) lands with the wallpaper wave.
Singleton {
    function wallpaperUrlForScreen(screen) { return "" }
    function isVideoPath(path: string): bool {
        if (!path) return false;
        const lower = String(path).toLowerCase();
        return lower.endsWith(".mp4") || lower.endsWith(".webm") || lower.endsWith(".mkv")
            || lower.endsWith(".avi") || lower.endsWith(".mov");
    }
    function isGifPath(path: string): bool {
        if (!path) return false;
        return String(path).toLowerCase().endsWith(".gif");
    }
}
