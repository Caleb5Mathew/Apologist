//
//  ClaudeAPI.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/8/24.
//

import Foundation

class ClaudeAPI: NSObject, URLSessionDataDelegate {
    static let shared = ClaudeAPI()

    private let apiKey: String = {
        if let envKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !envKey.isEmpty {
            return envKey
        }

        if let bundledKey = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String,
           !bundledKey.isEmpty {
            return bundledKey
        }

        return ""
    }()

    private let apiUrl = "https://api.anthropic.com/v1/messages"
    private let apiVersion = "2023-06-01"
    var memoryBuffer: [[String: Any]] = []

    var memory: [String] = [] // Default is internal

    // For streaming
    private var currentSession: URLSession?
    private var currentStreamTask: URLSessionDataTask?
    private var currentOnReceive: ((String) -> Void)?
    private var currentOnComplete: (() -> Void)?
    private var accumulatedData = Data()
    private var isStreaming = false

    // Define different prompts for buttons
    let defaultPrompt = """
    Respond from a Christian POV but don't explicitly say it, the viewer shouldn't know explicitly you're protestant. the goal is for the user to fully understand the answer to their question, cite famous theologians, protestant or catholic (when it doesn't conflict with protestant views), bible verses, or books whenever it benefits the answer, more bible verses than anything, try to understand where they're coming from or address common misconceptions.
    Do all of this in less than 150 words

    Don't start with a summary of the question or anything, just dive into the question, be clear
    """

    let digDeeperPrompt = """
    Based off your last response dig even deeper, reference protestant theologians whenever it fits but not too often, and catholic figures that don't clash with protestant teachings. You're speaking from a Christian POV but don't explicitly say it please. Also, dig deep, maybe introduce a thought-provoking question (not all the time though, just sometimes, like 30% of the time), or address common misconceptions or famous ways of thinking. Include interesting facts that support the Christian agenda. Don't start with a summary of the question or a bland noting.
    """

    let simplifyPrompt = """
    Using your previous response, simplify the message into plain and easy-to-understand language. Focus on making it clear and approachable for someone unfamiliar with complex theology or advanced Christian concepts. Keep the essence and meaning intact, but avoid using overly complicated words or ideas. Please speak as if you are explaining to a curious beginner in faith.
    """


    let expandPrompt = """
    Based on your history, what the past question/topic was about, expand on the topic. Note what already has been said and aim to add to the conversation, not just restate what has been said. Go in depth as well, and if it helps, sometimes quote famous Protestant theologians and Catholic figures that don't conflict with Protestant views. Also, answer from a Christian POV. If you can, start with the answer as well. Don't say 'Answer:' if it's not that simple of a question, be wary of that. Don't start with a recap of the question or the prompt.
    """

    let analogyPrompt = """
    Create an analogy with a Christianity mindset based on the previous question/topic in your memory. Make the analogy a bit interesting, it could be about the lives of famous people, funny stories, etc., and it could be about anything. Don't announce anything at the start, just dive into the analogy. Address common ways of thinking, misconceptions, etc. You can leave it unclear and be invested in the analogy at first, but in the paragraph after, explain the meaning of it with a smooth, seamless transition.
    """
    /// Adds a question to the memory buffer and ensures it retains only the last 10 questions
    func addToMemory(_ message: String) {
        if memory.count >= 10 {
            // Summarize memory before removing oldest entries
            summarizeMemory { summary in
                if let summary = summary {
                    self.memory.removeFirst() // Remove the oldest message
                    self.memory.removeFirst() // Remove the next oldest message
                    self.memory.append("Summary: \(summary)") // Add summarized version
                }
            }
        }
        memory.append(message) // Add the new message
        print("DEBUG: Updated memory: \(memory)")
    }


    func summarizeMemory(completion: @escaping (String?) -> Void) {
        guard !memory.isEmpty else {
            print("DEBUG: Memory is empty, no summarization needed.")
            completion(nil)
            return
        }

        // Combine memory into a single text block for summarization
        let memoryContext = memory.joined(separator: "\n")
        let summarizationPrompt = """
        Summarize the following conversation into a concise representation retaining the main points. Format the summary as: "Q: [user questions], A: [assistant responses]".

        \(memoryContext)
        """

        // Send summarization request
        sendQuery(summarizationPrompt) { result in
            switch result {
            case .success(let summary):
                print("DEBUG: Memory summarization successful:\n\(summary)")
                completion(summary)
            case .failure(let error):
                print("DEBUG: Memory summarization failed with error: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }






    func sendStreamedQuery(_ query: String, onReceive: @escaping (String) -> Void, onComplete: @escaping () -> Void) {
        // Validate API key
        guard apiKey != "YOUR_API_KEY_HERE" && apiKey != "API-KEY" && apiKey != "api-key" && !apiKey.isEmpty else {
            print("ERROR: Claude API key is not configured. Please set your API key in ClaudeAPI.swift")
            DispatchQueue.main.async { onComplete() }
            return
        }

        guard let url = URL(string: apiUrl) else {
            print("DEBUG: Invalid URL")
            DispatchQueue.main.async { onComplete() }
            return
        }

        addToMemory(query) // Always add queries to memory


        // Combine memory and user query
        let isAnalogy = query.contains(analogyPrompt)

        // Format memory for context, not as active queries
        let formattedMemory = memory.suffix(10).map { "- \($0)" }.joined(separator: "\n")

        // Build the context
        let context = """
        Background context:
        \(formattedMemory)

        \(isAnalogy ? analogyPrompt : "Current question:\n\(query)")
        """


        print("DEBUG: Sending query with context:\n\(context)")

        let parameters: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": 3000,
            "temperature": 0,
            "stream": true,
            "system": "Respond from a Christian Protestant perspective, but avoid explicitly stating or making it obvious that you are Protestant. The goal is to provide the user with a clear and comprehensive understanding of their question. Reference Bible verses prominently, alongside theologians (Protestant or Catholic, where views align with Protestant theology) or relevant books when helpful. Ensure the response is concise (under 240 words) and directly addresses the question without unnecessary preamble or summaries. Tailor the response to the user's perspective, addressing potential misconceptions or concerns they might have. Always prioritize what would best benefit the user in understanding the answer, guiding them with clarity, compassion, and biblical truth.",
            "messages": [
                [
                    "role": "user",
                    "content": context
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print("DEBUG: Failed to serialize request body: \(error.localizedDescription)")
            DispatchQueue.main.async { onComplete() }
            return
        }

        // Cancel any existing stream
        currentStreamTask?.cancel()

        // Store callbacks and reset state
        currentOnReceive = onReceive
        currentOnComplete = onComplete
        accumulatedData = Data()
        isStreaming = true

        // Create URLSession with delegate for streaming (store reference to prevent deallocation)
        // Use main queue for delegate callbacks to ensure thread safety with UI updates and property access
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
        currentSession = session
        let task = session.dataTask(with: request)
        currentStreamTask = task
        task.resume()
    }

    // MARK: - URLSessionDataDelegate for streaming

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        accumulatedData.append(data)

        // Process accumulated data for SSE lines
        if let string = String(data: accumulatedData, encoding: .utf8) {
            let lines = string.components(separatedBy: "\n")

            // Keep the last incomplete line in accumulatedData
            if let lastLine = lines.last, !lastLine.hasSuffix("\n") && !lastLine.isEmpty {
                accumulatedData = lastLine.data(using: .utf8) ?? Data()
            } else {
                accumulatedData = Data()
            }

            // Process complete lines
            for line in lines.dropLast(1) {
                processSSELine(line)
            }
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didCompleteWithError error: Error?) {
        // Skip if already completed (e.g., from message_stop)
        guard isStreaming else { return }
        isStreaming = false

        if let error = error {
            // Ignore cancellation errors (expected when we manually cancel after message_stop)
            if (error as NSError).code == NSURLErrorCancelled {
                return
            }
            print("DEBUG: Streaming error: \(error.localizedDescription)")
        } else {
            // Process any remaining data
            if let string = String(data: accumulatedData, encoding: .utf8) {
                let lines = string.components(separatedBy: "\n")
                for line in lines {
                    if !line.isEmpty {
                        processSSELine(line)
                    }
                }
            }

            // Check HTTP status
            if let httpResponse = dataTask.response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    print("DEBUG: HTTP Error: \(httpResponse.statusCode)")
                    if let data = accumulatedData.isEmpty ? nil : accumulatedData,
                       let errorString = String(data: data, encoding: .utf8) {
                        print("DEBUG: Error response: \(errorString)")
                    }
                } else {
                    print("DEBUG: Streaming completed successfully.")
                }
            }
        }

        DispatchQueue.main.async {
            self.currentOnComplete?()
            self.currentOnReceive = nil
            self.currentOnComplete = nil
            self.currentSession?.invalidateAndCancel()
            self.currentSession = nil
        }
    }

    private func processSSELine(_ line: String) {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

        // Skip empty lines and event type lines
        guard !trimmedLine.isEmpty && !trimmedLine.hasPrefix("event:") else { return }

        // Process data lines
        if trimmedLine.hasPrefix("data: ") {
            let jsonString = String(trimmedLine.dropFirst(6)) // Remove "data: " prefix

            // Skip [DONE] marker (OpenAI format, but harmless to check)
            if jsonString.trimmingCharacters(in: .whitespacesAndNewlines) == "[DONE]" {
                return
            }

            guard let jsonData = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                return
            }

            // Check for error and completion events (Anthropic format)
            if let type = json["type"] as? String {
                if type == "error", let errObj = json["error"] as? [String: Any], let msg = errObj["message"] as? String {
                    print("DEBUG: API error event: \(msg)")
                    self.isStreaming = false
                    self.currentOnComplete?()
                    self.currentOnReceive = nil
                    self.currentOnComplete = nil
                    self.currentStreamTask?.cancel()
                    self.currentSession?.invalidateAndCancel()
                    self.currentSession = nil
                    return
                }
                if type == "message_stop" {
                    // Stream is complete - manually trigger completion since connection may stay open
                    print("DEBUG: Received message_stop - completing stream")
                    self.isStreaming = false
                    self.currentOnComplete?()
                    self.currentOnReceive = nil
                    self.currentOnComplete = nil
                    self.currentStreamTask?.cancel()
                    self.currentSession?.invalidateAndCancel()
                    self.currentSession = nil
                    return
                }
                if type == "content_block_stop" {
                    return
                }
            }

            // Handle delta updates (content_block_delta events)
            if let delta = json["delta"] as? [String: Any],
               let textDelta = delta["text"] as? String {
                DispatchQueue.main.async {
                    self.currentOnReceive?(textDelta)
                }
            }
        }
    }






    func summarizeConversation(question: String, response: String, completion: @escaping (String?) -> Void) {
        let conversation = "Q: \(question)\nA: \(response)"
        let prompt = "Summarize the following conversation to retain its key points:\n\n\(conversation)"

        sendQuery(prompt) { result in
            switch result {
            case .success(let summary):
                print("DEBUG: Summarization successful:\n\(summary)")
                completion(summary)
            case .failure(let error):
                print("DEBUG: Summarization failed with error: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }




    /// Sends a single query to the API (non-streamed)
    func sendQuery(_ query: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Implementation for non-streamed query (reuse as needed)
    }
}
