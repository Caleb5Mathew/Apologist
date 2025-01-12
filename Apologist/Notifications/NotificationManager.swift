import Foundation
import UserNotifications
import CoreData

/// Handles habit-related notifications.
struct NotificationManager {
    static var lastNotificationType: String? // Keeps track of the last sent notification type.

    static func checkAndScheduleNotifications(context: NSManagedObjectContext) {
        do {
            let fetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
            let habits = try context.fetch(fetchRequest)

            print("Total number of habits: \(habits.count)")

            let calendar = Calendar.current
            let today = Date()
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!

            var hasRecentCheckmarks = false

            // Check for habits with completed dates in the last 7 days
            for habit in habits {
                if let completedDates = habit.completedDates_ as? [Date] {
                    let hasCheckmarks = completedDates.contains { $0 >= sevenDaysAgo && $0 <= today }
                    if hasCheckmarks {
                        hasRecentCheckmarks = true
                        break
                    }
                }
            }

            let center = UNUserNotificationCenter.current()

            // Clear existing notifications before scheduling new ones
            center.removeAllPendingNotificationRequests()

            if habits.count > 2 {
                if hasRecentCheckmarks {
                    print("Scheduling daily notifications.")
                    scheduleDailyNotification()
                } else {
                    print("No recent completions for habits. Scheduling alternating notifications.")
                    scheduleAlternatingNotification()
                }
            } else {
                print("Less than 2 habits. Scheduling alternating notifications.")
                scheduleAlternatingNotification()
            }
        } catch {
            print("Error fetching habits: \(error.localizedDescription)")
        }
    }

    /// Schedules a daily notification.
    private static func scheduleDailyNotification() {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "Daily Habit Reminder"
        content.body = "You're on track! Keep logging your habits daily to achieve your goals!"
        content.sound = .default

        // Schedule at 9 AM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("Error scheduling daily notification: \(error.localizedDescription)")
            } else {
                print("Daily notification scheduled.")
            }
        }
    }

    /// Schedules alternating notifications: journaling and question prompts.
    private static func scheduleAlternatingNotification() {
        let center = UNUserNotificationCenter.current()

        // Determine the notification type based on the last sent type
        let isQuestionNotification = (lastNotificationType != "question")

        let content = UNMutableNotificationContent()
        if isQuestionNotification {
            content.title = "Reflect and Explore"
            content.body = "Got any questions about God? We'll help you answer them!"
            lastNotificationType = "question"
        } else {
            content.title = "Take a Moment to Reflect"
            content.body = "Writing down your thoughts helps you process and understand them. Journal here about your day!"
            lastNotificationType = "journaling"
        }
        content.sound = .default

        // Schedule at 9 AM
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Error scheduling alternating notification: \(error.localizedDescription)")
            } else {
                print("\(lastNotificationType?.capitalized ?? "Notification") notification scheduled.")
            }
        }
    }

    /// Requests notification permissions from the user.
    static func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            } else {
                print("Notification permissions granted: \(granted)")
            }
        }
    }
}
