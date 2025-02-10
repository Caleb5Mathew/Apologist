//
//  HabitRowView.swift
//  Habit
//

import SwiftUI

struct HabitRowView: View {
    @ObservedObject var habit: Habit
    @Binding var activeHabit: Habit? // Binding to the centralized state in HabitListView
    @EnvironmentObject var dataController: DataController
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "#d4d4d4") // Light gray background
                .onTapGesture {
                    activeHabit = habit // Set the active habit to this one
                }
                .clipShape(
                    RoundedRectangle(cornerRadius: 13, style: .continuous) // Rounded corners
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(Color.white, lineWidth: 3) // White border
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 4) // Soft drop shadow

            VStack(spacing: 10) { // Adjusted spacing
                HStack(alignment: .top) {
                    percentageView
                        .padding(.leading, -6) // Align the percentage with the start of the habit title
                        .padding(.top, 8) // Scoot percentage circle slightly upward
                    Spacer()
                    checkmarksView
                        .padding(.trailing, 10)
                        .padding(.top, 2) // Scoot checkmarks upward slightly
                }

                .padding(.leading, 22)

                HStack {
                    habitTitle
                        .padding(.horizontal, 22)
                        .padding(.top, -9) // Add spacing between the title and percentage
                        .allowsHitTesting(false)
                    Spacer()
                }
            }
            .frame(maxHeight: .infinity, alignment: .top) // Align everything at the top
        }
        .frame(height: 100) // Adjusted height
        .clipShape(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
        )
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

        let calendar = Calendar.current
        let today = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!

        // Debug: Print all completedDates
        print("Completed Dates: \(habit.completedDates)")

        let recentCompletedDates = habit.completedDates.filter { completedDate in
            let isInRange = completedDate >= sevenDaysAgo && completedDate <= today
            print("Checking date \(completedDate): \(isInRange)")
            return isInRange
        }

        let completedCount = recentCompletedDates.count
        print("Completed Count: \(completedCount)")

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
        let progressPercentage = min(Int(progress * 100), 100) // Limit to 100%
        let scaledPercentage = min(progress * 1.8, 1.8) // Scale up to 130% when progress is 100%

        return ZStack {
            Circle()
                .fill(Color(habit.color))
                .frame(width: 35, height: 35)

            Circle()
                .stroke(style: StrokeStyle(lineWidth: CGFloat(progressPercentage) * progressMultiplier))
                .foregroundColor(Color(habit.color))
                .frame(width: CGFloat(30 * scaledPercentage), height: CGFloat(30 * scaledPercentage))

            Text("\(progressPercentage)%")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.black)
        }
        .frame(width: 50, height: 50)
        .alignmentGuide(.top) { _ in 0 }
    }




    var checkmarksView: some View {
        HStack(spacing: 0) {
            ForEach(0..<7) { dayIndex in
                let daysAgo = 6 - dayIndex

                Button {
                    toggleCompletion(daysAgo: daysAgo)
                } label: {
                    let calendar = Calendar.current
                    let today = Date()
                    let dateForCheck = calendar.date(byAdding: .day, value: -daysAgo, to: today)!

                    let isCompleted = habit.completedDates.contains { completedDate in
                        calendar.isDate(completedDate, inSameDayAs: dateForCheck)
                    }

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
            .padding(.top, 7) // Add vertical padding to scoot the text down
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.black)
            .if(colorScheme == .dark) { $0.shadow(radius: 1) }
    }

    func toggleCompletion(daysAgo: Int) {
        habit.toggleCompletion(daysAgo: daysAgo)
        HapticController.shared.impact(style: .medium)
        dataController.save()
    }
}

struct HabitRowView_Previews: PreviewProvider {
    static var previews: some View {
        HabitRowView(habit: Habit.example, activeHabit: .constant(nil))
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
