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

