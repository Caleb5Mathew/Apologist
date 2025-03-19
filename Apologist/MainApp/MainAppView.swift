//
//  MainAppView.swift
//  Apologist
//
//  Created by Caleb Matthews on 12/6/24.
//
import FirebaseFirestore

import SwiftUI

struct MainAppView: View {
    @State private var userInput: String = ""
    @State private var messages: [Message] = []
    @State private var isTyping: Bool = false
    @State private var selectedTab: Int = 1 // Default to "Ask" tab
    @State private var showSidebar: Bool = false
    @State private var isPresentingEditHabitView = false
    @State private var sortingOption: SortingOption = .byDate
    @State private var isSortingOrderAscending: Bool = false
    @State private var memoryBuffer: [String] = []
    @State private var showHomeFile: Bool = false // ✅ Controls HomeFile display
    @StateObject var viewModel = ViewModel() // ✅ Global tracking state

//    @State private var db = Firestore.firestore() // Firestore reference
//    @State private var currentUser: User? = Auth.auth().currentUser // Firebase user


var body: some View {
    ZStack {
        NavigationStack {
            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack {
                    // Single Home Button
                    if !showHomeFile { // ✅ Hide the home button when HomeFile is active
                        Button(action: {
                            print("DEBUG: Home button tapped! Navigating to HomeFile...")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let rootViewController = windowScene.windows.first?.rootViewController {
                                    UIView.performWithoutAnimation {
                                        showHomeFile = true
                                        rootViewController.dismiss(animated: false)
                                    }
                                }
                            }
                        }) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 22)) // Reduced Size for Consistency
                                .foregroundColor(Color(hex: "#D4DDE1")) // Softer White/Gray for Consistency
                                .padding(8)
                                .background(Color.clear) // Transparent Background for Seamlessness
                        }
                    }






                    Spacer()

                    // Enhanced "Apologist" Logo with Shadows and Modern Styling
                    Text("Apologist")
                        .font(.custom("Georgia", size: 28)) // Slightly larger for better visibility
                        .foregroundColor(Color(hex: "#FFFFFF")) // White color for contrast
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 3) // Soft shadow for depth
                        .shadow(color: Color.white.opacity(0.2), radius: 2, x: 0, y: 1) // Glow effect for elegance
                        .frame(maxWidth: .infinity, alignment: .center) // Centered alignment
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
                .padding(.top, 16)
                .background(Color(hex: "#0B1E30"))
                .zIndex(1)

                VStack(spacing: 0) {
                    currentPage
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(hex: "#0B1E30"))

                    // Bottom Navigation Bar
                    BottomNavigationBar(selectedTab: $selectedTab)
                        .frame(height: 50)
                        .background(Color(hex: "#0B1E30"))
                }
            }
            .background(Color(hex: "#0B1E30"))
            .navigationBarHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
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
    .safeAreaInset(edge: .bottom) {
        Color.clear.frame(height: 16)
    }
    .fullScreenCover(isPresented: $showHomeFile) {
        HomeFile(selectedTab: $selectedTab) // ✅ Updated to the correct reference
    }


    .environmentObject(viewModel) // ✅ Pass viewModel to all views
}







    // Track the previous tab
    @State private var previousTab: Int = 1 // Start with the default selectedTab

    // ✅ Now HomeFilePage is just another tab in MainAppView, no fullScreenCover needed.
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
    }


    // MARK: - Navigation Logic
    @State private var swipeDirection: Edge = .trailing // Track swipe direction

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
            selectedTab = 4
        }
    }

    // MARK: - Title Alignment Offset
    func alignmentOffset() -> CGFloat {
        switch selectedTab {
        case 3: // Feedback Tab
            return -16
        case 0: // Habits Tab
            return 16
        case 1, 2: // Questions, Journaling Tabs
            return -16.5
        case 4: // Bible Tab
            return -15.5
        default:
            return 0
        }
    }
}

extension AnyTransition {
    static func moveWipe(direction: Edge) -> AnyTransition {
        AnyTransition.modifier(
            active: WipeModifier(direction: direction, isActive: true),
            identity: WipeModifier(direction: direction, isActive: false)
        )
    }
}

struct WipeModifier: ViewModifier {
    let direction: Edge
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .clipShape(WipeShape(direction: direction, progress: isActive ? 1 : 0))
            .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

class ViewModel: ObservableObject {
    @Published var isHomeActive: Bool = false
}

struct WipeShape: Shape {
    let direction: Edge
    var progress: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let offset = rect.width * progress

        switch direction {
        case .leading:
            path.addRect(CGRect(x: -offset, y: 0, width: rect.width, height: rect.height))
        case .trailing:
            path.addRect(CGRect(x: offset, y: 0, width: rect.width, height: rect.height))
        case .top:
            path.addRect(CGRect(x: 0, y: -offset, width: rect.width, height: rect.height))
        case .bottom:
            path.addRect(CGRect(x: 0, y: offset, width: rect.width, height: rect.height))
        }
        return path
    }

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
}
