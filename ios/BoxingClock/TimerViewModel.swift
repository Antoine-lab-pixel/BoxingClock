import Foundation
import Observation

/// Port of the Android `TimerViewModel` (StateFlow → @Observable).
///
/// Main-thread confined, like its Android counterpart whose `viewModelScope`
/// runs on `Dispatchers.Main`: all mutations happen from SwiftUI actions and
/// from a `Timer` scheduled on the main run loop.
///
/// The countdown is anchored on the wall clock instead of a `sleep(1)` loop:
/// `phaseEndDate` is set once when a phase starts (or the timer resumes) and
/// every tick recomputes the remaining seconds from `Date()`. A late timer
/// fire therefore never accumulates drift — the Android `delay(1000)` version
/// loses a few milliseconds per tick, which adds up over a long session.
@Observable
final class TimerViewModel {

    // MARK: - Presets & settings

    private(set) var selectedPreset: Int = 0
    private(set) var allPresets: [TimerSettings] = Array(repeating: TimerSettings(), count: 3)
    private(set) var settings: TimerSettings = TimerSettings()

    // MARK: - Timer state

    private(set) var timerState: TimerState = TimerState()
    private(set) var isMuted: Bool = false

    /// In-app alarm volume (0.0–1.0), persisted and pushed to the player.
    /// Never touches the system volume — the closest iOS equivalent of the
    /// Android alarm-stream volume setting.
    var alarmVolume: Float = 1.0 {
        didSet {
            presetStore.saveAlarmVolume(alarmVolume)
            soundPlayer.volume = alarmVolume
        }
    }

    // MARK: - Dependencies

    private let soundPlayer: SoundPlaying
    private let presetStore: PresetStoring

    // MARK: - Tick engine

    private var tickTimer: Timer?
    /// Wall-clock instant the current phase must end. `nil` while paused.
    private var phaseEndDate: Date?
    private var clapperPlayed = false
    private var thirtySecondsPlayed = false

    // MARK: - Init

    init(soundPlayer: SoundPlaying = NullSoundPlayer(),
         presetStore: PresetStoring = InMemoryPresetStore()) {
        self.soundPlayer = soundPlayer
        self.presetStore = presetStore

        let presets = presetStore.loadPresets()
        let selected = presetStore.loadSelectedPreset()
        allPresets = presets
        selectedPreset = selected
        settings = presets[selected]
        alarmVolume = presetStore.loadAlarmVolume()
        soundPlayer.volume = alarmVolume
        resetTimer()
    }

    // MARK: - Presets

    func selectPreset(_ index: Int) {
        selectedPreset = index
        settings = allPresets[index]
        presetStore.saveSelectedPreset(index)
        resetTimer()
    }

    func updateSettings(_ newSettings: TimerSettings) {
        let index = selectedPreset
        settings = newSettings
        allPresets[index] = newSettings
        presetStore.savePreset(newSettings, at: index)
        resetTimer()
    }

    // MARK: - Mute

    func toggleMute() {
        isMuted.toggle()
    }

    // MARK: - Timer control

    func startTimer() {
        guard !timerState.isRunning else { return }

        timerState.isRunning = true
        timerState.hasStarted = true
        // Re-anchor the phase end from the frozen integer remaining value.
        phaseEndDate = Date().addingTimeInterval(TimeInterval(timerState.timeRemaining))
        startTicking()
    }

    func pauseTimer() {
        timerState.isRunning = false
        stopTicking()
    }

    func resetTimer() {
        pauseTimer()
        timerState = TimerState(
            currentPhase: .preparation,
            timeRemaining: settings.preparationTime,
            totalPhaseTime: settings.preparationTime,
            currentRound: 0
        )
        phaseEndDate = nil
        clapperPlayed = false
        thirtySecondsPlayed = false
    }

    // MARK: - Tick

    private func startTicking() {
        stopTicking()
        // 0.25 s cadence: the remaining time is recomputed from the wall
        // clock, so a late fire just shifts into the next computed second.
        tickTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopTicking() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    private func tick() {
        guard timerState.isRunning, let endDate = phaseEndDate else { return }

        let remaining = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
        guard remaining != timerState.timeRemaining else { return }
        let previous = timerState.timeRemaining

        // Sound cues — same thresholds and guards as the Android app.
        if timerState.currentPhase == .work {
            if settings.clapperEnabled, !clapperPlayed,
               previous > 11, remaining <= 11 {
                playClapper()
                clapperPlayed = true
            }
            if settings.thirtySecondsEnabled, !thirtySecondsPlayed,
               timerState.totalPhaseTime > 30,
               previous > 30, remaining <= 30 {
                playThirtySeconds()
                thirtySecondsPlayed = true
            }
        }

        if remaining < 1 {
            advancePhase()
        } else {
            timerState.timeRemaining = remaining
        }
    }

    // MARK: - Phase machine

    private func advancePhase() {
        switch timerState.currentPhase {

        case .preparation:
            playBell()
            timerState.currentPhase = .work
            timerState.currentRound = 1
            timerState.timeRemaining = settings.workTime
            timerState.totalPhaseTime = settings.workTime
            clapperPlayed = false
            thirtySecondsPlayed = false

        case .work:
            // rounds == 0 means unlimited rounds.
            let totalRounds = settings.rounds == 0 ? Int.max : settings.rounds

            if timerState.currentRound < totalRounds {
                playBell()
                timerState.currentPhase = .rest
                timerState.timeRemaining = settings.restTime
                timerState.totalPhaseTime = settings.restTime
            } else {
                if settings.endBellEnabled, !isMuted {
                    soundPlayer.playEndRounds()
                }
                resetTimer()
                return
            }

        case .rest:
            playBell()
            timerState.currentPhase = .work
            timerState.currentRound += 1
            timerState.timeRemaining = settings.workTime
            timerState.totalPhaseTime = settings.workTime
            clapperPlayed = false
            thirtySecondsPlayed = false
        }

        phaseEndDate = Date().addingTimeInterval(TimeInterval(timerState.timeRemaining))
    }

    // MARK: - Sounds

    private func playBell() {
        guard settings.bellEnabled, !isMuted else { return }
        soundPlayer.playBell()
    }

    private func playClapper() {
        guard !isMuted else { return }
        soundPlayer.playClapper()
    }

    private func playThirtySeconds() {
        guard !isMuted else { return }
        soundPlayer.playThirtySeconds()
    }

    deinit {
        stopTicking()
    }
}