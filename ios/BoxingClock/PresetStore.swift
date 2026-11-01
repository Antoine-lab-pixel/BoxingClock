import Foundation

/// Persistence seam for the 3 presets, the selected index and the in-app
/// alarm volume.
protocol PresetStoring: AnyObject {
    func loadPresets() -> [TimerSettings]
    func savePreset(_ preset: TimerSettings, at index: Int)
    func loadSelectedPreset() -> Int
    func saveSelectedPreset(_ index: Int)
    func loadAlarmVolume() -> Float
    func saveAlarmVolume(_ volume: Float)
}

/// Volatile store — every launch starts from the default presets.
final class InMemoryPresetStore: PresetStoring {
    private var presets: [TimerSettings]
    private var selected: Int
    private var alarmVolume: Float = 1.0

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

    func loadAlarmVolume() -> Float { alarmVolume }

    func saveAlarmVolume(_ volume: Float) { alarmVolume = volume }
}