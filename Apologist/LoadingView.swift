import SwiftUI
import SuperwallKit

struct LoadingView: View {
    @Binding var isLoaded: Bool
    @State private var isAnimating = false
    @State private var navigateToMainApp = false

    // Add these state variables if needed
    @State private var userInput: String = ""
    @State private var messages: [Message] = []
    @State private var isTyping: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient with midnight blue and black
                LinearGradient(
                    gradient: Gradient(colors: [.black, .midnightBlue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Apologist logo
                    Image("apologistLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .padding(.top, 40)

                    // Title with shadow
                    Text("Customizing Your Experience")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.7), radius: 10, x: 0, y: 5)
                        .padding(.top, 20)

                    // Subtitle
                    Text("Please wait while we set everything up...")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 40)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)

                    Spacer()

                    // Simple loading spinner
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2.0)
                    
                    Spacer()
                }
                .onAppear {
                    startLoadingSequence()
                }
            }
            .navigationBarHidden(true)
        }
        .overlay(
            NavigationLink(
                destination: MainAppView()
                    .navigationBarHidden(true),
                isActive: $navigateToMainApp
            ) {
                EmptyView()
            }
        )
    }

    private func startLoadingSequence() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            Superwall.shared.register(event: "campaign_trigger")
            isLoaded = true
            navigateToMainApp = true
        }
    }
}

