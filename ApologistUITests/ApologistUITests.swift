import XCTest

final class ApologistUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testQuestionReceivesRealResponse() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-hasCompletedOnboarding", "YES",
            "-dailyQuestionCount", "0"
        ]
        app.launch()

        let questionField = app.textFields["chat.question"]
        XCTAssertTrue(questionField.waitForExistence(timeout: 10))
        questionField.tap()
        questionField.typeText("What does grace mean in Christianity?")

        let sendButton = app.buttons["chat.send"]
        XCTAssertTrue(sendButton.isEnabled)
        sendButton.tap()

        let response = app.staticTexts.matching(identifier: "chat.response").firstMatch
        let usableAnswer = NSPredicate(
            format: "label.length > 20 AND NOT label CONTAINS[c] %@",
            "couldn't"
        )
        expectation(for: usableAnswer, evaluatedWith: response)
        waitForExpectations(timeout: 60)
    }
}
