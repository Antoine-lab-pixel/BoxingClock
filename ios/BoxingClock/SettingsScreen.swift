import SwiftUI

/// Port of `SettingsScreen.kt` — preset selector, duration rows, alarm volume
/// slider, sound toggles. Uses system colors so dark mode comes for free.
struct SettingsScreen: View {
    let viewModel: TimerViewModel

    /// The setting being edited, pushed to `SettingEditScreen`.
    @State private var editKey: String?

    var body: some View {
        // Preset selector fixed above the scroll area, like the Android layout
        VStack(spacing: 0) {
            presetSelector

            ScrollView {
                VStack(spacing: 0) {
                    settingRow(label: "Prep", value: formatDuration(viewModel.settings.preparationTime)) {
                        editKey = "preparation"
                    }
                    divider

                    settingRow(label: "Work", value: formatDuration(viewModel.settings.workTime)) {
                        editKey = "work"
                    }
                    divider

                    settingRow(label: "Rest", value: formatDuration(viewModel.settings.restTime)) {
                        editKey = "rest"
                    }
                    divider

                    settingRow(label: "Rounds", value: viewModel.settings.rounds == 0 ? "∞" : "\(viewModel.settings.rounds)") {
                        editKey = "rounds"
                    }
                    divider

                    volumeSlider
                    divider

                    toggleRow(title: "Bell", subtitle: "Sound at every phase transition", keyPath: \.bellEnabled)
                    divider
                    toggleRow(title: "End bell", subtitle: "Sound when all rounds are complete", keyPath: \.endBellEnabled)
                    divider
                    toggleRow(title: "Clapper", subtitle: "10s left in round at the end of the sound", keyPath: \.clapperEnabled)
                    divider
                    toggleRow(title: "30s reminder", subtitle: "Sound when 30s of work time remain", keyPath: \.thirtySecondsEnabled)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Settings")
        .navigationDestination(item: $editKey) { key in
            SettingEditScreen(settingKey: key, viewModel: viewModel)
        }
    }

    // MARK: - Preset selector

    private var presetSelector: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                let isSelected = viewModel.selectedPreset == index
                Button("\(index + 1)") {
                    viewModel.selectPreset(index)
                }
                .font(.system(size: 18, weight: isSelected ? .bold : .regular))
                .foregroundStyle(isSelected ? Color.white : Color.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.accentColor : Color.clear, in: Capsule())
            }
        }
        .padding(4)
        .background(Color(.secondarySystemBackground), in: Capsule())
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Rows

    private func settingRow(label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
                Text(value)
                    .font(.system(size: 20))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Divider().padding(.leading, 16)
    }

    private var volumeSlider: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.wave.2")
                .foregroundStyle(.secondary)
            Slider(
                value: Binding(
                    get: { Double(viewModel.alarmVolume) },
                    set: { viewModel.alarmVolume = Float($0) }
                ),
                in: 0...1
            )
            Text("\(Int((viewModel.alarmVolume * 100).rounded()))%")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func toggleRow(title: String, subtitle: String, keyPath: WritableKeyPath<TimerSettings, Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: settingBinding(keyPath))
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }

    /// Two-way binding on one field of the current preset — writes go through
    /// `updateSettings`, which persists and resets the timer (Android parity).
    private func settingBinding<T>(_ keyPath: WritableKeyPath<TimerSettings, T>) -> Binding<T> {
        Binding(
            get: { viewModel.settings[keyPath: keyPath] },
            set: { newValue in
                var settings = viewModel.settings
                settings[keyPath: keyPath] = newValue
                viewModel.updateSettings(settings)
            }
        )
    }

    // MARK: - Formatting (parity with SettingsScreen.kt)

    private func formatDuration(_ seconds: Int) -> String {
        if seconds >= 60 {
            String(format: "%d:%02d", seconds / 60, seconds % 60)
        } else {
            "\(seconds)s"
        }
    }
}

#Preview {
    NavigationStack {
        SettingsScreen(viewModel: TimerViewModel())
    }
}