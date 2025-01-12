
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
    @State private var selectedTab: Int = 2 // Default to "Ask" tab
    @State private var showCursor: Bool = false
    @State private var disableAutoscroll: Bool = false // Tracks whether autoscroll is disabled manually
    @State private var userInteracted: Bool = false // Tracks if the user interacted during this session
    @State private var showSidebar: Bool = false
    @State private var isPresentingEditHabitView = false
    @State private var sortingOption: SortingOption = .byDate
    @State private var isSortingOrderAscending: Bool = false

    var body: some View {
        ZStack {
            NavigationView {
                VStack(spacing: 0) {
                    HStack {
                        // Menu Button
                        Button(action: {
                            withAnimation {
                                showSidebar.toggle()
                            }
                        }) {
                            Image(systemName: "line.horizontal.3")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }
                        .frame(width: 45, height: 45)
                        .padding(.leading, -11)

                        Spacer()

                        // Title
                        Text("Apologist")
                            .font(.custom("Georgia", size: 25))
                            .foregroundColor(Color(hex: "#FFFFFF"))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .offset(x: alignmentOffset()) // Adjust dynamically based on selectedTab

                        Spacer()

                        // Conditionally display Plus Icon and Sort Menu for Habit Page
                        if selectedTab == 0 {
                            HStack(spacing: 16) {
                                // Sort Menu
                                Menu {
                                    Picker("Sorting", selection: $sortingOption) {
                                        ForEach(SortingOption.allCases, id: \.self) { option in
                                            Text(option.rawValue).tag(option)
                                        }
                                    }
                                    Button(action: {
                                        isSortingOrderAscending.toggle()
                                    }) {
                                        Text("Toggle Sort Order")
                                    }
                                } label: {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color(hex: "#D4DDE1"))
                                }

                                // Plus Icon
                                Button(action: {
                                    isPresentingEditHabitView = true
                                }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color(hex: "#F8C471"))
                                }
                                .sheet(isPresented: $isPresentingEditHabitView) {
                                    EditHabitView(habit: nil)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 0)
                    .background(Color(hex: "#0B1E30"))




                    .padding(.horizontal, 20) // Adjust horizontal padding
                    .padding(.top, 0)
                    .background(Color(hex: "#0B1E30"))

                    currentPage
                        .highPriorityGesture(
                            DragGesture(minimumDistance: 20) // Minimum distance to recognize a drag
                                .onEnded { value in
                                    // Calculate horizontal and vertical drag amounts
                                    let horizontalAmount = value.translation.width
                                    let verticalAmount = value.translation.height

                                    // Detect swipe direction
                                    if abs(horizontalAmount) > abs(verticalAmount) { // Horizontal swipe
                                        if horizontalAmount < -50 { // Swipe left
                                            print("Swipe left detected")
                                            goToNextPage()
                                        } else if horizontalAmount > 50 { // Swipe right
                                            print("Swipe right detected")
                                            goToPreviousPage()
                                        } else {
                                            print("Swipe gesture too short to register")
                                        }
                                    } else {
                                        print("Vertical gesture detected; ignoring")
                                    }
                                }
                        )







                }
                .background(Color(hex: "#0B1E30").ignoresSafeArea())
                .navigationBarHidden(true)
                .preferredColorScheme(.dark)
            }
            .navigationViewStyle(StackNavigationViewStyle())

            // Sidebar
            if showSidebar {
                SidebarMenu(showSidebar: $showSidebar, onOptionSelected: { option in
                    handleSidebarSelection(option)
                })
                .transition(.move(edge: .leading))
                .zIndex(1)
            }
        }
    }



    
    var askQuestionView: some View {
        VStack(spacing: 0) {

            

            // Conditional: Show Suggested Questions if No Messages Exist
            if messages.isEmpty {
                VStack(spacing: 12) {
                    // "SUGGESTED QUESTIONS" Header
                    Text("SUGGESTED QUESTIONS")
                        .font(.system(size: 12, weight: .bold)) // Header style
                        .kerning(1.5) // Add letter spacing
                        .foregroundColor(Color.white)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 5)

                    // Suggested Question Buttons
                    ForEach([
                        "How do I know God is real?",
                        "How do I hear God?",
                        "How could a loving God allow so much suffering?",
                        "Why would God send people to hell?"
                    ], id: \.self) { question in
                        Button(action: {
                            // Programmatically mimic sending the question
                            userInput = question
                            sendMessage()
                        }) {
                            Text(question)
                                .font(.system(size: 14, weight: .bold)) // Consistent font style
                                .kerning(1.5) // Match kerning
                                .foregroundColor(Color.white)
                                .padding(.horizontal, 12) // Snug padding
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white, lineWidth: 2) // Solid white outline
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 30) // Add extra spacing below the Apologist header
            }





            // Chat History with Scrolling
            ScrollViewReader { scrollView in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(messages.indices, id: \.self) { index in
                            let message = messages[index]
                            let isConsecutive = index > 0 && messages[index - 1].isUser == message.isUser

                            ChatBubble(
                                message: message,
                                isConsecutive: isConsecutive,
                                showCursor: showCursor && !message.isUser
                            )
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.3), value: message.revealedText)
                            .id(index) // Assign ID for autoscrolling
                        }

                        if isTyping {
                            TypingIndicator()
                                .frame(maxWidth: .infinity, alignment: .leading) // Align typing indicator to the left
                                .padding(.horizontal)
                                .id("TypingIndicator") // Assign ID to the typing indicator
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .background(Color(hex: "#0B1E30"))
                .gesture(DragGesture().onChanged { _ in
                    // Detect user interaction with the scroll view
                    disableAutoscroll = true
                    userInteracted = true // Track user interaction
                })
                .onChange(of: messages) { _ in
                    if !disableAutoscroll {
                        scrollToLast(scrollView: scrollView) // Scroll to the last message
                    }
                }
            }

            // Input Section
            HStack(alignment: .bottom, spacing: 10) {
                ZStack(alignment: .bottomTrailing) {
                    TextField("Ask a question...", text: $userInput, axis: .vertical)
                        .lineLimit(1...6) // Dynamic height
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

    }

    
    var menuButton: some View {
        Button(action: {
            withAnimation {
                showSidebar.toggle()
            }
        }) {
            Image(systemName: "line.horizontal.3")
                .font(.system(size: 22)) // Keep size smaller
                .frame(width: 45, height: 45) // Adjust frame size for consistent spacing
                .foregroundColor(.white)
        }
        .padding(.leading, 38) // Reduce leading padding to shift left
        .padding(.top, 5) // Add padding to shift up

    }
    @State private var swipeDirection: Edge = .trailing // Track swipe direction

    var currentPage: some View {
        Group {
            switch selectedTab {
            case 0:
                ContentView() // Habits
                    .transition(.move(edge: swipeDirection))
            case 1:
                askQuestionView // Questions
                    .transition(.move(edge: swipeDirection))
            case 2:
                JournalHomeView() // Journaling
                    .transition(.move(edge: swipeDirection))
            case 3:
                HomeScreenView(selectedTab: $selectedTab) // Feedback
                    .transition(.move(edge: swipeDirection))
            case 4:
                BibleView() // Bible
                    .transition(.move(edge: swipeDirection)) // Add the BibleView here
            default:
                ContentView() // Default to Habits
                    .transition(.move(edge: swipeDirection))
            }
        }
        .animation(.easeInOut, value: selectedTab) // Animate the transitions
    }




    private func goToNextPage() {
        swipeDirection = .trailing
        withAnimation {
            selectedTab = (selectedTab + 1) % 5 // Loops back to 0 after 4
        }
        print("Navigated to next page: \(selectedTab)")
    }

    private func goToPreviousPage() {
        swipeDirection = .leading
        withAnimation {
            selectedTab = (selectedTab - 1 + 5) % 5 // Loops back to 4 after 0
        }
        print("Navigated to previous page: \(selectedTab)")
    }







    func alignmentOffset() -> CGFloat {
        switch selectedTab {
        case 3: // Feedback Tab
            return -16 // Adjusted for proper alignment
        case 0: // Habits Tab
            return 16 // Adjust to the left slightly
        case 1, 2: // Questions, Journaling Tabs
            return -16.5 // Adjust to the left slightly
        case 4: // Bible Tab
            return -15.5 // Centered properly
        default:
            return 0 // Default case for safety
        }
    }


    private func handleSidebarSelection(_ option: SidebarOption) {
        withAnimation {
            showSidebar = false
        }
        switch option {
        case .habits:
            selectedTab = 0
        case .questions:
            selectedTab = 1
        case .journaling:
            selectedTab = 2
        case .feedback:
            selectedTab = 3
        case .bible:
            selectedTab = 4 // Bible tab
        }
    }



    private func scrollToLast(scrollView: ScrollViewProxy) {
        DispatchQueue.main.async {
            if let lastIndex = messages.indices.last {
                withAnimation(.easeOut(duration: 0.3)) {
                    scrollView.scrollTo(lastIndex, anchor: .bottom) // Scroll to the last message
                }
            } else if isTyping {
                withAnimation(.easeOut(duration: 0.3)) {
                    scrollView.scrollTo("TypingIndicator", anchor: .bottom) // Scroll to typing indicator
                }
            }
        }
    }

    private func resetAutoscroll() {
        // Re-enable autoscroll if a new question is asked
        userInteracted = false
        disableAutoscroll = false
    }

    func sendMessage() {
        guard !userInput.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("DEBUG: User input is empty")
            return
        }

        // Add user message
        let userMessage = Message(id: UUID(), text: userInput, revealedText: userInput, isUser: true)
        messages.append(userMessage)
        print("DEBUG: Appended user message: \(userMessage.text)")
        userInput = ""

        // Add placeholder for AI response
        let responseId = UUID()
        let responseMessage = Message(id: responseId, text: "", revealedText: "", isUser: false)
        messages.append(responseMessage)
        print("DEBUG: Appended placeholder response message")

        isTyping = true

        // Stream the AI response
        ClaudeAPI.shared.sendStreamedQuery(userMessage.text,
            onReceive: { chunk in
                if let index = self.messages.firstIndex(where: { $0.id == responseId }) {
                    DispatchQueue.main.async {
                        self.messages[index].text += chunk
                        print("DEBUG: Updated response message: \(self.messages[index].text)")
                    }
                }
            },
            onComplete: {
                DispatchQueue.main.async {
                    self.isTyping = false
                    self.revealWordsGradually(for: responseId) // Trigger gradual revealing
                }
            }
        )
    }



    





    func revealWordsGradually(for messageId: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else { return }

        let fullText = messages[index].text
        var revealedWords = [String]()
        let words = fullText.split(separator: " ")

        // Start with an empty revealed text and show the typing indicator
        messages[index].revealedText = ""
        isTyping = true // Show the `...` typing indicator
        showCursor = false // Hide `|` initially

        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            if revealedWords.count < words.count {
                revealedWords.append(String(words[revealedWords.count])) // Add the next word
                DispatchQueue.main.async {
                    self.messages[index].revealedText = revealedWords.joined(separator: " ") // Do NOT append `|`
                    if revealedWords.count == 1 {
                        self.isTyping = false // Hide the `...` after the first word
                        self.showCursor = true // Show the `|` after the first word
                    }
                }
            } else {
                timer.invalidate() // Stop the timer when all words are revealed
                DispatchQueue.main.async {
                    self.messages[index].revealedText = revealedWords.joined(separator: " ") // Ensure `|` is not appended
                    self.showCursor = false // Hide the `|` after text generation is complete
                }
            }
        }
    }








    // Progressive word reveal animation
    func startWordReveal(for messageId: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else { return }

        let fullText = messages[index].text
        let words = fullText.split(separator: " ") // Split into words
        var revealedWords: [Substring] = []

        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            if revealedWords.count < words.count {
                revealedWords.append(words[revealedWords.count]) // Add next word
                self.messages[index].revealedText = revealedWords.joined(separator: " ") // Update revealed text
                print("DEBUG: Revealed text: \(self.messages[index].revealedText)")
            } else {
                timer.invalidate() // Stop the timer when all words are revealed
            }
        }
    }












}


struct ChatBubble: View {
    var message: Message
    var isConsecutive: Bool
    var showCursor: Bool // Controls whether the `|` is shown

    var body: some View {
        VStack(alignment: .leading, spacing: isConsecutive ? 4 : 16) {
            if message.isUser {
                HStack {
                    Spacer()
                    Text(message.revealedText)
                        .padding()
                        .padding(.vertical, 1) // Slightly reduced vertical padding
                        .padding(.horizontal, 2) // Keep horizontal padding u
                        .background(Color(hex: "#1F5F4E"))
                        .foregroundColor(Color(hex: "#FFFFFF"))
                        .cornerRadius(20)
                        .frame(maxWidth: 250, alignment: .trailing)
                }
                .padding(.horizontal)
            } else {
                HStack(alignment: .top) {
                    // Append `|` only if `showCursor` is true
                    Text(message.revealedText + (showCursor ? "|" : ""))
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#FFFFFF"))
                        .lineSpacing(6)
                        .animation(nil, value: message.revealedText)
                        .padding(.horizontal)
                    Spacer()
                }
            }
        }
    }
}








struct WordByWordText: View {
    @State private var revealedText: String = ""
    let text: String
    let interval: Double = 0.05

    var body: some View {
        ZStack { // Prevent unnecessary flashing
            Text(text) // Full text (hidden, stabilizes layout)
                .hidden()
            
            Text(revealedText) // Dynamically revealed text
                .foregroundColor(Color(hex: "#FFFFFF")) // White text
                .animation(nil, value: revealedText) // Disable animation on updates
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




struct MessageText: View {
    let revealedText: String

    var body: some View {
        Text(revealedText)
            .font(.system(size: 16))
            .foregroundColor(Color(hex: "#FFFFFF"))
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
    var text: String // Full text of the message
    var revealedText: String // Text revealed incrementally
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

struct MainAppWrapperView: View {
    var body: some View {
        MainAppView() // Wraps MainAppView properly
    }
}
