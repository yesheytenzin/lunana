import "../../../services"
import QtQuick
import ".."

OsdValueIndicator {
    id: osdValues
    value: Audio.micVolume
    icon: Audio.micMuted ? "mic_off" : "mic"
    name: Translation.tr("Mic")
}
