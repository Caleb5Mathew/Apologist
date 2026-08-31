import FirebaseFunctions
import Foundation

enum ClaudeResponseParser {
    enum Error: Swift.Error {
        case invalidResponse
    }

    static func text(from value: Any) throws -> String {
        guard let payload = value as? [String: Any],
              let text = payload["text"] as? String,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Error.invalidResponse
        }

        return text
    }
}

@MainActor
final class ClaudeAPI {
    typealias StreamFactory = (String) throws -> AsyncThrowingStream<String, Swift.Error>

    static let shared = ClaudeAPI()

    var memory: [String] = []
    var isRequestInProgress: Bool { currentTask != nil }

    private var currentTask: Task<Void, Never>?
    private var timeoutTask: Task<Void, Never>?
    private var currentRequestID: UUID?
    private let streamFactory: StreamFactory?
    private let requestTimeoutNanoseconds: UInt64
    private let maxContextCharacters = 11_000

    let defaultPrompt = """
    Respond from a Christian point of view without announcing a denomination. Directly answer the question,
    using Bible verses and relevant theologians when helpful. Keep the response clear and under 150 words.
    """

    let digDeeperPrompt = """
    Go deeper on the previous answer. Add useful biblical context, address common misconceptions, and include a
    thought-provoking question when it helps. Do not repeat the prior answer or begin with a recap.
    """

    let simplifyPrompt = """
    Simplify the previous answer into plain, approachable language for someone unfamiliar with theology. Keep
    the meaning intact and avoid complicated terms.
    """

    let expandPrompt = """
    Expand on the previous answer with new context rather than restating it. Use relevant Bible verses and
    theologians when helpful, and begin directly with the added insight.
    """

    let analogyPrompt = """
    Explain the previous topic with an engaging analogy, then connect the analogy back to its Christian meaning.
    Address common misconceptions without announcing the structure beforehand.
    """

    init(
        streamFactory: StreamFactory? = nil,
        requestTimeoutNanoseconds: UInt64 = 50_000_000_000
    ) {
        self.streamFactory = streamFactory
        self.requestTimeoutNanoseconds = requestTimeoutNanoseconds
    }

    func addToMemory(_ message: String) {
        memory.append(message)
        if memory.count > 10 {
            memory.removeFirst(memory.count - 10)
        }
    }

    func sendStreamedQuery(
        _ query: String,
        onReceive: @escaping (String) -> Void,
        onError: @escaping (String) -> Void,
        onComplete: @escaping () -> Void
    ) {
        guard currentTask == nil else {
            onError("Please wait for the current answer to finish.")
            onComplete()
            return
        }

        let context = makeContext(for: query)
        addToMemory("User: \(query)")

        let requestID = UUID()
        currentRequestID = requestID
        currentTask = Task { [weak self] in
            guard let self else { return }
            var fullResponse = ""

            do {
                if let streamFactory {
                    let stream = try streamFactory(context)
                    for try await text in stream {
                        try Task.checkCancellation()
                        guard !text.isEmpty else { continue }
                        fullResponse += text
                        onReceive(text)
                    }
                } else {
                    let result = try await Functions.functions(region: "us-central1")
                        .httpsCallable("answerApologistQuestion")
                        .call(["context": context])
                    try Task.checkCancellation()
                    let text = try ClaudeResponseParser.text(from: result.data)
                    fullResponse += text
                    onReceive(text)
                }

                if fullResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    onError("I couldn't form a response. Please try asking that again.")
                } else {
                    addToMemory("Assistant: \(fullResponse)")
                }
            } catch is CancellationError {
                guard currentRequestID == requestID else { return }
                onError("The request was cancelled. Please try again.")
            } catch {
                guard currentRequestID == requestID else { return }
                #if DEBUG
                NSLog("AI response failed: %@", String(reflecting: error))
                #endif
                onError("I couldn't connect right now. Please try again in a moment.")
            }

            finishRequest(requestID: requestID, onComplete: onComplete)
        }

        timeoutTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(nanoseconds: requestTimeoutNanoseconds)
            } catch {
                return
            }
            guard currentRequestID == requestID else { return }

            currentTask?.cancel()
            currentTask = nil
            currentRequestID = nil
            timeoutTask = nil
            onError("That answer took too long. Please try asking again.")
            onComplete()
        }
    }

    private func finishRequest(requestID: UUID, onComplete: () -> Void) {
        guard currentRequestID == requestID else { return }
        timeoutTask?.cancel()
        timeoutTask = nil
        currentTask = nil
        currentRequestID = nil
        onComplete()
    }

    private func makeContext(for query: String) -> String {
        let currentRequest = "Current request:\n\(query)"
        let fixedCharacters = "Previous conversation:\n\n\n".count + currentRequest.count
        var remainingCharacters = max(0, maxContextCharacters - fixedCharacters)
        var retainedMessages: [String] = []

        for message in memory.suffix(8).reversed() {
            let line = "- \(message)"
            guard remainingCharacters > 0 else { break }

            if line.count <= remainingCharacters {
                retainedMessages.append(line)
                remainingCharacters -= line.count + 1
            } else {
                retainedMessages.append(String(line.prefix(remainingCharacters)))
                remainingCharacters = 0
            }
        }

        let formattedMemory = retainedMessages.reversed().joined(separator: "\n")
        return """
        Previous conversation:
        \(formattedMemory.isEmpty ? "None" : formattedMemory)

        \(currentRequest)
        """
    }
}
