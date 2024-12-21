//
//  HomeScreenView.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/20/24.
//import SwiftUI

import SwiftUI
import MessageUI

struct HomeScreenView: View {
    @State private var email: String = ""
    @State private var feedback: String = ""
    @State private var isSubmitted: Bool = false
    @Binding var selectedTab: Int
    @State private var showingMailError = false

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
                        // Email Field (Optional)
                        ZStack(alignment: .leading) {
                            if email.isEmpty {
                                Text("Your Email (optional)")
                                    .foregroundColor(Color(red: 0.682, green: 0.714, blue: 0.749)) // Light gray (#AEB6BF)
                                    .padding(.leading, 12)
                            }
                            TextField("", text: $email)
                                .padding(12)
                                .background(Color.clear) // Transparent background
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(red: 0.682, green: 0.714, blue: 0.749), lineWidth: 1) // Light gray border
                                )
                        }
                        .padding(.horizontal, 20)

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
                        sendFeedback()
                        withAnimation {
                            isSubmitted = true
                            email = ""
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
        .alert(isPresented: $showingMailError) {
            Alert(
                title: Text("Error"),
                message: Text("Mail services are not available."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    func sendFeedback() {
        guard MFMailComposeViewController.canSendMail() else {
            print("Mail services are not available.")
            showingMailError = true
            return
        }

        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.setToRecipients(["4caleb4mathew4@gmail.com"])
        mailComposeVC.setSubject("User Feedback")
        mailComposeVC.setMessageBody(
            """
            Email: \(email.isEmpty ? "No email provided" : email)
            Feedback:
            \(feedback)
            """, isHTML: false
        )
        mailComposeVC.mailComposeDelegate = Coordinator()
        UIApplication.shared.windows.first?.rootViewController?.present(mailComposeVC, animated: true)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                print("Mail error: \(error.localizedDescription)")
            } else {
                switch result {
                case .sent:
                    print("Mail sent successfully.")
                case .saved:
                    print("Mail saved as draft.")
                case .cancelled:
                    print("Mail cancelled by user.")
                case .failed:
                    print("Mail sending failed.")
                @unknown default:
                    print("Unknown result.")
                }
            }
            controller.dismiss(animated: true, completion: nil)
        }
    }
}
