
//
//  HomeScreenView.swift
//  Apologist
//
//  Created by Caleb Matthews on 12/20/24.
//

import SwiftUI
//import FirebaseFirestore

struct HomeScreenView: View {
    @State private var feedback: String = "" {
        didSet {
            print("DEBUG: Feedback state changed to '\(feedback)'")
        }
    }
    @State private var isSubmitted: Bool = false

    init() {
        print("DEBUG: HomeScreenView initialized")
    }

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
            .onAppear {
                print("DEBUG: HomeScreenView appeared")
            }

            VStack(spacing: 20) {
                // Logo at the top

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
                    .onAppear {
                        print("DEBUG: Feedback submission message displayed")
                    }
                } else {
                    // Input Fields
                    VStack(spacing: 16) {
                        ZStack(alignment: .topLeading) {
                            if feedback.isEmpty {
                                Text("Your feedback...")
                                    .foregroundColor(.white.opacity(0.4))
                                    .padding(.horizontal, 12)
                                    .padding(.top, 12)
                            }
                            TextEditor(text: $feedback)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .background(Color(hex: "#162B3E"))
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                                .cornerRadius(14)
                                .frame(height: 150)
                        }
                        .padding(.horizontal, 20)
                    }

                    // Submit Button
                    Button(action: {
                        withAnimation {
                            isSubmitted = true
                            feedback = ""
                        }
                    }) {
                        HStack {
                            Text("Submit")
                                .font(.headline.bold())
                            Image(systemName: "arrow.up")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "#0B1E30"))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#F8C471"), Color(hex: "#E8B84A")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(14)
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 10)
                }

                Spacer()
            }
        }
        .navigationBarHidden(true)
    }

//    func sendFeedbackToFirebase() {
//        guard !feedback.trimmingCharacters(in: .whitespaces).isEmpty else {
//            print("DEBUG: Error - Feedback is empty.")
//            return
//        }
//
//        print("DEBUG: Preparing to send feedback to Firestore")
//        let db = Firestore.firestore()
//
//        let feedbackData: [String: Any] = [
//            "feedback": feedback,
//            "timestamp": Timestamp(date: Date()) // Use Firestore's Timestamp
//        ]
//
//        db.collection("feedbacks").addDocument(data: feedbackData) { error in
//            if let error = error {
//                print("DEBUG: Error saving feedback - \(error.localizedDescription)")
//            } else {
//                print("DEBUG: Feedback successfully saved to Firestore!")
//            }
//        }
//    }
}
