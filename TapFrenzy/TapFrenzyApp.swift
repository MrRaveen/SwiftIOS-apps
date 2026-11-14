import SwiftUI

@main
struct TapFrenzyApp: App {
    init() {
        // UI tests pass "--reset" so every test run starts with no saved best score
        if CommandLine.arguments.contains("--reset") {
            UserDefaults.standard.removeObject(forKey: "bestScore")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
