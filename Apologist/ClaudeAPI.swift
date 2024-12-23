//
//  ClaudeAPI.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/8/24.
//

import Foundation

class ClaudeAPI {
    static let shared = ClaudeAPI()
    private let apiKey = "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"
    private let apiUrl = "https://api.anthropic.com/v1/messages"
    private let apiVersion = "2023-06-01"
    func sendStreamedQuery(_ query: String, onReceive: @escaping (String) -> Void, onComplete: @escaping () -> Void) {
        guard let url = URL(string: apiUrl) else {
            print("DEBUG: Invalid URL")
            return
        }
        
        let parameters: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 3000,
            "temperature": 0,
            "stream": true,
            "system": "Respond from a Christian POV but don't explicitly say it. The goal is for the user to fully understand the answer to their question, cite famous theologians, bible verses, or books whenever it benefits the answer, more bible verses than anything, try to understand where they're coming from or address common misconceptions.",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": query
                        ]
                    ]
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
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print("DEBUG: Networking error: \(error!.localizedDescription)")
                DispatchQueue.main.async {
                    onComplete()
                }
                return
            }
            
            guard let data = data, let rawResponse = String(data: data, encoding: .utf8) else {
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
                       let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                       let delta = json["delta"] as? [String: Any],
                       let textDelta = delta["text"] as? String {
                        DispatchQueue.main.async {
                            print("DEBUG: Received chunk: \(textDelta)")
                            onReceive(textDelta)
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                print("DEBUG: Streaming complete")
                onComplete()
            }
        }
        
        task.resume()
    }
}
