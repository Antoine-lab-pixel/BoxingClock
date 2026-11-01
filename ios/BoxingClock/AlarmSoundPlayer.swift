import AVFoundation

/// AVAudioPlayer-backed sound player — the iOS counterpart of the Android
/// `MediaPlayer` on the alarm stream.
///
/// Session strategy: category `.playback` + `.duckOthers` is set once, but the
/// session is only activated around actual playback. That way background
/// music is ducked *while a bell plays* and comes back right after — the
/// closest equivalent of `USAGE_ALARM` behavior — instead of being ducked for
/// the whole app lifetime.
final class AlarmSoundPlayer: NSObject, SoundPlaying, AVAudioPlayerDelegate {

    /// In-app playback volume (0.0–1.0). Does not touch the system volume.
    var volume: Float = 1.0

    private let bell: AVAudioPlayer?
    private let clapper: AVAudioPlayer?
    private let end: AVAudioPlayer?
    private let thirtySeconds: AVAudioPlayer?

    /// The sound currently playing — the next one cuts it, like the Android
    /// `MediaPlayer.release()` + `create()` cycle.
    private var current: AVAudioPlayer?

    override init() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.duckOthers])

        bell = AlarmSoundPlayer.load("bell")
        clapper = AlarmSoundPlayer.load("clapper")
        end = AlarmSoundPlayer.load("end")
        thirtySeconds = AlarmSoundPlayer.load("thirty_seconds")

        super.init()

        [bell, clapper, end, thirtySeconds].forEach { $0?.delegate = self }
    }

    /// Sounds live in `ios/BoxingClock/Resources/Sounds/`, picked up by the
    /// folder-synchronized group. Try the bundle root first (regular groups
    /// flatten), then the subdirectory (folder references keep it).
    private static func load(_ name: String) -> AVAudioPlayer? {
        let url = Bundle.main.url(forResource: name, withExtension: "m4a")
            ?? Bundle.main.url(forResource: name, withExtension: "m4a", subdirectory: "Resources/Sounds")
        guard let url else { return nil }
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        return player
    }

    // MARK: - SoundPlaying

    func playBell() { play(bell) }
    func playClapper() { play(clapper) }
    func playThirtySeconds() { play(thirtySeconds) }
    func playEndRounds() { play(end) }

    private func play(_ player: AVAudioPlayer?) {
        guard let player else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        current?.stop()
        current = player
        player.volume = volume
        player.currentTime = 0
        player.play()
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard player === current else { return }
        current = nil
        // Let background music return to full volume.
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    deinit {
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}