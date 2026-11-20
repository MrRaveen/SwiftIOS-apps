import XCTest
@testable import TapFrenzy

final class GameLogicTests: XCTestCase {

    // MARK: Timer bar

    func testBarIsFullAtStart() {
        XCTAssertEqual(GameLogic.remainingFraction(timeLeft: 10), 1, accuracy: 0.0001)
    }

    func testBarIsHalfwayAtFiveSeconds() {
        XCTAssertEqual(GameLogic.remainingFraction(timeLeft: 5), 0.5, accuracy: 0.0001)
    }

    func testBarIsEmptyWhenTimeIsUp() {
        XCTAssertEqual(GameLogic.remainingFraction(timeLeft: 0), 0, accuracy: 0.0001)
    }

    func testBarShrinksAsTimeRuns() {
        let earlier = GameLogic.remainingFraction(timeLeft: 7)
        let later = GameLogic.remainingFraction(timeLeft: 3)
        XCTAssertLessThan(later, earlier)
    }

    func testBarIsClamped() {
        XCTAssertEqual(GameLogic.remainingFraction(timeLeft: 15), 1, accuracy: 0.0001)
        XCTAssertEqual(GameLogic.remainingFraction(timeLeft: -3), 0, accuracy: 0.0001)
    }

    // MARK: Best score

    func testBestScoreKeepsHigherValue() {
        XCTAssertEqual(GameLogic.updatedBest(currentBest: 40, score: 12), 40)
        XCTAssertEqual(GameLogic.updatedBest(currentBest: 40, score: 55), 55)
        XCTAssertEqual(GameLogic.updatedBest(currentBest: 0, score: 0), 0)
    }

    // MARK: Status text

    func testStatusText() {
        XCTAssertEqual(GameLogic.statusText(phase: .idle, timeLeft: 10), "Tap to start")
        XCTAssertEqual(GameLogic.statusText(phase: .playing, timeLeft: 7.25), "7.2s left")
        XCTAssertEqual(GameLogic.statusText(phase: .over, timeLeft: 0), "Times up!")
    }

    func testStatusTextDuringTrap() {
        XCTAssertEqual(GameLogic.statusText(phase: .playing, timeLeft: 5, trapActive: true), "Trap! Don't tap!")
        // The trap text only shows while playing
        XCTAssertEqual(GameLogic.statusText(phase: .idle, timeLeft: 10, trapActive: true), "Tap to start")
    }

    // MARK: Combo (C1)

    func testFirstTapHasNoCombo() {
        XCTAssertEqual(GameLogic.nextMultiplier(current: 1, secondsSinceLastTap: nil), 1)
    }

    func testFastTapRaisesMultiplier() {
        XCTAssertEqual(GameLogic.nextMultiplier(current: 1, secondsSinceLastTap: 0.2), 2)
        XCTAssertEqual(GameLogic.nextMultiplier(current: 2, secondsSinceLastTap: 0.1), 3)
        XCTAssertEqual(GameLogic.nextMultiplier(current: 3, secondsSinceLastTap: 0.25), 4)
    }

    func testTapExactlyAtWindowStillCounts() {
        XCTAssertEqual(GameLogic.nextMultiplier(current: 1, secondsSinceLastTap: 0.3), 2)
    }

    func testSlowTapResetsMultiplier() {
        XCTAssertEqual(GameLogic.nextMultiplier(current: 4, secondsSinceLastTap: 0.31), 1)
        XCTAssertEqual(GameLogic.nextMultiplier(current: 2, secondsSinceLastTap: 2.0), 1)
    }

    func testMultiplierIsCapped() {
        XCTAssertEqual(GameLogic.nextMultiplier(current: 4, secondsSinceLastTap: 0.1), 5)
        XCTAssertEqual(GameLogic.nextMultiplier(current: 5, secondsSinceLastTap: 0.1), 5)
        XCTAssertEqual(GameLogic.nextMultiplier(current: 5, secondsSinceLastTap: 0.1), GameLogic.maxMultiplier)
    }

    // MARK: Trap colour (C2)

    func testTrapTapDeductsPoints() {
        XCTAssertEqual(GameLogic.scoreAfterTrapTap(score: 10), 10 - GameLogic.trapPenalty)
    }

    func testTrapTapNeverGoesBelowZero() {
        XCTAssertEqual(GameLogic.scoreAfterTrapTap(score: 1), 0)
        XCTAssertEqual(GameLogic.scoreAfterTrapTap(score: 0), 0)
    }

    func testTrapStartsWhenItsTimeHasCome() {
        let now = Date(timeIntervalSince1970: 1000)
        let roundEnd = now.addingTimeInterval(5)
        XCTAssertTrue(GameLogic.shouldStartTrap(now: now, nextTrap: now.addingTimeInterval(-1), roundEnd: roundEnd))
        XCTAssertTrue(GameLogic.shouldStartTrap(now: now, nextTrap: now, roundEnd: roundEnd))
    }

    func testTrapDoesNotStartTooEarly() {
        let now = Date(timeIntervalSince1970: 1000)
        let roundEnd = now.addingTimeInterval(5)
        XCTAssertFalse(GameLogic.shouldStartTrap(now: now, nextTrap: now.addingTimeInterval(1), roundEnd: roundEnd))
    }

    func testTrapDoesNotStartIfRoundEndsFirst() {
        let now = Date(timeIntervalSince1970: 1000)
        // Only 0.3s left, but a trap lasts 0.5s
        let roundEnd = now.addingTimeInterval(0.3)
        XCTAssertFalse(GameLogic.shouldStartTrap(now: now, nextTrap: now.addingTimeInterval(-1), roundEnd: roundEnd))
    }

    func testTrapSettingsMatchTheBrief() {
        XCTAssertEqual(GameLogic.trapDuration, 0.5, accuracy: 0.0001)
        XCTAssertEqual(GameLogic.comboWindow, 0.3, accuracy: 0.0001)
    }

    // MARK: Levels (Light It Up)

    func testLevelCardCounts() {
        XCTAssertEqual(Level.l1.cardCount, 3)
        XCTAssertEqual(Level.l2.cardCount, 4)
        XCTAssertEqual(Level.l3.cardCount, 6)
        XCTAssertEqual(Level.l4.cardCount, 9)
    }

    func testLevelGridShapes() {
        XCTAssertEqual(Level.l1.columns, 3); XCTAssertEqual(Level.l1.rows, 1)   // 3 in a row
        XCTAssertEqual(Level.l2.columns, 2); XCTAssertEqual(Level.l2.rows, 2)   // 2 x 2
        XCTAssertEqual(Level.l3.columns, 3); XCTAssertEqual(Level.l3.rows, 2)   // 2 x 3
        XCTAssertEqual(Level.l4.columns, 3); XCTAssertEqual(Level.l4.rows, 3)   // 3 x 3
    }

    func testLitWindowsGetShorter() {
        XCTAssertEqual(Level.l1.litWindow, 1.5, accuracy: 0.0001)
        XCTAssertEqual(Level.l2.litWindow, 1.2, accuracy: 0.0001)
        XCTAssertEqual(Level.l3.litWindow, 1.0, accuracy: 0.0001)
        XCTAssertEqual(Level.l4.litWindow, 0.8, accuracy: 0.0001)
    }

    func testLevelsInA60SecondRound() {
        XCTAssertEqual(Level.forElapsed(0, roundLength: 60), .l1)
        XCTAssertEqual(Level.forElapsed(14.9, roundLength: 60), .l1)
        XCTAssertEqual(Level.forElapsed(15, roundLength: 60), .l2)
        XCTAssertEqual(Level.forElapsed(29.9, roundLength: 60), .l2)
        XCTAssertEqual(Level.forElapsed(30, roundLength: 60), .l3)
        XCTAssertEqual(Level.forElapsed(44.9, roundLength: 60), .l3)
        XCTAssertEqual(Level.forElapsed(45, roundLength: 60), .l4)
        XCTAssertEqual(Level.forElapsed(59, roundLength: 60), .l4)
    }

    func testLevelsScaleWithRoundLength() {
        XCTAssertEqual(Level.forElapsed(7.4, roundLength: 30), .l1)
        XCTAssertEqual(Level.forElapsed(7.5, roundLength: 30), .l2)
        XCTAssertEqual(Level.forElapsed(22.5, roundLength: 90), .l2)
        XCTAssertEqual(Level.forElapsed(67.5, roundLength: 90), .l4)
    }

    func testOnlyLevel4AllowsTwoLitCards() {
        XCTAssertFalse(Level.l1.allowsDoubleLight)
        XCTAssertFalse(Level.l3.allowsDoubleLight)
        XCTAssertTrue(Level.l4.allowsDoubleLight)
        XCTAssertEqual(LightItUpLogic.litCount(for: .l1, roll: 0.0), 1)
        XCTAssertEqual(LightItUpLogic.litCount(for: .l4, roll: 0.2), 2)
        XCTAssertEqual(LightItUpLogic.litCount(for: .l4, roll: 0.9), 1)
    }

    func testGapIsStretchedSoOnlyOneCardIsLit() {
        // L1: window 1.5 + rest 0.25 = 1.75
        XCTAssertEqual(LightItUpLogic.nextGap(level: .l1, randomGap: 1.0), 1.75, accuracy: 0.0001)
        XCTAssertEqual(LightItUpLogic.nextGap(level: .l1, randomGap: 1.9), 1.9, accuracy: 0.0001)
        // L4: window 0.8 + rest 0.25 = 1.05
        XCTAssertEqual(LightItUpLogic.nextGap(level: .l4, randomGap: 1.0), 1.05, accuracy: 0.0001)
    }

    func testLives() {
        XCTAssertEqual(LightItUpLogic.maxLives, 3)
        XCTAssertEqual(LightItUpLogic.livesAfterMistake(3), 2)
        XCTAssertEqual(LightItUpLogic.livesAfterMistake(0), 0)
        XCTAssertFalse(LightItUpLogic.isOutOfLives(1))
        XCTAssertTrue(LightItUpLogic.isOutOfLives(0))
    }

    // MARK: Settings and modes

    func testRoundLengths() {
        XCTAssertEqual(RoundLength.short.seconds, 30, accuracy: 0.0001)
        XCTAssertEqual(RoundLength.normal.seconds, 60, accuracy: 0.0001)
        XCTAssertEqual(RoundLength.long.seconds, 90, accuracy: 0.0001)
        XCTAssertEqual(RoundLength.from(stored: 90), .long)
        XCTAssertEqual(RoundLength.from(stored: 45), .normal)   // unknown value -> 60s
    }

    func testModesKeepSeparateBestScores() {
        XCTAssertNotEqual(GameMode.tapFrenzy.bestScoreKey, GameMode.lightItUp.bestScoreKey)
    }
}