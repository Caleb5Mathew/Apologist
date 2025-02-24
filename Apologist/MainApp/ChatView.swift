//  ChatView.swift
//  Apologist
//
//  Created by Caleb Matthews  on 1/18/25.
//


import SuperwallKit
import SwiftUI
import FirebaseFirestore

struct ChatView: View {
    @Binding var userInput: String
    @Binding var messages: [Message]
    @Binding var isTyping: Bool
    @State private var disableAutoscroll: Bool = false // Tracks whether autoscroll is disabled manually
    @State private var userInteracted: Bool = false // Tracks if the user interacted during this session
    @State private var showCursor: Bool = false
    @State private var generationTimer: Timer? // Timer reference for stopping generation
    @State private var db = Firestore.firestore() // Firestore reference
    @State private var showTooltip = false
    @State private var revealTimer: DispatchSourceTimer?
    @State private var dailyQuestionCount: Int = 5 // Start with 5 questions available
    var body: some View {
        ZStack(alignment: messages.isEmpty ? .topTrailing : .topLeading) {
            VStack(spacing: 0) {
                // Chat History with Scrolling
                ScrollViewReader { scrollView in
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .center, spacing: 8) {
                            if messages.isEmpty {
                                // Suggested Questions or Empty ChatView
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
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 30) // Keeps space at the top
                            } else {
                                // Chat Messages
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
                                typingIndicatorView()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10) // Space above chat messages
                    }
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#0B1E30"), Color(hex: "#1D4038")]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .gesture(DragGesture()
                        .onChanged { _ in
                            disableAutoscroll = true
                        }
                        .onEnded { _ in
                            disableAutoscroll = false
                        }
                    )
                    
                    .onChange(of: messages) { _ in
                        if !disableAutoscroll {
                            scrollToLast(scrollView: scrollView)
                        }
                    }
                }
                
                // Input Section
                inputSection
            }
            
            // Question Counter Circle
            ZStack(alignment: .center) {
                Circle()
                    .fill(Color.gray.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(Superwall.shared.subscriptionStatus == .active
                             ? "∞"
                             : "\(max(0, 5 - dailyQuestionCount))/5")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    )


                    .contentShape(Circle())
                    .onTapGesture {
                        showTooltip = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showTooltip = false
                        }
                    }
                
                // Tooltip with fixed width
                if showTooltip {
                    VStack(alignment: .center, spacing: 3) {
                        Text("\(max(0, 5 - dailyQuestionCount))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        Text("of 5 free daily")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.white)
                            .fixedSize(horizontal: true, vertical: false)
                        Text("questions used")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.white)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .padding(6)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(6)
                    .shadow(radius: 2)
                    .offset(y: 45)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: showTooltip)
                }
            }
            .frame(width: 36, height: 36)
            .padding(.top, messages.isEmpty ? 10 : 15) // More top padding when showing messages
            .padding(messages.isEmpty ? .trailing : .leading, messages.isEmpty ? 20 : 25) // More leading padding when showing messages
        }
        .onAppear {
            resetDailyQuestionCountIfNeeded()
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
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#1D4038"), Color(hex: "#0B1E30")]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    
    @ViewBuilder
    private func typingIndicatorView() -> some View {
        if isTyping && messages.last?.revealedText.isEmpty == true {
            TypingIndicator() // ✅ Removed argument since TypingIndicator likely takes none
                .id(UUID()) // ✅ Forces SwiftUI to refresh
                .id(isTyping) // ✅ Forces SwiftUI to recognize state change
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
        } else {
            EmptyView() // ✅ Ensures function always returns something
        }
    }
    
    
    private func sendMessage() {
        generationTimer?.invalidate()
        print("DEBUG: Timer invalidated.")

        guard !userInput.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("DEBUG: User input is empty. Exiting sendMessage.")
            return
        }

        let isSubscribed = Superwall.shared.subscriptionStatus == .active
        print("DEBUG: Subscription status from Superwall - \(isSubscribed ? "Active" : "Inactive")")

        let currentDate = Calendar.current.startOfDay(for: Date())
        let lastAccessDate = UserDefaults.standard.object(forKey: "lastAccessDate") as? Date ?? Date.distantPast

        if currentDate > Calendar.current.startOfDay(for: lastAccessDate) {
            print("DEBUG: New day detected. Resetting daily question count.")
            UserDefaults.standard.set(currentDate, forKey: "lastAccessDate")
            UserDefaults.standard.set(0, forKey: "dailyQuestionCount")
            dailyQuestionCount = 0
        }

        print("DEBUG: Daily question count before increment: \(dailyQuestionCount)/5")

        if !isSubscribed && dailyQuestionCount >= 5 {
            print("DEBUG: Daily limit reached! TRIGGERING PAYWALL.")
            triggerPaywall()
            return
        }

        executeSendMessage()
    }



    private func triggerPaywall() {
        print("DEBUG: Attempting to trigger paywall...")

        Superwall.shared.register(event: "campaign_trigger") {
            print("DEBUG: Paywall triggered.")

            if Superwall.shared.subscriptionStatus == .active {
                print("DEBUG: User subscribed after paywall. Allowing message.")
                executeSendMessage()
            } else {
                print("DEBUG: Paywall dismissed. Message NOT sent.")
            }
        }
    }

    private func executeSendMessage() {
        incrementQuestionCount()
        
        messages.indices.forEach { index in
            if !messages[index].isUser {
                messages[index].isResponseEnd = false
                messages[index].actions = nil
            }
        }
        
        let userMessage = Message(id: UUID(), text: userInput, revealedText: userInput, isUser: true)
        messages.append(userMessage)
        print("DEBUG: User message added: \(userMessage)")
        
        ClaudeAPI.shared.addToMemory(userInput)
        print("DEBUG: Memory after adding user input: \(ClaudeAPI.shared.memory)")
        
        saveQuestionToFirestore(question: userInput)
        
        userInput = ""
        
        generationTimer?.invalidate()
        generationTimer = nil
        
        showCursor = false
        
        let responseId = UUID()
        let responseMessage = Message(id: responseId, text: "", revealedText: "", isUser: false)
        messages.append(responseMessage)
        print("DEBUG: Response message placeholder added with ID \(responseId)")
        
        isTyping = true
        print("DEBUG: Typing indicator set to true.")
        
        ClaudeAPI.shared.sendStreamedQuery(
            userMessage.text,
            onReceive: { chunk in
                if let index = messages.firstIndex(where: { $0.id == responseId }) {
                    DispatchQueue.main.async {
                        if messages[index].text == "..." {
                            messages[index].text = ""
                        }
                        
                        messages[index].text += chunk
                        print("DEBUG: Received chunk for response ID \(responseId): \(chunk)")
                    }
                } else {
                    print("DEBUG: Failed to find response message for chunk: \(chunk)")
                }
            },
            onComplete: {
                DispatchQueue.main.async {
                    isTyping = false
                    print("DEBUG: Typing indicator set to false. Starting word reveal for message ID \(responseId).")

                    if let index = messages.firstIndex(where: { $0.id == responseId }) {
                        revealWordsGradually(for: responseId) {
                            messages[index].actions = [
                                Action(title: "Analogy", action: { print("DEBUG: Tapped Analogy for message ID: \(responseId)") }),
                                Action(title: "Simplify", action: { print("DEBUG: Tapped Simplify for message ID: \(responseId)") }),
                                Action(title: "Expand", action: { print("DEBUG: Tapped Expand for message ID: \(responseId)") }),
                                Action(title: "Dig Deeper", action: { print("DEBUG: Tapped Dig Deeper for message ID: \(responseId)") })
                            ]
                            messages[index].isResponseEnd = true
                            print("DEBUG: Actions assigned to message ID \(responseId): \(messages[index].actions?.map { $0.title } ?? [])")
                        }
                    } else {
                        print("DEBUG: Could not find message for response ID \(responseId)")
                    }

                    messages = messages.map { $0 }
                    print("DEBUG: Messages array updated to trigger UI refresh. Current messages:\n\(messages)")
                }
            }
        )
    }

    private func incrementQuestionCount() {
        dailyQuestionCount += 1
        UserDefaults.standard.set(dailyQuestionCount, forKey: "dailyQuestionCount")
        
        print("DEBUG: Question count incremented to \(dailyQuestionCount)")

        if dailyQuestionCount >= 5 {
            print("DEBUG: Daily question limit reached! Next message should trigger paywall.")
        }
    }

    private func resetDailyQuestionCountIfNeeded() {
        let currentDate = Calendar.current.startOfDay(for: Date())
        let lastAccessDate = UserDefaults.standard.object(forKey: "lastAccessDate") as? Date ?? Date.distantPast

        if currentDate > Calendar.current.startOfDay(for: lastAccessDate) {
            UserDefaults.standard.set(currentDate, forKey: "lastAccessDate")
            UserDefaults.standard.set(0, forKey: "dailyQuestionCount")
            dailyQuestionCount = 0
        } else {
            dailyQuestionCount = UserDefaults.standard.integer(forKey: "dailyQuestionCount")
        }
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
    func saveQuestionToFirestore(question: String) {
        let db = Firestore.firestore()
        
        let questionData: [String: Any] = [
            "question": question,
            "timestamp": Timestamp(date: Date()) // Use Firestore's Timestamp
        ]
        
        db.collection("Questions").addDocument(data: questionData) { error in
            if let error = error {
                print("Error saving question: \(error.localizedDescription)")
            } else {
                print("Question successfully saved to Firestore!")
            }
        }
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
    
    
    private func revealWordsGradually(for messageId: UUID, typingSpeed: TimeInterval = 0.013, onComplete: @escaping () -> Void = {}) {
        generationTimer?.invalidate()
        
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else { return }
        
        let fullText = messages[index].text
        let characters = Array(fullText) // Convert text to a character array
        var currentIndex = 0
        
        // Reset states for a new response
        messages[index].revealedText = ""
        isTyping = true
        showCursor = true  // ✅ Cursor starts on

        print("DEBUG: Cursor is set to TRUE before reveal starts.")

        generationTimer = Timer.scheduledTimer(withTimeInterval: typingSpeed, repeats: true) { timer in
            DispatchQueue.main.async {
                if currentIndex < characters.count {
                    messages[index].revealedText.append(characters[currentIndex])
                    currentIndex += 1

                    // ✅ Hide cursor immediately after first character
                    if currentIndex == 1 {
                        showCursor = false
                        print("DEBUG: Cursor is set to FALSE after first character.")
                        
                        // ✅ Force UI update
                        messages = messages.map { $0 }
                    }

                } else {
                    // ✅ Stop timer when done
                    timer.invalidate()
                    self.generationTimer = nil
                    
                    isTyping = false
                    showCursor = false
                    print("DEBUG: Cursor is set to FALSE at the end of reveal.")

                    // ✅ Force final UI update
                    messages = messages.map { $0 }
                    onComplete()
                }
            }
        }
        
        RunLoop.current.add(generationTimer!, forMode: .common)
    }
}
