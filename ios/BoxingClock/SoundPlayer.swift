import Foundation

/// The four alarm sounds of the app. The real implementation (AVAudioPlayer on
/// a `.playback` + `.duckOthers` session) arrives with the audio PR; until
/// then the null player keeps the logic testable in previews and on device.
protocol SoundPlaying: AnyObject {
    func playBell()
    func playClapper()
    func playThirtySeconds()
    func playEndRounds()
}

/// No-op player — used until the audio layer is wired in.
final class NullSoundPlayer: SoundPlaying {
    func playBell() {}
    func playClapper() {}
    func playThirtySeconds() {}
    func playEndRounds() {}
}