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
                    ComingSoonView() // "Coming Soon" Page
                }

                // Bottom Tab Bar
                HStack {
                    Button(action: { selectedTab = 1 }) {
                        VStack {
                            Image(systemName: "house.fill")
                                .font(.system(size: 24))
                                .foregroundColor(selectedTab == 1 ? .blue : .gray)
                            Text("Home")
                                .font(.system(size: 10))
                                .foregroundColor(selectedTab == 1 ? .blue : .gray)
                        }
                    }
                    Spacer()
                    Button(action: { selectedTab = 2 }) {
                        VStack {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 24))
                                .foregroundColor(selectedTab == 2 ? .blue : .gray)
                            Text("Ask")
                                .font(.system(size: 10))
                                .foregroundColor(selectedTab == 2 ? .blue : .gray)
                        }
                    }
                    Spacer()
                    Button(action: { selectedTab = 3 }) {
                        VStack {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 24))
                                .foregroundColor(selectedTab == 3 ? .blue : .gray)
                            Text("More")
                                .font(.system(size: 10))
                                .foregroundColor(selectedTab == 3 ? .blue : .gray)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 30)
                .background(Color.black)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }

    // "Ask a Question" Page
    var askQuestionView: some View {
        VStack(spacing: 0) {
            // Chat Header
            Text("Apologist")
                .font(.custom("Georgia", size: 25)) // Georgia font
                .foregroundColor(.white)
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
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .background(Color.black)
                .onChange(of: messages) { _ in
                    withAnimation {
                        scrollView.scrollTo(messages.last?.id, anchor: .bottom)
                    }
                }
            }

            // Typing Indicator
            if isTyping {
                HStack {
                    Spacer()
                    Text("Apologist is typing...")
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                        .padding(.trailing, 16)
                }
            }

            // Input Section
            HStack {
                TextField("", text: $userInput, prompt: Text("Ask a question...")
                    .foregroundColor(.gray))
                    .padding(12) // Padding for height
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 1)
                    )
                    .font(.system(size: 14, design: .default))
                    .frame(height: 44) // Match height to the send button

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .frame(height: 44) // Ensure height matches text field
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.black)
        }
    }

    func sendMessage() {
        guard !userInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let userMessage = Message(id: UUID(), text: userInput, isUser: true)
        messages.append(userMessage)
        userInput = ""

        isTyping = true
        ClaudeAPI.shared.sendQuery(userMessage.text) { response in
            DispatchQueue.main.async {
                self.isTyping = false
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
        HStack {
            if message.isUser {
                Spacer()
                Text(message.text)
                    .padding(6)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.blue, Color.cyan]), startPoint: .top, endPoint: .bottom)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .frame(maxWidth: 200, alignment: .trailing)
            } else {
                Text(message.text)
                    .padding(6)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .frame(maxWidth: 200, alignment: .leading)
                Spacer()
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
