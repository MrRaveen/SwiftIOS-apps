import SwiftUI

// Colors taken from the Figma design, plus two for the new features
enum Constants {
    static let accentsBlue = Color(red: 0, green: 0.53, blue: 1)
    static let trackGray = Color(white: 0.9)
    static let pillGray = Color(white: 0.96)
    static let trapRed = Color(red: 1, green: 0.23, blue: 0.19)
    static let comboOrange = Color(red: 1, green: 0.58, blue: 0)
}

struct ContentView: View {
    // Game state
    @State private var phase: GamePhase = .idle
    @State private var score = 0
    @State private var timeLeft: TimeInterval = GameLogic.duration
    @State private var endDate = Date()

    // Combo state (C1)
    @State private var multiplier = 1
    @State private var lastTapDate: Date? = nil

    // Trap colour state (C2)
    @State private var trapActive = false
    @State private var trapEndDate = Date()
    @State private var nextTrapDate = Date()

    // Best score is saved on the device, so it survives app restarts
    @AppStorage("bestScore") private var bestScore = 0

    // The UI test turns the random trap and the combo off so it can count exactly
    private let trapsEnabled = !LaunchFlags.uiTesting
    private let comboEnabled = !LaunchFlags.uiTesting

    // Fires every 0.05s. The handler only does work while the phase is .playing.
    private let ticker = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        // GeometryReader tells us if the phone is turned sideways,
        // so the layout can change and still fit on the screen.
        GeometryReader { geo in
            let landscape = geo.size.width > geo.size.height

            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: landscape ? 8 : 12) {
                    TitlePill(compact: landscape)

                    switch phase {
                    case .idle, .playing:
                        gameScreen(landscape: landscape)
                    case .over:
                        resultScreen(landscape: landscape)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .frame(maxWidth: landscape ? 700 : 400)
            }
        }
        .onReceive(ticker) { _ in tick() }
    }

    // MARK: Screen 1 - idle and playing

    @ViewBuilder
    private func gameScreen(landscape: Bool) -> some View {
        if landscape {
            // Sideways: texts on the left, big button on the right
            HStack(alignment: .center, spacing: 24) {
                infoBlock(compact: true)
                    .frame(maxWidth: .infinity)
                tapButton(size: 170)
            }
            .foregroundColor(.black)
        } else {
            VStack(spacing: 12) {
                infoBlock(compact: false)
                tapButton(size: 229)
            }
            .foregroundColor(.black)
        }
    }

    // Score, combo badge, timer bar and status text
    private func infoBlock(compact: Bool) -> some View {
        VStack(spacing: compact ? 4 : 12) {
            Text("Score")
                .font(.system(size: 17, weight: .bold))
                .frame(height: compact ? 28 : 39)

            scoreRow(compact: compact)

            // Full at the start, shrinks to nothing when time is up
            TimerBar(progress: GameLogic.remainingFraction(timeLeft: timeLeft))
                .frame(height: compact ? 32 : 44)

            Text(GameLogic.statusText(phase: phase, timeLeft: timeLeft, trapActive: trapActive))
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(trapActive ? Constants.trapRed : .black)
                .frame(height: compact ? 28 : 39)
        }
    }

    // The score in the middle. The "x2!" badge sits on its right and only shows during a combo.
    // The empty space on the left keeps the score centered.
    private func scoreRow(compact: Bool) -> some View {
        HStack(spacing: 8) {
            Color.clear
                .frame(width: 44, height: 1)
                .accessibilityHidden(true)

            Text("\(score)")
                .font(.system(size: 17, weight: .bold))
                .accessibilityIdentifier("scoreValue")

            Text("x\(multiplier)!")
                .font(.system(size: 17, weight: .heavy))
                .foregroundColor(Constants.comboOrange)
                .frame(width: 44, alignment: .leading)
                .opacity(multiplier >= 2 ? 1 : 0)
                .animation(.easeOut(duration: 0.1), value: multiplier)
                .accessibilityHidden(multiplier < 2)
                .accessibilityIdentifier("comboBadge")
        }
        .frame(height: compact ? 28 : 39)
    }

    // The big round button. It turns red during a trap.
    private func tapButton(size: CGFloat) -> some View {
        Button(action: handleTap) {
            ZStack {
                Circle().fill(trapActive ? Constants.trapRed : Constants.accentsBlue)
                Text(trapActive ? "Trap!" : "Tap")
                    .font(.system(size: size * 0.175, weight: .light))
                    .foregroundColor(.white)
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
        }
        .buttonStyle(PressScaleStyle())
        .animation(.easeInOut(duration: 0.1), value: trapActive)
        .accessibilityIdentifier("tapButton")
    }

    // MARK: Screen 2 - result

    @ViewBuilder
    private func resultScreen(landscape: Bool) -> some View {
        if landscape {
            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("Times up!")
                        .font(.system(size: 17, weight: .bold))
                        .frame(height: 28)

                    Text("Your score")
                        .font(.system(size: 17, weight: .medium))
                        .frame(height: 28)

                    Text("\(score)")
                        .font(.system(size: 40, weight: .bold))
                        .frame(height: 49)
                        .accessibilityIdentifier("finalScore")
                }

                VStack(spacing: 12) {
                    bestScoreText
                    playAgainButton
                }
            }
            .foregroundColor(.black)
        } else {
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

                bestScoreText

                playAgainButton
                    .padding(.top, 12)
            }
            .foregroundColor(.black)
        }
    }

    private var bestScoreText: some View {
        Text("Best: \(bestScore)")
            .font(.system(size: 17, weight: .medium))
            .frame(height: 39)
            .accessibilityIdentifier("bestScore")
    }

    // The design has no button here, but the brief says "try again", so we add a simple one.
    private var playAgainButton: some View {
        Button(action: playAgain) {
            Text("Play again")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(Constants.accentsBlue)
                .clipShape(Capsule())
        }
        .accessibilityIdentifier("playAgainButton")
    }

    // MARK: Game actions

    private func handleTap() {
        switch phase {
        case .idle:
            startRound()
            score = 1                   // the tap that starts the round also counts
            lastTapDate = Date()
        case .playing:
            registerPlayingTap()
        case .over:
            break
        }
    }

    // A tap while the round is running
    private func registerPlayingTap() {
        let now = Date()

        // Ignore a tap that arrives after the time is up but before the timer noticed
        guard now < endDate else { return }

        // C2: tapping during a trap costs points and breaks the combo
        if trapActive {
            score = GameLogic.scoreAfterTrapTap(score: score)
            multiplier = 1
            lastTapDate = nil
            return
        }

        // C1: a fast tap raises the multiplier, a slow tap resets it to x1
        if comboEnabled {
            let gap = lastTapDate.map { now.timeIntervalSince($0) }
            multiplier = GameLogic.nextMultiplier(current: multiplier, secondsSinceLastTap: gap)
        } else {
            multiplier = 1
        }
        score += multiplier
        lastTapDate = now
    }

    private func startRound() {
        let now = Date()
        score = 0
        timeLeft = GameLogic.duration
        endDate = now.addingTimeInterval(GameLogic.duration)
        multiplier = 1
        lastTapDate = nil
        trapActive = false
        nextTrapDate = now.addingTimeInterval(TimeInterval.random(in: GameLogic.trapGapRange))
        phase = .playing
    }

    // Called by the timer. Uses the real clock (endDate) so the countdown stays accurate.
    private func tick() {
        guard phase == .playing else { return }
        let now = Date()
        timeLeft = max(0, endDate.timeIntervalSince(now))
        if timeLeft <= 0 {
            finishRound()
            return
        }

        // C1: the combo ends when no tap came within 300 ms
        if multiplier > 1, let last = lastTapDate,
           now.timeIntervalSince(last) > GameLogic.comboWindow {
            multiplier = 1
        }

        // C2: start a trap when it is time, end it after half a second
        if trapActive {
            if now >= trapEndDate {
                trapActive = false
                nextTrapDate = now.addingTimeInterval(TimeInterval.random(in: GameLogic.trapGapRange))
            }
        } else if trapsEnabled,
                  GameLogic.shouldStartTrap(now: now, nextTrap: nextTrapDate, roundEnd: endDate) {
            trapActive = true
            trapEndDate = now.addingTimeInterval(GameLogic.trapDuration)
        }
    }

    private func finishRound() {
        bestScore = GameLogic.updatedBest(currentBest: bestScore, score: score)
        trapActive = false
        multiplier = 1
        phase = .over
    }

    private func playAgain() {
        score = 0
        timeLeft = GameLogic.duration
        multiplier = 1
        lastTapDate = nil
        trapActive = false
        phase = .idle
    }
}

// MARK: - Small reusable views

// The "Tap Frenzy" rounded header at the top
struct TitlePill: View {
    // Smaller height when the phone is turned sideways
    var compact: Bool = false

    var body: some View {
        Text("Tap Frenzy")
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.black)
            .frame(maxWidth: 357, minHeight: compact ? 44 : 64)
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
