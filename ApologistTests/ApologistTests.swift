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

    @MainActor
    func testEmptyStreamShowsErrorAndCompletes() async {
        let client = ClaudeAPI { _ in
            AsyncThrowingStream { continuation in
                continuation.finish()
            }
        }
        let completion = expectation(description: "Empty stream completes")
        var receivedError: String?

        client.sendStreamedQuery(
            "Question",
            onReceive: { _ in XCTFail("An empty stream must not return text") },
            onError: { receivedError = $0 },
            onComplete: { completion.fulfill() }
        )

        await fulfillment(of: [completion], timeout: 1)
        XCTAssertEqual(receivedError, "I couldn't form a response. Please try asking that again.")
        XCTAssertFalse(client.isRequestInProgress)
    }

    @MainActor
    func testBusyRequestDoesNotPreventLaterQuery() async {
        var invocationCount = 0
        var heldContinuation: AsyncThrowingStream<String, Swift.Error>.Continuation?
        let client = ClaudeAPI { _ in
            invocationCount += 1
            if invocationCount == 1 {
                return AsyncThrowingStream { continuation in
                    heldContinuation = continuation
                }
            }
            return AsyncThrowingStream { continuation in
                continuation.yield("Later answer")
                continuation.finish()
            }
        }

        let firstCompletion = expectation(description: "First query completes")
        client.sendStreamedQuery(
            "First",
            onReceive: { _ in },
            onError: { error in XCTFail("Unexpected first error: \(error)") },
            onComplete: { firstCompletion.fulfill() }
        )

        let busyCompletion = expectation(description: "Busy query completes")
        var busyError: String?
        client.sendStreamedQuery(
            "Busy",
            onReceive: { _ in XCTFail("Busy query must not return text") },
            onError: { busyError = $0 },
            onComplete: { busyCompletion.fulfill() }
        )
        await fulfillment(of: [busyCompletion], timeout: 1)
        XCTAssertEqual(busyError, "Please wait for the current answer to finish.")
        XCTAssertTrue(client.isRequestInProgress)

        heldContinuation?.yield("First answer")
        heldContinuation?.finish()
        await fulfillment(of: [firstCompletion], timeout: 1)
        XCTAssertFalse(client.isRequestInProgress)

        let laterCompletion = expectation(description: "Later query completes")
        client.sendStreamedQuery(
            "Later",
            onReceive: { _ in },
            onError: { error in XCTFail("Unexpected later error: \(error)") },
            onComplete: { laterCompletion.fulfill() }
        )
        await fulfillment(of: [laterCompletion], timeout: 1)
        XCTAssertEqual(invocationCount, 2)
        XCTAssertFalse(client.isRequestInProgress)
    }

    @MainActor
    func testNeverEndingStreamTimesOutAndUnlocksClient() async {
        var invocationCount = 0
        var heldContinuation: AsyncThrowingStream<String, Swift.Error>.Continuation?
        let client = ClaudeAPI(
            streamFactory: { _ in
                invocationCount += 1
                if invocationCount > 1 {
                    return AsyncThrowingStream { continuation in
                        continuation.yield("Recovered answer")
                        continuation.finish()
                    }
                }
                return AsyncThrowingStream { continuation in
                    heldContinuation = continuation
                    continuation.yield("Partial answer")
                }
            },
            requestTimeoutNanoseconds: 20_000_000
        )
        let completion = expectation(description: "Timed out request completes")
        var receivedError: String?

        client.sendStreamedQuery(
            "Question",
            onReceive: { _ in },
            onError: { receivedError = $0 },
            onComplete: { completion.fulfill() }
        )

        await fulfillment(of: [completion], timeout: 1)
        XCTAssertEqual(receivedError, "That answer took too long. Please try asking again.")
        XCTAssertFalse(client.isRequestInProgress)

        let retryCompletion = expectation(description: "Query after timeout completes")
        var retryText = ""
        client.sendStreamedQuery(
            "Retry",
            onReceive: { retryText += $0 },
            onError: { error in XCTFail("Unexpected retry error: \(error)") },
            onComplete: { retryCompletion.fulfill() }
        )
        await fulfillment(of: [retryCompletion], timeout: 1)
        XCTAssertEqual(retryText, "Recovered answer")
        XCTAssertEqual(invocationCount, 2)
        XCTAssertFalse(client.isRequestInProgress)

        heldContinuation?.finish()
        XCTAssertFalse(client.isRequestInProgress)
    }

    func testAppCheckFactoryCreatesProvider() throws {
        let app = try XCTUnwrap(FirebaseApp.app())
        let provider = ApologistAppCheckProviderFactory().createProvider(with: app)

        XCTAssertNotNil(provider)
    }

    func testFreeUsersCanSendExactlyFiveQuestions() {
        for count in 0..<QuestionAccessPolicy.freeDailyLimit {
            XCTAssertTrue(QuestionAccessPolicy.canSend(dailyQuestionCount: count, isSubscribed: false))
            XCTAssertEqual(
                QuestionAccessPolicy.remainingFreeQuestions(dailyQuestionCount: count),
                QuestionAccessPolicy.freeDailyLimit - count
            )
        }

        XCTAssertFalse(
            QuestionAccessPolicy.canSend(
                dailyQuestionCount: QuestionAccessPolicy.freeDailyLimit,
                isSubscribed: false
            )
        )
        XCTAssertEqual(
            QuestionAccessPolicy.remainingFreeQuestions(
                dailyQuestionCount: QuestionAccessPolicy.freeDailyLimit
            ),
            0
        )
    }

    func testSubscribedUsersHaveUnlimitedQuestions() {
        XCTAssertTrue(
            QuestionAccessPolicy.canSend(dailyQuestionCount: 100, isSubscribed: true)
        )
        XCTAssertFalse(
            QuestionAccessPolicy.shouldRecordQuestion(isSubscribed: true, requestSucceeded: true)
        )
    }

    func testFailedRequestDoesNotUseFreeQuestion() {
        XCTAssertFalse(
            QuestionAccessPolicy.shouldRecordQuestion(isSubscribed: false, requestSucceeded: false)
        )
        XCTAssertTrue(
            QuestionAccessPolicy.shouldRecordQuestion(isSubscribed: false, requestSucceeded: true)
        )
    }

    func testQuestionLimitResetsOnNextCalendarDay() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let lastAccess = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 30, hour: 23)))
        let sameDay = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 30, hour: 23, minute: 59)))
        let nextDay = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 31)))

        XCTAssertFalse(QuestionAccessPolicy.isNewDay(lastAccessDate: lastAccess, now: sameDay, calendar: calendar))
        XCTAssertTrue(QuestionAccessPolicy.isNewDay(lastAccessDate: lastAccess, now: nextDay, calendar: calendar))
    }

    @MainActor
    func testClientSupportsConsecutiveQueries() async {
        var receivedPrompts: [String] = []
        let client = ClaudeAPI { prompt in
            receivedPrompts.append(prompt)
            return AsyncThrowingStream { continuation in
                continuation.yield("Answer")
                continuation.finish()
            }
        }

        for question in ["First question", "Second question"] {
            let completion = expectation(description: "\(question) completes")
            client.sendStreamedQuery(
                question,
                onReceive: { _ in },
                onError: { error in XCTFail("Unexpected error: \(error)") },
                onComplete: { completion.fulfill() }
            )
            await fulfillment(of: [completion], timeout: 1)
            XCTAssertFalse(client.isRequestInProgress)
        }

        XCTAssertEqual(receivedPrompts.count, 2)
        XCTAssertTrue(receivedPrompts[1].contains("First question"))
        XCTAssertTrue(receivedPrompts[1].contains("Second question"))
    }
}
