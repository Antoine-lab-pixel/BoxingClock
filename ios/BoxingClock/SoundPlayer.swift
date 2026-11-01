import Foundation

/// The four alarm sounds of the app, plus the in-app volume knob.
/// Previews and tests use the null player.
protocol SoundPlaying: AnyObject {
    /// Playback volume, 0.0–1.0 — never the system volume.
    var volume: Float { get set }

    func playBell()
    func playClapper()
    func playThirtySeconds()
    func playEndRounds()
}

/// No-op player — used in previews and tests, and before the audio layer
/// exists. Volume is accepted and ignored.
final class NullSoundPlayer: SoundPlaying {
    var volume: Float = 1.0

    func playBell() {}
    func playClapper() {}
    func playThirtySeconds() {}
    func playEndRounds() {}
}