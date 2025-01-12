//
//  SidebarMenu.swift
//  Apologist
//
//  Created by Caleb Matthews on 1/5/25.
//

import SwiftUI

enum SidebarOption: String, CaseIterable {
    case habits = "Habits"
    case questions = "Questions"
    case journaling = "Journaling"
    case feedback = "Feedback"
    case bible = "Bible"

    var iconName: String {
        switch self {
        case .habits: return "flame.fill" // A simple white flame
        case .questions: return "lightbulb.fill" // Keep this as it aligns with the theme
        case .journaling: return "book.closed.fill" // A closed book icon with no middle line
        case .feedback: return "message.fill" // A filled message bubble to avoid split lines
        case .bible: return "cross.fill" // A cross-like icon without splitting lines
        }
    }

    
}

struct SidebarMenu: View {
    @Binding var showSidebar: Bool
    let onOptionSelected: (SidebarOption) -> Void
    @State private var zoomEffect: CGFloat = 1.0
    @State private var transitioning: Bool = false
    @State private var selectedAnchor: UnitPoint = .center
    @State private var flashWhite: Bool = false

    var body: some View {
        ZStack {
            // Dimmed Background Tap Area
            if showSidebar {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSidebar = false
                        }
                    }
            }

            // Sidebar Content
            if showSidebar {
                GeometryReader { proxy in
                    VStack(spacing: 0) {
                        // Top Section: Menu Button and Apologist Header
                        HStack {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showSidebar = false
                                }
                            }) {
                                Image(systemName: "line.horizontal.3")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(.leading, 38)
                                    .padding(.top, 24)
                            }
                            Spacer()
                        }
                        .padding(.top, 50)

                        Text("Apologist")
                            .font(.custom("Georgia", size: 25))
                            .foregroundColor(.white)
                            .padding(.top, -21)
                            .padding(.leading, -1)
                            .padding(.bottom, 30)

                        // Sidebar Options
                        VStack(alignment: .leading, spacing: 25) {
                            ForEach(SidebarOption.allCases, id: \.self) { option in
                                Button(action: {
                                    calculateAnchor(for: option, in: proxy)
                                    startTransition(to: option)
                                }) {
                                    HStack(spacing: 15) {
                                        Image(systemName: option.iconName)
                                            .foregroundColor(.white)
                                            .frame(width: 24, height: 24)
                                        Text(option.rawValue)
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                }
                                Divider()
                                    .background(Color.gray.opacity(0.5))
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 10)

                        Spacer()
                    }
                    .frame(width: UIScreen.main.bounds.width) // Sidebar covers the whole screen width
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#0B1E30"), Color(hex: "#1A3F63")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(transitioning ? zoomEffect : 1.0, anchor: selectedAnchor) // Zoom into the icon
                    .animation(.easeInOut(duration: 0.5), value: zoomEffect)
                    .ignoresSafeArea()
                }
            }

            // Quick White Flash
            if flashWhite {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: showSidebar)
    }

    private func startTransition(to option: SidebarOption) {
        transitioning = true
        withAnimation(.easeInOut(duration: 0.012)) {
            zoomEffect = 300.0 // Increased zoom level
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.012) {
            withAnimation(.easeInOut(duration: 0.01)) {
                flashWhite = true // Flash the screen to white quickly
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.00) { // End flash and transition to the new page
                transitioning = false
                flashWhite = false
                showSidebar = false
                onOptionSelected(option) // Trigger the option's action immediately
            }
        }
    }

    private func calculateAnchor(for option: SidebarOption, in proxy: GeometryProxy) {
        // Get the index of the selected button
        let buttonIndex = SidebarOption.allCases.firstIndex(of: option) ?? 0

        // Map the button index to the recalculated Y offsets
        let yOffsets: [CGFloat] = [0.158, 0.232, 0.312, 0.391, 0.474]

        // Use the corresponding Y offset for the selected button
        let yOffset = yOffsets[buttonIndex]

        // Set the anchor point with adjusted X and Y values
        selectedAnchor = UnitPoint(x: 0.094, y: yOffset)
    }





}







//
////
////  SidebarMenu.swift
////  Apologist
////
////  Created by Caleb Matthews on 1/5/25.
////
//
//import SwiftUI
//
//enum SidebarOption: String, CaseIterable {
//    case habits = "Habits"
//    case questions = "Questions"
//    case journaling = "Journaling"
//    case feedback = "Feedback"
//    case bible = "Bible"
//
//    var iconName: String {
//        switch self {
//        case .habits: return "flame.fill"
//        case .questions: return "questionmark.circle.fill"
//        case .journaling: return "book.fill"
//        case .feedback: return "bubble.left.and.bubble.right.fill"
//        case .bible: return "cross.fill"
//        }
//    }
//}
//
//struct SidebarMenu: View {
//    @Binding var showSidebar: Bool
//    let onOptionSelected: (SidebarOption) -> Void
//    @State private var zoomingOption: SidebarOption? = nil
//    @State private var transitioning: Bool = false
//
//    var body: some View {
//        ZStack {
//            // Dimmed Background Tap Area
//            if showSidebar {
//                Color.black.opacity(0.4)
//                    .ignoresSafeArea()
//                    .onTapGesture {
//                        withAnimation(.easeInOut(duration: 0.3)) {
//                            showSidebar = false
//                        }
//                    }
//            }
//
//            // Sidebar Content
//            if showSidebar {
//                VStack(spacing: 0) {
//                    // Top Section: Menu Button and Apologist Header
//                    HStack {
//                        Button(action: {
//                            withAnimation(.easeInOut(duration: 0.3)) {
//                                showSidebar = false
//                            }
//                        }) {
//                            Image(systemName: "line.horizontal.3")
//                                .font(.title2)
//                                .foregroundColor(.white)
//                                .padding(.leading, 38)
//                                .padding(.top, 24)
//                        }
//                        Spacer()
//                    }
//                    .padding(.top, 50)
//
//                    Text("Apologist")
//                        .font(.custom("Georgia", size: 25))
//                        .foregroundColor(.white)
//                        .padding(.top, -21)
//                        .padding(.leading, -1)
//                        .padding(.bottom, 30)
//
//                    // Sidebar Options
//                    VStack(alignment: .leading, spacing: 25) {
//                        ForEach(SidebarOption.allCases, id: \.self) { option in
//                            Button(action: {
//                                startTransition(to: option)
//                            }) {
//                                HStack(spacing: 15) {
//                                    Image(systemName: option.iconName)
//                                        .foregroundColor(.white)
//                                        .frame(width: 24, height: 24)
//                                        .scaleEffect(zoomingOption == option ? 10.0 : 1.0) // Zoom in on selected icon
//                                        .animation(.easeInOut(duration: 0.5), value: zoomingOption)
//
//                                    Text(option.rawValue)
//                                        .font(.system(size: 20, weight: .semibold))
//                                        .foregroundColor(.white)
//                                        .opacity(zoomingOption == option ? 0.0 : 1.0) // Hide text during zoom
//                                        .animation(.easeInOut(duration: 0.5), value: zoomingOption)
//
//                                    Spacer()
//                                }
//                                .padding(.horizontal, 20)
//                            }
//                            Divider()
//                                .background(Color.gray.opacity(0.5))
//                                .opacity(zoomingOption == option ? 0.0 : 1.0) // Hide divider during zoom
//                        }
//                    }
//                    .padding(.horizontal, 10)
//                    .padding(.top, 10)
//
//                    Spacer()
//                }
//                .frame(width: UIScreen.main.bounds.width)
//                .background(
//                    LinearGradient(
//                        gradient: Gradient(colors: [Color(hex: "#0B1E30"), Color(hex: "#1A3F63")]),
//                        startPoint: .topLeading,
//                        endPoint: .bottomTrailing
//                    )
//                )
//                .ignoresSafeArea()
//            }
//        }
//        .animation(.easeInOut, value: showSidebar)
//    }
//
//    private func startTransition(to option: SidebarOption) {
//        transitioning = true
//        zoomingOption = option // Set the selected option for zoom
//        withAnimation(.easeInOut(duration: 0.5)) {
//            showSidebar = false // Close the sidebar after zoom
//        }
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            transitioning = false
//            zoomingOption = nil
//            onOptionSelected(option) // Trigger the option's action
//        }
//    }
//}
