package com.example.boxingclock.model

enum class Phase {
    PREPARATION,
    WORK,
    REST
}

data class TimerSettings(
    val preparationTime: Int = 10, // seconds
    val workTime: Int = 180, // 3 minutes
    val restTime: Int = 60, // 1 minute
    val rounds: Int = 3, // 0 means infinite
    val clapperEnabled: Boolean = true,
    val thirtySecondsEnabled: Boolean = true
)

data class TimerState(
    val currentPhase: Phase = Phase.PREPARATION,
    val timeRemaining: Int = 10,
    val totalPhaseTime: Int = 10, // Total duration of the current phase
    val currentRound: Int = 0,
    val isRunning: Boolean = false,
    val hasStarted: Boolean = false
)
