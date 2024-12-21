//
//  GuidedJournalingView.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/17/24.
//

//
//  GuidedJournalingView.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/17/24.
//

import SwiftUI

struct GuidedJournalingView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var journalManager = JournalEntryManager()
    @State private var showQuestion = false
    @State private var typedText = ""
    @State private var answer = ""
    @State private var showExitConfirmation = false
    @State private var currentPage = 1 // Tracks the current page (1, 2, 3, or 4)
    @State private var typewriterTimer: Timer?

    private let questions = [
        "What was the best part about today?",
        "What have you been stressing about recently?",
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
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(hex: "#FFFFFF")) // Yellow color
                            Text("")
                        }
                    }

                    Spacer()

                    if currentPage < questions.count { // Show checkmark except on the last page
                        Button(action: {
                            navigateForward()
                        }) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
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
                                .fill(Color(hex: "#14283A"))
                        )
                        .padding(.horizontal, 20)
                }

                Spacer()

                // Save and Exit Button
                HStack {
                    Spacer()
                    Button(action: {
                        saveAndExit()
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
        }
        .navigationBarHidden(true)
        .confirmationDialog("", isPresented: $showExitConfirmation) {
            Button("Exit", role: .destructive) {
                presentationMode.wrappedValue.dismiss()
            }
            Button("Save and Exit", role: .cancel) {
                saveAndExit()
            }
        } message: {
            Text("Exiting will not save current journal entry. Are you sure?")
        }
    }

    // Navigation Backward
    private func navigateBack() {
        if currentPage == 1 {
            presentationMode.wrappedValue.dismiss()
        } else {
            currentPage -= 1
            resetForNewPage()
        }
    }

    // Navigation Forward
    private func navigateForward() {
        if currentPage < questions.count {
            currentPage += 1
            resetForNewPage()
        }
    }

    // Reset State for New Page
    private func resetForNewPage() {
        typedText = "" // Clear the animated text
        answer = ""
        showQuestion = false // Temporarily hide the question for a smooth transition

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Fade in the new question after a slight delay
            fadeInBackground()
            typewriterEffect(for: questions[currentPage - 1])
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

    // Function to save the response and exit
    private func saveAndExit() {
        if !answer.isEmpty {
            journalManager.addEntry(
                title: "Guided Journaling - Page \(currentPage) - \(formattedDate())",
                content: answer,
                type: "Guided"
            )
        }
        presentationMode.wrappedValue.dismiss()
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
