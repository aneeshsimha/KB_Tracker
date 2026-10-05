import XCTest

final class FeatureFlowsTests: XCTestCase {
    @MainActor
    func testLibraryCreatesAndSavesCustomWorkout() {
        let app = launchApp()
        app.buttons["Workouts"].tap()
        XCTAssertTrue(app.staticTexts["Test ABC"].waitForExistence(timeout: 5))
        app.buttons["Create workout"].tap()
        XCTAssertTrue(app.navigationBars["Workout builder"].waitForExistence(timeout: 5))
        let name = app.textFields["Workout name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 30) + "Smoke Builder")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Smoke Builder"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testPressLogsTargetSavesToHistoryAndCanRepeat() {
        let app = launchApp()
        tapFavorite(named: "Test Press", in: app)
        let log = app.buttons["Log target reps"]
        XCTAssertTrue(log.waitForExistence(timeout: 12))
        log.tap()
        XCTAssertTrue(app.staticTexts["Workout complete"].waitForExistence(timeout: 5))
        tapWhenVisible(app.buttons["Save session"], in: app)

        let repeatButton = app.buttons["Repeat"]
        XCTAssertTrue(repeatButton.waitForExistence(timeout: 8))
        repeatButton.tap()
        XCTAssertTrue(app.navigationBars["Workout builder"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()

        app.buttons["Workout history"].tap()
        XCTAssertTrue(app.staticTexts["Test Press"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testMixedTimedAndRepBlocksCompleteInOrder() {
        let app = launchApp()
        tapFavorite(named: "Test mixed", in: app)
        XCTAssertTrue(app.staticTexts["BLOCK 1 OF 2"].waitForExistence(timeout: 5))
        let next = app.buttons["Start next block"]
        XCTAssertTrue(next.waitForExistence(timeout: 12))
        next.tap()
        XCTAssertTrue(app.staticTexts["BLOCK 2 OF 2"].waitForExistence(timeout: 5))
        let log = app.buttons["Log target reps"]
        XCTAssertTrue(log.waitForExistence(timeout: 5))
        log.tap()
        XCTAssertTrue(app.staticTexts["Workout complete"].waitForExistence(timeout: 5))
        tapWhenVisible(app.buttons["Save session"], in: app)
        XCTAssertTrue(app.staticTexts["Test mixed"].waitForExistence(timeout: 8))
    }

    @MainActor
    func testSwingRoundCompletesWithoutRest() {
        let app = launchApp()
        tapFavorite(named: "Test Swing", in: app)
        let log = app.buttons["Log target reps"]
        XCTAssertTrue(log.waitForExistence(timeout: 12))
        log.tap()
        XCTAssertTrue(app.staticTexts["Workout complete"].waitForExistence(timeout: 5))
        tapWhenVisible(app.buttons["Save session"], in: app)
        XCTAssertTrue(app.staticTexts["Test Swing"].waitForExistence(timeout: 8))
    }

    @MainActor
    func testProgramCreatesPlanAndChangesWeeklySchedule() {
        let app = launchApp()
        app.buttons["Program"].tap()
        XCTAssertTrue(app.staticTexts["UP NEXT"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["WEEKLY SCHEDULE"].exists)
        app.buttons["2 days"].tap()
        XCTAssertTrue(app.staticTexts["0 / 2 planned sessions"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Start planned workout"].exists)
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["KB_UI_TESTING"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["Workouts"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor
    private func tapFavorite(named name: String, in app: XCUIApplication) {
        let favorite = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", name)).firstMatch
        for _ in 0..<6 where !favorite.isHittable { app.swipeUp() }
        XCTAssertTrue(favorite.waitForExistence(timeout: 5), "Favorite \(name) was not visible")
        favorite.tap()
    }

    @MainActor
    private func tapWhenVisible(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<4 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        element.tap()
    }
}
