import XCTest

final class ApologistUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testConsecutiveQuestionsReceiveRealResponses() throws {
        guard ProcessInfo.processInfo.environment["RUN_LIVE_AI_TESTS"] == "1" else {
            throw XCTSkip("Set RUN_LIVE_AI_TESTS=1 to run the production AI integration test.")
        }

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
            format: "label.length > 20 AND NOT label CONTAINS[c] %@ AND NOT label CONTAINS[c] %@",
            "couldn't",
            "took too long"
        )
        expectation(for: usableAnswer, evaluatedWith: response)
        waitForExpectations(timeout: 60)

        questionField.tap()
        questionField.typeText("Why is forgiveness important?")

        expectation(for: NSPredicate(format: "isEnabled == YES"), evaluatedWith: sendButton)
        waitForExpectations(timeout: 30)
        sendButton.tap()

        let secondResponse = app.staticTexts.matching(identifier: "chat.response").element(boundBy: 1)
        expectation(for: usableAnswer, evaluatedWith: secondResponse)
        waitForExpectations(timeout: 60)
    }
}
