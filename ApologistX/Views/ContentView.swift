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
                        Color(hex: "#274E45"), // Original green under "Weekly Progress"
                        Color(hex: "#2F726A")  // Slightly lighter green
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                .ignoresSafeArea() // Cover safe area, including behind the navigation bar

                VStack(spacing: 0) {
                    Divider()
                        .background(
                            VStack {
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#000814"),  // Very dark blue
                                        Color(hex: "#001D34"),  // Intermediate dark blue
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




                    HeaderView()
                    HabitListView(sortingOption: sortingOption, isSortingOrderAscending: isSortingOrderAscending)
                }
            }
            .toolbar {
                addHabitToolbarItem
                sortMenuToolbarItem
            }
            .sheet(isPresented: $isPresentingEditHabitView) {
                EditHabitView(habit: nil)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Ensure consistent behavior across devices
        .modifier(StatusBarStyleModifier(style: .lightContent))
    }

    var addHabitToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                isPresentingEditHabitView = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 19).weight(.light))
                    .tint(Color(hex: "#F8C471")) // Star Glow Yellow
            }
            .accessibilityLabel("Add Habit")
            .accessibilityIdentifier("addHabit")
        }
    }

    var sortMenuToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            SortMenuView(selectedSortingOption: $sortingOption, isSortingOrderAscending: $isSortingOrderAscending)
                .tint(Color(hex: "#D4DDE1")) // Moonlight Silver
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
            .previewDisplayName("iPhone 14 Pro Max")
            .environment(\.locale, .init(identifier: "uk"))

        ContentView()
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
            .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}
