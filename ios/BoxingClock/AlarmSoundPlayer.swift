import AVFoundation

/// AVAudioPlayer-backed sound player — the iOS counterpart of the Android
/// `MediaPlayer` on the alarm stream.
///
/// Session strategy: category `.playback` + `.duckOthers`, but the session is
/// only activated around actual playback. Background music is ducked *while a
/// bell plays* and comes back right after — the closest equivalent of
/// `USAGE_ALARM` behavior — instead of being ducked for the whole app
/// lifetime.
///
/// Everything audio — player creation, `prepareToPlay()`, session activation,
/// playback — runs on one dedicated serial queue. None of those calls may
/// happen on the main thread (iOS logs UI-unresponsiveness warnings for
/// `setActive`/`prepareToPlay` called there). The queue also guarantees
/// ordering: the load block is enqueued at init, before any `play()`, so the
/// sounds always exist by the first bell.
final class AlarmSoundPlayer: NSObject, SoundPlaying, AVAudioPlayerDelegate {

    /// In-app playback volume (0.0–1.0). Does not touch the system volume.
    /// Written from the main thread, read at play() call time before hopping
    /// to the queue.
    var volume: Float = 1.0

    /// Serial queue owning the audio session, the players and `current`.
    private let sessionQueue = DispatchQueue(
        label: "com.antoinelabpixel.boxingclock.audiosession",
        qos: .userInitiated
    )

    private enum Sound: CaseIterable {
        case bell
        case clapper
        case end
        case thirtySeconds

        var fileName: String {
            switch self {
            case .bell: "bell"
            case .clapper: "clapper"
            case .end: "end"
            case .thirtySeconds: "thirty_seconds"
            }
        }
    }

    /// Queue-owned. Empty until the async load at init completes; a missing
    /// file just never plays (silent skip, like the Android try/catch).
    private var players: [Sound: AVAudioPlayer] = [:]

    /// The sound currently playing — the next one cuts it, like the Android
    /// `MediaPlayer.release()` + `create()` cycle. Queue-owned.
    private var current: AVAudioPlayer?

    override init() {
        super.init()

        let session = AVAudioSession.sharedInstance()
        sessionQueue.async {
            try? session.setCategory(.playback, mode: .default, options: [.duckOthers])

            for sound in Sound.allCases {
                let player = Self.load(sound.fileName)
                player?.delegate = self
                self.players[sound] = player
            }
        }
    }

    /// Sounds live in `ios/BoxingClock/Resources/Sounds/`, picked up by the
    /// folder-synchronized group. Try the bundle root first (regular groups
    /// flatten), then the subdirectory (folder references keep it).
    /// Must be called on sessionQueue.
    private static func load(_ name: String) -> AVAudioPlayer? {
        let url = Bundle.main.url(forResource: name, withExtension: "m4a")
            ?? Bundle.main.url(forResource: name, withExtension: "m4a", subdirectory: "Resources/Sounds")
        guard let url else { return nil }
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        return player
    }

    // MARK: - SoundPlaying

    func playBell() { play(.bell) }
    func playClapper() { play(.clapper) }
    func playThirtySeconds() { play(.thirtySeconds) }
    func playEndRounds() { play(.end) }

    private func play(_ sound: Sound) {
        let volume = self.volume

        sessionQueue.async { [weak self] in
            guard let self, let player = self.players[sound] else { return }

            self.current?.stop()
            self.current = player
            try? AVAudioSession.sharedInstance().setActive(true)
            player.volume = volume
            player.currentTime = 0
            player.play()
        }
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Hop to the queue whatever thread the callback arrives on — that is
        // where `current` lives.
        sessionQueue.async { [weak self] in
            guard let self, player === self.current else { return }
            self.current = nil

            // Let background music return to full volume.
            try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        }
    }

    deinit {
        let session = AVAudioSession.sharedInstance()
        sessionQueue.async {
            try? session.setActive(false, options: [.notifyOthersOnDeactivation])
        }
    }
}