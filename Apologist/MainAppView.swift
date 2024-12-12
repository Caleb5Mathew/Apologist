//
//  MainAppView.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/6/24.
//

import SwiftUI

struct MainAppView: View {
    @State private var userInput: String = ""
    @State private var messages: [Message] = []
    @State private var isTyping: Bool = false
    @State private var selectedTab: Int = 2 // Default to "Home" tab

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Main content based on selected tab
                if selectedTab == 1 {
                    HomePageView() // Home Page
                } else if selectedTab == 2 {
                    askQuestionView // "Ask Questions" Page
                } else if selectedTab == 3 {
                    ContentView() // "Coming Soon" Page
                }

                // Bottom Tab Bar
                HStack {
                    Spacer() // Add space to center items
                    Button(action: { selectedTab = 1 }) {
                        VStack {
                            Image(systemName: "house.fill")
                                .font(.system(size: 24))
                                .foregroundColor(selectedTab == 1 ? Color(hex: "#1F5F4E") : Color(hex: "#D4DDE1"))
                            Text("Home")
                                .font(.system(size: 10))
                                .foregroundColor(selectedTab == 1 ? Color(hex: "#1F5F4E") : Color(hex: "#D4DDE1"))
                        }
                    }
                    Spacer()
                    Button(action: { selectedTab = 2 }) {
                        VStack {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 24))
                                .foregroundColor(selectedTab == 2 ? Color(hex: "#1F5F4E") : Color(hex: "#D4DDE1"))
                            Text("Ask")
                                .font(.system(size: 10))
                                .foregroundColor(selectedTab == 2 ? Color(hex: "#1F5F4E") : Color(hex: "#D4DDE1"))
                        }
                    }
                    Spacer()
                    Button(action: { selectedTab = 3 }) {
                        VStack {
                            Image(systemName: "checkmark.circle.fill") // Replaced ellipsis with checkmark
                                .font(.system(size: 24))
                                .foregroundColor(selectedTab == 3 ? Color(hex: "#1F5F4E") : Color(hex: "#D4DDE1"))
                            Text("Habits")
                                .font(.system(size: 10))
                                .foregroundColor(selectedTab == 3 ? Color(hex: "#1F5F4E") : Color(hex: "#D4DDE1"))
                        }
                    }
                    Spacer() // Add space to center items
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 30)
                .background(LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#0B1E30"), Color(hex: "#274E45")]),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
            }
            .background(Color(hex: "#0B1E30").ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }

    var askQuestionView: some View {
        VStack(spacing: 0) {
            // Chat Header
            Text("Apologist")
                .font(.custom("Georgia", size: 25))
                .foregroundColor(Color(hex: "#D4DDE1"))
                .padding(.bottom, 10)

            // Chat History
            ScrollViewReader { scrollView in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(messages) { message in
                            ChatBubble(message: message)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.3), value: messages)
                        }

                        if isTyping {
                            TypingIndicator() // Add typing indicator in chat history
                                .frame(maxWidth: .infinity, alignment: .leading) // Align to the left
                                .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .background(Color(hex: "#0B1E30"))
                .onChange(of: messages) { _ in
                    withAnimation {
                        scrollView.scrollTo(messages.last?.id, anchor: .bottom)
                    }
                }
            }

            // Input Section
            HStack {
                TextField("", text: $userInput, prompt: Text("Ask a question...")
                    .foregroundColor(Color(hex: "#D4DDE1")))
                    .padding(12)
                    .background(Color(hex: "#274E45"))
                    .foregroundColor(Color(hex: "#D4DDE1"))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "#D4DDE1"), lineWidth: 1)
                    )
                    .font(.system(size: 14, design: .default))
                    .frame(height: 44)

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.black)
                        .padding()
                        .background(Color(hex: "#F5E3C2")) // Beige color
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "#D4DDE1"), lineWidth: 2) // Moonlight silver outline
                        )
                        .frame(height: 44)
                }

            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(hex: "#0B1E30"))
        }
    }

    func sendMessage() {
        guard !userInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let userMessage = Message(id: UUID(), text: userInput, isUser: true)
        messages.append(userMessage)
        userInput = ""

        isTyping = true // Show typing indicator
        ClaudeAPI.shared.sendQuery(userMessage.text) { response in
            DispatchQueue.main.async {
                self.isTyping = false // Hide typing indicator
                if let response = response {
                    let aiMessage = Message(id: UUID(), text: response, isUser: false)
                    self.messages.append(aiMessage)
                } else {
                    let errorMessage = Message(id: UUID(), text: "Sorry, something went wrong. Please try again.", isUser: false)
                    self.messages.append(errorMessage)
                }
            }
        }
    }
}

// ChatBubble Component
struct ChatBubble: View {
    var message: Message

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if message.isUser {
                Text(message.text)
                    .padding()
                    .background(Color(hex: "#1F5F4E")) // Use a consistent color for user messages
                    .foregroundColor(Color(hex: "#D4DDE1"))
                    .cornerRadius(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(message.text)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#2A6D87"), // A lighter blue-green at the top
                                Color(hex: "#174F65")  // A slightly darker blue-green at the bottom
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .foregroundColor(Color(hex: "#D4DDE1")) // Use the moonlight silver for text
                    .cornerRadius(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal) // Add padding to separate messages from the screen edges
    }
}




// Typing Indicator
struct TypingIndicator: View {
    @State private var dotCount = 1

    var body: some View {
        Text(String(repeating: ".", count: dotCount))
            .font(.system(size: 20, weight: .bold, design: .default))
            .foregroundColor(Color(hex: "#F8C471"))
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { timer in
                    dotCount = (dotCount % 3) + 1 // Cycle between 1, 2, and 3 dots
                }
            }
    }
}

// Message Model
struct Message: Identifiable, Equatable {
    let id: UUID
    let text: String
    let isUser: Bool
}

// Hex Color Extension
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
