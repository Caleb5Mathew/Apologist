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

    func sendQuery(_ query: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: apiUrl) else {
            print("DEBUG: Invalid URL")
            completion(nil)
            return
        }

        // Create the request payload
        let parameters: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 1000,
            "temperature": 0,
            "system": "Respond from a Christian POV but don't explicitly say it. The goal is for the user to fully understand the answer to their question, cite famous theologians, bible verses, or books whenever it benefits the answer, more bible verses than anything, try to understand where they're coming from or address common misconceptions. Do all of this in less than 300 words.",
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

        // Set up the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print("DEBUG: Failed to serialize request body: \(error.localizedDescription)")
            completion(nil)
            return
        }

        // Perform the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("DEBUG: Networking error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("DEBUG: Invalid response from server.")
                completion(nil)
                return
            }

            print("DEBUG: HTTP status code: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                print("DEBUG: Non-200 HTTP response received.")
                if let rawResponse = String(data: data ?? Data(), encoding: .utf8) {
                    print("DEBUG: Raw response: \(rawResponse)")
                }
                completion(nil)
                return
            }

            guard let data = data else {
                print("DEBUG: No data received.")
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let contentArray = json["content"] as? [[String: Any]] {
                    // Extract the text field from the first object in the content array
                    if let firstContent = contentArray.first?["text"] as? String {
                        completion(firstContent)
                    } else {
                        print("DEBUG: Content array doesn't contain text field.")
                        completion(nil)
                    }
                } else {
                    print("DEBUG: Unexpected JSON structure: \(String(data: data, encoding: .utf8) ?? "No JSON")")
                    completion(nil)
                }
            } catch {
                print("DEBUG: Failed to parse JSON: \(error.localizedDescription)")
                completion(nil)
            }
        }

        task.resume()
    }
}
