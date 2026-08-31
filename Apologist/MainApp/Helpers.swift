
//
//  Helpers.swift
//  Apologist
//
//  Created by Caleb Matthews  on 1/18/25.
//

//
//  Helpers.swift
//  Apologist
//
//  Created by Caleb Matthews on 12/6/24.
//
//import FirebaseFirestore

import SwiftUI
import Foundation

struct Action: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let action: () -> Void

    static func == (lhs: Action, rhs: Action) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title
    }
}

class Message: ObservableObject, Identifiable, Equatable {
    let id: UUID
    @Published var text: String
    @Published var revealedText: String
    let isUser: Bool
    @Published var actions: [Action]?
    @Published var isResponseEnd: Bool = false

    init(id: UUID = UUID(), text: String, revealedText: String, isUser: Bool, actions: [Action]? = nil, isResponseEnd: Bool = false) {
        self.id = id
        self.text = text
        self.revealedText = revealedText
        self.isUser = isUser
        self.actions = actions
        self.isResponseEnd = isResponseEnd
    }

    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id &&
               lhs.text == rhs.text &&
               lhs.revealedText == rhs.revealedText &&
               lhs.isUser == rhs.isUser &&
               lhs.isResponseEnd == rhs.isResponseEnd
    }
}

class MessagesViewModel: ObservableObject {
    @Published var messages: [Message] = []
}

@MainActor
enum FollowUpPrompt {
    static func prompt(
        for title: String,
        client: ClaudeAPI
    ) -> String {
        switch title {
        case "Simplify":
            return client.simplifyPrompt
        case "Expand":
            return client.expandPrompt
        case "Analogy":
            return client.analogyPrompt
        case "Dig Deeper":
            return client.digDeeperPrompt
        default:
            return client.defaultPrompt
        }
    }
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.currentIndex = hex.startIndex
        scanner.scanString("#", into: nil)

        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var phase: Int = 0
    var showIcon: Bool = true

    var body: some View {
        HStack(spacing: 5) {
            if showIcon {
                Image(systemName: "cross.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#F8C471").opacity(0.6))
            }
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(dotOpacity(for: i)))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .padding(.horizontal, showIcon ? 14 : 10)
        .padding(.vertical, 10)
        .background(Color(hex: "#132D42"))
        .cornerRadius(16)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
        }
    }

    private func dotOpacity(for index: Int) -> Double {
        index == phase ? 0.9 : 0.3
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    @Binding var messages: [Message]
    @Binding var isTyping: Bool
    @ObservedObject var message: Message
    var isConsecutive: Bool
    var showCursor: Bool
    var showTypingDots: Bool = false
    var canSendFollowUp: () -> Bool
    var presentPaywall: (@escaping () -> Void) -> Void
    var recordSuccessfulFollowUp: () -> Void

    private let accentGold = Color(hex: "#F8C471")
    private let userBubbleGradient = LinearGradient(
        colors: [Color(hex: "#1B6B52"), Color(hex: "#155A44")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    private let assistantBg = Color(hex: "#132D42")

    var body: some View {
        VStack(alignment: .leading, spacing: isConsecutive ? 2 : 14) {
            if message.isUser {
                userBubble
            } else {
                assistantBubble
            }
        }
    }

    // MARK: User Bubble

    private var userBubble: some View {
        HStack {
            Spacer()
            Text(message.revealedText)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(userBubbleGradient)
                .clipShape(ChatBubbleShape(isUser: true))
                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.string = message.revealedText
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
        }
        .padding(.leading, 52)
    }

    // MARK: Assistant Bubble

    private var assistantBubble: some View {
        HStack(alignment: .top, spacing: 10) {
            if !isConsecutive {
                Image(systemName: "cross.fill")
                    .font(.system(size: 11))
                    .foregroundColor(accentGold.opacity(0.7))
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            } else {
                Spacer().frame(width: 28)
            }

            VStack(alignment: .leading, spacing: 8) {
                if showTypingDots {
                    TypingIndicator(showIcon: false)
                } else {
                    let rawContent = message.revealedText.isEmpty ? message.text : message.revealedText
                    let displayText = rawContent.replacingOccurrences(
                        of: "--- Analogy Starts Below ---",
                        with: ""
                    ).trimmingCharacters(in: .whitespacesAndNewlines)

                    Text(displayText + (showCursor ? "|" : ""))
                        .accessibilityIdentifier("chat.response")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white.opacity(0.92))
                        .lineSpacing(7)
                        .animation(nil, value: message.revealedText)
                        .contextMenu {
                            Button(action: {
                                UIPasteboard.general.string = displayText
                            }) {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                        }
                }

                if let actions = message.actions {
                    actionButtonsSection(actions: actions)
                }
            }
            .padding(.trailing, 20)
        }
    }

    // MARK: Action Buttons

    @ViewBuilder
    private func actionButtonsSection(actions: [Action]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
                .padding(.vertical, 6)

            Text("DIG DEEPER")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .kerning(1.8)
                .foregroundColor(.white.opacity(0.35))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(actions) { action in
                        Button(action: {
                            handleActionTap(action: action)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: iconForAction(action.title))
                                    .font(.system(size: 11))
                                Text(action.title)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .disabled(isTyping)
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    private func iconForAction(_ title: String) -> String {
        switch title {
        case "Analogy": return "lightbulb"
        case "Simplify": return "text.badge.minus"
        case "Expand": return "text.badge.plus"
        default: return "arrow.right"
        }
    }

    private func handleActionTap(action: Action) {
        guard !isTyping else { return }
        guard canSendFollowUp() else {
            presentPaywall {
                handleActionTap(action: action)
            }
            return
        }
        isTyping = true

        let buttonTitle = action.title
        let selectedPrompt = FollowUpPrompt.prompt(for: buttonTitle, client: ClaudeAPI.shared)

        let responseId = UUID()

        messages.indices.forEach { index in
            if !messages[index].isUser {
                messages[index].actions = nil
                messages[index].isResponseEnd = false
            }
        }

        let userMessage = Message(id: UUID(), text: buttonTitle, revealedText: buttonTitle, isUser: true)
        messages.append(userMessage)

        let responseMessage = Message(id: responseId, text: "", revealedText: "", isUser: false)
        messages.append(responseMessage)
        var requestFailed = false

        ClaudeAPI.shared.sendStreamedQuery(
            selectedPrompt,
            onReceive: { chunk in
                if let index = messages.firstIndex(where: { $0.id == responseId }) {
                    DispatchQueue.main.async {
                        messages[index].text += chunk
                        messages[index].revealedText += chunk
                    }
                }
            },
            onError: { errorMessage in
                requestFailed = true
                if let index = messages.firstIndex(where: { $0.id == responseId }) {
                    messages[index].text = errorMessage
                    messages[index].revealedText = errorMessage
                }
            },
            onComplete: {
                DispatchQueue.main.async {
                    isTyping = false
                    if let index = messages.firstIndex(where: { $0.id == responseId }) {
                        if !requestFailed {
                            recordSuccessfulFollowUp()
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
            }
        )
    }
}

// MARK: - Chat Bubble Shape

struct ChatBubbleShape: Shape {
    let isUser: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailRadius: CGFloat = 6
        var path = Path()

        if isUser {
            path.addRoundedRect(
                in: CGRect(x: rect.minX, y: rect.minY, width: rect.width - tailRadius / 2, height: rect.height),
                cornerSize: CGSize(width: radius, height: radius)
            )
        } else {
            path.addRoundedRect(
                in: CGRect(x: tailRadius / 2, y: rect.minY, width: rect.width - tailRadius / 2, height: rect.height),
                cornerSize: CGSize(width: radius, height: radius)
            )
        }

        return path
    }
}

// MARK: - Word-by-Word Text Reveal

struct WordByWordText: View {
    @State private var revealedText: String = ""
    let text: String
    let interval: Double = 0.05

    var body: some View {
        ZStack {
            Text(text)
                .hidden()
            Text(revealedText)
                .foregroundColor(Color(hex: "#FFFFFF"))
                .animation(nil, value: revealedText)
                .onAppear {
                    revealWords()
                }
        }
    }

    private func revealWords() {
        let words = text.split(separator: " ").map(String.init)
        var index = 0
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            if index < words.count {
                revealedText += (revealedText.isEmpty ? "" : " ") + words[index]
                index += 1
            } else {
                timer.invalidate()
            }
        }
    }
}

private func revealWordsGradually(for message: Message, isTyping: Binding<Bool>, showCursor: Binding<Bool>, onComplete: @escaping () -> Void) {
    let fullText = message.text
    let words = fullText.split(separator: " ")
    var revealedWords: [String] = []

    message.revealedText = ""
    isTyping.wrappedValue = true
    showCursor.wrappedValue = false

    let interval = 0.1 / 1.6

    Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
        if revealedWords.count < words.count {
            revealedWords.append(String(words[revealedWords.count]))
            DispatchQueue.main.async {
                message.revealedText = revealedWords.joined(separator: " ")
            }
        } else {
            timer.invalidate()
            DispatchQueue.main.async {
                message.revealedText = fullText
                onComplete()
            }
        }
    }
}
