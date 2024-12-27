//
//  HomeScreenView.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/20/24.
//import SwiftUI
import SwiftUI
import FirebaseFirestore

struct HomeScreenView: View {
    @State private var feedback: String = ""
    @State private var isSubmitted: Bool = false
    @Binding var selectedTab: Int

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.043, green: 0.118, blue: 0.188), // Dark blue (#0B1E30)
                    Color(red: 0.114, green: 0.251, blue: 0.220)  // Greenish blue (#1D4038)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Logo at the top
                Text("Apologist")
                    .font(.custom("Georgia", size: 25))
                    .foregroundColor(.white)
                    .padding(.top, 16)

                // Header
                Text("Feedback")
                    .font(.largeTitle.bold())
                    .foregroundColor(Color(red: 0.831, green: 0.867, blue: 0.882)) // Moonlight Silver (#D4DDE1)
                    .padding(.top, 7)

                // Description
                Text("We'd love to hear from you!")
                    .font(.headline)
                    .foregroundColor(Color(red: 0.682, green: 0.714, blue: 0.749)) // Light gray (#AEB6BF)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                if isSubmitted {
                    // Feedback submitted confirmation
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                        Text("Feedback Submitted")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                } else {
                    // Input Fields
                    VStack(spacing: 16) {
                        // Feedback Field
                        ZStack(alignment: .topLeading) {
                            if feedback.isEmpty {
                                Text("Your feedback...")
                                    .foregroundColor(Color(red: 0.682, green: 0.714, blue: 0.749)) // Light gray (#AEB6BF)
                                    .padding(.horizontal, 8)
                                    .padding(.top, 12)
                            }
                            TextEditor(text: $feedback)
                                .scrollContentBackground(.hidden) // Hides the default opaque background
                                .padding(8)
                                .background(Color.clear) // Ensures transparency
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(red: 0.682, green: 0.714, blue: 0.749), lineWidth: 1) // Light gray border
                                )
                                .frame(height: 150) // Adjusted height for feedback
                        }
                        .padding(.horizontal, 20)
                    }

                    // Submit Button
                    Button(action: {
                        sendFeedbackToFirebase()
                        withAnimation {
                            isSubmitted = true
                            feedback = ""
                        }
                    }) {
                        Text("Submit")
                            .font(.headline.bold())
                            .foregroundColor(Color(red: 0.043, green: 0.118, blue: 0.188)) // Dark blue text (#0B1E30)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white) // White button
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.682, green: 0.714, blue: 0.749), lineWidth: 1) // Subtle border
                            )
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 10)
                }

                Spacer()
            }
        }
        .navigationBarHidden(true)
    }

    /// Function to send feedback to Firebase Firestore
    func sendFeedbackToFirebase() {
        let db = Firestore.firestore()

        let feedbackData: [String: Any] = [
            "feedback": feedback,
            "timestamp": Date().timeIntervalSince1970
        ]

        db.collection("feedbacks").addDocument(data: feedbackData) { error in
            if let error = error {
                print("Error saving feedback: \(error.localizedDescription)")
            } else {
                print("Feedback successfully saved to Firestore!")
            }
        }
    }
}
