import SwiftUI

@main
struct TapFrenzyApp: App {
    init() {
        // UI tests pass "--reset" so every run starts with no saved scores and the default round length
        if CommandLine.arguments.contains("--reset") {
            for mode in GameMode.allCases {
                UserDefaults.standard.removeObject(forKey: mode.bestScoreKey)
            }
            UserDefaults.standard.removeObject(forKey: RoundLength.storageKey)
        }
    }

    var body: some Scene {
        WindowGroup {
            // The stack starts on Home. Pushed screens get a Back button automatically.
            NavigationStack {
                HomeView()
            }
            .preferredColorScheme(.dark)
        }
    }
}