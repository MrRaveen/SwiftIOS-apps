import XCTest

final class TapFrenzyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Leave the simulator upright for the next test
        XCUIDevice.shared.orientation = .portrait
    }

    // MARK: Home

    func testHomeShowsBothModes() throws {
        let app = launchApp()
        XCTAssertTrue(app.buttons["tapFrenzyModeButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["lightItUpModeButton"].exists)
        XCTAssertTrue(app.buttons["settingsButton"].exists)
        attach(app, name: "00-home")
    }

    // MARK: Tap Frenzy

    // Plays one full round: start, tap 5 times, check the bar shrinks, wait for the time to run out, check the result.
    func testFullRound() throws {
        // "--reset" clears the saved scores.
        // "--ui-testing" turns off the random trap and the combo so the taps can be counted exactly.
        let app = launchApp()
        open("tapFrenzyModeButton", in: app)

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
        let app = launchApp()
        open("tapFrenzyModeButton", in: app)

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
        let app = launchApp()
        open("tapFrenzyModeButton", in: app)

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
        open("tapFrenzyModeButton", in: app)

        // Round 2: score 1. The best score must still be 3.
        XCTAssertTrue(app.buttons["tapButton"].waitForExistence(timeout: 5))
        app.buttons["tapButton"].tap()
        XCTAssertTrue(app.staticTexts["finalScore"].waitForExistence(timeout: 20))
        XCTAssertEqual(app.staticTexts["finalScore"].label, "1")
        XCTAssertEqual(app.staticTexts["bestScore"].label, "Best: 3")
    }

    // MARK: Light It Up

    // Tapping the lit card gives one point and keeps all 3 lives.
    func testLightItUpHitScoresAPoint() throws {
        let app = launchApp()
        open("lightItUpModeButton", in: app)
        startLightItUp(app)

        let litCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'card' AND value == 'lit'")
        ).firstMatch
        XCTAssertTrue(litCard.waitForExistence(timeout: 8), "A card should light up")
        attach(app, name: "06-lit-card")

        litCard.tap()
        XCTAssertEqual(app.staticTexts["scoreValue"].label, "1")
        XCTAssertEqual(lives(app), "3")
    }

    // Tapping a dark card costs one life and gives no points.
    func testLightItUpWrongTapLosesALife() throws {
        let app = launchApp()
        open("lightItUpModeButton", in: app)
        startLightItUp(app)

        let darkCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'card' AND value == 'off'")
        ).firstMatch
        XCTAssertTrue(darkCard.waitForExistence(timeout: 5))
        darkCard.tap()

        XCTAssertEqual(lives(app), "2")
        XCTAssertEqual(app.staticTexts["scoreValue"].label, "0")
    }

    // The round length chosen in Settings shows on the Light It Up start screen.
    func testRoundLengthSettingIsShown() throws {
        let app = launchApp()

        let settings = app.buttons["settingsButton"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()

        let thirty = app.buttons["roundLength30"]
        XCTAssertTrue(thirty.waitForExistence(timeout: 5))
        thirty.tap()
        app.buttons["settingsDoneButton"].tap()

        open("lightItUpModeButton", in: app)
        XCTAssertEqual(app.staticTexts["roundLabel"].label, "30s round")
    }

    // MARK: Helpers

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--reset", "--ui-testing"]
        app.launch()
        return app
    }

    // Taps a mode button on the Home screen
    private func open(_ identifier: String, in app: XCUIApplication) {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "\(identifier) should be on Home")
        button.tap()
    }

    private func startLightItUp(_ app: XCUIApplication) {
        let start = app.buttons["startButton"]
        XCTAssertTrue(start.waitForExistence(timeout: 5), "Start button should be on screen")
        start.tap()
    }

    private func lives(_ app: XCUIApplication) -> String {
        app.descendants(matching: .any)["lives"].value as? String ?? "?"
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