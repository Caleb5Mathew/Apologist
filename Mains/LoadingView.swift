import SwiftUI
import SuperwallKit

struct LoadingView: View {
    @Binding var isLoaded: Bool
    @State private var isAnimating = false
    @State private var navigateToHomeFile = false // ✅ Navigate to HomeFile after paywall
    @State private var selectedTab: Int = 1 // Default to "Ask" tab
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
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Main Title
                    Text("Personalizing\nFeatures")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                        .multilineTextAlignment(.center)
                    
                    // Subtitle
                    Text("Thank you for waiting...")
                        .font(.title2)
                        .foregroundColor(Color.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
                .padding()
                .onAppear {
                    startLoadingSequence()
                }
            }
            .navigationBarHidden(true)
            .borderLoadingAnimation(isAnimating: $isAnimating)
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
            .fullScreenCover(isPresented: $navigateToHomeFile) {
                HomeFile(selectedTab: $selectedTab) // ✅ Updated to the correct reference
            }
        }
    }
    
    // ✅ Ensures paywall and HomeFile trigger at exactly 2.5 seconds
    private func startLoadingSequence() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isLoaded = true
            
            DispatchQueue.main.async {
                Superwall.shared.register(placement: "campaign_trigger")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    navigateToHomeFile = true // ✅ Navigates to HomeFile after 2.5s
                }
            }
        }
    }
    var currentPage: some View {
        Group {
            switch selectedTab {
            case 0:
                ContentView()
            case 1:
                ChatView(
                    userInput: $userInput,
                    messages: $messages,
                    isTyping: $isTyping
                )
            case 2:
                JournalHomeView()
            case 3:
                HomeScreenView()
            case 4:
                BibleView()
            default:
                EmptyView() // ✅ Prevents accidental overlap
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
        .id(selectedTab) // ✅ Ensures UI updates when switching tabs
    }}


extension View {
    func borderLoadingAnimation(isAnimating: Binding<Bool>) -> some View {
        modifier(BorderLoadingAnimation(isAnimating: isAnimating))
    }
}

struct BorderLoadingAnimation: ViewModifier, Animatable {
    @Binding var isAnimating: Bool
    
    private let lineWidth: CGFloat = 12 // Increased thickness
    @State private var hasTopSafeAreaInset: Bool = false

    var animatableData: Double {
        get { isAnimating ? 1.0 : 0.0 }
        set { isAnimating = newValue > 0.5 }
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: hasTopSafeAreaInset ? 0 : 52)
                        .stroke(
                            AngularGradient(
                                stops: [
                                    .init(color: Color(hex: "#6A5ACD"), location: 0), // Blue-Purple
                                    .init(color: Color(hex: "#1B3A4B"), location: 0.5), // Dark Blue
                                    .init(color: Color(hex: "#6A5ACD"), location: 1)  // Blue-Purple
                                ],
                                center: .center,
                                angle: .degrees(isAnimating ? 360 : 0)
                            ),
                            lineWidth: lineWidth
                        )
                        .frame(width: geometry.size.width - lineWidth, height: geometry.size.height - lineWidth)
                        .padding(.top, lineWidth / 2)
                        .padding(.leading, lineWidth / 2)
                        .onAppear {
                            let topSafeAreaInset = geometry.safeAreaInsets.top
                            hasTopSafeAreaInset = topSafeAreaInset > 20
                        }
                }
            )
            .ignoresSafeArea()
    }
}
