////
////  playground.swift
////  Apologist
////
////  Created by Caleb Matthews  on 2/7/25.
////
//
//
//struct ChatBubble: View {
//    @Binding var messages: [Message] // Add messages as a binding
//    @ObservedObject var message: Message // Updated to ObservableObject
//    var isConsecutive: Bool
//    var showCursor: Bool // Controls whether the `|` is shown
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: isConsecutive ? 4 : 16) {
//            if message.isUser {
//                // User Message
//                HStack {
//                    Spacer()
//                    Text(message.revealedText)
//                        .padding()
//                        .background(Color(hex: "#1F5F4E"))
//                        .foregroundColor(Color(hex: "#FFFFFF"))
//                        .cornerRadius(20)
//                        .frame(maxWidth: 250, alignment: .trailing)
//                        .contextMenu {
//                            Button(action: {
//                                UIPasteboard.general.string = message.revealedText
//                                print("DEBUG: User copied message: \(message.revealedText)")
//                            }) {
//                                Text("Copy")
//                                Image(systemName: "doc.on.doc")
//                            }
//                        }
//                }
//                .padding(.horizontal)
//                .onAppear {
//                    print("DEBUG: Rendering user message: \(message.revealedText)")
//                }
//            } else {
//                // Assistant Message
//                HStack(alignment: .top) {
//                    VStack(alignment: .leading, spacing: 8) {
//                        // Check if the analogy marker is present
//                        if message.revealedText.contains("--- Analogy Starts Below ---") {
//                            // Clean the revealedText to remove the marker
//                            let cleanedText = message.revealedText.replacingOccurrences(of: "--- Analogy Starts Below ---", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
//                            
//                            // Display the cleaned text
//                            Text(cleanedText)
//                                .font(.system(size: 16, weight: .regular))
//                                .foregroundColor(Color(hex: "#FFFFFF")) // White color for clarity
//                                .lineSpacing(6)
//                                .animation(nil, value: message.revealedText)
//                                .contextMenu {
//                                    Button(action: {
//                                        UIPasteboard.general.string = cleanedText
//                                        print("DEBUG: Cleaned analogy text copied.")
//                                    }) {
//                                        Text("Copy")
//                                        Image(systemName: "doc.on.doc")
//                                    }
//                                }
//                        } else {
//                            // Render entire message normally if no analogy marker exists
//                            Text(message.revealedText + (showCursor ? "|" : ""))
//                                .font(.system(size: 16))
//                                .foregroundColor(Color(hex: "#FFFFFF"))
//                                .lineSpacing(6)
//                                .animation(nil, value: message.revealedText)
//                                .contextMenu {
//                                    Button(action: {
//                                        UIPasteboard.general.string = message.revealedText
//                                        print("DEBUG: Assistant message copied: \(message.revealedText)")
//                                    }) {
//                                        Text("Copy")
//                                        Image(systemName: "doc.on.doc")
//                                    }
//                                }
//                                .onAppear {
//                                    print("DEBUG: Rendering assistant message: \(message.revealedText)")
//                                }
//                        }
//
//                        // Action buttons (unchanged)
//                        // Action buttons (unchanged)
//                        if let actions = message.actions {
//                            Spacer()
//                                .frame(height: 24)
//
//                            HStack {
//                                Spacer()
//                                Text("Dig Deeper")
//                                    .font(.system(size: 14, weight: .bold))
//                                    .kerning(1.5)
//                                    .foregroundColor(Color.white)
//                                    .multilineTextAlignment(.center)
//                                Spacer()
//                            }
//                            .padding(.bottom, 16)
//
//                            HStack(spacing: 16) {
//                                ForEach(actions.filter { $0.title != "Dig Deeper" }) { action in
//                                    Button(action: {
//                                        // Determine which query to send based on button title
//                                        let selectedPrompt: String
//                                        let buttonTitle = action.title
//                                        if buttonTitle == "Simplify" {
//                                            selectedPrompt = ClaudeAPI.shared.simplifyPrompt // Use Simplify prompt
//                                        } else if buttonTitle == "Expand" {
//                                            selectedPrompt = ClaudeAPI.shared.expandPrompt // Use Expand prompt
//                                        } else if buttonTitle == "Analogy" {
//                                            // For "Analogy", include the memory context, last user question, and last assistant response
//                                            let memoryContext = ClaudeAPI.shared.memory.suffix(10).joined(separator: "\n") // Include broader memory context
//                                            let lastUserQuestion = messages.last(where: { $0.isUser })?.text ?? "No user question found."
//                                            let lastAssistantResponse = messages.last(where: { !$0.isUser })?.text ?? "No assistant response found."
//
//                                            selectedPrompt = """
//                                            \(ClaudeAPI.shared.analogyPrompt)
//
//                                            Based on the following previous messages:
//                                            \(memoryContext)
//
//                                            User's Last Question: \(lastUserQuestion)
//                                            Assistant's Last Response: \(lastAssistantResponse)
//                                            """
//                                        }
//
// else {
//                                            selectedPrompt = ClaudeAPI.shared.analogyPrompt // Default to analogy if no match
//                                        }
//
//                                        let responseId = UUID() // Generate a new ID for the response
//
//                                        // Clear actions for all other assistant messages before appending a new one
//                                        messages.indices.forEach { index in
//                                            if !messages[index].isUser {
//                                                messages[index].actions = nil
//                                                messages[index].isResponseEnd = false
//                                            }
//                                        }
//
//                                        // Append a "user" message for the button request
//                                        let userMessage = Message(
//                                            id: UUID(),
//                                            text: buttonTitle,
//                                            revealedText: buttonTitle,
//                                            isUser: true
//                                        )
//                                        messages.append(userMessage)
//
//                                        // Append a placeholder for the button response
//                                        let responseMessage = Message(
//                                            id: responseId,
//                                            text: "",
//                                            revealedText: "",
//                                            isUser: false
//                                        )
//                                        messages.append(responseMessage)
//
//                                        // Send the selected query using `sendStreamedQuery`
//                                        ClaudeAPI.shared.sendStreamedQuery(
//                                            selectedPrompt,
//                                            onReceive: { chunk in
//                                                // Only append chunks to the response message
//                                                if let index = messages.firstIndex(where: { $0.id == responseId }) {
//                                                    DispatchQueue.main.async {
//                                                        messages[index].text += chunk
//                                                        messages[index].revealedText += chunk
//                                                        print("DEBUG: \(buttonTitle) response chunk received: \(chunk)")
//                                                    }
//                                                }
//                                            },
//                                            onComplete: {
//                                                DispatchQueue.main.async {
//                                                    print("DEBUG: \(buttonTitle) response completed.")
//                                                    if let index = messages.firstIndex(where: { $0.id == responseId }) {
//                                                        // Reveal the response gradually and toggle the typing indicator
//                                                        revealWordsGradually(for: messages[index], isTyping: .constant(false), showCursor: .constant(false)) {
//                                                            // Assign follow-up actions after the response is fully revealed
//                                                            messages[index].actions = [
//                                                                Action(title: "Analogy", action: { print("DEBUG: Tapped Analogy for message ID: \(responseId)") }),
//                                                                Action(title: "Simplify", action: { print("DEBUG: Tapped Simplify for message ID: \(responseId)") }),
//                                                                Action(title: "Expand", action: { print("DEBUG: Tapped Expand for message ID: \(responseId)") }),
//                                                                Action(title: "Dig Deeper", action: { print("DEBUG: Tapped Dig Deeper for message ID: \(responseId)") })
//                                                            ]
//                                                            messages[index].isResponseEnd = true
//                                                        }
//                                                    }
//                                                }
//                                            }
//                                        )
//                                    })
//
// {
//                                        Text(action.title)
//                                            .font(.system(size: 14, weight: .bold))
//                                            .kerning(1.5)
//                                            .foregroundColor(Color.white)
//                                            .padding(.horizontal, 12)
//                                            .padding(.vertical, 8)
//                                            .background(
//                                                RoundedRectangle(cornerRadius: 12)
//                                                    .stroke(Color.white, lineWidth: 2)
//                                            )
//                                    }
//
//                                }
//                            }
//                            .frame(maxWidth: .infinity)
//                            .padding(.bottom, 16)
//                        }
//
//                    }
//                    .padding(.horizontal)
//                    Spacer()
//                }
//            }
//        }
//    }
//}
