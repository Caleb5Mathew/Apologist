import Foundation
import UserNotifications
import CoreData

/// Handles habit-related notifications.
struct NotificationManager {
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
                    print("No recent completions for habits. Scheduling every-other-day notifications with alternating messages.")
                    scheduleAlternateMessagesNotification()
                }
            } else {
                print("Less than 2 habits. Scheduling every-other-day notifications with alternating messages.")
                scheduleAlternateMessagesNotification()
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

    /// Schedules every-other-day notifications with alternating messages.
    private static func scheduleAlternateMessagesNotification() {
        let center = UNUserNotificationCenter.current()

        // First notification message
        let content1 = UNMutableNotificationContent()
        content1.title = "Reflect and Explore"
        content1.body = "Got any questions about God? We'll help you answer them!"
        content1.sound = .default

        // Second notification message
        let content2 = UNMutableNotificationContent()
        content2.title = "Take a Moment to Reflect"
        content2.body = "Writing down your thoughts helps you process and understand them, Journal here about your day for a bit."
        content2.sound = .default

        // Schedule the first notification
        var dateComponents1 = DateComponents()
        dateComponents1.hour = 9 // First notification at 9 AM
        let trigger1 = UNCalendarNotificationTrigger(dateMatching: dateComponents1, repeats: true)

        let request1 = UNNotificationRequest(identifier: UUID().uuidString, content: content1, trigger: trigger1)
        center.add(request1) { error in
            if let error = error {
                print("Error scheduling first alternating notification: \(error.localizedDescription)")
            } else {
                print("First alternating notification scheduled.")
            }
        }

        // Schedule the second notification on alternating days
        var dateComponents2 = DateComponents()
        dateComponents2.hour = 9
        dateComponents2.day = Calendar.current.component(.day, from: Date()) % 2 == 0 ? nil : 1 // Alternate day logic
        let trigger2 = UNCalendarNotificationTrigger(dateMatching: dateComponents2, repeats: true)

        let request2 = UNNotificationRequest(identifier: UUID().uuidString, content: content2, trigger: trigger2)
        center.add(request2) { error in
            if let error = error {
                print("Error scheduling second alternating notification: \(error.localizedDescription)")
            } else {
                print("Second alternating notification scheduled.")
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
