//  ChatView.swift
//  Apologist
//
//  Created by Caleb Matthews  on 1/18/25.


import SuperwallKit
import SwiftUI
import FirebaseFirestore

struct ChatView: View {
    @Binding var userInput: String
    @Binding var messages: [Message]
    @Binding var isTyping: Bool
    @State private var disableAutoscroll: Bool = false
    @State private var userInteracted: Bool = false
    @State private var showCursor: Bool = false
    @State private var generationTimer: Timer?
    @State private var db = Firestore.firestore()
    @State private var showTooltip = false
    @State private var revealTimer: DispatchSourceTimer?
    @State private var dailyQuestionCount: Int = 0
    @State private var subscriptionStatus: SubscriptionStatus = .inactive

    private let bgColor = Color(hex: "#0B1E30")
    private let accentGold = Color(hex: "#F8C471")
    private let cardColor = Color(hex: "#132D42")
    private let userBubbleColor = Color(hex: "#1B5E4B")
    private let inputFieldColor = Color(hex: "#162B3E")

    var body: some View {
        ZStack(alignment: messages.isEmpty ? .topTrailing : .topLeading) {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#0B1E30"), Color(hex: "#1D4038")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollViewReader { scrollView in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if messages.isEmpty {
                                emptyStateView
                            } else {
                                ForEach(messages.indices, id: \.self) { index in
                                    let message = messages[index]
                                    let isConsecutive = index > 0 && messages[index - 1].isUser == message.isUser

                                    ChatBubble(
                                        messages: $messages,
                                        isTyping: $isTyping,
                                        message: message,
                                        isConsecutive: isConsecutive,
                                        showCursor: showCursor && !message.isUser,
                                        showTypingDots: isTyping && message.id == messages.last?.id && !message.isUser && message.text.isEmpty && message.revealedText.isEmpty
                                    )
                                    .transition(.opacity)
                                    .animation(.easeInOut(duration: 0.3), value: message.revealedText)
                                    .id(index)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                    }
                    .gesture(DragGesture()
                        .onChanged { _ in disableAutoscroll = true }
                        .onEnded { _ in disableAutoscroll = false }
                    )
                    .onChange(of: messages) { _ in
                        if !disableAutoscroll {
                            scrollToLast(scrollView: scrollView)
                        }
                    }
                }

                inputSection
            }

            questionCounterOverlay
        }
        .onAppear {
            resetDailyQuestionCountIfNeeded()
            updateSubscriptionStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            updateSubscriptionStatus()
        }
        .onDisappear {
            generationTimer?.invalidate()
            generationTimer = nil
            showCursor = false
            if !ClaudeAPI.shared.isRequestInProgress {
                isTyping = false
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 28) {
            Spacer().frame(height: 40)

            Image(systemName: "cross.fill")
                .font(.system(size: 36))
                .foregroundColor(accentGold.opacity(0.7))

            VStack(spacing: 6) {
                Text("What's on your mind?")
                    .font(.custom("Georgia", size: 22))
                    .foregroundColor(.white)
                Text("Ask any question about faith, theology, or life.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                ForEach([
                    "How do I know God is real?",
                    "How do I hear God?",
                    "How could a loving God allow suffering?",
                    "Why would God send people to hell?"
                ], id: \.self) { question in
                    Button(action: {
                        userInput = question
                        sendMessage()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 13))
                                .foregroundColor(accentGold.opacity(0.8))
                            Text(question)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .lineSpacing(2)
                                .minimumScaleFactor(0.85)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(cardColor)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Input Section

    var inputSection: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                TextField("Ask a question...", text: $userInput, axis: .vertical)
                    .accessibilityIdentifier("chat.question")
                    .lineLimit(1...6)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .padding(.trailing, 40)
                    .background(inputFieldColor)
                    .cornerRadius(22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .foregroundColor(Color.white)
                    .font(.system(size: 15))
                    .onChange(of: userInput) { newValue in
                        if newValue.count > 500 {
                            userInput = String(newValue.prefix(500))
                        }
                    }

                Text("\(userInput.count)/500")
                    .font(.system(size: 10))
                    .foregroundColor(Color.white.opacity(0.25))
                    .padding(.trailing, 14)
                    .padding(.bottom, 10)
            }

            Button(action: {
                sendMessage()
                resetAutoscroll()
            }) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(bgColor)
                    .frame(width: 42, height: 42)
                    .background(
                        LinearGradient(
                            colors: [accentGold, Color(hex: "#E8B84A")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
            }
            .accessibilityIdentifier("chat.send")
            .disabled(isTyping || userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(isTyping ? 0.5 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.clear)
    }

    // MARK: - Question Counter

    private var questionCounterOverlay: some View {
        ZStack(alignment: .center) {
            let countText: String = {
                switch subscriptionStatus {
                case .active: return "∞"
                default: return "\(max(0, 5 - dailyQuestionCount))"
                }
            }()

            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(countText)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                )
                .contentShape(Circle())
                .onTapGesture {
                    showTooltip = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showTooltip = false
                    }
                }

            if showTooltip {
                VStack(alignment: .center, spacing: 2) {
                    Text("\(max(0, 5 - dailyQuestionCount)) of 5")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                    Text("free daily questions")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                        .fixedSize(horizontal: true, vertical: false)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.85))
                .cornerRadius(8)
                .offset(y: 40)
                .transition(.scale.combined(with: .opacity))
                .animation(.easeInOut(duration: 0.2), value: showTooltip)
            }
        }
        .frame(width: 32, height: 32)
        .padding(.top, messages.isEmpty ? 10 : 15)
        .padding(messages.isEmpty ? .trailing : .leading, messages.isEmpty ? 16 : 20)
    }

    // MARK: - Message Logic

    private func sendMessage() {
        generationTimer?.invalidate()

        guard !isTyping else { return }

        guard !userInput.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        let isSubscribed: Bool = {
            switch subscriptionStatus {
            case .active:
                return true
            default:
                return false
            }
        }()
        print("DEBUG: Subscription status - \(isSubscribed ? "Active" : "Inactive")")

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
        Superwall.shared.register(placement: "campaign_trigger") {
            print("DEBUG: Paywall dismissed.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                updateSubscriptionStatus()
                switch self.subscriptionStatus {
                case .active:
                    print("DEBUG: User subscribed after paywall. Allowing message.")
                    self.executeSendMessage()
                default:
                    print("DEBUG: Paywall dismissed without subscription. Message NOT sent.")
                }
            }
        }
    }

    private func updateSubscriptionStatus() {
        subscriptionStatus = Superwall.shared.subscriptionStatus
        print("DEBUG: Subscription status updated to: \(subscriptionStatus)")
    }

    private func executeSendMessage() {
        let isSubscribed: Bool = {
            switch subscriptionStatus {
            case .active: return true
            default: return false
            }
        }()

        if !isSubscribed { incrementQuestionCount() }

        messages.indices.forEach { index in
            if !messages[index].isUser {
                messages[index].isResponseEnd = false
                messages[index].actions = nil
            }
        }

        let userMessage = Message(id: UUID(), text: userInput, revealedText: userInput, isUser: true)
        messages.append(userMessage)

        saveQuestionToFirestore(question: userInput)
        userInput = ""

        generationTimer?.invalidate()
        generationTimer = nil
        showCursor = false

        let responseId = UUID()
        let responseMessage = Message(id: responseId, text: "", revealedText: "", isUser: false)
        messages.append(responseMessage)

        isTyping = true
        var requestFailed = false

        ClaudeAPI.shared.sendStreamedQuery(
            userMessage.text,
            onReceive: { chunk in
                if let index = messages.firstIndex(where: { $0.id == responseId }) {
                    DispatchQueue.main.async {
                        if messages[index].text == "..." {
                            messages[index].text = ""
                        }
                        messages[index].text += chunk
                    }
                }
            },
            onError: { message in
                requestFailed = true
                if let index = messages.firstIndex(where: { $0.id == responseId }) {
                    messages[index].text = message
                    messages[index].revealedText = ""
                }
            },
            onComplete: {
                DispatchQueue.main.async {
                    isTyping = false
                    if let index = messages.firstIndex(where: { $0.id == responseId }) {
                        revealWordsGradually(for: responseId) {
                            if !requestFailed {
                                messages[index].actions = [
                                    Action(title: "Analogy", action: { }),
                                    Action(title: "Simplify", action: { }),
                                    Action(title: "Expand", action: { }),
                                    Action(title: "Dig Deeper", action: { })
                                ]
                            }
                            messages[index].isResponseEnd = true
                        }
                    }
                    messages = messages.map { $0 }
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

    private func scrollToLastMessage() {
        DispatchQueue.main.async {
            if let lastMessageIndex = messages.indices.last {
                withAnimation { }
            }
        }
    }

    func saveQuestionToFirestore(question: String) {
        let db = Firestore.firestore()
        let questionData: [String: Any] = [
            "question": question,
            "timestamp": Timestamp(date: Date())
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
            }
        }
    }

    private func resetAutoscroll() {
        userInteracted = false
        disableAutoscroll = false
    }

    private func revealWordsGradually(for messageId: UUID, typingSpeed: TimeInterval = 0.013, onComplete: @escaping () -> Void = {}) {
        generationTimer?.invalidate()
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else {
            isTyping = false
            showCursor = false
            onComplete()
            return
        }

        let fullText = messages[index].text
        let characters = Array(fullText)
        var currentIndex = 0

        messages[index].revealedText = ""
        isTyping = true
        showCursor = true

        let timer = Timer.scheduledTimer(withTimeInterval: typingSpeed, repeats: true) { timer in
            DispatchQueue.main.async {
                guard timer.isValid else { return }
                guard index < messages.count else {
                    timer.invalidate()
                    generationTimer = nil
                    isTyping = false
                    showCursor = false
                    onComplete()
                    return
                }

                if currentIndex < characters.count {
                    if index < messages.count {
                        messages[index].revealedText.append(characters[currentIndex])
                    }
                    currentIndex += 1
                    if currentIndex == 1 {
                        showCursor = false
                        messages = messages.map { $0 }
                    }
                } else {
                    timer.invalidate()
                    self.generationTimer = nil
                    isTyping = false
                    showCursor = false
                    messages = messages.map { $0 }
                    onComplete()
                }
            }
        }
        generationTimer = timer
        RunLoop.current.add(timer, forMode: .common)
    }
}
