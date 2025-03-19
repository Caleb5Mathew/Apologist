//import Foundation
//import UserNotifications
//import CoreData
//
///// Handles habit-related notifications.
//struct NotificationManager {
//    static var lastNotificationType: String? // Keeps track of the last sent notification type.
//
//    static func checkAndScheduleNotifications(context: NSManagedObjectContext) {
//        do {
//            let fetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
//            let habits = try context.fetch(fetchRequest)
//
//            print("Total number of habits: \(habits.count)")
//
//            let calendar = Calendar.current
//            let today = Date()
//            let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!
//
//            var hasRecentCheckmarks = false
//
//            // Check for habits with completed dates in the last 7 days
//            for habit in habits {
//                if let completedDates = habit.completedDates_ as? [Date] {
//                    let hasCheckmarks = completedDates.contains { $0 >= sevenDaysAgo && $0 <= today }
//                    if hasCheckmarks {
//                        hasRecentCheckmarks = true
//                        break
//                    }
//                }
//            }
//
//            let center = UNUserNotificationCenter.current()
//
//            // Clear existing notifications before scheduling new ones
//            center.removeAllPendingNotificationRequests()
//
//            if habits.count > 2 {
//                if hasRecentCheckmarks {
//                    print("Scheduling daily notifications.")
//                    scheduleDailyNotification()
//                } else {
//                    print("No recent completions for habits. Scheduling alternating notifications.")
//                    scheduleAlternatingNotification()
//                }
//            } else {
//                print("Less than 2 habits. Scheduling alternating notifications.")
//                scheduleAlternatingNotification()
//            }
//        } catch {
//            print("Error fetching habits: \(error.localizedDescription)")
//        }
//    }
//
//    /// Schedules a daily notification at a random time between 9 AM and 7 PM.
//    private static func scheduleDailyNotification() {
//        let center = UNUserNotificationCenter.current()
//
//        let content = UNMutableNotificationContent()
//        content.title = "Daily Habit Reminder"
//        content.body = "You're on track! Keep logging your habits daily to achieve your goals!"
//        content.sound = .default
//
//        // Generate a random time between 9 AM and 7 PM
//        let hour = Int.random(in: 9...19) // Hours from 9 to 19 (7 PM)
//        let minute = Int.random(in: 0..<60) // Minutes from 0 to 59
//
//        var dateComponents = DateComponents()
//        dateComponents.hour = hour
//        dateComponents.minute = minute
//
//        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
//
//        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
//
//        center.add(request) { error in
//            if let error = error {
//                print("Error scheduling daily notification: \(error.localizedDescription)")
//            } else {
//                print("Daily notification scheduled for \(hour):\(String(format: "%02d", minute)).")
//            }
//        }
//    }
//
//    /// Schedules alternating notifications: journaling and question prompts.
//    private static func scheduleAlternatingNotification() {
//        let center = UNUserNotificationCenter.current()
//
//        // Determine the notification type based on the last sent type
//        let isQuestionNotification = (lastNotificationType != "question")
//
//        let content = UNMutableNotificationContent()
//        if isQuestionNotification {
//            content.title = "Reflect and Explore"
//            content.body = "Got any questions about God? We'll help you answer them!"
//            lastNotificationType = "question"
//        } else {
//            content.title = "Take a Moment to Reflect"
//            content.body = "Writing down your thoughts helps you process and understand them. Journal here about your day!"
//            lastNotificationType = "journaling"
//        }
//        content.sound = .default
//
//        // Generate a random time between 9 AM and 7 PM
//        let hour = Int.random(in: 9...19)
//        let minute = Int.random(in: 0..<60)
//
//        var dateComponents = DateComponents()
//        dateComponents.hour = hour
//        dateComponents.minute = minute
//
//        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
//
//        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
//        center.add(request) { error in
//            if let error = error {
//                print("Error scheduling alternating notification: \(error.localizedDescription)")
//            } else {
//                print("\(lastNotificationType?.capitalized ?? "Notification") notification scheduled for \(hour):\(String(format: "%02d", minute)).")
//            }
//        }
//    }
//
//    /// Requests notification permissions from the user.
//    static func requestNotificationPermissions() {
//        let center = UNUserNotificationCenter.current()
//        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
//            if let error = error {
//                print("Notification permission error: \(error.localizedDescription)")
//            } else {
//                print("Notification permissions granted: \(granted)")
//            }
//        }
//    }
//}
import Foundation
import UserNotifications
import CoreData

struct NotificationManager {
    static var receiveBibleVerseNotifications: Bool {
        get { UserDefaults.standard.bool(forKey: "receiveBibleVerseNotifications") }
        set { UserDefaults.standard.set(newValue, forKey: "receiveBibleVerseNotifications") }
    }
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
            center.removeAllPendingNotificationRequests() // Clears all old ones

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
        if NotificationManager.receiveBibleVerseNotifications {
            NotificationManager.scheduleDailyBibleVerseNotification()
        }

    }
    
    private static func getBibleVerse() -> String {
        let verses = [
            "Philippians 4:13 - 'I can do all this through him who gives me strength.'",
            "Proverbs 3:5-6 - 'Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.'",
            "Jeremiah 29:11 - 'For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future.'",
            "Romans 8:28 - 'And we know that in all things God works for the good of those who love him, who have been called according to his purpose.'",
            "Matthew 6:33 - 'But seek first his kingdom and his righteousness, and all these things will be given to you as well.'",
            "Isaiah 41:10 - 'So do not fear, for I am with you; do not be dismayed, for I am your God. I will strengthen you and help you; I will uphold you with my righteous right hand.'",
            "John 3:16 - 'For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.'",
            "Psalm 23:1 - 'The Lord is my shepherd, I lack nothing.'",
            "Psalm 23:4 - 'Even though I walk through the darkest valley, I will fear no evil, for you are with me; your rod and your staff, they comfort me.'",
            "2 Timothy 1:7 - 'For the Spirit God gave us does not make us timid, but gives us power, love and self-discipline.'",
            "Romans 12:2 - 'Do not conform to the pattern of this world, but be transformed by the renewing of your mind. Then you will be able to test and approve what God’s will is—his good, pleasing and perfect will.'",
            "1 Peter 5:7 - 'Cast all your anxiety on him because he cares for you.'",
            "Joshua 1:9 - 'Have I not commanded you? Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go.'",
            "Isaiah 40:31 - 'But those who hope in the Lord will renew their strength. They will soar on wings like eagles; they will run and not grow weary, they will walk and not be faint.'",
            "Ephesians 2:8-9 - 'For it is by grace you have been saved, through faith—and this is not from yourselves, it is the gift of God—not by works, so that no one can boast.'",
            "Hebrews 11:1 - 'Now faith is confidence in what we hope for and assurance about what we do not see.'",
            "Matthew 11:28 - 'Come to me, all you who are weary and burdened, and I will give you rest.'",
            "Psalm 46:1 - 'God is our refuge and strength, an ever-present help in trouble.'",
            "Colossians 3:23 - 'Whatever you do, work at it with all your heart, as working for the Lord, not for human masters.'",
            "Galatians 6:9 - 'Let us not become weary in doing good, for at the proper time we will reap a harvest if we do not give up.'",
            "James 1:2-3 - 'Consider it pure joy, my brothers and sisters, whenever you face trials of many kinds, because you know that the testing of your faith produces perseverance.'",
            "John 14:27 - 'Peace I leave with you; my peace I give you. I do not give to you as the world gives. Do not let your hearts be troubled and do not be afraid.'",
            "Psalm 119:105 - 'Your word is a lamp for my feet, a light on my path.'",
            "Proverbs 18:10 - 'The name of the Lord is a fortified tower; the righteous run to it and are safe.'",
            "Isaiah 26:3 - 'You will keep in perfect peace those whose minds are steadfast, because they trust in you.'",
            "Romans 10:9 - 'If you declare with your mouth, ‘Jesus is Lord,’ and believe in your heart that God raised him from the dead, you will be saved.'",
            "2 Corinthians 5:17 - 'Therefore, if anyone is in Christ, the new creation has come: The old has gone, the new is here!'",
            "Psalm 34:8 - 'Taste and see that the Lord is good; blessed is the one who takes refuge in him.'",
            "1 Corinthians 10:13 - 'No temptation has overtaken you except what is common to mankind. And God is faithful; he will not let you be tempted beyond what you can bear. But when you are tempted, he will also provide a way out so that you can endure it.'",
            "Psalm 37:4 - 'Take delight in the Lord, and he will give you the desires of your heart.'",
            "Romans 15:13 - 'May the God of hope fill you with all joy and peace as you trust in him, so that you may overflow with hope by the power of the Holy Spirit.'",
            "Ephesians 6:11 - 'Put on the full armor of God, so that you can take your stand against the devil’s schemes.'",
            "Micah 6:8 - 'He has shown you, O mortal, what is good. And what does the Lord require of you? To act justly and to love mercy and to walk humbly with your God.'",
            "1 Thessalonians 5:16-18 - 'Rejoice always, pray continually, give thanks in all circumstances; for this is God’s will for you in Christ Jesus.'",
            "Luke 1:37 - 'For no word from God will ever fail.'",
            "Hebrews 4:12 - 'For the word of God is alive and active. Sharper than any double-edged sword, it penetrates even to dividing soul and spirit, joints and marrow; it judges the thoughts and attitudes of the heart.'",
            "2 Chronicles 7:14 - 'If my people, who are called by my name, will humble themselves and pray and seek my face and turn from their wicked ways, then I will hear from heaven, and I will forgive their sin and will heal their land.'",
            "Romans 5:8 - 'But God demonstrates his own love for us in this: While we were still sinners, Christ died for us.'",
            "Psalm 19:14 - 'May these words of my mouth and this meditation of my heart be pleasing in your sight, Lord, my Rock and my Redeemer.'",
            "Matthew 22:37-39 - 'Jesus replied: ‘Love the Lord your God with all your heart and with all your soul and with all your mind.’ This is the first and greatest commandment. And the second is like it: ‘Love your neighbor as yourself.’'",
            "1 John 4:19 - 'We love because he first loved us.'",
            "Psalm 27:1 - 'The Lord is my light and my salvation—whom shall I fear? The Lord is the stronghold of my life—of whom shall I be afraid?'",
            "Colossians 3:2 - 'Set your minds on things above, not on earthly things.'",
            "Genesis 1:1 - 'In the beginning God created the heavens and the earth.'",
            "Exodus 14:14 - 'The Lord will fight for you; you need only to be still.'",
            "Deuteronomy 31:6 - 'Be strong and courageous. Do not be afraid or terrified because of them, for the Lord your God goes with you; he will never leave you nor forsake you.'",
            "Joshua 24:15 - 'But as for me and my household, we will serve the Lord.'",
            "Judges 6:12 - 'When the angel of the Lord appeared to Gideon, he said, “The Lord is with you, mighty warrior.”'",
            "Ruth 1:16 - 'But Ruth replied, “Don’t urge me to leave you or to turn back from you. Where you go I will go, and where you stay I will stay. Your people will be my people and your God my God.”'",
            "1 Samuel 16:7 - 'But the Lord said to Samuel, “Do not consider his appearance or his height, for I have rejected him. The Lord does not look at the things people look at. People look at the outward appearance, but the Lord looks at the heart.”'",
            "2 Samuel 22:31 - 'As for God, his way is perfect: The Lord’s word is flawless; he shields all who take refuge in him.'",
            "1 Kings 8:39 - 'Then hear from heaven, your dwelling place. Forgive and act; deal with everyone according to all they do, since you know their hearts (for you alone know every human heart),'",
            "2 Kings 6:16 - 'Don’t be afraid,” the prophet answered. “Those who are with us are more than those who are with them.”'",
            "1 Chronicles 16:11 - 'Look to the Lord and his strength; seek his face always.'",
            "2 Chronicles 15:7 - 'But as for you, be strong and do not give up, for your work will be rewarded.'",
            "Ezra 10:4 - 'Rise up; this matter is in your hands. We will support you, so take courage and do it.'",
            "Nehemiah 8:10 - 'Do not grieve, for the joy of the Lord is your strength.'",
            "Esther 4:14 - 'And who knows but that you have come to your royal position for such a time as this?'",
            "Job 19:25 - 'I know that my redeemer lives, and that in the end he will stand on the earth.'",
            "Psalm 9:9 - 'The Lord is a refuge for the oppressed, a stronghold in times of trouble.'",
            "Psalm 16:8 - 'I keep my eyes always on the Lord. With him at my right hand, I will not be shaken.'",
            "Psalm 27:14 - 'Wait for the Lord; be strong and take heart and wait for the Lord.'",
            "Psalm 34:17 - 'The righteous cry out, and the Lord hears them; he delivers them from all their troubles.'",
            "Psalm 55:22 - 'Cast your cares on the Lord and he will sustain you; he will never let the righteous be shaken.'",
            "Proverbs 4:23 - 'Above all else, guard your heart, for everything you do flows from it.'",
            "Proverbs 16:3 - 'Commit to the Lord whatever you do, and he will establish your plans.'",
            "Ecclesiastes 3:1 - 'There is a time for everything, and a season for every activity under the heavens.'",
            "Song of Solomon 4:7 - 'You are altogether beautiful, my darling; there is no flaw in you.'",
            "Isaiah 54:17 - 'No weapon forged against you will prevail, and you will refute every tongue that accuses you.'",
            "Jeremiah 33:3 - 'Call to me and I will answer you and tell you great and unsearchable things you do not know.'",
            "Lamentations 3:22-23 - 'Because of the Lord’s great love we are not consumed, for his compassions never fail. They are new every morning; great is your faithfulness.'",
            "Ezekiel 36:26 - 'I will give you a new heart and put a new spirit in you; I will remove from you your heart of stone and give you a heart of flesh.'",
            "Daniel 3:17-18 - 'If we are thrown into the blazing furnace, the God we serve is able to deliver us from it, and he will deliver us from Your Majesty’s hand. But even if he does not, we want you to know, Your Majesty, that we will not serve your gods or worship the image of gold you have set up.'",
            "Hosea 6:6 - 'For I desire mercy, not sacrifice, and acknowledgment of God rather than burnt offerings.'",
            "Joel 2:25 - 'I will repay you for the years the locusts have eaten.'",
            "Amos 5:24 - 'But let justice roll on like a river, righteousness like a never-failing stream!'",
            "Obadiah 1:15 - 'The day of the Lord is near for all nations. As you have done, it will be done to you; your deeds will return upon your own head.'",
            "Jonah 2:2 - 'In my distress I called to the Lord, and he answered me. From deep in the realm of the dead I called for help, and you listened to my cry.'",
            "Micah 7:7 - 'But as for me, I watch in hope for the Lord, I wait for God my Savior; my God will hear me.'",
            "Nahum 1:7 - 'The Lord is good, a refuge in times of trouble. He cares for those who trust in him.'",
            "Habakkuk 3:19 - 'The Sovereign Lord is my strength; he makes my feet like the feet of a deer, he enables me to tread on the heights.'",
            "Zephaniah 3:17 - 'The Lord your God is with you, the Mighty Warrior who saves. He will take great delight in you; in his love he will no longer rebuke you, but will rejoice over you with singing.'",
            "Haggai 2:9 - 'The glory of this present house will be greater than the glory of the former house, says the Lord Almighty. And in this place I will grant peace, declares the Lord Almighty.'",
            "Zechariah 4:6 - 'So he said to me, “This is the word of the Lord to Zerubbabel: ‘Not by might nor by power, but by my Spirit,’ says the Lord Almighty.”'",
            "Malachi 3:10 - 'Bring the whole tithe into the storehouse, that there may be food in my house. Test me in this, says the Lord Almighty, and see if I will not throw open the floodgates of heaven and pour out so much blessing that there will not be room enough to store it.'"
        ]

        return verses.randomElement() ?? "Matthew 6:33 - 'Seek first the kingdom of God and His righteousness.'"
    }

    static func scheduleDailyBibleVerseNotification() {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing Bible verse notification (to avoid duplicates)
        center.removePendingNotificationRequests(withIdentifiers: ["dailyBibleVerse"])

        let content = UNMutableNotificationContent()
        content.title = "Daily Bible Verse"
        content.body = getBibleVerse() // Random verse every time!
        content.sound = .default

        // Schedule at 8 AM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // 👇 IMPORTANT: Use UNIQUE identifier EACH day (current date ensures it updates)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())

        let request = UNNotificationRequest(identifier: "dailyBibleVerse-\(todayString)", content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("Error scheduling Bible verse notification: \(error.localizedDescription)")
            } else {
                print("✅ Daily Bible verse notification scheduled for 8:00 AM with verse: \(content.body)")
            }
        }
    }

    
    
//    static func scheduleDailyBibleVerseNotification() {
//        let center = UNUserNotificationCenter.current()
//
//        let content = UNMutableNotificationContent()
//        content.title = "Daily Bible Verse"
//        content.body = getBibleVerse() // Calls the function to fetch a verse
//        content.sound = .default
//
//        // Bible verse notification at 8 AM
//        var dateComponents = DateComponents()
//        dateComponents.hour = 8
//        dateComponents.minute = 0
//
//        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
//
//        let request = UNNotificationRequest(identifier: "dailyBibleVerse", content: content, trigger: trigger)
//
//        center.add(request) { error in
//            if let error = error {
//                print("Error scheduling Bible verse notification: \(error.localizedDescription)")
//            } else {
//                print("✅ Daily Bible verse notification scheduled for 8:00 AM.")
//            }
//        }
//    }
    static var prayerReminders: [[String: Any]] {
        get {
            return UserDefaults.standard.array(forKey: "prayerReminders") as? [[String: Any]] ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "prayerReminders")
        }
    }

    static func schedulePrayerReminders() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["prayerReminder"]) // Remove old ones

        for (index, reminder) in prayerReminders.enumerated() {
            if let time = reminder["time"] as? String,
               let days = reminder["days"] as? [Bool] {

                let timeComponents = time.split(separator: ":").compactMap { Int($0) }
                guard timeComponents.count == 2 else { continue }
                let hour = timeComponents[0]
                let minute = timeComponents[1]

                for (dayIndex, isEnabled) in days.enumerated() where isEnabled {
                    var dateComponents = DateComponents()
                    dateComponents.hour = hour
                    dateComponents.minute = minute
                    dateComponents.weekday = dayIndex + 1 // 1 = Sunday, 7 = Saturday

                    let content = UNMutableNotificationContent()
                    content.title = "Prayer Reminder"
                    content.body = "Take a moment to pray 🙏."
                    content.sound = .default

                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

                    let request = UNNotificationRequest(identifier: "prayerReminder_\(index)_\(dayIndex)", content: content, trigger: trigger)
                    center.add(request) { error in
                        if let error = error {
                            print("Error scheduling prayer reminder: \(error.localizedDescription)")
                        } else {
                            print("✅ Prayer reminder scheduled for \(time) on day \(dayIndex + 1).")
                        }
                    }
                }
            }
        }
    }
/// Schedules a daily notification at a random time between 9 AM and 7 PM.
    private static func scheduleDailyNotification() {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "Daily Habit Reminder"
        content.body = "You're on track! Keep logging your habits daily to achieve your goals!"
        content.sound = .default

        // Generate a random time between 9 AM and 7 PM
        let hour = Int.random(in: 9...19) // Hours from 9 to 19 (7 PM)
        let minute = Int.random(in: 0..<60) // Minutes from 0 to 59

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("Error scheduling daily notification: \(error.localizedDescription)")
            } else {
                print("Daily notification scheduled for \(hour):\(String(format: "%02d", minute)).")
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

        // Generate a random time between 9 AM and 7 PM
        let hour = Int.random(in: 9...19)
        let minute = Int.random(in: 0..<60)

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Error scheduling alternating notification: \(error.localizedDescription)")
            } else {
                print("\(lastNotificationType?.capitalized ?? "Notification") notification scheduled for \(hour):\(String(format: "%02d", minute)).")
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
