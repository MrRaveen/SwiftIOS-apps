import Foundation

// The three phases of a round: waiting for the start, playing, and the result screen.
enum GamePhase {
    case idle
    case playing
    case over
}

// Launch arguments used by the UI tests.
enum LaunchFlags {
    // "--ui-testing" turns off the random trap and the combo in Tap Frenzy,
    // and makes Light It Up slower, so the UI tests can count exactly.
    static let uiTesting = CommandLine.arguments.contains("--ui-testing")
}

// Game settings and the small pure functions behind the UI.
// They live outside the view so they can be unit tested.
enum GameLogic {
    // Tap Frenzy round length in seconds
    static let duration: TimeInterval = 10

    // MARK: Combo (C1)

    // Two taps closer together than this (in seconds) build a combo.
    static let comboWindow: TimeInterval = 0.3
    // The multiplier never goes above this (x5), so the score stays fair.
    static let maxMultiplier = 5

    // The multiplier for the next tap.
    // - no previous tap, or the gap is longer than 300 ms -> back to x1
    // - gap is 300 ms or less -> one step higher, up to maxMultiplier
    static func nextMultiplier(current: Int, secondsSinceLastTap: TimeInterval?) -> Int {
        guard let gap = secondsSinceLastTap, gap <= comboWindow else { return 1 }
        return min(current + 1, maxMultiplier)
    }

    // MARK: Trap colour (C2)

    // How long the button stays red (seconds)
    static let trapDuration: TimeInterval = 0.5
    // Random wait between traps (seconds)
    static let trapGapRange: ClosedRange<TimeInterval> = 1.5...3.5
    // Points lost when you tap during a trap
    static let trapPenalty = 2

    // Score after a tap during a trap. It never goes below 0.
    static func scoreAfterTrapTap(score: Int) -> Int {
        max(0, score - trapPenalty)
    }

    // A trap starts when its time has come, but only if it can finish before the round ends.
    static func shouldStartTrap(now: Date, nextTrap: Date, roundEnd: Date) -> Bool {
        now >= nextTrap && roundEnd.timeIntervalSince(now) > trapDuration
    }

    // MARK: Timer bar, best score, status text

    // How much of the round is left, from 1.0 (full bar at the start) to 0.0 (time is up).
    // Values are clamped to 0...1.
    static func remainingFraction(timeLeft: TimeInterval, duration: TimeInterval = GameLogic.duration) -> Double {
        guard duration > 0 else { return 0 }
        let fraction = timeLeft / duration
        return min(max(fraction, 0), 1)
    }

    // The best score after a finished round: keep the higher of the two.
    static func updatedBest(currentBest: Int, score: Int) -> Int {
        max(currentBest, score)
    }

    // Text shown above the tap button depending on the phase.
    static func statusText(phase: GamePhase, timeLeft: TimeInterval, trapActive: Bool = false) -> String {
        switch phase {
        case .idle:
            return "Tap to start"
        case .playing:
            if trapActive { return "Trap! Don't tap!" }
            return String(format: "%.1fs left", max(timeLeft, 0))
        case .over:
            return "Times up!"
        }
    }
}

// MARK: - Game modes

// The two modes on the Home screen
enum GameMode: CaseIterable {
    case tapFrenzy
    case lightItUp

    var title: String {
        switch self {
        case .tapFrenzy: return "Tap Frenzy"
        case .lightItUp: return "Light It Up"
        }
    }

    // Each mode keeps its own best score
    var bestScoreKey: String {
        switch self {
        case .tapFrenzy: return "bestScore.tapFrenzy"
        case .lightItUp: return "bestScore.lightItUp"
        }
    }
}

// MARK: - Settings

// Round length choices for Light It Up (Settings sheet)
enum RoundLength: Int, CaseIterable, Identifiable {
    case short = 30
    case normal = 60
    case long = 90

    // Key used with @AppStorage
    static let storageKey = "roundLength"

    var id: Int { rawValue }
    var seconds: TimeInterval { TimeInterval(rawValue) }
    var title: String { "\(rawValue)s" }

    // Turns the saved number back into a choice. Anything unknown becomes 60s.
    static func from(stored: Int) -> RoundLength {
        RoundLength(rawValue: stored) ?? .normal
    }
}

// MARK: - Light It Up rules

enum LightItUpLogic {
    static let maxLives = 3

    // A new light comes every 1 to 2 seconds
    static let gapRange: ClosedRange<TimeInterval> = 1.0...2.0
    // The card stays dark at least this long before the next light
    static let restGap: TimeInterval = 0.25
    // Chance of two lit cards at once on the last level
    static let doubleLightChance = 0.5

    // The UI tests wait longer for the first light and keep lit cards lit 3x longer
    static var firstLightDelay: TimeInterval { LaunchFlags.uiTesting ? 2.5 : 0.8 }
    static var windowScale: Double { LaunchFlags.uiTesting ? 3 : 1 }

    // Time until the next light. On the first levels the lit window (1.5s, 1.2s)
    // is longer than the shortest gap (1s), so the gap is stretched to keep
    // only one card lit at a time.
    static func nextGap(level: Level, randomGap: TimeInterval, windowScale: Double = 1) -> TimeInterval {
        max(randomGap, level.litWindow * windowScale + restGap)
    }

    // How many cards light up now. roll is a random number from 0 to 1.
    static func litCount(for level: Level, roll: Double) -> Int {
        guard level.allowsDoubleLight else { return 1 }
        return roll < doubleLightChance ? 2 : 1
    }

    // A wrong tap or a missed card costs one life
    static func livesAfterMistake(_ lives: Int) -> Int {
        max(0, lives - 1)
    }

    static func isOutOfLives(_ lives: Int) -> Bool {
        lives <= 0
    }
}