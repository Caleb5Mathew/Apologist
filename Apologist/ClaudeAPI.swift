import FirebaseAILogic
import Foundation

@MainActor
final class ClaudeAPI {
    typealias StreamFactory = (String) throws -> AsyncThrowingStream<String, Swift.Error>

    static let shared = ClaudeAPI()

    var memory: [String] = []
    var isRequestInProgress: Bool { currentTask != nil }

    private var currentTask: Task<Void, Never>?
    private let streamFactory: StreamFactory?
    private let systemPrompt = """
    Respond from a Christian Protestant perspective without announcing the denomination. Give a clear,
    compassionate answer that directly addresses the question. Prioritize relevant Bible verses, and cite
    Protestant theologians, compatible Catholic thinkers, or books when they genuinely help. Address likely
    misconceptions and keep the answer under 240 words. Do not begin with a recap or generic preamble.
    """
    private lazy var model = FirebaseAI.firebaseAI(backend: .vertexAI(location: "global"))
        .generativeModel(
            modelName: "gemini-3.7-flash",
            generationConfig: GenerationConfig(maxOutputTokens: 1_000),
            systemInstruction: ModelContent(role: "system", parts: systemPrompt),
            requestOptions: RequestOptions(timeout: 45)
        )

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

    init(streamFactory: StreamFactory? = nil) {
        self.streamFactory = streamFactory
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

        let formattedMemory = memory.suffix(8).map { "- \($0)" }.joined(separator: "\n")
        let context = """
        Previous conversation:
        \(formattedMemory.isEmpty ? "None" : formattedMemory)

        Current request:
        \(query)
        """
        addToMemory("User: \(query)")

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
                    let stream = try model.generateContentStream(context)
                    for try await response in stream {
                        try Task.checkCancellation()
                        guard let text = response.text, !text.isEmpty else { continue }
                        fullResponse += text
                        onReceive(text)
                    }
                }

                if fullResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    onError("I couldn't form a response. Please try asking that again.")
                } else {
                    addToMemory("Assistant: \(fullResponse)")
                }
            } catch is CancellationError {
                onError("The request was cancelled. Please try again.")
            } catch {
                #if DEBUG
                print("AI response failed: \(error.localizedDescription)")
                #endif
                onError("I couldn't connect right now. Please try again in a moment.")
            }

            currentTask = nil
            onComplete()
        }
    }
}
