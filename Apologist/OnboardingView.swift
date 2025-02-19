//
//  LaunchScreenView.swift
//  Apologist
//
//  Created by Caleb Matthews on 12/6/24.
//


import SwiftUI
import FirebaseFirestore
import SuperwallKit

struct OnboardingView: View {
    @Binding var isLoaded: Bool

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var currentScreenIndex = 0
    @State private var currentQuestionIndex = 0
    @State private var userResponses: [String] = Array(repeating: "", count: 6)
    @State private var multiSelections: Set<String> = []
    @State private var gradientPhase1: CGFloat = 0
    @State private var gradientPhase2: CGFloat = 0
    @State private var gradientPhase3: CGFloat = 0
    @State private var completedQuestions: Set<Int> = []
    @State private var showLoadingView = false
    @State private var navigateToChatView = false
    @State private var isShowingWelcomeScreen = true
    @State private var isShowingIntroScreen = true

    // Add these state variables if needed
    @State private var userInput: String = ""
    @State private var messages: [Message] = []
    @State private var isTyping: Bool = false

    private let introScreens = [
        ("Faith Meets Reason", "Have deep questions about Christianity? Apologist provides clear, thoughtful, and reasoned answers to help you explore faith with confidence."),
        ("Ask, Learn, Grow", "No question is too big. Challenge your doubts, strengthen your faith, and get AI-driven answers now.")
    ]

    private let questions = [
        Question(
            title: "What is your age?",
            subtitle: nil,
            options: ["13-17", "18-24", "25-34", "35-44", "45-54", "55+"],
            isMultiSelect: false
        ),
        Question(
            title: "Do you lean towards a denomination?",
            subtitle: nil,
            options: ["Protestant", "Catholic", "Orthodox", "Non-denominational", "Seeking/Curious", "Other"],
            isMultiSelect: false
        ),
        Question(
            title: "How long have you been a Christian?",
            subtitle: nil,
            options: ["New believer", "1-5 years", "5-10 years", "10+ years", "Still exploring", "Prefer not to say"],
            isMultiSelect: false
        ),
        Question(
            title: "What brings you to Apologist?",
            subtitle: "Select all that apply",
            options: ["Strengthen my faith", "Answer difficult questions", "Learn apologetics", "Help others believe", "Personal doubts", "General interest"],
            isMultiSelect: true
        ),
        Question(
            title: "How did you hear about us?",
            subtitle: nil,
            options: ["App Store Search", "TikTok", "Instagram", "Facebook", "Friend/Family", "Other"],
            isMultiSelect: false
        ),
        Question(
            title: "What interests you most?",
            subtitle: "Select all that apply",
            options: ["Exploring Faith", "Apologetics", "Deep Biblical Study", "Christian Philosophy", "Defending Faith", "Personal Growth"],
            isMultiSelect: true
        )
    ]
    
    private let db = Firestore.firestore()
    
    private func isValidToProgress() -> Bool {
        if questions[currentQuestionIndex].isMultiSelect {
            return !multiSelections.isEmpty
        }
        return !userResponses[currentQuestionIndex].isEmpty
    }
    
    private func saveUserResponses() {
        let responseData: [String: Any] = [
            "timestamp": FieldValue.serverTimestamp(),
            "age": userResponses[0],
            "denomination": userResponses[1],
            "christianExperience": userResponses[2],
            "reasonForJoining": userResponses[3],
            "discoverySource": userResponses[4],
            "topicsOfInterest": Array(multiSelections),
            "deviceInfo": [
                "model": UIDevice.current.model,
                "systemVersion": UIDevice.current.systemVersion
            ]
        ]
        
        db.collection("User_Onboarding")
            .document()
            .setData(responseData) { error in
                if let error = error {
                    print("Error saving to Firebase: \(error.localizedDescription)")
                } else {
                    print("Successfully saved to Firebase")
                    hasCompletedOnboarding = true
                }
            }
    }
    
    private func triggerPaywall() {
        Superwall.shared.register(event: "campaign_trigger")
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if isShowingIntroScreen {
                    introScreen
                } else if isShowingWelcomeScreen {
                    WelcomeScreen(isShowingWelcomeScreen: $isShowingWelcomeScreen)
                } else {
                    onboardingQuestions
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.darkBlue, .midnightBlue, .lightBlue]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .overlay(
                NavigationLink(
                    destination: ChatView(
                        userInput: $userInput,
                        messages: $messages,
                        isTyping: $isTyping
                    ),
                    isActive: $navigateToChatView
                ) {
                    EmptyView()
                }
            )
        }
    }
    
    
    private var introScreen: some View {
        ZStack {
            backgroundView  // ✅ Unified Background Styling

            VStack(spacing: 24) {
                // **Title - Heavy Apple Style**
                Text("Welcome to Apologist")
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // **Subtitle - Smaller, Subtle but Bold**
                Text("Apologist is your companion for exploring Christianity with reasoned answers. Deepen your faith, challenge your doubts, and gain insights into biblical teachings.")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // **CTA Button - Glassy Professional Look**
                Button(action: {
                    withAnimation {
                        isShowingIntroScreen = false
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "#D4DDE1"))

                        Text("Get Started")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "#D4DDE1"))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.black.opacity(0.4)) // Glass effect
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1.2)
                            )
                            .shadow(color: Color.white.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 32)
                }
                .padding(.top, 20)
            }
        }
    }





    @ViewBuilder
    private var onboardingQuestions: some View {
        Group {
            if showLoadingView {
                LoadingView(isLoaded: $isLoaded)
            } else {
                GeometryReader { geometry in
                    ZStack {
                        // Enhanced Animated Background with Spinning Slices
                        ZStack {
                            // Base gradient layer
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .init(red: 0.04, green: 0.08, blue: 0.15),
                                    .init(red: 0.04, green: 0.12, blue: 0.19),
                                    .init(red: 0.29, green: 0.61, blue: 0.83)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .rotationEffect(.degrees(gradientPhase1))
                            
                            // First spinning slice
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    .init(red: 0.29, green: 0.61, blue: 0.83).opacity(0.1),
                                    .init(red: 0.04, green: 0.08, blue: 0.15).opacity(0.2)
                                ]),
                                center: .init(
                                    x: 0.5 + 0.3 * sin(gradientPhase2),
                                    y: 0.5 + 0.3 * cos(gradientPhase2)
                                ),
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.8
                            )
                            .rotationEffect(.degrees(-gradientPhase2 * 30))
                            .blendMode(.overlay)
                            
                            // Second spinning slice
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    .init(red: 0.04, green: 0.08, blue: 0.15).opacity(0.1),
                                    .init(red: 0.29, green: 0.61, blue: 0.83).opacity(0.2)
                                ]),
                                center: .init(
                                    x: 0.5 + 0.3 * cos(gradientPhase3),
                                    y: 0.5 + 0.3 * sin(gradientPhase3)
                                ),
                                startRadius: geometry.size.width * 0.2,
                                endRadius: geometry.size.width
                            )
                            .rotationEffect(.degrees(gradientPhase3 * 45))
                            .blendMode(.overlay)
                            
                            // Third spinning slice (opposite direction)
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    .init(red: 0.04, green: 0.08, blue: 0.15).opacity(0.1),
                                    .init(red: 0.29, green: 0.61, blue: 0.83).opacity(0.15),
                                    .init(red: 0.04, green: 0.08, blue: 0.15).opacity(0.1)
                                ]),
                                center: .center
                            )
                            .rotationEffect(.degrees(-gradientPhase1 * 15))
                            .blendMode(.overlay)
                        }
                        .ignoresSafeArea()
                        .onAppear {
                            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                                gradientPhase1 = 360
                            }
                            withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                                gradientPhase2 = .pi * 2
                            }
                            withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
                                gradientPhase3 = .pi * 2
                            }
                        }
                        
                        // Subtle particle overlay
                        ParticlesView()
                            .opacity(0.07)
                        
                        VStack(spacing: 0) {
                            // App Title
                            Text("Apologist")
                                .font(.custom("Georgia", size: 25))
                                .foregroundColor(.white)
                                .padding(.top, geometry.size.height * 0.03)
                                .padding(.bottom, 15)
                            
                            // Progress Dots
                            HStack(spacing: 8) {
                                ForEach(0..<questions.count) { index in
                                    Circle()
                                        .fill(completedQuestions.contains(index) ? Color.green :
                                              index == currentQuestionIndex ? Color.white : Color.white.opacity(0.3))
                                        .frame(width: 10, height: 10)
                                        .scaleEffect(index == currentQuestionIndex ? 1.2 : 1.0)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                                .blur(radius: index == currentQuestionIndex ? 1 : 0)
                                        )
                                        .animation(.spring(response: 0.3), value: currentQuestionIndex)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Question content moved up
                            VStack(spacing: 15) {
                                Text(questions[currentQuestionIndex].title)
                                    .font(.system(size: 32, weight: .heavy))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.horizontal)
                                    .padding(.top, geometry.size.height * 0.02)
                                
                                if let subtitle = questions[currentQuestionIndex].subtitle {
                                    Text(subtitle)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                        .padding(.top, 4)
                                }
                                
                                // Options moved up
                                VStack(spacing: 10) {
                                    ForEach(questions[currentQuestionIndex].options, id: \.self) { option in
                                        OptionButton(
                                            option: option,
                                            isSelected: questions[currentQuestionIndex].isMultiSelect
                                                ? multiSelections.contains(option)
                                                : userResponses[currentQuestionIndex] == option,
                                            action: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    if questions[currentQuestionIndex].isMultiSelect {
                                                        if multiSelections.contains(option) {
                                                            multiSelections.remove(option)
                                                        } else {
                                                            multiSelections.insert(option)
                                                        }
                                                    } else {
                                                        userResponses[currentQuestionIndex] = option
                                                    }
                                                    // Mark question as completed when answered
                                                    completedQuestions.insert(currentQuestionIndex)
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 25)
                                .padding(.top, geometry.size.height * 0.03)
                                
                                Spacer()
                                
                                // Navigation buttons moved up
                                NavigationButtons(
                                    currentQuestionIndex: $currentQuestionIndex,
                                    showLoadingView: $showLoadingView,
                                    isLoaded: $isLoaded,
                                    userResponses: $userResponses,
                                    multiSelections: $multiSelections,
                                    questions: questions,
                                    triggerPaywall: triggerPaywall
                                )
                            }
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}



    // **🔹 Background: Final Apple-Level Gradient**
    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.blue.opacity(0.85),
                    Color.midnightBlue.opacity(0.9),
                    Color.black.opacity(1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            // **Subtle Blur Overlay for Depth**
            Color.black.opacity(0.15)
                .edgesIgnoringSafeArea(.all)
        }
    }

    private var backgroundView_two: some View {
        ZStack {
            // **Step 1: Background Image**
            Image("Apologist_backdrop")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // **Step 2: Darkening Overlay (Adjust opacity as needed)**
            Color.black.opacity(0.4) // ✅ Darkens without making it B&W
                .ignoresSafeArea()
        }
    }


struct WelcomeScreen: View {
    @Binding var isShowingWelcomeScreen: Bool
    @State private var animateText = false
    @State private var showFeatureList = false
    @State private var showButton = false

    var body: some View {
        ZStack {
            backgroundView

            VStack(alignment: .leading, spacing: 24) {
                Spacer()

                // **Title (H1 - Larger, Heavier)**
                Text("Welcome to Apologist")
                    .font(.system(size: 40, weight: .heavy, design: .default))
                    .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                    .padding(.leading, 32)
                    .opacity(animateText ? 1 : 0)
                    .animation(.easeInOut(duration: 0.8), value: animateText)

                // **Subtitle (Smaller, but Still Bolded)**
                Text("Deepen your faith, challenge doubts, and explore Christianity with reasoned answers.")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 32)
                    .opacity(animateText ? 1 : 0)
                    .animation(.easeInOut(duration: 1.0), value: animateText)

                // **Feature Highlights (Smaller, Balanced Layout)**
                if showFeatureList {
                    VStack(alignment: .leading, spacing: 14) {
                        featureRow(iconName: "book.fill", title: "Gain deeper biblical insights")
                        dividerLine
                        featureRow(iconName: "person.3.fill", title: "Strengthen your faith with well-reasoned answers")
                        dividerLine
                        featureRow(iconName: "lightbulb.fill", title: "Ask any question and get AI-driven responses")
                    }
                    .padding(.leading, 32)
                    .padding(.trailing, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 1, dampingFraction: 0.7), value: showFeatureList)
                }

                Spacer()

                // **Continue Button (Final Apple-Level Refinement)**
                if showButton {
                    Button(action: {
                        withAnimation {
                            isShowingWelcomeScreen = false
                        }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver

                            Text("Continue")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "#D4DDE1"))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.black.opacity(0.4)) // Soft glassy-black
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1.2)
                                )
                                .shadow(color: Color.white.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, 32)
                    }
                    .transition(.opacity)
                }
            }
            .padding(.bottom, 56)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateText = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showFeatureList = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showButton = true
            }
        }
    }

    // **🔹 Background: Final Level Polish**
    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.blue.opacity(0.85),
                    Color.midnightBlue.opacity(0.9),
                    Color.black.opacity(1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            // **Subtle Blur Overlay for Depth**
            Color.black.opacity(0.15)
                .edgesIgnoringSafeArea(.all)
        }
    }

    // **🔹 Feature Row (Refined for Balance)**
    private func featureRow(iconName: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver

            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))

            Spacer()
        }
        .padding(.vertical, 6)
    }

    // **🔹 Subtle Divider Between Features**
    private var dividerLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(height: 1)
            .padding(.leading, 32)
            .padding(.trailing, 40)
    }
}

// **🔹 Preview**
struct WelcomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeScreen(isShowingWelcomeScreen: .constant(true))
    }
}



struct OptionButton: View {
    let option: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(option)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(isSelected ? Color.white : Color.white.opacity(0.3), lineWidth: 1.5)
                        )
                )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct Question {
    let title: String
    let subtitle: String?
    let options: [String]
    let isMultiSelect: Bool
}


struct ParticlesView: View {
    @State private var phase: CGFloat = 0
    @State private var particlePhase: CGFloat = 0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            ParticleCanvas(timeline: timeline)
        }
    }
}

struct ParticleCanvas: View {
    let timeline: TimelineViewDefaultContext
    
    var body: some View {
        Canvas { context, size in
            let currentPhase = timeline.date.timeIntervalSinceReferenceDate.remainder(dividingBy: 10)
            let currentParticlePhase = timeline.date.timeIntervalSinceReferenceDate.remainder(dividingBy: 5)
            
            for layer in 0...2 {
                drawParticleLayer(
                    context: &context,
                    size: size,
                    layer: layer,
                    currentPhase: currentPhase,
                    currentParticlePhase: currentParticlePhase
                )
            }
        }
    }
    
    private func drawParticleLayer(
        context: inout GraphicsContext,
        size: CGSize,
        layer: Int,
        currentPhase: Double,
        currentParticlePhase: Double
    ) {
        context.opacity = 0.3 - (0.1 * CGFloat(layer))
        
        for i in 0...50 {
            let speed = CGFloat(layer + 1)
            let xOffset = sin(CGFloat(i) * 0.5 + (currentPhase * speed))
            let yOffset = cos(CGFloat(i) * 0.5 + (currentPhase * speed))
            
            let position = CGPoint(
                x: size.width * (0.1 + 0.8 * ((sin(CGFloat(i) + currentParticlePhase * speed) + 1) / 2)),
                y: size.height * (0.1 + 0.8 * ((cos(CGFloat(i) + currentParticlePhase * speed) + 1) / 2))
            )
            
            let particleSize = 1.5 + sin(CGFloat(i) + currentPhase) * 0.5
            
            context.opacity = (sin(CGFloat(i) + currentPhase) + 1) / 4
            
            context.fill(
                Path(ellipseIn: CGRect(
                    x: position.x + (xOffset * 2),
                    y: position.y + (yOffset * 2),
                    width: particleSize,
                    height: particleSize
                )),
                with: .color(.white)
            )
            
            context.opacity = context.opacity / 3
            context.fill(
                Path(ellipseIn: CGRect(
                    x: position.x + (xOffset * 2) - 1,
                    y: position.y + (yOffset * 2) - 1,
                    width: particleSize + 2,
                    height: particleSize + 2
                )),
                with: .color(.white)
            )
        }
    }
}

struct NavigationButtons: View {
    @Binding var currentQuestionIndex: Int
    @Binding var showLoadingView: Bool
    @Binding var isLoaded: Bool
    @Binding var userResponses: [String]
    @Binding var multiSelections: Set<String>
    let questions: [Question]
    let triggerPaywall: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if currentQuestionIndex > 0 {
                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentQuestionIndex -= 1
                    }
                }
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom, 8)
            }

            Button(currentQuestionIndex == questions.count - 1 ? "Begin Journey" : "Continue") {
                if isValidToProgress() {
                    if currentQuestionIndex == questions.count - 1 {
                        print("[DEBUG] 'Begin Journey' button was pressed.") // ✅ Terminal print
                        saveUserResponses()
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding") // ✅ Ensure onboarding is marked complete
                        showLoadingView = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            triggerPaywall() // ✅ Only trigger once
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentQuestionIndex += 1
                        }
                    }
                }
            }


            .font(.system(size: 20, weight: .heavy))
            .foregroundColor(.white)
            .frame(width: 380)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
            )
            .scaleEffect(currentQuestionIndex == questions.count - 1 ? 1.05 : 1.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentQuestionIndex)
        }
        .padding(.bottom, 30)
    }

    private func isValidToProgress() -> Bool {
        if questions[currentQuestionIndex].isMultiSelect {
            return !multiSelections.isEmpty
        }
        return !userResponses[currentQuestionIndex].isEmpty
    }

    private func saveUserResponses() {
        let db = Firestore.firestore()
        let responseData: [String: Any] = [
            "timestamp": FieldValue.serverTimestamp(),
            "age": userResponses[0],
            "denomination": userResponses[1],
            "christianExperience": userResponses[2],
            "reasonForJoining": userResponses[3],
            "discoverySource": userResponses[4],
            "topicsOfInterest": Array(multiSelections),
            "deviceInfo": [
                "model": UIDevice.current.model,
                "systemVersion": UIDevice.current.systemVersion
            ]
        ]
        
        db.collection("User_Onboarding").addDocument(data: responseData) { error in
            if let error = error {
                print("Error saving to Firebase: \(error.localizedDescription)")
            } else {
                print("Successfully saved to Firebase")
            }
        }
    }
}
extension Color {
    static let darkBlue = Color(red: 0/255, green: 0/255, blue: 139/255)
    static let midnightBlue = Color(red: 25/255, green: 25/255, blue: 112/255)
    static let lightBlue = Color(red: 173/255, green: 216/255, blue: 230/255)
}
