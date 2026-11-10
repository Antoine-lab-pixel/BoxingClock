import SwiftUI
import UIKit

// MARK: - Phase colors (parity with ui/theme/Color.kt)

private extension Color {
    static let phasePreparation = Color(red: 0xFD / 255, green: 0xD8 / 255, blue: 0x35 / 255) // yellow 600
    static let phaseWork = Color(red: 0x43 / 255, green: 0xA0 / 255, blue: 0x47 / 255)        // green 600
    static let phaseRest = Color(red: 0xE5 / 255, green: 0x39 / 255, blue: 0x35 / 255)        // red 600
    static let playIcon = Color(red: 0x2E / 255, green: 0x7D / 255, blue: 0x32 / 255)         // green 800
}

// MARK: - Main screen

/// Port of `MainScreen.kt` — full-screen phase-colored timer.
/// Portrait and landscape layouts mirror the Android ones; orientation is
/// derived from the vertical size class (iPhone-only target: compact only
/// while rotated), matching Android's orientation-based switch. Non-interactive
/// layers above the tap layer use `allowsHitTesting(false)` to reproduce
/// Compose's pass-through hit testing.
struct MainScreen: View {
    let viewModel: TimerViewModel
    @State private var showSettings = false

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isLandscape: Bool {
        // iPhone-only target: the vertical size class is compact only while
        // rotated. Follow the physical orientation (like Android's
        // orientation-based switch) instead of the horizontal size class —
        // which only turns regular on Max/Plus models — so every iPhone gets
        // the landscape layout (single-line MM:SS timer, bottom progress
        // bar, phase label in the top bar…).
        verticalSizeClass == .compact
    }

    private var backgroundColor: Color {
        switch viewModel.timerState.currentPhase {
        case .preparation: .phasePreparation
        case .work: .phaseWork
        case .rest: .phaseRest
        }
    }

    private var isInitialState: Bool { !viewModel.timerState.hasStarted }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            if isInitialState {
                startOverlay
            } else {
                runningContent
                tapLayer
                pausedOverlay
                progressIndicator
            }

            topBar
        }
        // Keep the screen on while the timer runs (FLAG_KEEP_SCREEN_ON parity).
        .onChange(of: viewModel.timerState.isRunning) { _, isRunning in
            UIApplication.shared.isIdleTimerDisabled = isRunning
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showSettings) {
            SettingsScreen(viewModel: viewModel)
        }
    }

    // MARK: Start overlay

    /// Full-screen, centered on the window (parity: `Alignment.Center`).
    private var startOverlay: some View {
        Color.clear
            .ignoresSafeArea()
            .overlay {
                if isLandscape {
                    landscapeStartOverlay
                } else {
                    portraitStartOverlay
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { viewModel.startTimer() }
    }

    private var portraitStartOverlay: some View {
        VStack(spacing: 0) {
            playIcon
            Text("Prep \(viewModel.timerState.timeRemaining)s")
                .font(.system(size: 64, weight: .black))
                .tracking(-1)
                .foregroundColor(.black)
            Text("TAP TO START")
                .font(.system(size: 16, weight: .bold))
                .tracking(4)
                .foregroundColor(.black.opacity(0.5))
                .padding(.top, 12)
        }
    }

    private var landscapeStartOverlay: some View {
        ZStack {
            playIcon
            Text("Prep \(viewModel.timerState.timeRemaining)s")
                .font(.system(size: 64, weight: .black))
                .tracking(-1)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.leading, 48)
            Text("TAP TO START")
                .font(.system(size: 32, weight: .bold))
                .tracking(4)
                .foregroundColor(.black.opacity(0.5))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .padding(.trailing, 48)
        }
    }

    private var playIcon: some View {
        Image(systemName: "play.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 180, height: 180)
            .foregroundColor(.playIcon)
    }

    // MARK: Running content

    /// Landscape-only downward shift of the timer's centering point: the
    /// timer is centered on the full screen, then pushed down by half this
    /// amount. With the hourglass bar now pinned at the physical top (20 pt)
    /// above the top bar strip (~140 pt), 140 keeps the digits' clearance
    /// under the strip at the previously tuned level (~17 pt). Higher = lower.
    private static let landscapeTopBarInset: CGFloat = 140

    /// Centered on the window, not on the safe area (parity with the root Box).
    private var runningContent: some View {
        Color.clear
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 8) {
                    if !isLandscape {
                        Text(viewModel.timerState.currentPhase.title)
                            .font(.system(size: 26, weight: .bold))
                            .tracking(10)
                            .foregroundColor(.black.opacity(0.45))
                    }
                    TimerDisplay(
                        timeInSeconds: viewModel.timerState.timeRemaining,
                        totalPhaseTime: viewModel.timerState.totalPhaseTime,
                        isLandscape: isLandscape
                    )
                }
                // Landscape: recenter below the top bar.
                .padding(.top, isLandscape ? Self.landscapeTopBarInset : 0)
            }
            .allowsHitTesting(false)
    }

    /// Full-screen tap to pause/resume — sits above the timer, below the
    /// paused overlay and top bar.
    private var tapLayer: some View {
        Color.clear
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
                if viewModel.timerState.isRunning {
                    viewModel.pauseTimer()
                } else {
                    viewModel.startTimer()
                }
            }
    }

    // MARK: Paused overlay

    @ViewBuilder
    private var pausedOverlay: some View {
        if !viewModel.timerState.isRunning {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            if isLandscape {
                // Landscape: PAUSED + RESET grouped centrally
                HStack(spacing: 48) {
                    pausedLabel(fontSize: 52)
                    resetButton
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            } else {
                // Portrait: PAUSED + RESET stacked at the physical bottom
                VStack(spacing: 8) {
                    pausedLabel(fontSize: 64)
                    resetButton
                }
                .padding(.bottom, 48)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }

    private func pausedLabel(fontSize: CGFloat) -> some View {
        Text("PAUSED")
            .font(.system(size: fontSize, weight: .black))
            .tracking(6)
            .foregroundColor(.white)
            .allowsHitTesting(false)
    }

    private var resetButton: some View {
        Button {
            viewModel.resetTimer()
        } label: {
            Text("RESET")
                .font(.system(size: 32, weight: .bold))
                .tracking(2)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.25), in: Capsule())
        }
    }

    // MARK: Progress indicator

    /// Vertical along the trailing edge in portrait, horizontal along the
    /// physical top in landscape (above the gear/mute row) — fill shrinks
    /// with the remaining time.
    private var progressIndicator: some View {
        let progress = Double(viewModel.timerState.timeRemaining)
            / Double(max(1, viewModel.timerState.totalPhaseTime))

        return Color.clear
            .ignoresSafeArea()
            .overlay(alignment: isLandscape ? .top : .trailing) {
                if isLandscape {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Color.black.opacity(0.12)
                            Color.black.opacity(0.35)
                                .frame(width: proxy.size.width * progress)
                        }
                    }
                    .frame(height: 20)
                    .ignoresSafeArea()
                } else {
                    GeometryReader { proxy in
                        ZStack(alignment: .bottom) {
                            Color.black.opacity(0.12)
                            Color.black.opacity(0.35)
                                .frame(height: proxy.size.height * progress)
                        }
                    }
                    .frame(width: 14)
                    .ignoresSafeArea()
                }
            }
            .allowsHitTesting(false)
    }

    // MARK: Top bar

    private var topBar: some View {
        ZStack {
            if isLandscape && !isInitialState {
                Text(viewModel.timerState.currentPhase.title)
                    .font(.system(size: 26, weight: .bold))
                    .tracking(10)
                    .foregroundColor(.black.opacity(0.45))
                    .allowsHitTesting(false)
            }

            HStack(alignment: .top) {
                if isInitialState {
                    VStack(alignment: .leading, spacing: 2) {
                        sessionInfoRow(label: "ROUNDS", value: viewModel.settings.rounds == 0 ? "∞" : "\(viewModel.settings.rounds)")
                        sessionInfoRow(label: "WORK", value: formatDuration(viewModel.settings.workTime))
                        sessionInfoRow(label: "REST", value: formatDuration(viewModel.settings.restTime))
                    }
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("ROUND")
                            .font(.system(size: 32, weight: .bold))
                            .tracking(3)
                            .foregroundColor(.black.opacity(0.55))
                            .allowsHitTesting(false)
                        Text(viewModel.timerState.roundLabel(totalRounds: viewModel.settings.rounds))
                            .font(.system(size: 64, weight: .black))
                            .tracking(-1)
                            .foregroundColor(.black)
                            .allowsHitTesting(false)
                    }
                }

                Spacer(minLength: 24)

                HStack(spacing: 4) {
                    Button {
                        viewModel.toggleMute()
                    } label: {
                        Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.black.opacity(0.7))
                            // 44 pt hit target (HIG) — the frame alone is not
                            // hittable, the contentShape makes it so.
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.black.opacity(0.7))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        // Landscape running: leave room for the hourglass bar pinned at the
        // physical top edge (20 pt) so it sits above the gear/mute row.
        .padding(.top, isLandscape && !isInitialState ? 20 : 0)
        // Inert strip: the top bar swallows taps (gear/mute area, round label,
        // landscape phase title, status bar) so a missed tap can't pause the
        // running round — the buttons keep priority over the parent gesture.
        .background(alignment: .top) {
            Color.clear
                .ignoresSafeArea(edges: .top)
                .contentShape(Rectangle())
                .onTapGesture { }
        }
        // The root ZStack centers its children by default — expand this bar
        // to full height, pinned to the top (parity: top bar of the root Box).
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func sessionInfoRow(label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 32, weight: .bold))
                .tracking(2)
                .foregroundColor(.black.opacity(0.55))
                .frame(width: 150, alignment: .leading)
                .allowsHitTesting(false)
            Text(value)
                .font(.system(size: 32, weight: .black))
                .foregroundColor(.black)
                .allowsHitTesting(false)
        }
    }

    // MARK: Formatting (parity with formatDuration in MainScreen.kt)

    private func formatDuration(_ seconds: Int) -> String {
        if seconds >= 60 {
            String(format: "%d:%02d", seconds / 60, seconds % 60)
        } else {
            "\(seconds)s"
        }
    }
}

// MARK: - Timer display

/// Port of `TimerDisplay` — the display modes and their typography. The
/// sub-60 s mode triggers on the remaining time (< 60 s), whatever the
/// phase's total length: the last minute of a long phase (Work, long rest…)
/// shows the same large single number as short phases (PREP…).
struct TimerDisplay: View {
    let timeInSeconds: Int
    let totalPhaseTime: Int
    let isLandscape: Bool

    private var minutes: Int { timeInSeconds / 60 }
    private var seconds: Int { timeInSeconds % 60 }

    var body: some View {
        switch (timeInSeconds < 60, isLandscape) {
        case (true, true):
            // Landscape sub-60 s: single large number
            timeText("\(timeInSeconds)", size: 270, tracking: -8)

        case (true, false):
            // Portrait sub-60 s: large single number
            timeText("\(timeInSeconds)", size: 403, tracking: -12)

        case (false, true):
            // Landscape with minutes remaining: single-line MM:SS
            timeText(String(format: "%02d:%02d", minutes, seconds), size: 256, tracking: -5)

        case (false, false):
            // Portrait with minutes remaining: stacked MM / SS
            VStack(spacing: 0) {
                timeText(String(format: "%02d", minutes), size: 200, tracking: -6)
                timeText(String(format: "%02d", seconds), size: 200, tracking: -6)
            }
        }
    }

    private func timeText(_ text: String, size: CGFloat, tracking: CGFloat) -> some View {
        Text(text)
            .font(.system(size: size, weight: .black))
            .tracking(tracking)
            .monospacedDigit()
            .foregroundColor(.black)
            // Safety net: at very large sizes a two-digit value (uniform
            // monospaced advance ≈ 0.6 em per digit) can exceed the screen
            // width — scale down just enough to fit instead of clipping.
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MainScreen(viewModel: TimerViewModel())
    }
}