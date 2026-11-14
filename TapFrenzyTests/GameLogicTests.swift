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
}
