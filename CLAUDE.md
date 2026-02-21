# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Boxing Clock is a native Android interval timer app for boxing training. Built with Kotlin, Jetpack Compose (Material3), and MVVM architecture. Targets Android 12+ (minSdk 24, compileSdk 36, Java 21).

## Build & Test

This project is built and tested using Android Studio. Do not run build or test commands yourself — the developer handles all building and testing through the IDE.

## Architecture

### Navigation & Entry Point

`MainActivity` creates the `TimerViewModel` (via `TimerViewModelFactory`) and sets the Compose content root. `BoxingClockApp` is a `NavHost` with two routes: `main` (the timer screen) and `settings`.

### State Management

`TimerViewModel` (extends `AndroidViewModel`) is the single source of truth, exposing two `StateFlow`s:
- `_timerState: StateFlow<TimerState>` — live timer display data (phase, time remaining, round, running state)
- `_settings: StateFlow<TimerSettings>` — user configuration (prep/work/rest durations, rounds, clapper toggle)

Settings are not persisted to disk; they reset on app restart.

### Timer State Machine

Phases cycle in order: `PREPARATION` (once) → `WORK` → `REST` → `WORK` → `REST` → ... until rounds complete. A coroutine ticks every 1000ms. When `rounds == 0`, the work-rest cycle runs infinitely.

Audio cues (via `MediaPlayer`, released in `onCleared()`):
- `bell.wav` — every phase transition
- `clapper.wav` — 10 seconds before end of WORK phase (if enabled in settings)
- `end.wav` — all rounds complete

### Phase Colors

Defined in `ui/theme/Color.kt`: PREPARATION = Yellow, WORK = Green, REST = Red.

### Custom UI Components

`ui/components/Pickers.kt` contains `WheelPicker` (scrollable snapping list), `TimePicker` (two `WheelPicker`s for MM:SS), and `RoundsPicker` (single picker, with ∞ for 0 rounds).

### Key Files

| File | Purpose |
|------|---------|
| `TimerViewModel.kt` | Timer loop, phase transitions, audio playback |
| `model/Models.kt` | `TimerState`, `TimerSettings`, `Phase` enum |
| `ui/screens/MainScreen.kt` | Timer display, color-coded background, play/pause/reset |
| `ui/screens/SettingsScreen.kt` | Settings UI with pickers |
| `ui/components/Pickers.kt` | Reusable wheel picker components |
| `res/raw/` | `bell.wav`, `clapper.wav`, `end.wav` |
