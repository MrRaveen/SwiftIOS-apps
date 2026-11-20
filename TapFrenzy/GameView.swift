import SwiftUI

// Tap Frenzy (Tutorial 1): same rules, new arcade look.
// C1 combo: fast taps raise the multiplier. C2 trap: a red button costs points.
struct GameView: View {
    // Game state
    @State private var phase: GamePhase = .idle
    @State private var score = 0
    @State private var timeLeft: TimeInterval = GameLogic.duration
    @State private var endDate = Date()
    @State private var isNewBest = false

    // Combo state (C1)
    @State private var multiplier = 1
    @State private var lastTapDate: Date? = nil

    // Trap colour state (C2)
    @State private var trapActive = false
    @State private var trapEndDate = Date()
    @State private var nextTrapDate = Date()

    // Best score of this mode, saved on the device
    @AppStorage(GameMode.tapFrenzy.bestScoreKey) private var bestScore = 0

    // The UI tests turn the random trap and the combo off so they can count exactly
    private let trapsEnabled = !LaunchFlags.uiTesting
    private let comboEnabled = !LaunchFlags.uiTesting

    // Fires every 0.05s. The handler only does work while the phase is .playing.
    private let ticker = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        // GeometryReader tells us if the phone is turned sideways
        GeometryReader { geo in
            let landscape = geo.size.width > geo.size.height

            ZStack {
                GameBackground(glow: trapActive ? Constants.trapRed : Constants.accentsBlue)

                VStack(spacing: landscape ? 8 : 18) {
                    if !landscape {
                        Text("TAP FRENZY")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .tracking(4)
                            .foregroundStyle(LinearGradient(colors: [Color.white, Constants.accentsBlue],
                                                            startPoint: .top, endPoint: .bottom))
                    }

                    switch phase {
                    case .idle, .playing:
                        Spacer(minLength: 0)
                        gameScreen(landscape: landscape)
                    case .over:
                        Spacer(minLength: 0)
                        ResultPanel(title: "Times up!",
                                    score: score,
                                    best: bestScore,
                                    isNewBest: isNewBest,
                                    compact: landscape,
                                    onPlayAgain: playAgain)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .frame(maxWidth: landscape ? 700 : 420)
            }
        }
        .onReceive(ticker) { _ in tick() }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: Idle and playing

    @ViewBuilder
    private func gameScreen(landscape: Bool) -> some View {
        if landscape {
            // Sideways: texts on the left, big button on the right
            HStack(alignment: .center, spacing: 24) {
                infoBlock(compact: true)
                    .frame(maxWidth: .infinity)
                tapButton(size: 170)
            }
        } else {
            VStack(spacing: 22) {
                infoBlock(compact: false)
                tapButton(size: 230)
            }
        }
    }

    // Score, combo badge, timer bar and status text
    private func infoBlock(compact: Bool) -> some View {
        VStack(spacing: compact ? 6 : 12) {
            Text("SCORE")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundColor(Color.white.opacity(0.55))

            scoreRow(compact: compact)

            // Full at the start, shrinks to nothing when time is up
            TimerBar(progress: GameLogic.remainingFraction(timeLeft: timeLeft),
                     tint: trapActive ? Constants.trapRed : Constants.accentsBlue)

            Text(GameLogic.statusText(phase: phase, timeLeft: timeLeft, trapActive: trapActive))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(trapActive ? Constants.trapRed : Color.white)
        }
    }

    // The score in the middle. The "x2!" badge sits on its right and only shows during a combo.
    // The empty space on the left keeps the score centered.
    private func scoreRow(compact: Bool) -> some View {
        HStack(spacing: 10) {
            Color.clear
                .frame(width: 64, height: 1)
                .accessibilityHidden(true)

            Text("\(score)")
                .font(.system(size: compact ? 44 : 72, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.white)
                .accessibilityIdentifier("scoreValue")
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.15), value: score)

            Text("x\(multiplier)!")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(Constants.comboOrange)
                .frame(width: 64, alignment: .leading)
                .opacity(multiplier >= 2 ? 1 : 0)
                .scaleEffect(multiplier >= 2 ? 1 : 0.6)
                .animation(.spring(response: 0.25, dampingFraction: 0.5), value: multiplier)
                .accessibilityHidden(multiplier < 2)
                .accessibilityIdentifier("comboBadge")
        }
    }

    // The big round button. It turns red during a trap.
    private func tapButton(size: CGFloat) -> some View {
        let tint = trapActive ? Constants.trapRed : Constants.accentsBlue

        return Button(action: handleTap) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [tint, tint.opacity(0.55)],
                                         startPoint: .top, endPoint: .bottom))
                Circle()
                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 4)
                Text(trapActive ? "TRAP!" : "TAP")
                    .font(.system(size: size * 0.2, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundColor(.white)
            }
            .frame(width: size, height: size)
            .neonGlow(tint, radius: 26)
            .contentShape(Circle())
        }
        .buttonStyle(PressScaleStyle())
        .animation(.easeInOut(duration: 0.1), value: trapActive)
        .accessibilityIdentifier("tapButton")
    }

    // MARK: Game actions

    private func handleTap() {
        switch phase {
        case .idle:
            startRound()
            score = 1                   // the tap that starts the round also counts
            lastTapDate = Date()
            Haptics.tap()
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
            Haptics.error()
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
        Haptics.tap()
    }

    private func startRound() {
        let now = Date()
        score = 0
        isNewBest = false
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
        isNewBest = score > bestScore
        bestScore = GameLogic.updatedBest(currentBest: bestScore, score: score)
        trapActive = false
        multiplier = 1
        phase = .over
        Haptics.success()
    }

    private func playAgain() {
        score = 0
        isNewBest = false
        timeLeft = GameLogic.duration
        multiplier = 1
        lastTapDate = nil
        trapActive = false
        phase = .idle
    }
}

#Preview("Tap Frenzy") {
    NavigationStack {
        GameView()
    }
}