import Foundation

/// `UserDefaults` + `Codable` persistence — the iOS counterpart of the
/// Android DataStore `SettingsRepository`. The 3 presets are stored as one
/// JSON array; the selected index and the in-app alarm volume have their own
/// keys. Missing or malformed data falls back to defaults, like the
/// `prefs[key] ?: default` reads on Android.
final class UserDefaultsPresetStore: PresetStoring {

    private let defaults: UserDefaults
    private let presetsKey = "boxingclock.presets"
    private let selectedKey = "boxingclock.selectedPreset"
    private let alarmVolumeKey = "boxingclock.alarmVolume"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Presets

    func loadPresets() -> [TimerSettings] {
        guard let data = defaults.data(forKey: presetsKey),
              let presets = try? JSONDecoder().decode([TimerSettings].self, from: data),
              presets.count == 3 else {
            return Array(repeating: TimerSettings(), count: 3)
        }
        return presets
    }

    func savePreset(_ preset: TimerSettings, at index: Int) {
        var presets = loadPresets()
        guard presets.indices.contains(index) else { return }
        presets[index] = preset
        if let data = try? JSONEncoder().encode(presets) {
            defaults.set(data, forKey: presetsKey)
        }
    }

    // MARK: - Selected preset

    func loadSelectedPreset() -> Int {
        min(max(0, defaults.integer(forKey: selectedKey)), 2)
    }

    func saveSelectedPreset(_ index: Int) {
        defaults.set(index, forKey: selectedKey)
    }

    // MARK: - Alarm volume

    func loadAlarmVolume() -> Float {
        let stored = defaults.float(forKey: alarmVolumeKey)
        // float() returns 0.0 both for "unset" and a genuine 0 — fall back to
        // the default only when nothing was ever stored.
        guard defaults.object(forKey: alarmVolumeKey) != nil else { return 1.0 }
        return min(max(stored, 0.0), 1.0)
    }

    func saveAlarmVolume(_ volume: Float) {
        defaults.set(volume, forKey: alarmVolumeKey)
    }
}