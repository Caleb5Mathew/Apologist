//
//  HabitRowView.swift
//  Habit
//
//  Created by Nazarii Zomko on 15.05.2023.
//

import SwiftUI

struct HabitRowView: View {
    @ObservedObject var habit: Habit
    @State private var isPresentingEditHabitView = false
    @EnvironmentObject var dataController: DataController
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "#d4d4d4") // Light gray background
                .onTapGesture {
                    isPresentingEditHabitView = true
                }
                .clipShape(
                    RoundedRectangle(cornerRadius: 13, style: .continuous) // Rounded corners
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(Color.white, lineWidth: 3) // Black border
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 4) // Soft drop shadow
            VStack(spacing: -8) {
                HStack() {
                    percentageView
                    Spacer()
                    checkmarksView
                        .padding(.trailing, 10)
                }
                .padding(.leading, 22)
                .padding(.top, 12)
                VStack {
                    HStack {
                        habitTitle
                            .padding(.horizontal, 22)
                            .allowsHitTesting(false)
                        Spacer()
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(height: 100)
        .clipShape(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
        )
        .sheet(isPresented: $isPresentingEditHabitView) {
            DetailView(habit: habit)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(habit.title), \(habit.strengthPercentage)% strength, \(habit.isCompleted(daysAgo: 0) ? "completed" : "not completed") for today.")
        .accessibilityAction(named: "Toggle completion for today") {
            toggleCompletion(daysAgo: 0)
            UIAccessibility.post(notification: .announcement, argument: "\(habit.isCompleted(daysAgo: 0) ? "completed" : "not completed")")
        }
    }

    var progressMultiplier: Double {
        guard let regularity = habit.regularity?.lowercased() else { return 6.4 } // Default to 6.4 if no regularity

        switch regularity {
        case "once a week":
            return 6.4 // 1 day a week
        case "2 times a week":
            return 6.4 / 1.0
        case "3 times a week":
            return 6.4 / 1.0
        case "4 times a week":
            return 6.4 / 1.0
        case "5 times a week":
            return 6.4 / 1.0
        case "6 times a week":
            return 6.4 / 1.0
        case "everyday":
            return 6.4 / 1.0 // Assuming every day in a week (7 days)
        default:
            return 6.4 // Default to max stroke multiplier
        }
    }

    var progress: Double {
        guard let regularity = habit.regularity?.lowercased() else { return 0.0 }
        
        // Get the last 7 days
        let calendar = Calendar.current
        let today = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!

        // Count completed dates in the last 7 days
        let recentCompletedDates = habit.completedDates.filter { completedDate in
            completedDate >= sevenDaysAgo && completedDate <= today
        }
        let completedCount = recentCompletedDates.count

        // Calculate progress based on regularity
        switch regularity {
        case "everyday":
            return Double(completedCount) / 7.0
        case "every other day":
            return Double(completedCount) / 4.0
        case "once a week":
            return Double(completedCount) / 1.0
        case "2 times a week":
            return Double(completedCount) / 2.0
        case "3 times a week":
            return Double(completedCount) / 3.0
        case "4 times a week":
            return Double(completedCount) / 4.0
        case "5 times a week":
            return Double(completedCount) / 5.0
        case "6 times a week":
            return Double(completedCount) / 6.0
        default:
            return 0.0
        }
    }

    var percentageView: some View {
        let progressPercentage = min(Int(progress * 100), 100)

        return Text("\(progressPercentage)%")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.black)
            .background(
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: CGFloat(progressPercentage) * progressMultiplier)) // Dynamically calculate the stroke width
                    .background(Circle().fill(Color(habit.color))) // Stroke and fill the circle
                    .frame(width: 30, height: 30)
                    .foregroundColor(Color(habit.color))
                    .offset(x: -0.5)
            )
    }

    var checkmarksView: some View {
        HStack(spacing: 0) {
            ForEach(0..<7) { number in // Updated to show 7 days
                let daysAgo = abs(number - 6) // Adjust for 7 days in reverse order
                Button {
                    toggleCompletion(daysAgo: daysAgo)
                } label: {
                    let isCompleted = habit.isCompleted(daysAgo: daysAgo)
                    Image(isCompleted ? "checkmark" : "circle")
                        .resizable()
                        .foregroundColor(.black)
                        .padding(isCompleted ? 9 : 10)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Constants.dayOfTheWeekFrameSize, height: Constants.dayOfTheWeekFrameSize)
                        .contentShape(Rectangle())
                }
            }
        }
    }

    var habitTitle: some View {
        Text(habit.title ?? "")
            .font(.system(size: 16,  weight: .semibold)) // Bold title
            .foregroundColor(.black)
            .if(colorScheme == .dark) { $0.shadow(radius: 1) }
    }
    
    func toggleCompletion(daysAgo: Int) {
        habit.toggleCompletion(daysAgo: daysAgo)
        HapticController.shared.impact(style: .soft)
        dataController.save()
    }
}

struct HabitRowView_Previews: PreviewProvider {
    static var previews: some View {
        HabitRowView(habit: Habit.example)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

