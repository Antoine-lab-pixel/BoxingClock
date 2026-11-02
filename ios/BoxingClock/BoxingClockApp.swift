import SwiftUI

@main
struct BoxingClockApp: App {
    // Shared across screens: the timer keeps running while you browse the
    // settings, exactly like the shared Android ViewModel.
    @State private var viewModel = TimerViewModel(
        soundPlayer: AlarmSoundPlayer(),
        presetStore: UserDefaultsPresetStore()
    )

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainScreen(viewModel: viewModel)
            }
        }
    }
}