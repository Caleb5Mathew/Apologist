//
//  GuidedJournalingView.swift
//  Apologist
//
//  Created by Caleb Matthews on 12/17/24.
//

import SwiftUI
import CoreHaptics

struct GuidedJournalingView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var journalManager = JournalEntryManager()
    @State private var showQuestion = false
    @State private var typedText = ""
    @State private var answer = ""
    @State private var answers: [String] = [] // Stores answers for all questions
    @State private var showExitConfirmation = false
    @State private var currentPage = 1 // Tracks the current page (1, 2, 3, or 4)
    @State private var typewriterTimer: Timer?
    @State private var engine: CHHapticEngine?
    @State private var showBackConfirmation = false // Tracks if back navigation confirmation should be shown
    @State private var showNextQuestion = false // Controls fade-in visibility of "Next Question >"

    private let questions = [
        "What have you been stressing about recently?",
        "What was the best part about today?",
        "What are some things you would like to work on throughout this week?",
        "What are you grateful for?"
    ]

    var body: some View {
        ZStack {
            // Background Color
            Color(hex: "#0B1E30")
                .ignoresSafeArea()
                .opacity(showQuestion ? 1.0 : 0.0) // Fade-in effect

            VStack {
                // Top Bar
                HStack {
                    Button(action: {
                        if !answer.isEmpty || currentPage > 1 {
                            showBackConfirmation = true
                        } else {
                            navigateBack()
                        }
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(hex: "#FFFFFF"))
                            Text("")
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer()

                if showQuestion {
                    HStack {
                        Spacer()
                        Text(typedText)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .onAppear {
                                typewriterEffect(for: questions[currentPage - 1])
                            }
                            .transition(.opacity)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }

                Spacer()

                // Multiline Answer Field
                if showQuestion {
                    MultilineTextView(text: $answer)
                        .frame(height: 150)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "#1B3A4B")) // Slightly more contrasted gray
                        )
                        .padding(.horizontal, 20)
                }

                // Show "Next Question >" for all pages except the last one
                if currentPage < questions.count {
                    HStack {
                        Spacer()
                        Button(action: {
                            navigateForward()
                            triggerHapticFeedback(style: .success)
                        }) {
                            Text("Next Question >")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(showNextQuestion ? Color.white : Color.gray)
                                .opacity(showNextQuestion ? 1.0 : 0.0) // Fade-in effect
                        }
                        .disabled(!showNextQuestion) // Prevent clicking before fade-in completes
                        .offset(y: showNextQuestion ? 0 : 20) // Start slightly higher, then animate down
                        .animation(.easeInOut(duration: 1.0), value: showNextQuestion)
                        Spacer()
                    }
                    .padding(.top, 10)
                    .onAppear {
                        // Trigger fade-in animation with color and position change
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation {
                                showNextQuestion = true
                            }
                        }
                    }
                }

                Spacer()

                // Save and Exit Button
                HStack {
                    Spacer()
                    Button(action: {
                        saveAndExit()
                        triggerHapticFeedback(style: .success)
                    }) {
                        Text("Save and Exit")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 10)
            }
        }
        .onAppear {
            fadeInBackground()
            prepareHaptics()
            resetForNewPage() // Trigger reset for the first page
        }
        .navigationBarHidden(true)
        .confirmationDialog("", isPresented: $showExitConfirmation) {
            Button("Exit", role: .destructive) {
                navigateToJournalHome()
                triggerHapticFeedback(style: .error)
            }
            Button("Save and Exit", role: .cancel) {
                saveAndExit()
                triggerHapticFeedback(style: .success)
            }
        } message: {
            Text("Exiting will not save current journal entry. Are you sure?")
        }
        .confirmationDialog("", isPresented: $showBackConfirmation) {
            Button("Exit", role: .destructive) {
                navigateToJournalHome()
                triggerHapticFeedback(style: .error)
            }
            Button("Save and Exit", role: .cancel) {
                saveCurrentPageAndNavigateBack()
                triggerHapticFeedback(style: .success)
            }
        } message: {
            Text("You have unsaved changes. Would you like to save your progress before going back?")
        }
    }

    // Navigation Backward
    private func navigateBack() {
        if currentPage > 1 {
            currentPage -= 1
            resetForNewPage()
        } else {
            navigateToJournalHome()
        }
    }

    private func saveCurrentPageAndNavigateBack() {
        if !answer.isEmpty {
            answers.append("Q\(currentPage): \(questions[currentPage - 1])\nA: \(answer)")
        }

        if !answers.isEmpty {
            let fullEntry = answers.joined(separator: "\n\n")
            journalManager.addEntry(
                title: "Guided Journaling - \(formattedDate())",
                content: fullEntry,
                type: "Guided Journaling"
            )
        }
        navigateToJournalHome()
    }

    private func navigateToJournalHome() {
        presentationMode.wrappedValue.dismiss()
        answers.removeAll() // Clear answers after saving or exiting
    }

    private func navigateForward() {
        if !answer.isEmpty {
            answers.append("Q\(currentPage): \(questions[currentPage - 1])\nA: \(answer)")
            answer = "" // Clear answer field for the next question
        }

        if currentPage < questions.count {
            currentPage += 1
            resetForNewPage()
        }
    }

    private func resetForNewPage() {
        typedText = "" // Clear the animated text
        answer = ""
        showQuestion = false // Temporarily hide the question for a smooth transition
        showNextQuestion = false // Reset fade-in for "Next Question >"

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Fade in the new question after a slight delay
            fadeInBackground()
            typewriterEffect(for: questions[currentPage - 1])
        }

        // Explicitly set `showNextQuestion` for all pages except the last
        if currentPage < questions.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    showNextQuestion = true
                }
            }
        }
    }

    // Function to fade in the background
    private func fadeInBackground() {
        withAnimation(.easeIn(duration: 2.0)) { // Slower fade-in effect
            showQuestion = true
        }
    }

    private func typewriterEffect(for question: String) {
        // Ensure the text is cleared before starting
        typedText = ""
        
        // Cancel any existing timer
        typewriterTimer?.invalidate()
        
        var currentIndex = 0
        let characters = Array(question) // Convert the question into an array of characters
        typewriterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if currentIndex < characters.count {
                typedText.append(characters[currentIndex]) // Append the next character
                currentIndex += 1
            } else {
                timer.invalidate()
                typewriterTimer = nil // Clear the timer reference when done
            }
        }
    }

    private func saveAndExit() {
        if !answer.isEmpty {
            answers.append("Q\(currentPage): \(questions[currentPage - 1])\nA: \(answer)")
        }

        if !answers.isEmpty {
            let fullEntry = answers.joined(separator: "\n\n")
            journalManager.addEntry(
                title: "Guided Journaling - \(formattedDate())",
                content: fullEntry,
                type: "Guided Journaling"
            )
        }

        navigateToJournalHome()
    }

    // Prepare haptics
    private func prepareHaptics() {
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptic engine failed to start: \(error.localizedDescription)")
        }
    }

    private func triggerHapticFeedback(style: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(style)
    }

    // Format the date
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: Date())
    }
}

// Multiline Text View
struct MultilineTextView: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = UIColor.white
        textView.backgroundColor = UIColor.clear
        textView.delegate = context.coordinator
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: MultilineTextView

        init(_ parent: MultilineTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}
