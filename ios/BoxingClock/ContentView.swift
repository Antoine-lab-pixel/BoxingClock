import SwiftUI

/// Temporary bench for the ported timer logic. The full main screen (start
/// overlay, progress bar, per-phase colors, tap-to-pause) replaces this in
/// the main-screen PR — keep it minimal on purpose: live state, the three
/// controls, preset switching.
struct ContentView: View {
    @State private var viewModel = TimerViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Text(viewModel.timerState.currentPhase.title)
                .font(.title.bold())

            Text("\(viewModel.timerState.timeRemaining)")
                .font(.system(size: 88, weight: .black, design: .default))
                .contentTransition(.numericText())
                .monospacedDigit()

            Text("Round \(viewModel.timerState.roundLabel(totalRounds: viewModel.settings.rounds))")
                .foregroundStyle(.secondary)

            ProgressView(value: Double(viewModel.timerState.timeRemaining),
                         total: Double(max(1, viewModel.timerState.totalPhaseTime)))

            HStack(spacing: 24) {
                Button(viewModel.timerState.isRunning ? "Pause" : "Start") {
                    if viewModel.timerState.isRunning {
                        viewModel.pauseTimer()
                    } else {
                        viewModel.startTimer()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Reset") {
                    viewModel.resetTimer()
                }
                .buttonStyle(.bordered)

                Button(viewModel.isMuted ? "Unmute" : "Mute") {
                    viewModel.toggleMute()
                }
                .buttonStyle(.bordered)
            }

            Picker("Preset", selection: Binding(
                get: { viewModel.selectedPreset },
                set: { viewModel.selectPreset($0) }
            )) {
                ForEach(0..<3, id: \.self) { index in
                    Text("Preset \(index + 1)").tag(index)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}