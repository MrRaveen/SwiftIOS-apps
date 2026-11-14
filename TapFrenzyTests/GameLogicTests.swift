import XCTest
@testable import TapFrenzy

final class GameLogicTests: XCTestCase {

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

    func testBestScoreKeepsHigherValue() {
        XCTAssertEqual(GameLogic.updatedBest(currentBest: 40, score: 12), 40)
        XCTAssertEqual(GameLogic.updatedBest(currentBest: 40, score: 55), 55)
        XCTAssertEqual(GameLogic.updatedBest(currentBest: 0, score: 0), 0)
    }

    func testStatusText() {
        XCTAssertEqual(GameLogic.statusText(phase: .idle, timeLeft: 10), "Tap to start")
        XCTAssertEqual(GameLogic.statusText(phase: .playing, timeLeft: 7.25), "7.2s left")
        XCTAssertEqual(GameLogic.statusText(phase: .over, timeLeft: 0), "Times up!")
    }
}
