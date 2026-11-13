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



// import XCTest

// final class TapFrenzyUITests: XCTestCase {

//     override func setUpWithError() throws {
//         continueAfterFailure = false
//     }

//     // Plays one full round: start, tap 5 times, wait for the time to run out, check the result.
//     func testFullRound() throws {
//         let app = XCUIApplication()
//         app.launchArguments = ["--reset"]   // clears the saved best score
//         app.launch()

//         // Start screen
//         let tapButton = app.buttons["tapButton"]
//         XCTAssertTrue(tapButton.waitForExistence(timeout: 5), "Tap button should be on screen")
//         XCTAssertTrue(app.staticTexts["Tap to start"].exists)
//         XCTAssertEqual(app.staticTexts["scoreValue"].label, "0")
//         attach(app, name: "01-start")

//         // 5 taps. The first one also starts the 10 second timer.
//         for _ in 1...5 {
//             tapButton.tap()
//         }
//         XCTAssertEqual(app.staticTexts["scoreValue"].label, "5")
//         attach(app, name: "02-playing")

//         // Wait for the round to end (10s timer, 20s timeout to be safe)
//         let finalScore = app.staticTexts["finalScore"]
//         XCTAssertTrue(finalScore.waitForExistence(timeout: 20), "Result screen should appear")
//         XCTAssertTrue(app.staticTexts["Times up!"].exists)
//         XCTAssertEqual(finalScore.label, "5")
//         XCTAssertEqual(app.staticTexts["bestScore"].label, "Best: 5")
//         attach(app, name: "03-result")

//         // Play again goes back to the start screen
//         app.buttons["playAgainButton"].tap()
//         XCTAssertTrue(app.buttons["tapButton"].waitForExistence(timeout: 5))
//         XCTAssertTrue(app.staticTexts["Tap to start"].exists)
//         XCTAssertEqual(app.staticTexts["scoreValue"].label, "0")
//         attach(app, name: "04-play-again")
//     }

//     // Saves a screenshot into the test results (your CI turns these into images)
//     private func attach(_ app: XCUIApplication, name: String) {
//         let attachment = XCTAttachment(screenshot: app.screenshot())
//         attachment.name = name
//         attachment.lifetime = .keepAlways
//         add(attachment)
//     }
// }