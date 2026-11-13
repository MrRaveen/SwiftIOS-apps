import Foundation

// The three phases of the game: waiting for the first tap, the 10 second round, and the result screen.
enum GamePhase {
    case idle
    case playing
    case over
}

// Game settings and the small pure functions behind the UI.
// They live outside the view so they can be unit tested.
enum GameLogic {
    // Round length in seconds
    static let duration: TimeInterval = 10

    // How much of the round has passed, from 0.0 (just started) to 1.0 (time is up).
    // Values outside the range are clamped so the progress bar never overflows.
    static func elapsedFraction(timeLeft: TimeInterval, duration: TimeInterval = GameLogic.duration) -> Double {
        guard duration > 0 else { return 1 }
        let fraction = (duration - timeLeft) / duration
        return min(max(fraction, 0), 1)
    }

    // The best score after a finished round: keep the higher of the two.
    static func updatedBest(currentBest: Int, score: Int) -> Int {
        max(currentBest, score)
    }

    // Text shown above the tap button depending on the phase.
    static func statusText(phase: GamePhase, timeLeft: TimeInterval) -> String {
        switch phase {
        case .idle:
            return "Tap to start"
        case .playing:
            return String(format: "%.1fs left", max(timeLeft, 0))
        case .over:
            return "Times up!"
        }
    }
}
