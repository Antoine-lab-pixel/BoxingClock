package com.example.boxingclock

import android.app.Application
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
import kotlinx.coroutines.launch

class TimerViewModel(application: Application) : AndroidViewModel(application) {
    private val _settings = MutableStateFlow(TimerSettings())
    val settings: StateFlow<TimerSettings> = _settings.asStateFlow()

    private val _timerState = MutableStateFlow(TimerState())
    val timerState: StateFlow<TimerState> = _timerState.asStateFlow()

    private var timerJob: Job? = null
    private var mediaPlayer: MediaPlayer? = null
    private var clapperPlayed = false

    fun updateSettings(newSettings: TimerSettings) {
        _settings.value = newSettings
        resetTimer()
    }

    fun startTimer() {
        if (_timerState.value.isRunning) return

        _timerState.value = _timerState.value.copy(isRunning = true)

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
    }

    private fun tick() {
        val state = _timerState.value
        val newTimeRemaining = state.timeRemaining - 1

        // Check for clapper (12s before end of work phase)
        if (state.currentPhase == Phase.WORK && 
            newTimeRemaining == 11 &&
            _settings.value.clapperEnabled && 
            !clapperPlayed) {
            playClapper()
            clapperPlayed = true
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
                playBell()
                // Move to first work round
                _timerState.value = state.copy(
                    currentPhase = Phase.WORK,
                    currentRound = 1,
                    timeRemaining = sets.workTime,
                    totalPhaseTime = sets.workTime
                )
                clapperPlayed = false
            }
            Phase.WORK -> {
                val totalRounds = if (sets.rounds == 0) Int.MAX_VALUE else sets.rounds
                
                if (state.currentRound < totalRounds) {
                    playBell()
                     // Move to rest
                    _timerState.value = state.copy(
                        currentPhase = Phase.REST,
                        timeRemaining = sets.restTime,
                        totalPhaseTime = sets.restTime
                    )
                } else {
                    // Finished all rounds
                    playEndRounds()
                    resetTimer()
                }
            }
            Phase.REST -> {
                playBell()
                // Next work round
                _timerState.value = state.copy(
                    currentPhase = Phase.WORK,
                    currentRound = state.currentRound + 1,
                    timeRemaining = sets.workTime,
                    totalPhaseTime = sets.workTime
                )
                clapperPlayed = false
            }
        }
    }

    private fun playClapper() {
        try {
            mediaPlayer?.release()
            mediaPlayer = MediaPlayer.create(getApplication(), R.raw.clapper)
            mediaPlayer?.start()
        } catch (e: Exception) {
            // Handle error silently
        }
    }

    private fun playBell() {
        try {
            mediaPlayer?.release()
            mediaPlayer = MediaPlayer.create(getApplication(), R.raw.bell)
            mediaPlayer?.start()
        } catch (e: Exception) {
            // Handle error silently
        }
    }

    private fun playEndRounds() {
        try {
            mediaPlayer?.release()
            mediaPlayer = MediaPlayer.create(getApplication(), R.raw.end)
            mediaPlayer?.start()
        } catch (e: Exception) {
            // Handle error silently
        }
    }

    override fun onCleared() {
        super.onCleared()
        timerJob?.cancel()
        mediaPlayer?.release()
    }
}
