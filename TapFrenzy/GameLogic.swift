import Foundation

// The three phases of the game: waiting for the first tap, the 10 second round, and the result screen.
enum GamePhase {
    case idle
    case playing
    case over
}

// Launch arguments used by the UI tests.
enum LaunchFlags {
    // "--ui-testing" turns off the random trap and the combo,
    // so the UI test can count taps exactly.
    static let uiTesting = CommandLine.arguments.contains("--ui-testing")
}

// Game settings and the small pure functions behind the UI.
// They live outside the view so they can be unit tested.
enum GameLogic {
    // Round length in seconds
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
    // The bar shrinks as the round runs out. Values are clamped to 0...1.
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
