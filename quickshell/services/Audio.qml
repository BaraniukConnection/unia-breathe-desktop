pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Гучність і вимкнення звуку на поточному виході PipeWire.
Singleton {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: !!sink && !!sink.audio
    readonly property int volume: ready ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: ready && sink.audio.muted
    readonly property string device: sink ? (sink.description || sink.nickname || sink.name) : ""
    readonly property string icon: muted || volume === 0 ? "volume_off" : "volume_up"

    function setVolume(v) {
        if (!ready) return
        sink.audio.muted = false
        sink.audio.volume = Math.max(0, Math.min(100, v)) / 100
    }
    function toggleMute() { if (ready) sink.audio.muted = !sink.audio.muted }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
}
