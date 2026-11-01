import Foundation

/// The three phases of a training session, mirroring the Android `Phase` enum.
enum Phase: String, Codable {
    case preparation
    case work
    case rest

    /// Short label used on the main screen (parity with Android).
    var title: String {
        switch self {
        case .preparation: "PREP"
        case .work: "WORK"
        case .rest: "REST"
        }
    }
}

/// One preset: the 8 configurable values, defaults identical to Android.
struct TimerSettings: Codable, Equatable {
    var preparationTime: Int = 10        // seconds
    var workTime: Int = 180              // 3 minutes
    var restTime: Int = 60               // 1 minute
    var rounds: Int = 3                  // 0 means infinite
    var bellEnabled: Bool = true
    var endBellEnabled: Bool = true
    var clapperEnabled: Bool = true
    var thirtySecondsEnabled: Bool = true
}

/// Snapshot of the timer, mirroring the Android `TimerState`.
struct TimerState: Equatable {
    var currentPhase: Phase = .preparation
    var timeRemaining: Int = 10
    var totalPhaseTime: Int = 10         // total duration of the current phase
    var currentRound: Int = 0
    var isRunning: Bool = false
    var hasStarted: Bool = false

    /// `X / N`, or just `X` when rounds is infinite — parity with Android.
    func roundLabel(totalRounds: Int) -> String {
        totalRounds > 0 ? "\(currentRound) / \(totalRounds)" : "\(currentRound)"
    }
}