import Foundation

struct Card: Identifiable {
    let id: Int
    var isLit: Bool
    // When the lit card goes dark by itself. nil while the card is off.
    var expiresAt: Date? = nil

    // A fresh board of dark cards
    static func makeCards(count: Int) -> [Card] {
        (0..<count).map { Card(id: $0, isLit: false) }
    }
}