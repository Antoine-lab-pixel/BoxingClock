package com.example.boxingclock

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.example.boxingclock.model.TimerSettings
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "boxing_settings")

class SettingsRepository(private val context: Context) {

    companion object {
        val SELECTED_PRESET = intPreferencesKey("selected_preset")

        fun prepKey(i: Int) = intPreferencesKey("preset_${i}_prep")
        fun workKey(i: Int) = intPreferencesKey("preset_${i}_work")
        fun restKey(i: Int) = intPreferencesKey("preset_${i}_rest")
        fun roundsKey(i: Int) = intPreferencesKey("preset_${i}_rounds")
        fun clapperKey(i: Int) = booleanPreferencesKey("preset_${i}_clapper")
    }

    val selectedPreset: Flow<Int> = context.dataStore.data.map { prefs ->
        prefs[SELECTED_PRESET] ?: 0
    }

    val allPresets: Flow<List<TimerSettings>> = context.dataStore.data.map { prefs ->
        (0..2).map { i ->
            val defaults = TimerSettings()
            TimerSettings(
                preparationTime = prefs[prepKey(i)] ?: defaults.preparationTime,
                workTime = prefs[workKey(i)] ?: defaults.workTime,
                restTime = prefs[restKey(i)] ?: defaults.restTime,
                rounds = prefs[roundsKey(i)] ?: defaults.rounds,
                clapperEnabled = prefs[clapperKey(i)] ?: defaults.clapperEnabled
            )
        }
    }

    suspend fun savePreset(index: Int, settings: TimerSettings) {
        context.dataStore.edit { prefs ->
            prefs[prepKey(index)] = settings.preparationTime
            prefs[workKey(index)] = settings.workTime
            prefs[restKey(index)] = settings.restTime
            prefs[roundsKey(index)] = settings.rounds
            prefs[clapperKey(index)] = settings.clapperEnabled
        }
    }

    suspend fun saveSelectedPreset(index: Int) {
        context.dataStore.edit { prefs ->
            prefs[SELECTED_PRESET] = index
        }
    }
}
