//
//  ApologistTests.swift
//  ApologistTests
//
//  Created by Caleb Matthews  on 12/6/24.
//

import XCTest
import FirebaseCore
@testable import Apologist

private enum TestStreamError: Swift.Error {
    case failed
}

final class ApologistTests: XCTestCase {
    @MainActor
    func testMemoryKeepsOnlyTenMostRecentMessages() {
        let client = ClaudeAPI()

        for index in 0..<12 {
            client.addToMemory("Message \(index)")
        }

        XCTAssertEqual(client.memory.count, 10)
        XCTAssertEqual(client.memory.first, "Message 2")
        XCTAssertEqual(client.memory.last, "Message 11")

    }

    @MainActor
    func testSuccessfulStreamDeliversTextAndCompletes() async {
        let client = ClaudeAPI { _ in
            AsyncThrowingStream { continuation in
                continuation.yield("A clear ")
                continuation.yield("answer.")
                continuation.finish()
            }
        }
        let completion = expectation(description: "Stream completes")
        var receivedText = ""
        var receivedError: String?

        client.sendStreamedQuery(
            "Question",
            onReceive: { receivedText += $0 },
            onError: { receivedError = $0 },
            onComplete: { completion.fulfill() }
        )

        XCTAssertTrue(client.isRequestInProgress)
        await fulfillment(of: [completion], timeout: 1)
        XCTAssertEqual(receivedText, "A clear answer.")
        XCTAssertNil(receivedError)
        XCTAssertFalse(client.isRequestInProgress)
    }

    @MainActor
    func testFailedStreamShowsErrorAndCompletes() async {
        let client = ClaudeAPI { _ in throw TestStreamError.failed }
        let completion = expectation(description: "Failed stream completes")
        var receivedError: String?

        client.sendStreamedQuery(
            "Question",
            onReceive: { _ in XCTFail("A failed stream must not return text") },
            onError: { receivedError = $0 },
            onComplete: { completion.fulfill() }
        )

        await fulfillment(of: [completion], timeout: 1)
        XCTAssertEqual(receivedError, "I couldn't connect right now. Please try again in a moment.")
        XCTAssertFalse(client.isRequestInProgress)
    }

    func testAppCheckFactoryCreatesProvider() throws {
        let app = try XCTUnwrap(FirebaseApp.app())
        let provider = ApologistAppCheckProviderFactory().createProvider(with: app)

        XCTAssertNotNil(provider)
    }
}
