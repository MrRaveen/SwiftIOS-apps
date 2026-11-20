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