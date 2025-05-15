//
//
//
//import Foundation
//
//class ClaudeAPI: NSObject {
//
//    static let shared = ClaudeAPI()
//    private let apiUrl = "https://api.anthropic.com/v1/messages"
//    private let apiVersion = "2023-06-01"
//    var memoryBuffer: [[String: Any]] = []
//    private var streamingSession: URLSession?
//    private var streamingTask: URLSessionDataTask?
//    private var streamedDataBuffer = Data()
//    private var onStreamReceive: ((String) -> Void)?
//    private var onStreamComplete: (() -> Void)?
//    private var isStreamingAnalogy = false
//    private var receivedFullResponse = ""
//    var memory: [String] = [] // Default is internal
//    
//    // Define different prompts for buttons
//    let defaultPrompt = """
//    Respond from a Christian POV but don't explicitly say it, the viewer shouldn't know explicitly you're protestant. the goal is for the user to fully understand the answer to their question, cite famous theologians, protestant or catholic (when it doesn't conflict with protestant views), bible verses, or books whenever it benefits the answer, more bible verses than anything, try to understand where they're coming from or address common misconceptions.
//    Do all of this in less than 150 words
//    
//    Don't start with a summary of the question or anything, just dive into the question, be clear
//    """
//    
//    let digDeeperPrompt = """
//    Based off your last response dig even deeper, reference protestant theologians whenever it fits but not too often, and catholic figures that don't clash with protestant teachings. You're speaking from a Christian POV but don't explicitly say it please. Also, dig deep, maybe introduce a thought-provoking question (not all the time though, just sometimes, like 30% of the time), or address common misconceptions or famous ways of thinking. Include interesting facts that support the Christian agenda. Don't start with a summary of the question or a bland noting.
//    """
//    
//    let simplifyPrompt = """
//    Using your previous response, simplify the message into plain and easy-to-understand language. Focus on making it clear and approachable for someone unfamiliar with complex theology or advanced Christian concepts. Keep the essence and meaning intact, but avoid using overly complicated words or ideas. Please speak as if you are explaining to a curious beginner in faith.
//    """
//    
//    
//    let expandPrompt = """
//    Based on your history, what the past question/topic was about, expand on the topic. Note what already has been said and aim to add to the conversation, not just restate what has been said. Go in depth as well, and if it helps, sometimes quote famous Protestant theologians and Catholic figures that don't conflict with Protestant views. Also, answer from a Christian POV. If you can, start with the answer as well. Don't say 'Answer:' if it's not that simple of a question, be wary of that. Don't start with a recap of the question or the prompt.
//    """
//    
//    let analogyPrompt = """
//    Create an analogy with a Christianity mindset based on the previous question/topic in your memory. Make the analogy a bit interesting, it could be about the lives of famous people, funny stories, etc., and it could be about anything. Don't announce anything at the start, just dive into the analogy. Address common ways of thinking, misconceptions, etc. You can leave it unclear and be invested in the analogy at first, but in the paragraph after, explain the meaning of it with a smooth, seamless transition.
//    """
//    /// Adds a question to the memory buffer and ensures it retains only the last 10 questions
//    func addToMemory(_ message: String) {
//        if memory.count >= 10 {
//            // Summarize memory before removing oldest entries
//            summarizeMemory { summary in
//                if let summary = summary {
//                    self.memory.removeFirst() // Remove the oldest message
//                    self.memory.removeFirst() // Remove the next oldest message
//                    self.memory.append("Summary: \(summary)") // Add summarized version
//                }
//            }
//        }
//        memory.append(message) // Add the new message
//        print("DEBUG: Updated memory: \(memory)")
//    }
//    
//    
//    func summarizeMemory(completion: @escaping (String?) -> Void) {
//        guard !memory.isEmpty else {
//            print("DEBUG: Memory is empty, no summarization needed.")
//            completion(nil)
//            return
//        }
//        
//        // Combine memory into a single text block for summarization
//        let memoryContext = memory.joined(separator: "\n")
//        let summarizationPrompt = """
//        Summarize the following conversation into a concise representation retaining the main points. Format the summary as: "Q: [user questions], A: [assistant responses]".
//        
//        \(memoryContext)
//        """
//        
//        // Send summarization request
//        sendQuery(summarizationPrompt) { result in
//            switch result {
//            case .success(let summary):
//                print("DEBUG: Memory summarization successful:\n\(summary)")
//                completion(summary)
//            case .failure(let error):
//                print("DEBUG: Memory summarization failed with error: \(error.localizedDescription)")
//                completion(nil)
//            }
//        }
//    }
//    
//    
//    
//    
//    
//    
//    func sendStreamedQuery(_ query: String, onReceive: @escaping (String) -> Void, onComplete: @escaping () -> Void) {
//        var fullResponse = ""
//        guard let url = URL(string: apiUrl) else {
//            print("DEBUG: Invalid URL")
//            return
//        }
//        
//        // Add the current query to memory
//        if !query.contains(analogyPrompt) {
//            // Only add non-analogy queries to memory
//            addToMemory(query)
//        }
//        
//        // Determine if the query is for analogy
//        let isAnalogy = query.contains(analogyPrompt)
//        
//        // Format memory context (last 10 entries) for inclusion in the prompt
//        let formattedMemory = memory.suffix(10).map { "- \($0)" }.joined(separator: "\n")
//        
//        // Build the full context based on the type of query (Analogy or Regular)
//        let context = isAnalogy
//        ? """
//            \(analogyPrompt)
//            
//            Based on the following memory context:
//            \(formattedMemory)
//            
//            Current input:
//            \(query)
//            """
//        : """
//            Background context:
//            \(formattedMemory)
//            
//            Current question:
//            \(query)
//            """
//        
//        // Log the constructed context for debugging
//        print("DEBUG: Sending query with context:\n\(context)")
//        
//        // Define parameters for the API call
//        let parameters: [String: Any] = [
//            "model": "claude-3-5-sonnet-20241022",
//            "max_tokens": 3000,
//            "temperature": 0,
//            "stream": true,
//            "system": """
//            Respond from a Christian Protestant perspective, but avoid explicitly stating or making it obvious that you are Protestant. The goal is to provide the user with a clear and comprehensive understanding of their question. Reference Bible verses prominently, alongside theologians (Protestant or Catholic, where views align with Protestant theology) or relevant books when helpful. Ensure the response is concise (under 200 words) and directly addresses the question without unnecessary preamble or summaries. Tailor the response to the user's perspective, addressing potential misconceptions or concerns they might have. Always prioritize what would best benefit the user in understanding the answer, guiding them with clarity, compassion, and biblical truth.
//            """,
//            "messages": [
//                [
//                    "role": "user",
//                    "content": context
//                ]
//            ]
//        ]
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
//        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
//        } catch {
//            print("DEBUG: Failed to serialize request body: \(error.localizedDescription)")
//            return
//        }
//        
//        var isAnalogySection = false // Tracks if we're in the analogy section
//        self.onStreamReceive = onReceive
//        self.onStreamComplete = onComplete
//        self.isStreamingAnalogy = isAnalogy
//        
//        let sessionConfig = URLSessionConfiguration.default
//        self.streamingSession = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
//        
//        self.streamingTask = self.streamingSession?.dataTask(with: request)
//        self.streamingTask?.resume()
//        
        
        //        let task = URLSession.shared.dataTask(with: request) { data, response, error in
        //            if let httpResponse = response as? HTTPURLResponse {
        //                print("DEBUG: HTTP Status Code: \(httpResponse.statusCode)")
        //
        //                if !(200...299).contains(httpResponse.statusCode) {
        //                    print("DEBUG: 🚨 Unexpected HTTP status code: \(httpResponse.statusCode)")
        //                    DispatchQueue.main.async {
        //                        onReceive("[Error: Server returned status code \(httpResponse.statusCode)]")
        //                        onComplete()
        //                    }
        //                    return
        //                }
        //            }
        //
        //
        //            guard error == nil else {
        //                print("DEBUG: Networking error: \(error!.localizedDescription)")
        //                DispatchQueue.main.async {
        //                    onComplete()
        //                }
        //                return
        //            }
        //            guard let data = data else {
        //                print("DEBUG: ❗ No data received.")
        //                DispatchQueue.main.async {
        //                    onComplete()
        //                }
        //                return
        //            }
        //
        //            guard let rawResponse = String(data: data, encoding: .utf8) else {
        //                print("DEBUG: ❗ Failed to decode UTF-8 response.")
        //                if let rawDump = String(data: data, encoding: .ascii) {
        //                    print("DEBUG: ASCII fallback content: \(rawDump.prefix(300))")
        //                }
        //                DispatchQueue.main.async {
        //                    onComplete()
        //                }
        //                return
        //            }
        //
        //
        //            // Process Server-Sent Events (SSE) line by line
        //            rawResponse.enumerateLines { line, _ in
        //                if line.starts(with: "data: ") {
        //                    let jsonString = line.replacingOccurrences(of: "data: ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        //
        //                    if let jsonData = jsonString.data(using: .utf8),
        //                       let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
        //
        //                        // ✅ Handle 'delta' part (text chunks)
        //                        if let delta = json["delta"] as? [String: Any],
        //                           let textDelta = delta["text"] as? String {
        //
        //                            print("🔹 Text chunk received: \(textDelta)") // 👈 Add this line
        //                            if isAnalogy {
        //                                if !isAnalogySection && textDelta.lowercased().contains("consider") {
        //                                    isAnalogySection = true
        //                                    onReceive("\n\n--- Analogy Starts Below ---\n\n")
        //                                }
        //                                onReceive(textDelta)
        //                            } else {
        //                                onReceive(textDelta)
        //                            }
        //
        //                            // Add to fullResponse
        //                            fullResponse += textDelta
        //                        }
        //
        //                        // ✅ Handle 'stop_reason'
        //                        if let stopReason = json["stop_reason"] as? String, stopReason == "end_turn" {
        //                            print("DEBUG: Stream ended. Full response collected:\n\(fullResponse)")
        //
        //                            if fullResponse.isEmpty {
        //                                print("DEBUG: ❗ Claude returned empty response.")
        //                                DispatchQueue.main.async {
        //                                    onReceive("[No response received, try again.]")
        //                                }
        //                            }
        //
        //                        }
        //
        //                    } // END of jsonData block
        //                } // END of starts(with: data)
        //            }
        ////            rawResponse.enumerateLines { line, _ in
        ////                if line.starts(with: "data: ") {
        ////                    let jsonString = line.replacingOccurrences(of: "data: ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        ////
        ////                    if let jsonData = jsonString.data(using: .utf8),
        ////                       let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
        ////                       let delta = json["delta"] as? [String: Any],
        ////                       let textDelta = delta["text"] as? String {
        ////
        ////                        if isAnalogy {
        ////                            if !isAnalogySection && textDelta.lowercased().contains("consider") {
        ////                                isAnalogySection = true
        ////                                onReceive("\n\n--- Analogy Starts Below ---\n\n") // Send the separator to the UI
        ////                            }
        ////                            // Send analogy-specific response chunks
        ////                            onReceive(textDelta)
        ////                        } else {
        ////                            // For regular responses, handle normally
        ////                            onReceive(textDelta)
        ////                        }
        ////                        fullResponse += textDelta
        ////                    }
        ////
        ////                }
        ////            }
        ////
        ////
        ////
        //
        //
        //            DispatchQueue.main.async {
        //                print("DEBUG: Streaming complete. Triggering memory updates and summarization.")
        //                if !fullResponse.isEmpty {
        //                    // Add to regular memory
        //                    ClaudeAPI.shared.addToMemory(fullResponse)
        //                    print("DEBUG: Final response added to memory: \(fullResponse)")
        //
        //                    // ✅ Also add to memoryBuffer for summarization
        //                    ClaudeAPI.shared.memoryBuffer.append([
        //                        "role": "assistant",
        //                        "content": fullResponse
        //                    ])
        //                } else {
        //                    print("DEBUG: No final response content.")
        //                }
        //
        //                // ✅ Add assistant response to memory (applies to all query types)
        //                if let lastAssistantMessage = ClaudeAPI.shared.memoryBuffer.last(where: { $0["role"] as? String == "assistant" })?["content"] as? String {
        //                    ClaudeAPI.shared.addToMemory(lastAssistantMessage)
        //                    print("DEBUG: Assistant response added to memory: \(lastAssistantMessage)")
        //                } else {
        //                    print("DEBUG: No valid assistant response found to add to memory.")
        //                }
        //
        //                // ✅ Add user input to memory (applies to all query types)
        //                ClaudeAPI.shared.addToMemory(query)
        //                print("DEBUG: User input added to memory: \(query)")
        //
        //                ClaudeAPI.shared.memoryBuffer.append([
        //                    "role": "user",
        //                    "content": query
        //                ])
        //
        //                // ✅ Summarize conversation for non-analogy responses
        //                if !isAnalogy {
        //                    if let lastUserMessage = ClaudeAPI.shared.memoryBuffer.last(where: { $0["role"] as? String == "user" })?["content"] as? String,
        //                       let lastAssistantMessage = ClaudeAPI.shared.memoryBuffer.last(where: { $0["role"] as? String == "assistant" })?["content"] as? String {
        //                        ClaudeAPI.shared.summarizeConversation(question: lastUserMessage, response: lastAssistantMessage) { summary in
        //                            if let summary = summary {
        //                                let summaryEntry = [
        //                                    "role": "summary",
        //                                    "content": summary
        //                                ]
        //                                ClaudeAPI.shared.memoryBuffer.append(summaryEntry)
        //                                print("DEBUG: Summary added to memory buffer:\n\(summary)")
        //                            }
        //                            onComplete() // Final completion after summarization
        //                        }
        //                    } else {
        //                        print("DEBUG: No valid user/assistant messages found for summarization.")
        //                        onComplete()
        //                    }
        //                } else {
        //                    // Skip summarization for analogy
        //                    print("DEBUG: Skipping summarization for analogy.")
        //                    onComplete()
        //                }
        //            }
        //
        //
        //
        //
        //        }
        //
        //
        //        task.resume()
        //    }
        
        
        
        
        
        
        
        
//
//}
//    func summarizeConversation(question: String, response: String, completion: @escaping (String?) -> Void) {
//        let conversation = "Q: \(question)\nA: \(response)"
//        let prompt = "Summarize the following conversation to retain its key points:\n\n\(conversation)"
//        
//        sendQuery(prompt) { result in
//            switch result {
//            case .success(let summary):
//                print("DEBUG: Summarization successful:\n\(summary)")
//                completion(summary)
//            case .failure(let error):
//                print("DEBUG: Summarization failed with error: \(error.localizedDescription)")
//                completion(nil)
//            }
//        }
//    }
//    
//    
//    
//    
//    /// Sends a single query to the API (non-streamed)
//    func sendQuery(_ query: String, completion: @escaping (Result<String, Error>) -> Void) {
//        guard let url = URL(string: apiUrl) else {
//            let error = NSError(domain: "Invalid URL", code: 0, userInfo: nil)
//            completion(Result.failure(error as Error))
//            return
//        }
//
//
//
//
//        let parameters: [String: Any] = [
//            "model": "claude-3-5-sonnet-20241022",
//            "max_tokens": 3000,
//            "temperature": 0,
//            "system": "You are a Christian theology assistant.",
//            "messages": [
//                [
//                    "role": "user",
//                    "content": query
//                ]
//            ]
//        ]
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
//        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
//        } catch {
//            completion(.failure(error as Error))
//            return
//        }
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                completion(.failure(error as Error))
//                return
//            }
//
//            guard let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//                  let content = (json["content"] as? String) ?? (json["completion"] as? String) else {
//                completion(.failure(NSError(domain: "No content in response", code: 0)))
//                return
//            }
//
//            completion(.success(content))
//        }.resume()
//    }
//
//}
//extension ClaudeAPI: URLSessionDataDelegate {
//        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
//            streamedDataBuffer.append(data)
//            
//            guard let stringData = String(data: data, encoding: .utf8) else { return }
//            
//            stringData.enumerateLines { line, _ in
//                guard line.starts(with: "data: ") else { return }
//                
//                let payload = line.replacingOccurrences(of: "data: ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
//                
//                if payload == "[DONE]" {
//                    DispatchQueue.main.async {
//                        self.finalizeStreaming()
//                    }
//                    return
//                }
//                
//                if let jsonData = payload.data(using: .utf8),
//                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
//                   let delta = json["delta"] as? [String: Any],
//                   let text = delta["text"] as? String {
//                    
//                    self.receivedFullResponse += text
//                    
//                    DispatchQueue.main.async {
//                        if self.isStreamingAnalogy && text.lowercased().contains("consider") {
//                            self.onStreamReceive?("\n\n--- Analogy Starts Below ---\n\n")
//                        }
//                        self.onStreamReceive?(text)
//                    }
//                }
//            }
//        }
//        
//        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//            DispatchQueue.main.async {
//                self.finalizeStreaming()
//            }
//        }
//        
//        private func finalizeStreaming() {
//            print("DEBUG: Streaming complete. Triggering memory update.")
//            if !receivedFullResponse.isEmpty {
//                self.addToMemory(receivedFullResponse)
//            }
//            onStreamComplete?()
//            
//            // Clean up
//            streamingTask = nil
//            streamingSession = nil
//            streamedDataBuffer = Data()
//            receivedFullResponse = ""
//            onStreamReceive = nil
//            onStreamComplete = nil
//        }
//    }
//



//
//  ClaudeAPI.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/8/24.
//

import Foundation

class ClaudeAPI {
    static let shared = ClaudeAPI()
     private let apiKey = "ANTHROPIC_API_KEY"
    private let apiUrl = "https://api.anthropic.com/v1/messages"
    private let apiVersion = "2023-06-01"
    var memoryBuffer: [[String: Any]] = []

    var memory: [String] = [] // Default is internal

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
        var fullResponse = ""
        guard let url = URL(string: apiUrl) else {
            print("DEBUG: Invalid URL")
            return
        }

        // Add the current query to memory
        if !query.contains(analogyPrompt) {
            // Only add non-analogy queries to memory
            addToMemory(query)
        }

        // Determine if the query is for analogy
        let isAnalogy = query.contains(analogyPrompt)

        // Format memory context (last 10 entries) for inclusion in the prompt
        let formattedMemory = memory.suffix(10).map { "- \($0)" }.joined(separator: "\n")

        // Build the full context based on the type of query (Analogy or Regular)
        let context = isAnalogy
            ? """
            \(analogyPrompt)

            Based on the following memory context:
            \(formattedMemory)

            Current input:
            \(query)
            """
            : """
            Background context:
            \(formattedMemory)

            Current question:
            \(query)
            """

        // Log the constructed context for debugging
        print("DEBUG: Sending query with context:\n\(context)")

        // Define parameters for the API call
        let parameters: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 3000,
            "temperature": 0,
            "stream": true,
            "system": """
            Respond from a Christian Protestant perspective, but avoid explicitly stating or making it obvious that you are Protestant. The goal is to provide the user with a clear and comprehensive understanding of their question. Reference Bible verses prominently, alongside theologians (Protestant or Catholic, where views align with Protestant theology) or relevant books when helpful. Ensure the response is concise (under 200 words) and directly addresses the question without unnecessary preamble or summaries. Tailor the response to the user's perspective, addressing potential misconceptions or concerns they might have. Always prioritize what would best benefit the user in understanding the answer, guiding them with clarity, compassion, and biblical truth.
            """,
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
            return
        }

        var isAnalogySection = false // Tracks if we're in the analogy section

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print("DEBUG: Networking error: \(error!.localizedDescription)")
                DispatchQueue.main.async {
                    onComplete()
                }
                return
            }

            guard let data = data, let rawResponse = String(data: data, encoding: .utf8) else { // Define rawResponse here
                print("DEBUG: No data or invalid encoding")
                DispatchQueue.main.async {
                    onComplete()
                }
                return
            }

            // Process Server-Sent Events (SSE) line by line
            rawResponse.enumerateLines { line, _ in
                if line.starts(with: "data: ") {
                    let jsonString = line.replacingOccurrences(of: "data: ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)

                    if let jsonData = jsonString.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {

                        // ✅ Handle 'delta' part (text chunks)
                        if let delta = json["delta"] as? [String: Any],
                           let textDelta = delta["text"] as? String {

                            if isAnalogy {
                                if !isAnalogySection && textDelta.lowercased().contains("consider") {
                                    isAnalogySection = true
                                    onReceive("\n\n--- Analogy Starts Below ---\n\n")
                                }
                                onReceive(textDelta)
                            } else {
                                onReceive(textDelta)
                            }

                            // Add to fullResponse
                            fullResponse += textDelta
                        }

                        // ✅ Handle 'stop_reason'
                        if let stopReason = json["stop_reason"] as? String, stopReason == "end_turn" {
                            print("DEBUG: Stream ended. Full response collected:\n\(fullResponse)")

                            if fullResponse.isEmpty {
                                DispatchQueue.main.async {
                                    onReceive("[No response received, try again.]")
                                }
                            }
                        }

                    } // END of jsonData block
                } // END of starts(with: data)
            }
//            rawResponse.enumerateLines { line, _ in
//                if line.starts(with: "data: ") {
//                    let jsonString = line.replacingOccurrences(of: "data: ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
//
//                    if let jsonData = jsonString.data(using: .utf8),
//                       let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
//                       let delta = json["delta"] as? [String: Any],
//                       let textDelta = delta["text"] as? String {
//
//                        if isAnalogy {
//                            if !isAnalogySection && textDelta.lowercased().contains("consider") {
//                                isAnalogySection = true
//                                onReceive("\n\n--- Analogy Starts Below ---\n\n") // Send the separator to the UI
//                            }
//                            // Send analogy-specific response chunks
//                            onReceive(textDelta)
//                        } else {
//                            // For regular responses, handle normally
//                            onReceive(textDelta)
//                        }
//                        fullResponse += textDelta
//                    }
//
//                }
//            }
//
//
//
            
            
            DispatchQueue.main.async {
                print("DEBUG: Streaming complete. Triggering memory updates and summarization.")
                if !fullResponse.isEmpty {
                    ClaudeAPI.shared.addToMemory(fullResponse)
                    print("DEBUG: Final response added to memory: \(fullResponse)")
                } else {
                    print("DEBUG: No final response content.")
                }
                // ✅ Add assistant response to memory (applies to all query types)
                if let lastAssistantMessage = ClaudeAPI.shared.memoryBuffer.last(where: { $0["role"] as? String == "assistant" })?["content"] as? String {
                    ClaudeAPI.shared.addToMemory(lastAssistantMessage)
                    print("DEBUG: Assistant response added to memory: \(lastAssistantMessage)")
                } else {
                    print("DEBUG: No valid assistant response found to add to memory.")
                }

                // ✅ Add user input to memory (applies to all query types)
                ClaudeAPI.shared.addToMemory(query)
                print("DEBUG: User input added to memory: \(query)")

                // ✅ Summarize conversation for non-analogy responses
                if !isAnalogy {
                    if let lastUserMessage = ClaudeAPI.shared.memoryBuffer.last(where: { $0["role"] as? String == "user" })?["content"] as? String,
                       let lastAssistantMessage = ClaudeAPI.shared.memoryBuffer.last(where: { $0["role"] as? String == "assistant" })?["content"] as? String {
                        ClaudeAPI.shared.summarizeConversation(question: lastUserMessage, response: lastAssistantMessage) { summary in
                            if let summary = summary {
                                let summaryEntry = [
                                    "role": "summary",
                                    "content": summary
                                ]
                                ClaudeAPI.shared.memoryBuffer.append(summaryEntry)
                                print("DEBUG: Summary added to memory buffer:\n\(summary)")
                            }
                            onComplete() // Final completion after summarization
                        }
                    } else {
                        print("DEBUG: No valid user/assistant messages found for summarization.")
                        onComplete()
                    }
                } else {
                    // Skip summarization for analogy
                    print("DEBUG: Skipping summarization for analogy.")
                    onComplete()
                }
            }




        }
        

        task.resume()
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
}//        import Foundation
//
//        class ClaudeAPI {
//            static let shared = ClaudeAPI()
//            private let apiUrl = "https://api.anthropic.com/v1/messages"
//            private let apiVersion = "2023-06-01"
//            var memoryBuffer: [[String: Any]] = []
//
//            var memory: [String] = [] // Default is internal
//
//            // Define different prompts for buttons
//            let defaultPrompt = """
//            Respond from a Christian POV but don't explicitly say it, the viewer shouldn't know explicitly you're protestant. the goal is for the user to fully understand the answer to their question, cite famous theologians, protestant or catholic (when it doesn't conflict with protestant views), bible verses, or books whenever it benefits the answer, more bible verses than anything, try to understand where they're coming from or address common misconceptions.
//            Do all of this in less than 150 words
//
//            Don't start with a summary of the question or anything, just dive into the question, be clear
//            """
//
//            let digDeeperPrompt = """
//            Based off your last response dig even deeper, reference protestant theologians whenever it fits but not too often, and catholic figures that don't clash with protestant teachings. You're speaking from a Christian POV but don't explicitly say it please. Also, dig deep, maybe introduce a thought-provoking question (not all the time though, just sometimes, like 30% of the time), or address common misconceptions or famous ways of thinking. Include interesting facts that support the Christian agenda. Don't start with a summary of the question or a bland noting.
//            """
//
//            let simplifyPrompt = """
//            Using your previous response, simplify the message into plain and easy-to-understand language. Focus on making it clear and approachable for someone unfamiliar with complex theology or advanced Christian concepts. Keep the essence and meaning intact, but avoid using overly complicated words or ideas. Please speak as if you are explaining to a curious beginner in faith.
//            """
//
//
//            let expandPrompt = """
//            Based on your history, what the past question/topic was about, expand on the topic. Note what already has been said and aim to add to the conversation, not just restate what has been said. Go in depth as well, and if it helps, sometimes quote famous Protestant theologians and Catholic figures that don't conflict with Protestant views. Also, answer from a Christian POV. If you can, start with the answer as well. Don't say 'Answer:' if it's not that simple of a question, be wary of that. Don't start with a recap of the question or the prompt.
//            """
//
//            let analogyPrompt = """
//            Create an analogy with a Christianity mindset based on the previous question/topic in your memory. Make the analogy a bit interesting, it could be about the lives of famous people, funny stories, etc., and it could be about anything. Don't announce anything at the start, just dive into the analogy. Address common ways of thinking, misconceptions, etc. You can leave it unclear and be invested in the analogy at first, but in the paragraph after, explain the meaning of it with a smooth, seamless transition.
//            """
//            /// Adds a question to the memory buffer and ensures it retains only the last 10 questions
//            func addToMemory(_ message: String) {
//                if memory.count >= 10 {
//                    // Summarize memory before removing oldest entries
//                    summarizeMemory { summary in
//                        if let summary = summary {
//                            self.memory.removeFirst() // Remove the oldest message
//                            self.memory.removeFirst() // Remove the next oldest message
//                            self.memory.append("Summary: \(summary)") // Add summarized version
//                        }
//                    }
//                }
//                memory.append(message) // Add the new message
//                print("DEBUG: Updated memory: \(memory)")
//            }
//
//
//            func summarizeMemory(completion: @escaping (String?) -> Void) {
//                guard !memory.isEmpty else {
//                    print("DEBUG: Memory is empty, no summarization needed.")
//                    completion(nil)
//                    return
//                }
//
//                // Combine memory into a single text block for summarization
//                let memoryContext = memory.joined(separator: "\n")
//                let summarizationPrompt = """
//                Summarize the following conversation into a concise representation retaining the main points. Format the summary as: "Q: [user questions], A: [assistant responses]".
//                
//                \(memoryContext)
//                """
//
//                // Send summarization request
//                sendQuery(summarizationPrompt) { result in
//                    switch result {
//                    case .success(let summary):
//                        print("DEBUG: Memory summarization successful:\n\(summary)")
//                        completion(summary)
//                    case .failure(let error):
//                        print("DEBUG: Memory summarization failed with error: \(error.localizedDescription)")
//                        completion(nil)
//                    }
//                }
//            }
//
//            
//            
//            
//            
//            
//            func sendStreamedQuery(_ query: String, onReceive: @escaping (String) -> Void, onComplete: @escaping () -> Void) {
//                var fullResponse = ""
//                guard let url = URL(string: apiUrl) else {
//                    print("DEBUG: Invalid URL")
//                    return
//                }
//
//                // Add the current query to memory
//                if !query.contains(analogyPrompt) {
//                    // Only add non-analogy queries to memory
//                    addToMemory(query)
//                }
//
//                // Determine if the query is for analogy
//                let isAnalogy = query.contains(analogyPrompt)
//
//                // Format memory context (last 10 entries) for inclusion in the prompt
//                let formattedMemory = memory.suffix(10).map { "- \($0)" }.joined(separator: "\n")
//
//                // Build the full context based on the type of query (Analogy or Regular)
//                let context = isAnalogy
//                    ? """
//                    \(analogyPrompt)
//
//                    Based on the following memory context:
//                    \(formattedMemory)
//
//                    Current input:
//                    \(query)
//                    """
//                    : """
//                    Background context:
//                    \(formattedMemory)
//
//                    Current question:
//                    \(query)
//                    """
//
//                // Log the constructed context for debugging
//                print("DEBUG: Sending query with context:\n\(context)")
//
//                // Define parameters for the API call
//                let parameters: [String: Any] = [
//                    "model": "claude-3-5-sonnet-20241022",
//                    "max_tokens": 3000,
//                    "temperature": 0,
//                    "stream": true,
//                    "system": """
//                    Respond from a Christian Protestant perspective, but avoid explicitly stating or making it obvious that you are Protestant. The goal is to provide the user with a clear and comprehensive understanding of their question. Reference Bible verses prominently, alongside theologians (Protestant or Catholic, where views align with Protestant theology) or relevant books when helpful. Ensure the response is concise (under 200 words) and directly addresses the question without unnecessary preamble or summaries. Tailor the response to the user's perspective, addressing potential misconceptions or concerns they might have. Always prioritize what would best benefit the user in understanding the answer, guiding them with clarity, compassion, and biblical truth.
//                    """,
//                    "messages": [
//                        [
//                            "role": "user",
//                            "content": context
//                        ]
//                    ]
//                ]
//
//                var request = URLRequest(url: url)
//                request.httpMethod = "POST"
//                request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
//                request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
//                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//                do {
//                    request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
//                } catch {
//                    print("DEBUG: Failed to serialize request body: \(error.localizedDescription)")
//                    return
//                }
//
//                var isAnalogySection = false // Tracks if we're in the analogy section
//
//                let task = URLSession.shared.dataTask(with: request) { data, response, error in
//                    if let httpResponse = response as? HTTPURLResponse {
//                        print("DEBUG: HTTP Status Code: \(httpResponse.statusCode)")
//
//                        if !(200...299).contains(httpResponse.statusCode) {
//                            print("DEBUG: 🚨 Unexpected HTTP status code: \(httpResponse.statusCode)")
//                            DispatchQueue.main.async {
//                                onReceive("[Error: Server returned status code \(httpResponse.statusCode)]")
//                                onComplete()
//                            }
//                            return
//                        }
//                    }
//
//
//                    guard error == nil else {
//                        print("DEBUG: Networking error: \(error!.localizedDescription)")
//                        DispatchQueue.main.async {
//                            onComplete()
//                        }
//                        return
//                    }
//                    guard let data = data else {
//                        print("DEBUG: ❗ No data received.")
//                        DispatchQueue.main.async {
//                            onComplete()
//                        }
//                        return
//                    }
//
//                    guard let rawResponse = String(data: data, encoding: .utf8) else {
//                        print("DEBUG: ❗ Failed to decode UTF-8 response.")
//                        if let rawDump = String(data: data, encoding: .ascii) {
//                            print("DEBUG: ASCII fallback content: \(rawDump.prefix(300))")
//                        }
//                        DispatchQueue.main.async {
//                            onComplete()
//                        }
//                        return
//                    }
//
//
//                    // Process Server-Sent Events (SSE) line by line
//                    rawResponse.enumerateLines { line, _ in
//                        if line.starts(with: "data: ") {
//                            let jsonString = line.replacingOccurrences(of: "data: ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
//
//                            if let jsonData = jsonString.data(using: .utf8),
//                               let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
//
//                                // ✅ Handle 'delta' part (text chunks)
//                                if let delta = json["delta"] as? [String: Any],
//                                   let textDelta = delta["text"] as? String {
//
//                                    print("🔹 Text chunk received: \(textDelta)") // 👈 Add this line
//                                    DispatchQueue.main.async {
//                                        if isAnalogy {
//                                            if !isAnalogySection && textDelta.lowercased().contains("consider") {
//                                                isAnalogySection = true
//                                                onReceive("\n\n--- Analogy Starts Below ---\n\n")
//                                            }
//                                            onReceive(textDelta)
//                                        } else {
//                                            onReceive(textDelta)
//                                        }
//                                    }
//
//
//                                    // Add to fullResponse
//                                    fullResponse += textDelta
//                                }
//
//                                // ✅ Handle 'stop_reason'
//                                if let stopReason = json["stop_reason"] as? String, stopReason == "end_turn" {
//                                    print("DEBUG: Stream ended. Full response collected:\n\(fullResponse)")
//
//                                    if fullResponse.isEmpty {
//                                        print("DEBUG: ❗ Claude returned empty response.")
//                                        DispatchQueue.main.async {
//                                            onReceive("[No response received, try again.]")
//                                        }
//                                    }
//
//                                }
//
//                            } // END of jsonData block
//                        } // END of starts(with: data)
//                    }
//        //            rawResponse.enumerateLines { line, _ in
//        //                if line.starts(with: "data: ") {
//        //                    let jsonString = line.replacingOccurrences(of: "data: ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
//        //
//        //                    if let jsonData = jsonString.data(using: .utf8),
//        //                       let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
//        //                       let delta = json["delta"] as? [String: Any],
//        //                       let textDelta = delta["text"] as? String {
//        //
//        //                        if isAnalogy {
//        //                            if !isAnalogySection && textDelta.lowercased().contains("consider") {
//        //                                isAnalogySection = true
//        //                                onReceive("\n\n--- Analogy Starts Below ---\n\n") // Send the separator to the UI
//        //                            }
//        //                            // Send analogy-specific response chunks
//        //                            onReceive(textDelta)
//        //                        } else {
//        //                            // For regular responses, handle normally
//        //                            onReceive(textDelta)
//        //                        }
//        //                        fullResponse += textDelta
//        //                    }
//        //
//        //                }
//        //            }
//        //
//        //
//        //
//                    
//                    
//                    DispatchQueue.main.async {
//                        print("DEBUG: Streaming complete. Triggering memory updates and summarization.")
//                        if !fullResponse.isEmpty {
//                            // Add to regular memory
//                            ClaudeAPI.shared.addToMemory(fullResponse)
//                            print("DEBUG: Final response added to memory: \(fullResponse)")
//
//                            // ✅ Also add to memoryBuffer for summarization
//                            ClaudeAPI.shared.memoryBuffer.append([
//                                "role": "assistant",
//                                "content": fullResponse
//                            ])
//                        } else {
//                            print("DEBUG: No final response content.")
//                        }
//
//                        // ✅ Add assistant response to memory (applies to all query types)
//                        if let lastAssistantMessage = ClaudeAPI.shared.memoryBuffer.last(where: { $0["role"] as? String == "assistant" })?["content"] as? String {
//                            ClaudeAPI.shared.addToMemory(lastAssistantMessage)
//                            print("DEBUG: Assistant response added to memory: \(lastAssistantMessage)")
//                        } else {
//                            print("DEBUG: No valid assistant response found to add to memory.")
//                        }
//
//                        // ✅ Add user input to memory (applies to all query types)
//                        ClaudeAPI.shared.addToMemory(query)
//                        print("DEBUG: User input added to memory: \(query)")
//
//                        ClaudeAPI.shared.memoryBuffer.append([
//                            "role": "user",
//                            "content": query
//                        ])
//
//                        // ✅ Summarize conversation for non-analogy responses
//                        if !isAnalogy {
//                            if let lastUserMessage = ClaudeAPI.shared.memoryBuffer.last(where: { $0["role"] as? String == "user" })?["content"] as? String,
//                               let lastAssistantMessage = ClaudeAPI.shared.memoryBuffer.last(where: { $0["role"] as? String == "assistant" })?["content"] as? String {
//                                ClaudeAPI.shared.summarizeConversation(question: lastUserMessage, response: lastAssistantMessage) { summary in
//                                    if let summary = summary {
//                                        let summaryEntry = [
//                                            "role": "summary",
//                                            "content": summary
//                                        ]
//                                        ClaudeAPI.shared.memoryBuffer.append(summaryEntry)
//                                        print("DEBUG: Summary added to memory buffer:\n\(summary)")
//                                    }
//                                    onComplete() // Final completion after summarization
//                                }
//                            } else {
//                                print("DEBUG: No valid user/assistant messages found for summarization.")
//                                onComplete()
//                            }
//                        } else {
//                            // Skip summarization for analogy
//                            print("DEBUG: Skipping summarization for analogy.")
//                            onComplete()
//                        }
//                    }
//
//
//
//
//                }
//                
//
//                task.resume()
//            }
//
//
//
//            
//            
//            
//            
//            
//            func summarizeConversation(question: String, response: String, completion: @escaping (String?) -> Void) {
//                let conversation = "Q: \(question)\nA: \(response)"
//                let prompt = "Summarize the following conversation to retain its key points:\n\n\(conversation)"
//
//                sendQuery(prompt) { result in
//                    switch result {
//                    case .success(let summary):
//                        print("DEBUG: Summarization successful:\n\(summary)")
//                        completion(summary)
//                    case .failure(let error):
//                        print("DEBUG: Summarization failed with error: \(error.localizedDescription)")
//                        completion(nil)
//                    }
//                }
//            }
//
//            
//
//
//            /// Sends a single query to the API (non-streamed)
//            func sendQuery(_ query: String, completion: @escaping (Result<String, Error>) -> Void) {
//                // Implementation for non-streamed query (reuse as needed)
//            }
//        }
