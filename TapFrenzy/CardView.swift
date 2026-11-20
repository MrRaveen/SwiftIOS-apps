import SwiftUI

// The two kinds of feedback flash
enum FeedbackKind {
    case correct
    case wrong
}

struct CardView: View {
    let card: Card
    // Glow colour of the current level
    var glow: Color = Constants.neonCyan
    // nil when the card isn't flashing
    var flash: FeedbackKind? = nil
    let onTap: () -> Void

    private var isGlowing: Bool { card.isLit || flash != nil }

    // A flash colour wins over the normal lit and dark colours
    private var colors: [Color] {
        switch flash {
        case .correct:
            return [Constants.correctGreen, Constants.correctGreen.opacity(0.65)]
        case .wrong:
            return [Constants.trapRed, Constants.trapRed.opacity(0.65)]
        case nil:
            if card.isLit { return [glow, glow.opacity(0.7)] }
            return [Color.white.opacity(0.10), Color.white.opacity(0.04)]
        }
    }

    private var glowColor: Color {
        switch flash {
        case .correct: return Constants.correctGreen
        case .wrong: return Constants.trapRed
        case nil: return card.isLit ? glow : Color.clear
        }
    }

    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(isGlowing ? 0.85 : 0.15),
                                      lineWidth: card.isLit ? 3 : 1.5)
                )
                .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                // Lit cards grow a little and glow
                .scaleEffect(card.isLit ? 1.08 : 1)
                .shadow(color: glowColor.opacity(0.85), radius: isGlowing ? 22 : 0)
                .animation(.easeInOut(duration: 0.2), value: card.isLit)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("card\(card.id)")
        .accessibilityValue(card.isLit ? "lit" : "off")
    }
}

#Preview {
    ZStack {
        GameBackground()
        HStack(spacing: 16) {
            CardView(card: Card(id: 0, isLit: true), glow: Level.l2.glow, onTap: {})
                .frame(width: 100, height: 100)
            CardView(card: Card(id: 1, isLit: false), onTap: {})
                .frame(width: 100, height: 100)
        }
    }
}