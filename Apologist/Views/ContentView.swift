//
//  ContentView.swift
//  Habit
//
//  Created by Nazarii Zomko on 13.05.2023.
//

//
//  ContentView.swift
//  Habit
//
//  Created by Nazarii Zomko on 13.05.2023.
//

import SwiftUI

struct ContentView: View {
    @State private var isPresentingEditHabitView = false
    @AppStorage("sortingOption") private var sortingOption: SortingOption = .byDate
    @AppStorage("isSortingOrderDescending") private var isSortingOrderAscending = false

    init() {
        // Set up custom navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = nil
        appearance.backgroundColor = .clear // Ensure no default background is added
        appearance.titleTextAttributes = [.foregroundColor: UIColor(Color(hex: "#D4DDE1"))] // Moonlight Silver
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color(hex: "#D4DDE1"))]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#0B1E30"), // Original green under "Weekly Progress"
                        Color(hex: "#0B1E30")  // Slightly lighter green
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Divider()
                        .padding(.top, 10) // Add padding above the divider to scoot it down

                        .background(
                            VStack {
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#0B1E30"),  // Very dark blue
                                        Color(hex: "#0B1E30"),  // Intermediate dark blue
                                        Color(hex: "#0B1E30")   // Target dark blue
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: UIScreen.main.bounds.height / 8) // Covers 1/8 of the screen
                                Spacer()
                            }
                            .ignoresSafeArea(edges: .top) // Ensure it extends fully to the top
                        )

                    // HeaderView remains at the top
                    HeaderView(
                        onAddHabit: {
                            isPresentingEditHabitView = true
                        },
                        onSortOptionChanged: { newSortOption, isAscending in
                            sortingOption = newSortOption
                            isSortingOrderAscending = isAscending
                        }
                    )

                    // Habit List View
                    HabitListView(sortingOption: sortingOption, isSortingOrderAscending: isSortingOrderAscending)
                }
            }
            .sheet(isPresented: $isPresentingEditHabitView) {
                EditHabitView(habit: nil)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Ensure consistent behavior across devices
        .modifier(StatusBarStyleModifier(style: .lightContent))
    }
}
