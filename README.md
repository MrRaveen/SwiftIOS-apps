# Tap Frenzy

A small SwiftUI game. Tap the big blue button as many times as you can in 10 seconds.

- Phases: idle -> playing -> over
- State: `@State` for the round, `@AppStorage` for the saved best score
- Timer: `Timer.publish` (ticks every 0.05s, uses the real clock for accuracy)
- Works in portrait and landscape

## Extra features

**C1 - Combo.** If two taps come within 300 ms, the multiplier goes up (x2!, x3!, x4!, x5!).
Each tap then adds the multiplier to the score. A slower tap resets it to x1.
The multiplier is shown in orange next to the score. It stops at x5.

**C2 - Trap colour.** Every 1.5 to 3.5 seconds the button turns red for 0.5 seconds
(the status text says "Trap! Don't tap!"). A tap during the trap takes 2 points away
(the score never goes below 0) and resets the combo. A trap never starts if it
could not finish before the round ends.

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
| `TapFrenzy/ContentView.swift` | Both screens, the layouts and the game actions |
| `TapFrenzy/GameLogic.swift` | Phases, round length, combo and trap rules, small pure functions |
| `TapFrenzyTests/GameLogicTests.swift` | Unit tests for the pure functions |
| `TapFrenzyUITests/TapFrenzyUITests.swift` | UI tests: full round, rotation, saved best score |

## Run in Xcode

1. Double-click `TapFrenzy.xcodeproj`.
2. At the top of Xcode pick the scheme `TapFrenzy` and an iPhone simulator.
3. Press `Cmd + R`.

Minimum iOS version is 16.0, so any simulator from 16.0 up works (including 17.5).

## Test checklist (by hand)

- **Saved best score:** play a round, then force-quit the simulator app
  (`Cmd + Shift + H` twice, swipe the app up), open it again, play a round.
  "Best" must still show your old best score.
- **Fast tapping:** tap as fast as you can. Every tap must count.
- **Rotate:** Device -> Rotate Left / Rotate Right (`Cmd + Left/Right`). Everything must stay on screen.
- **Combo:** tap fast, "x2!" and up appears next to the score. Stop for a moment, it disappears.
- **Trap:** when the button turns red, tap it. The score must drop by 2.

The same checks for saved score and rotation also run as UI tests.
The UI tests start the app with `--ui-testing`, which turns off the random trap
and the combo so the taps can be counted exactly.

## CI

See `.github/workflows/ios-ci.yml`. It builds from the committed `TapFrenzy.xcodeproj`.
