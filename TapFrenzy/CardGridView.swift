import SwiftUI

struct CardGridView: View {
    @State private var level: Level = .l1
    @State private var cards: [Card] = (0..<Level.l1.gridCount).map { Card(id: $0, isLit: false) }
    @State private var score = 0
    // Seconds passed in the round
    @State private var elapsed: TimeInterval = 0
    // Cards that are flashing right now, keyed by card id
    @State private var flashes: [Int: FeedbackKind] = [:]

    private static let flipInterval: TimeInterval = 1.0   // seconds between new lit cards
    private static let penalty = 1                        // points lost on a wrong tap or a missed card

    // Lights a new card every flipInterval seconds
    private let flipTimer = Timer.publish(every: CardGridView.flipInterval, on: .main, in: .common).autoconnect()
    // Moves the round clock forward every 0.1 seconds
    private let roundTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private let columns = [GridItem(.adaptive(minimum: 80), spacing: 12)]

    private var roundOver: Bool { elapsed >= GameLogic.duration }

    var body: some View {
        VStack(spacing: 12) {
            Text("Score: \(score)   \(level.title)")
                .font(.system(size: 17, weight: .bold))

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(cards) { card in
                        CardView(card: card, flash: flashes[card.id]) {
                            handleTap(card)
                        }
                    }
                }
                .padding(12)
            }
        }
        .onReceive(flipTimer) { _ in lightRandomCard() }
        .onReceive(roundTimer) { _ in advanceRound() }
    }

    // MARK: Round clock and levels

    private func advanceRound() {
        guard !roundOver else { return }
        elapsed += 0.1

        let newLevel = Level.forElapsed(elapsed)
        if newLevel != level {
            level = newLevel
            // The grid size comes from the level, so a new level rebuilds the cards.
            // The grid reflows automatically because ForEach gets a different count.
            cards = (0..<newLevel.gridCount).map { Card(id: $0, isLit: false) }
        }
    }

    // MARK: Lighting cards

    // Picks one card that is off, turns it on, and schedules it to turn off
    private func lightRandomCard() {
        guard !roundOver else { return }

        let offIDs = cards.filter { !$0.isLit }.map { $0.id }
        guard let pickedID = offIDs.randomElement() else { return }

        setLit(id: pickedID, to: true)

        // The window length comes from the current level
        DispatchQueue.main.asyncAfter(deadline: .now() + level.litWindow) {
            expireIfStillLit(pickedID)
        }
    }

    // Runs when the window ends. If the card is still lit, the player missed it.
    // A tap would have cleared the lit state, so a tapped card is skipped here.
    private func expireIfStillLit(_ id: Int) {
        guard let card = cards.first(where: { $0.id == id }), card.isLit else { return }
        setLit(id: id, to: false)
        score = max(0, score - CardGridView.penalty)
        flash(id, .wrong)
    }

    // MARK: Taps

    private func handleTap(_ card: Card) {
        guard !roundOver else { return }

        if card.isLit {
            // Correct: score up and clear the lit state
            score += 1
            setLit(id: card.id, to: false)
            flash(card.id, .correct)
        } else {
            // Wrong card: small penalty, but never below 0
            score = max(0, score - CardGridView.penalty)
            flash(card.id, .wrong)
        }
    }

    // MARK: Helpers

    private func setLit(id: Int, to value: Bool) {
        guard let index = cards.firstIndex(where: { $0.id == id }) else { return }
        cards[index].isLit = value
    }

    // Shows a green or red flash for a short time, then clears it
    private func flash(_ id: Int, _ kind: FeedbackKind) {
        withAnimation(.easeOut(duration: 0.15)) {
            flashes[id] = kind
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.15)) {
                flashes[id] = nil
            }
        }
    }
}

#Preview {
    CardGridView()
}