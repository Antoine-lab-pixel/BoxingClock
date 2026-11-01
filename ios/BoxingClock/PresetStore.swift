import Foundation

/// Persistence seam for the 3 presets and the selected index. The
/// `UserDefaults`-backed implementation arrives with the settings PR; the
/// in-memory store keeps the flow testable in the meantime.
protocol PresetStoring: AnyObject {
    func loadPresets() -> [TimerSettings]
    func savePreset(_ preset: TimerSettings, at index: Int)
    func loadSelectedPreset() -> Int
    func saveSelectedPreset(_ index: Int)
}

/// Volatile store — every launch starts from the default presets.
final class InMemoryPresetStore: PresetStoring {
    private var presets: [TimerSettings]
    private var selected: Int

    init(presets: [TimerSettings] = Array(repeating: TimerSettings(), count: 3),
         selected: Int = 0) {
        self.presets = presets
        self.selected = selected
    }

    func loadPresets() -> [TimerSettings] { presets }

    func savePreset(_ preset: TimerSettings, at index: Int) {
        guard presets.indices.contains(index) else { return }
        presets[index] = preset
    }

    func loadSelectedPreset() -> Int { selected }

    func saveSelectedPreset(_ index: Int) { selected = index }
}