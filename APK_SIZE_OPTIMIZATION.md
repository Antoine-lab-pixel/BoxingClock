# APK Size Optimization

Current installed size: ~44MB. Main cause is `isMinifyEnabled = false` — the full Compose + Material3 + Kotlin runtime is bundled with no dead-code removal.

Sound files are not the main culprit (bell 704K, clapper 284K, end 772K — total ~1.76MB).

## 1. Enable R8 shrinking — biggest win (~20-25MB saved)

In `app/build.gradle.kts`, update the release build type:

```kotlin
release {
    isMinifyEnabled = true
    isShrinkResources = true
    proguardFiles(
        getDefaultProguardFile("proguard-android-optimize.txt"),
        "proguard-rules.pro"
    )
}
```

R8 tree-shakes unused code from all libraries and shrinks/obfuscates what remains. Typically cuts installed size by more than half for a Compose app.

## 2. Convert WAV → OGG Vorbis (~1.2MB saved)

WAV is uncompressed. OGG Vorbis compresses audio by ~80% with no perceptible quality loss for short sound effects. Android supports OGG natively.

- Convert `bell.wav`, `clapper.wav`, `end.wav` to OGG using Audacity or ffmpeg:
  ```bash
  ffmpeg -i bell.wav -c:a libvorbis -q:a 4 bell.ogg
  ffmpeg -i clapper.wav -c:a libvorbis -q:a 4 clapper.ogg
  ffmpeg -i end.wav -c:a libvorbis -q:a 4 end.ogg
  ```
- Replace the files in `app/src/main/res/raw/`
- No code changes needed — `MediaPlayer.create(context, R.raw.bell)` works the same with OGG

## 3. Distribute as Android App Bundle (AAB)

Publish an AAB instead of an APK to the Play Store. Google Play then delivers only the resources and code relevant to each device (screen density, CPU architecture). Reduces download size by 15-40% on top of other optimizations. Does not affect locally installed size.

Build AAB via Android Studio: **Build → Generate Signed Bundle / APK → Android App Bundle**
