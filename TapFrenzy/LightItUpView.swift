import SwiftUI

// The Light It Up game screen: idle -> playing -> over
struct LightItUpView: View {
    // Settings and saved data
    @AppStorage(RoundLength.storageKey) private var roundLengthRaw = RoundLength.normal.rawValue
    @AppStorage(GameMode.lightItUp.bestScoreKey) private var bestScore = 0

    // Round state
    @State private var phase: GamePhase = .idle
    @State private var level: Level = .l1
    @State private var cards: [Card] = Card.makeCards(count: Level.l1.cardCount)
    @State private var score = 0
    @State private var lives = LightItUpLogic.maxLives
    @State private var timeLeft: TimeInterval = RoundLength.normal.seconds
    @State private var roundSeconds: TimeInterval = RoundLength.normal.seconds
    @State private var startDate = Date()
    @State private var nextLightDate = Date()
    @State private var endedEarly = false
    @State private var isNewBest = false

    // Feedback
    @State private var flashes: [Int: FeedbackKind] = [:]
    @State private var levelBanner: Level? = nil

    // One clock for everything. It uses the real time, like Tap Frenzy does.
    private let ticker = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    private var selectedLength: RoundLength { RoundLength.from(stored: roundLengthRaw) }

    private var displayTimeLeft: TimeInterval {
        phase == .idle ? selectedLength.seconds : timeLeft
    }
    private var progress: Double {
        phase == .idle ? 1 : GameLogic.remainingFraction(timeLeft: timeLeft, duration: roundSeconds)
    }
    private var secondsLeft: Int { Int(ceil(displayTimeLeft)) }

    var body: some View {
        GeometryReader { geo in
            let landscape = geo.size.width > geo.size.height

            ZStack {
                GameBackground(glow: level.glow)

                Group {
                    if landscape {
                        HStack(spacing: 20) {
                            hud(compact: true)
                                .frame(width: 220)
                            stage(landscape: true)
                        }
                    } else {
                        VStack(spacing: 16) {
                            hud(compact: false)
                            stage(landscape: false)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)

                levelUpOverlay
            }
        }
        .onReceive(ticker) { _ in tick() }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: HUD (score, level, lives, time)

    private func hud(compact: Bool) -> some View {
        VStack(spacing: 12) {
            if compact {
                VStack(spacing: 10) {
                    scoreBlock
                    levelBadge
                    HeartsView(lives: lives)
                }
            } else {
                HStack {
                    scoreBlock
                    Spacer()
                    levelBadge
                    Spacer()
                    HeartsView(lives: lives)
                }
            }

            HStack(spacing: 10) {
                TimerBar(progress: progress, tint: level.glow)
                Text("\(secondsLeft)s")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)
                    .frame(width: 48, alignment: .trailing)
                    .accessibilityIdentifier("timeLeft")
            }
        }
        .padding(14)
        .glassPanel(cornerRadius: 22)
    }

    private var scoreBlock: some View {
        VStack(spacing: 0) {
            Text("SCORE")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundColor(Color.white.opacity(0.55))

            Text("\(score)")
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.white)
                .accessibilityIdentifier("scoreValue")
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.15), value: score)
        }
    }

    private var levelBadge: some View {
        VStack(spacing: 2) {
            Text("LEVEL")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundColor(Color.white.opacity(0.55))

            Text(level.title)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(level.glow)
                .neonGlow(level.glow, radius: 10)
                .accessibilityIdentifier("levelValue")
        }
    }

    // MARK: Stage (changes with the phase)

    @ViewBuilder
    private func stage(landscape: Bool) -> some View {
        switch phase {
        case .idle:
            idleStage
        case .playing:
            board
        case .over:
            resultStage(landscape: landscape)
        }
    }

    private var idleStage: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)

            VStack(spacing: 14) {
                Text("LIGHT IT UP")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundColor(.white)
                    .neonGlow(level.glow, radius: 14)

                Text("Tap the lit card before it goes dark. A wrong tap or a missed card costs a life.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.white.opacity(0.75))

                HStack(spacing: 10) {
                    infoChip(icon: "heart.fill", text: "\(LightItUpLogic.maxLives) lives", id: "livesInfo")
                    infoChip(icon: "timer", text: "\(selectedLength.title) round", id: "roundLabel")
                }
            }
            .padding(20)
            .glassPanel()

            Button(action: startRound) {
                ArcadeButtonLabel(title: "START", icon: "play.fill", tint: level.glow)
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityIdentifier("startButton")

            Spacer(minLength: 0)
        }
    }

    private func infoChip(icon: String, text: String, id: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
                .accessibilityIdentifier(id)
        }
        .font(.system(size: 14, weight: .bold, design: .rounded))
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color.white.opacity(0.1)))
    }

    private func resultStage(landscape: Bool) -> some View {
        VStack {
            Spacer(minLength: 0)
            ResultPanel(title: endedEarly ? "Out of lives!" : "Times up!",
                        score: score,
                        best: bestScore,
                        isNewBest: isNewBest,
                        detail: "Reached level \(level.number)",
                        compact: landscape,
                        onPlayAgain: playAgain)
            Spacer(minLength: 0)
        }
    }

    // The card grid. LazyVGrid + GridItem: the number of columns and cards comes from the level,
    // and the card size is worked out from the free space, so it fits in portrait and landscape.
    private var board: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 14
            let columnCount = level.columns
            let rowCount = level.rows
            let sideByWidth = (geo.size.width - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
            let sideByHeight = (geo.size.height - spacing * CGFloat(rowCount - 1)) / CGFloat(rowCount)
            let side = max(40, min(sideByWidth, sideByHeight, 140))
            let columns = Array(repeating: GridItem(.fixed(side), spacing: spacing), count: columnCount)

            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(cards) { card in
                    CardView(card: card, glow: level.glow, flash: flashes[card.id]) {
                        handleTap(card)
                    }
                    .frame(width: side, height: side)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: Level-up flash

    @ViewBuilder
    private var levelUpOverlay: some View {
        if let banner = levelBanner {
            ZStack {
                banner.glow.opacity(0.18)
                    .ignoresSafeArea()

                VStack(spacing: 6) {
                    Text("LEVEL \(banner.number)!")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .neonGlow(banner.glow, radius: 26)
                        .accessibilityIdentifier("levelBanner")

                    Text(banner.note)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(banner.glow)
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.8)))
            .allowsHitTesting(false)
        }
    }

    private func showBanner(_ newLevel: Level) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            levelBanner = newLevel
        }
        Haptics.heavy()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeOut(duration: 0.25)) {
                if levelBanner == newLevel { levelBanner = nil }
            }
        }
    }

    // MARK: Round control

    private func startRound() {
        let now = Date()
        roundSeconds = selectedLength.seconds
        startDate = now
        timeLeft = roundSeconds
        score = 0
        lives = LightItUpLogic.maxLives
        level = .l1
        cards = Card.makeCards(count: Level.l1.cardCount)
        flashes = [:]
        endedEarly = false
        isNewBest = false
        nextLightDate = now.addingTimeInterval(LightItUpLogic.firstLightDelay)
        phase = .playing
        Haptics.tap()
    }

    private func playAgain() {
        withAnimation(.easeInOut(duration: 0.25)) {
            phase = .idle
            level = .l1
            cards = Card.makeCards(count: Level.l1.cardCount)
        }
        score = 0
        lives = LightItUpLogic.maxLives
        timeLeft = selectedLength.seconds
        flashes = [:]
        levelBanner = nil
    }

    private func finishRound(endedEarly early: Bool) {
        guard phase == .playing else { return }
        endedEarly = early
        isNewBest = score > bestScore
        bestScore = GameLogic.updatedBest(currentBest: bestScore, score: score)

        for index in cards.indices {
            cards[index].isLit = false
            cards[index].expiresAt = nil
        }
        levelBanner = nil
        withAnimation(.easeInOut(duration: 0.25)) {
            phase = .over
        }
        Haptics.success()
    }

    // MARK: The game loop (called by the ticker)

    private func tick() {
        guard phase == .playing else { return }
        let now = Date()
        let elapsed = now.timeIntervalSince(startDate)

        timeLeft = max(0, roundSeconds - elapsed)
        if timeLeft <= 0 {
            finishRound(endedEarly: false)
            return
        }

        // The level follows the clock
        let newLevel = Level.forElapsed(elapsed, roundLength: roundSeconds)
        if newLevel != level {
            startLevel(newLevel, now: now)
        }

        // Lit cards that ran out of time are a miss
        expireLitCards(now: now)
        guard phase == .playing else { return }

        // Time for the next light?
        if now >= nextLightDate {
            lightCards(now: now)
        }
    }

    // New level: new number of cards, so the grid reflows by itself
    private func startLevel(_ newLevel: Level, now: Date) {
        withAnimation(.easeInOut(duration: 0.5)) {
            level = newLevel
            cards = Card.makeCards(count: newLevel.cardCount)
            flashes = [:]
        }
        // A short pause so the player can read the new board
        nextLightDate = max(nextLightDate, now.addingTimeInterval(0.8))
        showBanner(newLevel)
    }

    private func lightCards(now: Date) {
        let freeIndexes = cards.indices.filter { !cards[$0].isLit }
        let wanted = LightItUpLogic.litCount(for: level, roll: Double.random(in: 0..<1))
        let window = level.litWindow * LightItUpLogic.windowScale

        for index in freeIndexes.shuffled().prefix(wanted) {
            cards[index].isLit = true
            cards[index].expiresAt = now.addingTimeInterval(window)
        }

        let randomGap = TimeInterval.random(in: LightItUpLogic.gapRange)
        nextLightDate = now.addingTimeInterval(
            LightItUpLogic.nextGap(level: level, randomGap: randomGap, windowScale: LightItUpLogic.windowScale)
        )
    }

    // A lit card that was not tapped in time: it goes dark and the player loses a life
    private func expireLitCards(now: Date) {
        for index in cards.indices {
            guard cards[index].isLit, let expiry = cards[index].expiresAt, now >= expiry else { continue }
            let id = cards[index].id
            cards[index].isLit = false
            cards[index].expiresAt = nil
            flash(id, .wrong)
            loseLife()
        }
    }

    // MARK: Taps

    private func handleTap(_ card: Card) {
        guard phase == .playing,
              let index = cards.firstIndex(where: { $0.id == card.id }) else { return }

        if cards[index].isLit {
            // Correct: score up and clear the lit state
            cards[index].isLit = false
            cards[index].expiresAt = nil
            score += 1
            flash(card.id, .correct)
            Haptics.tap()
        } else {
            // Wrong card: lose a life
            flash(card.id, .wrong)
            loseLife()
        }
    }

    private func loseLife() {
        guard phase == .playing else { return }
        withAnimation {
            lives = LightItUpLogic.livesAfterMistake(lives)
        }
        Haptics.error()
        if LightItUpLogic.isOutOfLives(lives) {
            finishRound(endedEarly: true)
        }
    }

    // Brief green (correct) or red (wrong) flash on a card
    private func flash(_ id: Int, _ kind: FeedbackKind) {
        withAnimation(.easeOut(duration: 0.15)) {
            flashes[id] = kind
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeOut(duration: 0.2)) {
                flashes[id] = nil
            }
        }
    }
}

#Preview("Light It Up") {
    NavigationStack {
        LightItUpView()
    }
}