//
//  DetailView.swift
//  Habit
//
//  Created by Nazarii Zomko on 21.07.2023.
//

import SwiftUI

struct DetailView: View {
    @ObservedObject var habit: Habit
    @AppStorage("overviewPageIndex") private var overviewPageIndex = 0
    
    private var completedDates: Binding<[DateComponents]> {
        Binding(
            get: { habit.completedDates.asDateComponents },
            set: { newValue in
                habit.completedDates = newValue.asDates
                dataController.save()
            }
        )
    }
    
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                regularityAndReminder
                overview
                ChartView(dates: habit.completedDates, color: habit.color)
                    .padding([.horizontal, .bottom])
                CalendarView(dateInterval: .init(start: .distantPast, end: Date.now), completedDates: completedDates, color: habit.color)
            }
            .toolbarBackground(Color(hex: "#1E1E1E"), for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(habit.title)
                        .font(.system(size: 20, weight: .semibold, design: .default))
                        .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                        .tracking(1.2) // Subtle letter spacing
                }

                ToolbarItem(placement: .destructiveAction) {
                    NavigationLink("Edit") {
                        EditHabitView(habit: habit)
                    }
                    .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                    .accessibilityIdentifier("editHabit")
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                }
            }
            .onAppear {
                setupAppearance()
            }
        }
    }

    var regularityAndReminder: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("REGULARITY")
                    .font(.caption.bold())
                    .foregroundColor(Color(hex: "#F8C471")) // Gold tone
                    .tracking(0.8)
                Text(habit.regularity ?? "Not Set")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
            }
            .padding(.leading)
            .padding(.trailing, 70)

            VStack(alignment: .leading, spacing: 5) {
                Text("REMIND ME")
                    .font(.caption.bold())
                    .foregroundColor(Color(hex: "#F8C471")) // Gold tone
                    .tracking(0.8)
                Text("--:--") // Placeholder for future reminder logic
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
            }

            Spacer()
        }
        .padding(.top, 30)
        .padding(.bottom, 15)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#1E1E1E"), Color(hex: "#1E1E1E")]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    var overview: some View {
        ZStack(alignment: .topLeading) {
            TabView(selection: $overviewPageIndex) {
                OverviewView(
                    title: "Habit Strength",
                    mainText: "\(habit.strengthPercentage)%",
                    secondaryText1: "Month: +\(habit.strengthGainedWithinLastDays(daysAgo: 30))%",
                    secondaryText2: "Year: +\(habit.strengthGainedWithinLastDays(daysAgo: 365))%"
                )
                .tag(0)

                OverviewView(
                    title: "Completions",
                    mainText: "\(habit.completedDates.count)",
                    secondaryText1: "Month: +\(habit.completionsWithinLastDays(daysAgo: 30))",
                    secondaryText2: "Year: +\(habit.completionsWithinLastDays(daysAgo: 365))"
                )
                .tag(1)

                OverviewView(
                    title: "Streak",
                    mainText: "\(habit.streak) days",
                    secondaryText1: "Longest Streak: \(habit.longestStreak) days",
                    secondaryText2: ""
                )
                .tag(2)
            }
            .tabViewStyle(.page)
            .frame(height: 190)

            HStack {
                Text("OVERVIEW")
                    .font(.caption.bold())
                    .foregroundColor(Color(hex: "#F8C471")) // Gold tone
                    .tracking(0.8)
                    .padding()

                Spacer()

                Text("Created: \(formattedCreationDate)")
                    .font(.caption)
                    .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                    .padding(.trailing)
            }
        }
    }

    private var formattedCreationDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: habit.creationDate)
    }

    func setupAppearance() {
        let color = UIColor.label
        UIPageControl.appearance().currentPageIndicatorTintColor = color
        UIPageControl.appearance().pageIndicatorTintColor = color.withAlphaComponent(0.4)
    }
    
    struct OverviewView: View {
        var title: LocalizedStringKey
        var mainText: LocalizedStringKey
        var secondaryText1: LocalizedStringKey
        var secondaryText2: LocalizedStringKey
        
        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundColor(Color(hex: "#F8C471")) // Gold tone
                    .tracking(0.8)
                Text(mainText)
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                HStack {
                    Text(secondaryText1)
                        .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                    Spacer()
                    Text(secondaryText2)
                        .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                }
            }
            .padding()
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(habit: Habit.example)
            .previewLayout(.sizeThatFits)
    }
}
