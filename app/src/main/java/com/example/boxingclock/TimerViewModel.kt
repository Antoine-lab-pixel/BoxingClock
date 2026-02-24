package com.example.boxingclock

import android.app.Application
import android.media.AudioAttributes
import android.media.MediaPlayer
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.boxingclock.model.Phase
import com.example.boxingclock.model.TimerSettings
import com.example.boxingclock.model.TimerState
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

class TimerViewModel(application: Application) : AndroidViewModel(application) {

    private val repository = SettingsRepository(application)

    private val _selectedPreset = MutableStateFlow(0)
    val selectedPreset: StateFlow<Int> = _selectedPreset.asStateFlow()

    private val _allPresets = MutableStateFlow(List(3) { TimerSettings() })
    val allPresets: StateFlow<List<TimerSettings>> = _allPresets.asStateFlow()

    private val _settings = MutableStateFlow(TimerSettings())
    val settings: StateFlow<TimerSettings> = _settings.asStateFlow()

    private val _timerState = MutableStateFlow(TimerState())
    val timerState: StateFlow<TimerState> = _timerState.asStateFlow()

    private val alarmAudioAttributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_ALARM)
        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
        .build()

    private val _isMuted = MutableStateFlow(false)
    val isMuted: StateFlow<Boolean> = _isMuted.asStateFlow()

    fun toggleMute() { _isMuted.value = !_isMuted.value }

    private var timerJob: Job? = null
    private var mediaPlayer: MediaPlayer? = null
    private var clapperPlayed = false
    private var thirtySecondsPlayed = false

    init {
        viewModelScope.launch {
            val presets = repository.allPresets.first()
            val selected = repository.selectedPreset.first()
            _allPresets.value = presets
            _selectedPreset.value = selected
            _settings.value = presets[selected]
            resetTimer()
        }
    }

    fun selectPreset(index: Int) {
        _selectedPreset.value = index
        _settings.value = _allPresets.value[index]
        viewModelScope.launch {
            repository.saveSelectedPreset(index)
        }
        resetTimer()
    }

    fun updateSettings(newSettings: TimerSettings) {
        val index = _selectedPreset.value
        _settings.value = newSettings
        _allPresets.value = _allPresets.value.toMutableList().also { it[index] = newSettings }
        viewModelScope.launch {
            repository.savePreset(index, newSettings)
        }
        resetTimer()
    }

    fun startTimer() {
        if (_timerState.value.isRunning) return

        _timerState.value = _timerState.value.copy(isRunning = true, hasStarted = true)

        timerJob = viewModelScope.launch {
            while (_timerState.value.isRunning) {
                delay(1000)
                tick()
            }
        }
    }

    fun pauseTimer() {
        _timerState.value = _timerState.value.copy(isRunning = false)
        timerJob?.cancel()
    }

    fun resetTimer() {
        pauseTimer()
        val sets = _settings.value
        _timerState.value = TimerState(
            currentPhase = Phase.PREPARATION,
            timeRemaining = sets.preparationTime,
            totalPhaseTime = sets.preparationTime,
            currentRound = 0
        )
        clapperPlayed = false
        thirtySecondsPlayed = false
    }

    private fun tick() {
        val state = _timerState.value
        val newTimeRemaining = state.timeRemaining - 1

        if (state.currentPhase == Phase.WORK &&
            newTimeRemaining == 11 &&
            _settings.value.clapperEnabled &&
            !clapperPlayed) {
            playClapper()
            clapperPlayed = true
        }

        if (state.currentPhase == Phase.WORK &&
            newTimeRemaining == 30 &&
            state.totalPhaseTime > 30 &&
            _settings.value.thirtySecondsEnabled &&
            !thirtySecondsPlayed) {
            playThirtySeconds()
            thirtySecondsPlayed = true
        }

        if (newTimeRemaining < 1) {
            advancePhase()
        } else {
            _timerState.value = state.copy(timeRemaining = newTimeRemaining)
        }
    }

    private fun advancePhase() {
        val state = _timerState.value
        val sets = _settings.value

        when (state.currentPhase) {
            Phase.PREPARATION -> {
                if (sets.bellEnabled) playBell()
                _timerState.value = state.copy(
                    currentPhase = Phase.WORK,
                    currentRound = 1,
                    timeRemaining = sets.workTime,
                    totalPhaseTime = sets.workTime
                )
                clapperPlayed = false
                thirtySecondsPlayed = false
            }
            Phase.WORK -> {
                val totalRounds = if (sets.rounds == 0) Int.MAX_VALUE else sets.rounds

                if (state.currentRound < totalRounds) {
                    if (sets.bellEnabled) playBell()
                    _timerState.value = state.copy(
                        currentPhase = Phase.REST,
                        timeRemaining = sets.restTime,
                        totalPhaseTime = sets.restTime
                    )
                } else {
                    if (sets.endBellEnabled) playEndRounds()
                    resetTimer()
                }
            }
            Phase.REST -> {
                if (sets.bellEnabled) playBell()
                _timerState.value = state.copy(
                    currentPhase = Phase.WORK,
                    currentRound = state.currentRound + 1,
                    timeRemaining = sets.workTime,
                    totalPhaseTime = sets.workTime
                )
                clapperPlayed = false
                thirtySecondsPlayed = false
            }
        }
    }

    private fun playSound(resId: Int) {
        if (_isMuted.value) return
        try {
            mediaPlayer?.release()
            mediaPlayer = MediaPlayer.create(getApplication(), resId, alarmAudioAttributes, 0)
            mediaPlayer?.start()
        } catch (e: Exception) {
            // Handle error silently
        }
    }

    private fun playThirtySeconds() = playSound(R.raw.thirty_seconds)
    private fun playClapper() = playSound(R.raw.clapper)
    private fun playBell() = playSound(R.raw.bell)
    private fun playEndRounds() = playSound(R.raw.end)

    override fun onCleared() {
        super.onCleared()
        timerJob?.cancel()
        mediaPlayer?.release()
    }
}
