import SwiftUI

// Colors taken from the Figma design
enum Constants {
    static let accentsBlue = Color(red: 0, green: 0.53, blue: 1)
    static let trackGray = Color(white: 0.9)
    static let pillGray = Color(white: 0.96)
}

struct ContentView: View {
    // Game state
    @State private var phase: GamePhase = .idle
    @State private var score = 0
    @State private var timeLeft: TimeInterval = GameLogic.duration
    @State private var endDate = Date()

    // Best score is saved on the device, so it survives app restarts
    @AppStorage("bestScore") private var bestScore = 0

    // Fires every 0.05s. The handler only does work while the phase is .playing.
    private let ticker = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 12) {
                TitlePill()

                switch phase {
                case .idle, .playing:
                    gameScreen
                case .over:
                    resultScreen
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .frame(maxWidth: 400)
        }
        .onReceive(ticker) { _ in tick() }
    }

    // MARK: Screen 1 - idle and playing

    private var gameScreen: some View {
        VStack(spacing: 12) {
            Text("Score")
                .font(.system(size: 17, weight: .bold))
                .frame(height: 39)

            Text("\(score)")
                .font(.system(size: 17, weight: .bold))
                .frame(height: 39)
                .accessibilityIdentifier("scoreValue")

            // Full at the start, shrinks to nothing when time is up
            TimerBar(progress: GameLogic.remainingFraction(timeLeft: timeLeft))
                .frame(height: 44)

            Text(GameLogic.statusText(phase: phase, timeLeft: timeLeft))
                .font(.system(size: 17, weight: .bold))
                .frame(height: 39)

            Button(action: handleTap) {
                ZStack {
                    Circle().fill(Constants.accentsBlue)
                    Text("Tap")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(.white)
                }
                .frame(width: 229, height: 229)
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityIdentifier("tapButton")
        }
        .foregroundColor(.black)
    }

    // MARK: Screen 2 - result

    private var resultScreen: some View {
        VStack(spacing: 12) {
            Text("Times up!")
                .font(.system(size: 17, weight: .bold))
                .frame(height: 39)

            Text("Your score")
                .font(.system(size: 17, weight: .medium))
                .frame(height: 39)

            Text("\(score)")
                .font(.system(size: 40, weight: .bold))
                .frame(height: 49)
                .accessibilityIdentifier("finalScore")

            Text("Best: \(bestScore)")
                .font(.system(size: 17, weight: .medium))
                .frame(height: 39)
                .accessibilityIdentifier("bestScore")

            // The design has no button here, but the brief says "try again", so we add a simple one.
            Button(action: playAgain) {
                Text("Play again")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Constants.accentsBlue)
                    .clipShape(Capsule())
            }
            .padding(.top, 12)
            .accessibilityIdentifier("playAgainButton")
        }
        .foregroundColor(.black)
    }

    // MARK: Game actions

    private func handleTap() {
        switch phase {
        case .idle:
            startRound()
            score = 1           // the tap that starts the round also counts
        case .playing:
            score += 1
        case .over:
            break
        }
    }

    private func startRound() {
        score = 0
        timeLeft = GameLogic.duration
        endDate = Date().addingTimeInterval(GameLogic.duration)
        phase = .playing
    }

    // Called by the timer. Uses the real clock (endDate) so the countdown stays accurate.
    private func tick() {
        guard phase == .playing else { return }
        timeLeft = max(0, endDate.timeIntervalSinceNow)
        if timeLeft <= 0 {
            finishRound()
        }
    }

    private func finishRound() {
        bestScore = GameLogic.updatedBest(currentBest: bestScore, score: score)
        phase = .over
    }

    private func playAgain() {
        score = 0
        timeLeft = GameLogic.duration
        phase = .idle
    }
}

// MARK: - Small reusable views

// The "Tap Frenzy" rounded header at the top
struct TitlePill: View {
    var body: some View {
        Text("Tap Frenzy")
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.black)
            .frame(maxWidth: 357, minHeight: 64)
            .background(Constants.pillGray)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
    }
}

// Thin bar that starts full and shrinks from right to left as time runs out
struct TimerBar: View {
    // 1.0 = full bar, 0.0 = empty
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Constants.trackGray).frame(height: 4)
                Capsule()
                    .fill(Constants.accentsBlue)
                    .frame(width: max(0, geo.size.width * progress), height: 4)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 6)
        .accessibilityElement()
        .accessibilityLabel("Time left")
        .accessibilityValue("\(Int(progress * 100)) percent")
        .accessibilityIdentifier("timerBar")
    }
}

// Makes the big button shrink a little while pressed
struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

#Preview("Game") {
    ContentView()
}
