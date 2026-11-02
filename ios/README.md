# BoxingClock — iOS

iOS version of BoxingClock for personal use. SwiftUI port of the Android app
(Kotlin + Jetpack Compose), without a paid Apple Developer account.

## Prerequisites

- macOS with Xcode 16 or newer
- A free Apple ID (yours is enough)
- The target iPhone, with Developer Mode enabled
  (Settings → Privacy & Security → Developer Mode — iOS 16+)

## Build

1. Open `BoxingClock.xcodeproj` in Xcode.
2. Xcode → Settings → Accounts: add your Apple ID if you haven't already.
3. Select the BoxingClock project → *BoxingClock* target → *Signing &
   Capabilities* tab: check *Automatically manage signing* and choose your
   *Personal Team*.
4. Plug in the iPhone, select it as the destination, then `Cmd+R`.
5. On first launch, if iOS refuses to open the app:
   Settings → General → VPN & Device Management → approve your developer
   profile.

## Important notes

- **7-day validity**: the app is signed with a free profile. After 7 days it
  refuses to open — plugging the iPhone back in and pressing `Cmd+R` renews it
  in place (settings and presets are kept). Count on ~2 minutes per week.
- **Never change the bundle ID** (`com.antoinelabpixel.boxingclock`): the free
  quota is limited to 10 App IDs / 7 days.
- **Smoother build**: Product → Scheme → Edit Scheme → Run → Info →
  Build Configuration → *Release* (the timer and animations stay lightweight).
- Wi-Fi debugging is possible after the first wired connection
  (Window → Devices and Simulators → *Connect via network*).

## Audio behavior

Sounds play through `AVAudioSession` `.playback` + `.duckOthers`: they are
audible even when the iPhone is in silent mode, and any playing music ducks
during the bell then comes back — the closest equivalent to the Android alarm
stream.

## Android / F-Droid impact

None. F-Droid only builds from tags; this folder is inert for Gradle (F-Droid
recipe: `subdir: app`). The Android version is only republished when a
`v<version>` tag is pushed on `main`.

## If the project won't open in your Xcode version

The `project.pbxproj` targets Xcode 16+ (folder-synchronized groups). If you
run into a problem: File → New → Project → iOS App (name `BoxingClock`,
SwiftUI interface, Swift language), then replace the generated `BoxingClock/`
folder with the one from this repo and set up the target: iOS 17+, bundle ID
`com.antoinelabpixel.boxingclock`, portrait + landscape orientations.