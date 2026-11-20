import SwiftUI
import UIKit

// MARK: - Colours

enum Constants {
    // Background
    static let bgTop = Color(red: 0.04, green: 0.04, blue: 0.13)
    static let bgBottom = Color(red: 0.10, green: 0.05, blue: 0.22)
    static let panel = Color.white.opacity(0.07)
    static let panelStroke = Color.white.opacity(0.14)

    // Neon colours
    static let accentsBlue = Color(red: 0, green: 0.53, blue: 1)
    static let neonCyan = Color(red: 0.0, green: 0.9, blue: 1.0)
    static let neonViolet = Color(red: 0.62, green: 0.4, blue: 1.0)
    static let neonAmber = Color(red: 1.0, green: 0.78, blue: 0.2)
    static let neonMagenta = Color(red: 1.0, green: 0.25, blue: 0.8)

    // Feedback colours
    static let trapRed = Color(red: 1, green: 0.23, blue: 0.19)
    static let comboOrange = Color(red: 1, green: 0.58, blue: 0)
    static let correctGreen = Color(red: 0.2, green: 0.95, blue: 0.5)
    static let heartRed = Color(red: 1, green: 0.3, blue: 0.4)
}

// Each level has its own glow colour, so the player sees the level change without reading.
extension Level {
    var glow: Color {
        switch self {
        case .l1: return Constants.neonCyan
        case .l2: return Constants.neonViolet
        case .l3: return Constants.neonAmber
        case .l4: return Constants.neonMagenta
        }
    }
}

// Look of each mode on the Home screen
extension GameMode {
    var subtitle: String {
        switch self {
        case .tapFrenzy: return "Smash the button for 10 seconds. Chase combos, dodge the traps."
        case .lightItUp: return "Hit the lit card before it goes dark. 4 levels, 3 lives."
        }
    }

    var icon: String {
        switch self {
        case .tapFrenzy: return "hand.tap.fill"
        case .lightItUp: return "lightbulb.fill"
        }
    }

    var accent: Color {
        switch self {
        case .tapFrenzy: return Constants.accentsBlue
        case .lightItUp: return Constants.neonViolet
        }
    }
}

// MARK: - Helpers

extension View {
    // Soft neon glow around a view
    func neonGlow(_ color: Color, radius: CGFloat = 12) -> some View {
        self
            .shadow(color: color.opacity(0.85), radius: radius / 2)
            .shadow(color: color.opacity(0.55), radius: radius)
    }

    // Dark glass card with a thin border
    func glassPanel(cornerRadius: CGFloat = 24) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Constants.panel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Constants.panelStroke, lineWidth: 1.5)
            )
    }
}

// Phone vibration for taps, hits and mistakes
enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func heavy() { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
}

// MARK: - Shared views

// Dark gradient with a coloured glow at the top
struct GameBackground: View {
    var glow: Color = Constants.accentsBlue

    var body: some View {
        ZStack {
            LinearGradient(colors: [Constants.bgTop, Constants.bgBottom],
                           startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [glow.opacity(0.35), Color.clear],
                           center: .top, startRadius: 10, endRadius: 420)
            RadialGradient(colors: [Constants.neonMagenta.opacity(0.16), Color.clear],
                           center: .bottomTrailing, startRadius: 10, endRadius: 360)
        }
        .ignoresSafeArea()
    }
}

// Makes a button shrink a little while pressed
struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

// The big glowing capsule used for START and PLAY AGAIN
struct ArcadeButtonLabel: View {
    let title: String
    var icon: String? = nil
    var tint: Color = Constants.neonCyan

    var body: some View {
        HStack(spacing: 10) {
            if let icon = icon {
                Image(systemName: icon)
            }
            Text(title)
        }
        .font(.system(size: 20, weight: .heavy, design: .rounded))
        .foregroundColor(.white)
        .padding(.horizontal, 36)
        .padding(.vertical, 16)
        .background(
            Capsule().fill(LinearGradient(colors: [tint, tint.opacity(0.65)],
                                          startPoint: .top, endPoint: .bottom))
        )
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 1.5))
        .neonGlow(tint, radius: 14)
    }
}

// Bar that starts full and shrinks from right to left as time runs out
struct TimerBar: View {
    // 1.0 = full bar, 0.0 = empty
    let progress: Double
    var tint: Color = Constants.neonCyan

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12))
                Capsule()
                    .fill(LinearGradient(colors: [tint, tint.opacity(0.6)],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, geo.size.width * progress))
                    .neonGlow(tint, radius: 8)
            }
        }
        .frame(height: 12)
        .accessibilityElement()
        .accessibilityLabel("Time left")
        .accessibilityValue("\(Int(progress * 100)) percent")
        .accessibilityIdentifier("timerBar")
    }
}

// Row of hearts. Empty hearts are lives that are gone.
struct HeartsView: View {
    let lives: Int
    var maxLives: Int = LightItUpLogic.maxLives

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<maxLives, id: \.self) { index in
                let alive = index < lives
                Image(systemName: alive ? "heart.fill" : "heart")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(alive ? Constants.heartRed : Color.white.opacity(0.25))
                    .scaleEffect(alive ? 1 : 0.8)
                    .shadow(color: alive ? Constants.heartRed.opacity(0.8) : Color.clear, radius: 6)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: lives)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lives")
        .accessibilityValue("\(lives)")
        .accessibilityIdentifier("lives")
    }
}

// The "round finished" card, used by both modes
struct ResultPanel: View {
    let title: String
    let score: Int
    let best: Int
    let isNewBest: Bool
    var detail: String? = nil
    var compact: Bool = false
    let onPlayAgain: () -> Void

    var body: some View {
        Group {
            if compact {
                HStack(spacing: 32) {
                    scoreBlock
                    actions
                }
            } else {
                VStack(spacing: 18) {
                    scoreBlock
                    actions
                }
            }
        }
        .padding(24)
        .glassPanel()
        .foregroundColor(.white)
    }

    private var scoreBlock: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 26, weight: .heavy, design: .rounded))

            Text("Your score")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(Color.white.opacity(0.65))

            Text("\(score)")
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .accessibilityIdentifier("finalScore")

            if let detail = detail {
                Text(detail)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.65))
                    .accessibilityIdentifier("resultDetail")
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 14) {
            if isNewBest {
                Label("NEW BEST!", systemImage: "trophy.fill")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(Constants.neonAmber)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Constants.neonAmber.opacity(0.18)))
                    .overlay(Capsule().strokeBorder(Constants.neonAmber.opacity(0.7), lineWidth: 1.5))
                    .accessibilityIdentifier("newBestBadge")
            }

            Text("Best: \(best)")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .accessibilityIdentifier("bestScore")

            Button(action: onPlayAgain) {
                ArcadeButtonLabel(title: "PLAY AGAIN", icon: "arrow.clockwise")
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityIdentifier("playAgainButton")
        }
    }
}