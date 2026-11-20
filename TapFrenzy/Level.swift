import Foundation

// The four levels of Light It Up (60-second round shown; they scale with the round length)
//   L1  first 25%   3 cards in a row   1.5s window
//   L2  25% - 50%   4 cards (2x2)      1.2s window
//   L3  50% - 75%   6 cards (2x3)      1.0s window
//   L4  last 25%    9 cards (3x3)      0.8s window, two cards may light at once
enum Level: Int, CaseIterable {
    case l1 = 1, l2, l3, l4

    var number: Int { rawValue }
    var title: String { "L\(rawValue)" }

    var cardCount: Int {
        switch self {
        case .l1: return 3
        case .l2: return 4
        case .l3: return 6
        case .l4: return 9
        }
    }

    // Columns of the grid. This is what changes the grid shape.
    var columns: Int {
        switch self {
        case .l1: return 3   // one row of 3
        case .l2: return 2   // 2 x 2
        case .l3: return 3   // 2 rows of 3
        case .l4: return 3   // 3 x 3
        }
    }

    var rows: Int { (cardCount + columns - 1) / columns }

    // How long a lit card stays lit (seconds)
    var litWindow: TimeInterval {
        switch self {
        case .l1: return 1.5
        case .l2: return 1.2
        case .l3: return 1.0
        case .l4: return 0.8
        }
    }

    // Only the last level can light two cards at the same time
    var allowsDoubleLight: Bool { self == .l4 }

    // Short text for the level-up flash
    var note: String {
        switch self {
        case .l1: return "Warm-up"
        case .l2: return "Focus up!"
        case .l3: return "Scan the grid!"
        case .l4: return "Two cards can light at once!"
        }
    }

    // The level for the time that has passed. Each level takes a quarter of the round.
    static func forElapsed(_ elapsed: TimeInterval, roundLength: TimeInterval) -> Level {
        guard roundLength > 0 else { return .l1 }
        let fraction = elapsed / roundLength
        switch fraction {
        case ..<0.25: return .l1
        case ..<0.5:  return .l2
        case ..<0.75: return .l3
        default:      return .l4
        }
    }
}