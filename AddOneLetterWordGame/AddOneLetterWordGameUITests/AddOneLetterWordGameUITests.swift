import XCTest

final class AddOneLetterWordGameUITests: XCTestCase {
    func testLaunchDisplaysPlayScreen() {
        let app = XCUIApplication()
        app.launch()

        let newGameButton = app.buttons["New Game"]
        XCTAssertTrue(newGameButton.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Hint"].exists)
        XCTAssertTrue(app.buttons["Submit"].exists)
    }

    func testOpenAndDismissNewGameSheet() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["New Game"].tap()
        let sheetNavBar = app.navigationBars["New Game"]
        XCTAssertTrue(sheetNavBar.waitForExistence(timeout: 2))
        sheetNavBar.buttons["Close"].tap()
    }

    func testNavigateToSettings() {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))
        let soundToggle = app.switches["Sound"]
        XCTAssertTrue(soundToggle.exists)
    }
}
