import XCTest

final class TapFrenzyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Leave the simulator upright for the next test
        XCUIDevice.shared.orientation = .portrait
    }

    // Plays one full round: start, tap 5 times, check the bar shrinks, wait for the time to run out, check the result.
    func testFullRound() throws {
        let app = XCUIApplication()
        // "--reset" clears the saved best score.
        // "--ui-testing" turns off the random trap and the combo so the taps can be counted exactly.
        app.launchArguments = ["--reset", "--ui-testing"]
        app.launch()

        // Start screen
        let tapButton = app.buttons["tapButton"]
        XCTAssertTrue(tapButton.waitForExistence(timeout: 5), "Tap button should be on screen")
        XCTAssertTrue(app.staticTexts["Tap to start"].exists)
        XCTAssertEqual(app.staticTexts["scoreValue"].label, "0")
        XCTAssertEqual(percent(of: timerBar(app)), 100, "Bar should be full at the start")
        attach(app, name: "01-start")

        // 5 taps. The first one also starts the 10 second timer.
        for _ in 1...5 {
            tapButton.tap()
        }
        XCTAssertEqual(app.staticTexts["scoreValue"].label, "5")

        // The bar should shrink while the round runs
        let before = percent(of: timerBar(app))
        sleep(2)
        let after = percent(of: timerBar(app))
        XCTAssertLessThan(after, before, "Bar should shrink as time runs out")
        XCTAssertLessThan(after, 100, "Bar should not be full during the round")
        attach(app, name: "02-playing")

        // Wait for the round to end (10s timer, 20s timeout to be safe)
        let finalScore = app.staticTexts["finalScore"]
        XCTAssertTrue(finalScore.waitForExistence(timeout: 20), "Result screen should appear")
        XCTAssertTrue(app.staticTexts["Times up!"].exists)
        XCTAssertEqual(finalScore.label, "5")
        XCTAssertEqual(app.staticTexts["bestScore"].label, "Best: 5")
        attach(app, name: "03-result")

        // Play again goes back to the start screen
        app.buttons["playAgainButton"].tap()
        XCTAssertTrue(app.buttons["tapButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Tap to start"].exists)
        XCTAssertEqual(app.staticTexts["scoreValue"].label, "0")
        attach(app, name: "04-play-again")
    }

    // The layout must still work when the phone is turned sideways.
    func testLayoutWorksWhenRotated() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--reset", "--ui-testing"]
        app.launch()

        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1)   // let the rotation finish

        let tapButton = app.buttons["tapButton"]
        XCTAssertTrue(tapButton.waitForExistence(timeout: 5), "Tap button should exist in landscape")
        XCTAssertTrue(tapButton.isHittable, "Tap button should be fully on screen in landscape")
        attach(app, name: "05-landscape")

        tapButton.tap()
        XCTAssertEqual(app.staticTexts["scoreValue"].label, "1")

        // Back to portrait: the round keeps going and the score is kept
        XCUIDevice.shared.orientation = .portrait
        sleep(1)
        XCTAssertTrue(app.buttons["tapButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tapButton"].isHittable)
        XCTAssertEqual(app.staticTexts["scoreValue"].label, "1")
    }

    // The best score must be saved on the device (same as force-quitting the app by hand).
    func testBestScoreSurvivesRestart() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--reset", "--ui-testing"]
        app.launch()

        // Round 1: score 3
        let tapButton = app.buttons["tapButton"]
        XCTAssertTrue(tapButton.waitForExistence(timeout: 5))
        for _ in 1...3 {
            tapButton.tap()
        }
        XCTAssertTrue(app.staticTexts["finalScore"].waitForExistence(timeout: 20))
        XCTAssertEqual(app.staticTexts["bestScore"].label, "Best: 3")

        // Close the app completely, then start it again WITHOUT "--reset"
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        // Round 2: score 1. The best score must still be 3.
        XCTAssertTrue(app.buttons["tapButton"].waitForExistence(timeout: 5))
        app.buttons["tapButton"].tap()
        XCTAssertTrue(app.staticTexts["finalScore"].waitForExistence(timeout: 20))
        XCTAssertEqual(app.staticTexts["finalScore"].label, "1")
        XCTAssertEqual(app.staticTexts["bestScore"].label, "Best: 3")
    }

    // Finds the timer bar. A fresh query each time, so the value is current.
    private func timerBar(_ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["timerBar"]
    }

    // Reads "73 percent" as 73
    private func percent(of element: XCUIElement) -> Int {
        let text = element.value as? String ?? ""
        return Int(text.replacingOccurrences(of: " percent", with: "")) ?? -1
    }

    // Saves a screenshot into the test results (your CI turns these into images)
    private func attach(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
