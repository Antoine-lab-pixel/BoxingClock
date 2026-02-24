# BoxingClock
Simple Boxing clock / timer Android app that emphasizes readability. Built with Kotlin and Jetpack Compose.

## Features

- **Prep / Work / Rest** phases with configurable durations
- **Unlimited or fixed rounds** (∞ mode supported)
- **3 preset slots** — switch instantly between training configurations
- **Audio cues** — bell at each phase transition, clapper at 10s left, 30s reminder, end bell (each individually toggleable)
- **Alarm stream audio** — sounds stay audible even while music is playing
- **Mute/unmute** button on the main screen
- **Alarm volume** control in settings
- **Screen stays on** while the timer is running
- Portrait and landscape support with edge-to-edge UI

## Tech stack

- Kotlin + Jetpack Compose (Material3)
- MVVM — `TimerViewModel` + `StateFlow`
- DataStore for persistent settings
- `MediaPlayer` with `USAGE_ALARM` audio attributes
- Minimum SDK 24 — Target SDK 36

## Build

Open in Android Studio and run on a device or emulator.
