# Tap Frenzy

A small SwiftUI game. Tap the big blue button as many times as you can in 10 seconds.

- Phases: idle -> playing -> over
- State: `@State` for the round, `@AppStorage` for the saved best score
- Timer: `Timer.publish` (ticks every 0.05s, uses the real clock for accuracy)

## Folder structure

    TapFrenzy/                      <- project root (open this folder)
    ├── TapFrenzy.xcodeproj/        <- the Xcode project (double-click this)
    ├── TapFrenzy/                  <- app source code
    │   ├── TapFrenzyApp.swift
    │   ├── ContentView.swift
    │   └── GameLogic.swift
    ├── TapFrenzyTests/
    │   └── GameLogicTests.swift
    ├── TapFrenzyUITests/
    │   └── TapFrenzyUITests.swift
    └── .github/workflows/ios-ci.yml

| File | What it does |
|---|---|
| `TapFrenzy/TapFrenzyApp.swift` | App entry point |
| `TapFrenzy/ContentView.swift` | Both screens and the game actions |
| `TapFrenzy/GameLogic.swift` | Phases, round length, small pure functions |
| `TapFrenzyTests/GameLogicTests.swift` | Unit tests for the pure functions |
| `TapFrenzyUITests/TapFrenzyUITests.swift` | UI test that plays one full round |

## Run in Xcode

1. Double-click `TapFrenzy.xcodeproj`.
2. At the top of Xcode pick the scheme `TapFrenzy` and an iPhone simulator.
3. Press `Cmd + R`.

Minimum iOS version is 16.0, so any simulator from 16.0 up works (including 17.5).

## CI

See `.github/workflows/ios-ci.yml`. It builds from the committed `TapFrenzy.xcodeproj`.
