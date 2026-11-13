# Tap Frenzy

A small SwiftUI game. Tap the big blue button as many times as you can in 10 seconds.

- Phases: idle -> playing -> over
- State: `@State` for the round, `@AppStorage` for the saved best score
- Timer: `Timer.publish` (ticks every 0.05s, uses the real clock for accuracy)

## Files

| File | What it does |
|---|---|
| `TapFrenzy/TapFrenzyApp.swift` | App entry point |
| `TapFrenzy/ContentView.swift` | Both screens and the game actions |
| `TapFrenzy/GameLogic.swift` | Phases, round length, small pure functions |
| `TapFrenzyTests/GameLogicTests.swift` | Unit tests for the pure functions |
| `project.yml` | XcodeGen config, creates the Xcode project |

## Build

On a Mac:

    brew install xcodegen
    xcodegen generate
    open TapFrenzy.xcodeproj

In CI see `.github/workflows/ios.yml`.
