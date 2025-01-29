//
//  ChatView.swift
//  Apologist
//
//  Created by Caleb Matthews  on 1/18/25.
//



import SwiftUI
//import FirebaseFirestore

struct ChatView: View {
    @Binding var userInput: String
    @Binding var messages: [Message]
    @Binding var isTyping: Bool
    @State private var disableAutoscroll: Bool = false // Tracks whether autoscroll is disabled manually
    @State private var userInteracted: Bool = false // Tracks if the user interacted during this session
    @State private var showCursor: Bool = false
    @State private var generationTimer: Timer? // Timer reference for stopping generation
//    @State private var db = Firestore.firestore() // Firestore reference

    var body: some View {
        VStack(spacing: 0) {
            // Suggested Questions (if no messages exist)
            if messages.isEmpty {
                VStack(spacing: 12) {
                    Text("SUGGESTED QUESTIONS")
                        .font(.system(size: 12, weight: .bold))
                        .kerning(1.5)
                        .foregroundColor(Color.white)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 5)
                    
                    ForEach([
                        "How do I know God is real?",
                        "How do I hear God?",
                        "How could a loving God allow so much suffering?",
                        "Why would God send people to hell?"
                    ], id: \.self) { question in
                        Button(action: {
                            userInput = question
                            sendMessage()
                        }) {
                            Text(question)
                                .font(.system(size: 14, weight: .bold))
                                .kerning(1.5)
                                .foregroundColor(Color.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 30)
            }
            
            // Chat History with Scrolling
            ScrollViewReader { scrollView in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(messages.indices, id: \.self) { index in
                            let message = messages[index]
                            let isConsecutive = index > 0 && messages[index - 1].isUser == message.isUser

                            ChatBubble(
                                messages: $messages,
                                message: message,
                                isConsecutive: isConsecutive,
                                showCursor: showCursor && !message.isUser
                            )

                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.3), value: message.revealedText)
                            .id(index)
                        }


                        
                        if isTyping {
                            TypingIndicator()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .id("TypingIndicator")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .background(Color(hex: "#0B1E30"))
                .gesture(DragGesture().onChanged { _ in
                    disableAutoscroll = true
                    userInteracted = true
                })
                .onChange(of: messages) { _ in
                    if !disableAutoscroll {
                        scrollToLast(scrollView: scrollView)
                    }
                }
            }
            
            // Input Section
            inputSection
        }
    }
    
    var inputSection: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                TextField("Ask a question...", text: $userInput, axis: .vertical)
                    .lineLimit(1...6)
                    .padding(10)
                    .background(Color(hex: "#274E45"))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .foregroundColor(Color.white)
                    .font(.system(size: 16))
                    .onChange(of: userInput) { newValue in
                        if newValue.count > 500 {
                            userInput = String(newValue.prefix(500))
                        }
                    }
                
                // Character Count Display
                Text("\(userInput.count)/500")
                    .font(.system(size: 12))
                    .foregroundColor(Color.gray)
                    .padding(.trailing, 12)
                    .padding(.bottom, 8)
            }
            
            // Send Button
            Button(action: {
                sendMessage()
                resetAutoscroll()
            }) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.black)
                    .padding()
                    .background(Color(hex: "#F5E3C2"))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .frame(height: 44)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(hex: "#0B1E30"))
    }
    

    
    
    
    private func sendMessage() {
        generationTimer?.invalidate()
        generationTimer = nil
        print("DEBUG: Timer invalidated.")

        // Ensure user input is not empty
        guard !userInput.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("DEBUG: User input is empty. Exiting sendMessage.")
            return
        }

        // Reset `isResponseEnd` and `actions` for all assistant messages
        messages.indices.forEach { index in
            if !messages[index].isUser {
                messages[index].isResponseEnd = false
                messages[index].actions = nil
            }
        }

        // Create and append the user's message
        let userMessage = Message(id: UUID(), text: userInput, revealedText: userInput, isUser: true)
        messages.append(userMessage)
        print("DEBUG: User message added: \(userMessage)")

        // Add user input to memory
        ClaudeAPI.shared.addToMemory(userInput)
        print("DEBUG: Memory after adding user input: \(ClaudeAPI.shared.memory)")

        
//        saveQuestionToFirestore(question: userInput)

        // Reset user input field
        userInput = ""

        // Create and append the assistant's placeholder response
        let responseId = UUID()
        let responseMessage = Message(id: responseId, text: "", revealedText: "", isUser: false)
        messages.append(responseMessage)
        print("DEBUG: Response message placeholder added with ID \(responseId)")

        // Set typing state to true
        isTyping = true
        print("DEBUG: Typing indicator set to true.")

        // Send the query using ClaudeAPI
        ClaudeAPI.shared.sendStreamedQuery(
            userMessage.text,
            onReceive: { chunk in
                // Append received chunk to the assistant's response
                if let index = messages.firstIndex(where: { $0.id == responseId }) {
                    DispatchQueue.main.async {
                        messages[index].text += chunk
                        messages[index].revealedText += chunk
                        print("DEBUG: Received chunk for response ID \(responseId): \(chunk)")
                    }
                } else {
                    print("DEBUG: Failed to find response message for chunk: \(chunk)")
                }
            },
            onComplete: {
                DispatchQueue.main.async {
                    // Set typing state to false
                    isTyping = false
                    print("DEBUG: Typing indicator set to false. Starting word reveal for message ID \(responseId).")

                    // Reveal words gradually for the response
                    revealWordsGradually(for: responseId) {
                        // Assign follow-up buttons after the response is fully revealed
                        if let lastResponseIndex = messages.firstIndex(where: { $0.id == responseId }) {
                            messages[lastResponseIndex].actions = [
                                Action(title: "Analogy", action: { print("DEBUG: Tapped Analogy for message ID: \(responseId)") }),
                                Action(title: "Simplify", action: { print("DEBUG: Tapped Simplify for message ID: \(responseId)") }),
                                Action(title: "Expand", action: { print("DEBUG: Tapped Expand for message ID: \(responseId)") }),
                                Action(title: "Dig Deeper", action: { print("DEBUG: Tapped Dig Deeper for message ID: \(responseId)") })
                            ]
                            messages[lastResponseIndex].isResponseEnd = true // Mark response as completed
                            print("DEBUG: Actions assigned to message ID \(responseId): \(messages[lastResponseIndex].actions?.map { $0.title } ?? [])")
                        } else {
                            print("DEBUG: Could not find message for response ID \(responseId)")
                        }

                        // Trigger UI update
                        messages = messages.map { $0 }
                        print("DEBUG: Messages array updated to trigger UI refresh. Current messages:\n\(messages)")
                    }
                }
            }
        )
    }


    
    // Scroll to the last message for autoscroll functionality
    private func scrollToLastMessage() {
        DispatchQueue.main.async {
            if let lastMessageIndex = messages.indices.last {
                withAnimation {
                    // Assuming scrollView is being used
                    // You may need to bind a ScrollViewProxy to enable smooth scrolling
                    // Replace `scrollView.scrollTo(lastMessageIndex)` with your implementation
                }
            }
        }
    }
    // Function to save questions to Firestore
//    func saveQuestionToFirestore(question: String) {
//        let db = Firestore.firestore()
//
//        let questionData: [String: Any] = [
//            "question": question,
//            "timestamp": Timestamp(date: Date()) // Use Firestore's Timestamp
//        ]
//
//        db.collection("Questions").addDocument(data: questionData) { error in
//            if let error = error {
//                print("Error saving question: \(error.localizedDescription)")
//            } else {
//                print("Question successfully saved to Firestore!")
//            }
//        }
//    }
    
    
    private func sendFollowUpPrompt(using prompt: String) {
        generationTimer?.invalidate()
        generationTimer = nil

        guard let lastResponse = messages.last(where: { !$0.isUser })?.text else {
            print("DEBUG: No previous AI response found to use for follow-up.")
            return
        }

        let followUpQuery = "\(prompt)\n\n\(lastResponse)"
        let followUpMessage = Message(id: UUID(), text: "", revealedText: "", isUser: false)
        messages.append(followUpMessage)
        isTyping = true

        ClaudeAPI.shared.sendStreamedQuery(followUpQuery,
            onReceive: { chunk in
                if let index = messages.firstIndex(where: { $0.id == followUpMessage.id }) {
                    DispatchQueue.main.async {
                        messages[index].text += chunk
                    }
                }
            },
            onComplete: {
                DispatchQueue.main.async {
                    isTyping = false
                    revealWordsGradually(for: followUpMessage.id)
                }
            }
        )
    }

    
    
    

    private func scrollToLast(scrollView: ScrollViewProxy) {
        DispatchQueue.main.async {
            if let lastIndex = messages.indices.last {
                withAnimation(.easeOut(duration: 0.3)) {
                    scrollView.scrollTo(lastIndex, anchor: .bottom)
                }
            } else if isTyping {
                withAnimation(.easeOut(duration: 0.3)) {
                    scrollView.scrollTo("TypingIndicator", anchor: .bottom)
                }
            }
        }
    }
    
    private func resetAutoscroll() {
        userInteracted = false
        disableAutoscroll = false
    }
    
    
    private func revealWordsGradually(for messageId: UUID, onComplete: @escaping () -> Void = {}) {
        // Stop any previous timer
        generationTimer?.invalidate()
        
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else { return }
        
        let fullText = messages[index].text
        var revealedWords = [String]()
        let words = fullText.split(separator: " ")
        
        // Reset states for a new response
        messages[index].revealedText = ""
        isTyping = true
        showCursor = false
        
        // Timer for word-by-word reveal
        generationTimer = Timer.scheduledTimer(withTimeInterval: 0.125, repeats: true) { timer in
            if revealedWords.count < words.count {
                revealedWords.append(String(words[revealedWords.count]))
                DispatchQueue.main.async {
                    messages[index].revealedText = revealedWords.joined(separator: " ")
                    
                    // Ensure `...` disappears and `|` appears after the first word
                    if revealedWords.count == 1 {
                        isTyping = false // Turn off typing indicator
                        showCursor = true // Turn on the cursor
                    }
                }
            } else {
                // Invalidate timer when response is complete
                timer.invalidate()
                DispatchQueue.main.async {
                    messages[index].revealedText = revealedWords.joined(separator: " ")
                    isTyping = false // Ensure typing indicator is off
                    showCursor = false // Remove the cursor after completion
                    
                    // Execute the onComplete handler
                    onComplete()
                }
            }
        }
    }

}
