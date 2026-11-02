import SwiftUI

/// Port of `SettingEditScreen.kt` — wheel pickers for the durations and the
/// round count, with an OK button that commits and pops.
struct SettingEditScreen: View {
    let settingKey: String
    let viewModel: TimerViewModel

    @Environment(\.dismiss) private var dismiss

    // Local state seeded from the current preset, like the Android `remember`
    @State private var minutes: Int
    @State private var seconds: Int
    @State private var rounds: Int

    init(settingKey: String, viewModel: TimerViewModel) {
        self.settingKey = settingKey
        self.viewModel = viewModel
        let settings = viewModel.settings

        switch settingKey {
        case "preparation":
            _minutes = State(initialValue: settings.preparationTime / 60)
            _seconds = State(initialValue: settings.preparationTime % 60)
        case "work":
            _minutes = State(initialValue: settings.workTime / 60)
            _seconds = State(initialValue: settings.workTime % 60)
        case "rest":
            _minutes = State(initialValue: settings.restTime / 60)
            _seconds = State(initialValue: settings.restTime % 60)
        default:
            _minutes = State(initialValue: 0)
            _seconds = State(initialValue: 0)
        }
        _rounds = State(initialValue: settings.rounds)
    }

    private var title: String {
        switch settingKey {
        case "preparation": "Prep"
        case "work": "Work"
        case "rest": "Rest"
        case "rounds": "Rounds"
        default: ""
        }
    }

    var body: some View {
        VStack(spacing: 40) {
            switch settingKey {
            case "preparation", "work", "rest":
                TimePickerView(minutes: $minutes, seconds: $seconds)
            case "rounds":
                RoundsPickerView(rounds: $rounds)
            default:
                EmptyView()
            }

            Button {
                var settings = viewModel.settings
                switch settingKey {
                case "preparation": settings.preparationTime = minutes * 60 + seconds
                case "work": settings.workTime = minutes * 60 + seconds
                case "rest": settings.restTime = minutes * 60 + seconds
                case "rounds": settings.rounds = rounds
                default: break
                }
                viewModel.updateSettings(settings)
                dismiss()
            } label: {
                Text("OK")
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 160)
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(title)
    }
}

// MARK: - Pickers

/// Minutes 0–60 / seconds 0–59 wheel pickers — the iOS wheel is the native
/// equivalent of the Android snap-scroll `WheelPicker`. Row text is 34 pt
/// (2× the default) so the rows and digits are comfortably tappable.
struct TimePickerView: View {
    @Binding var minutes: Int
    @Binding var seconds: Int

    var body: some View {
        HStack {
            wheelColumn(label: "Min", selection: $minutes, items: (0...60).map { "\($0)" }, width: 160)
            Text(":")
                .font(.system(size: 40, weight: .bold))
                .padding(.horizontal, 12)
            wheelColumn(label: "Sec", selection: $seconds, items: (0...59).map { String(format: "%02d", $0) }, width: 160)
        }
    }

    private func wheelColumn(label: String, selection: Binding<Int>, items: [String], width: CGFloat) -> some View {
        VStack(spacing: 10) {
            Text(label)
                .font(.system(size: 20, weight: .bold))
            Picker(label, selection: selection) {
                ForEach(items.indices, id: \.self) { index in
                    Text(items[index])
                        .font(.system(size: 34, weight: .bold))
                        .tag(index)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: width, height: 200)
        }
    }
}

/// ∞ (0) + rounds 1–20.
struct RoundsPickerView: View {
    @Binding var rounds: Int

    private let items: [String] = ["∞"] + (1...20).map { "\($0)" }

    var body: some View {
        VStack(spacing: 10) {
            Text("Rounds")
                .font(.system(size: 20, weight: .bold))
            // Index doubles as the value: 0 = ∞, 1–20 = round count
            Picker("Rounds", selection: $rounds) {
                ForEach(items.indices, id: \.self) { index in
                    Text(items[index])
                        .font(.system(size: 34, weight: .bold))
                        .tag(index)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 160, height: 200)
        }
    }
}

#Preview {
    NavigationStack {
        SettingEditScreen(settingKey: "work", viewModel: TimerViewModel())
    }
}