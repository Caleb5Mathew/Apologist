//
//  MainAppView.swift
//  Apologist
//
//  Created by Caleb Matthews on 12/6/24.
//
//import FirebaseFirestore

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

//    @State private var db = Firestore.firestore() // Firestore reference
//    @State private var currentUser: User? = Auth.auth().currentUser // Firebase user

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

                    VStack(spacing: 0) {
                        currentPage
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        // Bottom Navigation Bar
                        BottomNavigationBar(selectedTab: $selectedTab)
                            .frame(height: 60)
                            .background(Color(hex: "#0B1E30"))
                    }
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
    
    
    // Track the previous tab
    @State private var previousTab: Int = 1 // Start with the default selectedTab

    var currentPage: some View {
        Group {
            switch selectedTab {
            case 0:
                ContentView() // Habits
            case 1:
                ChatView(
                    userInput: $userInput,
                    messages: $messages,
                    isTyping: $isTyping
                )
            case 2:
                JournalHomeView() // Journaling
            case 3:
                HomeScreenView() // Feedback
            case 4:
                BibleView() // Bible
            default:
                ContentView() // Default to Habits
            }
        }
        .transition(.asymmetric(
            insertion: .moveWipe(direction: calculateSwipeDirection()),
            removal: .opacity
        ))
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
        .onChange(of: selectedTab) { newValue in
            previousTab = newValue // Update the previous tab when the selection changes
        }
    }

    // Determine the swipe direction based on the relative tab positions
    private func calculateSwipeDirection() -> Edge {
        if selectedTab > previousTab {
            return .trailing // Swipe left to right (forward navigation)
        } else {
            return .leading // Swipe right to left (backward navigation)
        }
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
