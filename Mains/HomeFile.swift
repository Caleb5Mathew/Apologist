

import SwiftUI
import DotLottie
import FirebaseFirestore
import Security
import UserNotifications


struct HomeFile: View {
    @Binding var selectedTab: Int // Bind to MainAppView
    @State private var connectionLevel: Double = 50
    @State private var navigateToChatView = false // Navigation state
    @State private var isHomeVisible: Bool = true // ✅ Controls HomeFile visibility
    @State private var showHomeFile: Bool = false // ✅ Define showHomeFile here
    @State private var showPrayerSettings: Bool = false // ✅ Declare the state variable
    // State variables for chat
    @State private var notificationsEnabled = false  // ✅ Tracks notification status
    @State private var showNotificationAlert = false
    @State private var userInput: String = ""
    @State private var messages: [Message] = []
    @State private var isTyping: Bool = false
    @State private var isSliderVisible: Bool = true // ✅ Controls visibility of the slider and percentage
    @State private var showCheckmark: Bool = false
    @State private var isBibleVerseEnabled = NotificationManager.receiveBibleVerseNotifications
    @EnvironmentObject var dataController: DataController // ✅ Inject Core Data
    @EnvironmentObject var viewModel: ViewModel // ✅ Access global state
    var adjustedPadding: CGFloat {
        return isHomeVisible ? 40 : 15 // ✅ When HomeFile is visible, use 0 padding to prevent stacking
    }

    var body: some View {
        GeometryReader { geometry in // ✅ Ensures proper layout expansion
            VStack(spacing: 0) {
                // ✅ Always show the Top Navigation Bar
                TopNavigationBar(selectedTab: $selectedTab, showHomeFile: $showHomeFile)
                    .zIndex(1)
                    .background(Color(hex: "#0B1E30"))

                ZStack {
                    if !isHomeVisible {
                        currentPage
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(hex: "#0B1E30").ignoresSafeArea()) // ✅ Ensure full background coverage
                            .transition(.opacity)
                            .padding(.bottom, 14)
                            .frame(minHeight: geometry.size.height * 0.90, maxHeight: geometry.size.height * 0.90) // ✅ Constrain ScrollView Size
                            .ignoresSafeArea(edges: .bottom) // ✅ Ensures full-screen height
                    }

                    if isHomeVisible {
                        VStack(spacing: 15) {
 
                            // 🔹 Grayish Divider
                            Divider()
                                .background(Color.white.opacity(0.3))
                                .padding(.horizontal, 16)
                                .padding(.bottom, 10) // ✅ Increased spacing


                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: 22) { // ✅ **Reduced space between cards**
                                    // 🟡 Daily Question Section with Full Background Coverage
                                    // 🟡 Daily Question Section with Black Background & White Border
                                    if isSliderVisible {
                                        VStack {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.black.opacity(0.3)) // ✅ Black background with opacity
                                                .background(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(Color.white.opacity(0.6), lineWidth: 1) // ✅ White border
                                                )
                                                .frame(maxWidth: .infinity, minHeight: 130) // ✅ Ensures full coverage
                                                .padding(.horizontal, 16)
                                                .overlay(
                                                    VStack(spacing: 8) {
                                                        // Title
                                                        Text("Daily Question")
                                                            .font(.system(size: 18, weight: .bold))
                                                            .foregroundColor(.white.opacity(0.95))
                                                        
                                                        // Question Prompt
                                                        Text("How connected do you feel with God today?")
                                                            .font(.system(size: 14, weight: .medium))
                                                            .foregroundColor(.white.opacity(0.85))
                                                            .multilineTextAlignment(.center)
                                                            .padding(.horizontal, 16)
                                                        
                                                        // 🟡 Slider (With UserDefaults Saving)
                                                        Slider(value: $connectionLevel, in: 0...100, step: 1, onEditingChanged: { isEditing in
                                                            if !isEditing {
                                                                saveSliderValueToFirestore(connectionLevel) // 🔥 Save to Firestore
                                                                
                                                                // ✅ Hide slider & show checkmark smoothly
                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                                    withAnimation(.easeOut(duration: 0.5)) {
                                                                        isSliderVisible = false
                                                                        showCheckmark = true
                                                                    }
                                                                    
                                                                    // ✅ Hide checkmark after 1.5 seconds
                                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                                        withAnimation(.easeOut(duration: 0.5)) {
                                                                            showCheckmark = false
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        })
                                                        .accentColor(Color(hex: "#FFD700"))
                                                        .padding(.horizontal, 12)
                                                        
                                                        
                                                        .accentColor(Color(hex: "#FFD700"))
                                                        .padding(.horizontal, 12)
                                                        
                                                        // Percentage Display
                                                        Text("\(Int(connectionLevel))%")
                                                            .font(.system(size: 16, weight: .bold))
                                                            .foregroundColor(Color(hex: "#FFD700"))
                                                    }
                                                        .padding(16) // ✅ Proper spacing inside the card
                                                )
                                        }
                                    }
                                }




                                    // ✅ Lottie Checkmark Animation (Appears After Slider Disappears)
                                    if showCheckmark {
                                        ZStack {
                                            LottieCheckmarkView()
                                                .frame(width: 100, height: 100)
                                                .onAppear {
                                                    print("DEBUG: Checkmark animation triggered")
                                                }
                                        }
                                        .transition(.scale)
                                    } else {
                                        Color.clear
                                    }
                                    
                                Divider()
                                    .background(Color.white.opacity(0.3))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                prayerRemindersSection
                                bibleVerseSection
                                Divider()
                                    .background(Color.white.opacity(0.3))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    // 🟢 Ask a Question Button
                                    Button(action: {
                                        withAnimation {
                                            selectedTab = 1
                                            isHomeVisible = false
                                        }
                                    }) {
                                        HomeCardView(
                                            title: "Ask A Question",
                                            subtitle: "What would you like to know today?",
                                            imageName: "QuestionsHome",
                                            buttonText: "Ask Now"
                                        )
                                    }
                    

                                    // 🟠 Track Your Habits Button
                                    Button(action: {
                                        withAnimation {
                                            selectedTab = 0
                                            isHomeVisible = false
                                        }
                                    }) {
                                        HomeCardView(
                                            title: "Track Your Habits",
                                            subtitle: "Stay consistent on your journey.",
                                            imageName: "HabitHome", // ✅ Fixed Image Name
                                            buttonText: "Track Habits"
                                        )
                                    }

                                    // 🔵 Journal Button
                                    Button(action: {
                                        withAnimation {
                                            selectedTab = 2
                                            isHomeVisible = false
                                        }
                                    }) {
                                        HomeCardView(
                                            title: "Journal",
                                            subtitle: "Reflect on your day and grow.",
                                            imageName: "JournalingHome",
                                            buttonText: "Start Journaling"
                                        )
                                    }



                                    Spacer().frame(height: 130) // ✅ **Fix #3: Reduce bottom padding**
                                }
                                .padding(.horizontal)
                                .frame(maxHeight: .infinity) // ✅ Allows flexible spacing instead of forcing min height
                                .frame(minHeight: geometry.size.height * 0.8, maxHeight: geometry.size.height * 0.9) // ✅ Constrain ScrollView Size
                            }
                        }
//                        .frame(width: geometry.size.width, height: geometry.size.height)
//                        .transition(.opacity)
                    }

                    // ✅ Bottom Navigation Bar (Now properly spaced)
                    VStack {
                        Spacer()
                        BottomNavigationBar(selectedTab: $selectedTab)
                            .frame(height: 20) // ✅ Consistent height
                            .padding(.bottom, adjustedPadding) // ✅ Uses computed property to prevent stacking
                            .background(Color(hex: "#0B1E30"))
                            .ignoresSafeArea(edges: .bottom)
                            .onChange(of: selectedTab) { newTab in
                                print("DEBUG: selectedTab changed to \(newTab)")
                                isHomeVisible = (newTab == 5) // ✅ Ensures HomeFile hides when switching away
                            }
                    }

                        }


                .ignoresSafeArea(edges: .bottom) // ✅ Ensures full-screen usage
                .frame(width: geometry.size.width, height: geometry.size.height)
                .transition(.opacity)
        }

                .background(
                      LinearGradient(gradient: Gradient(colors: [Color(hex: "#0B1E30"), Color(hex: "#1D4038")]),
                                     startPoint: .top,
                                     endPoint: .bottom)
                      .ignoresSafeArea()
                  )

                .onAppear {
                    if selectedTab != 5 {
                        selectedTab = 5
                    }
                    isHomeVisible = (selectedTab == 5)

//                    viewModel.isHomeActive = (selectedTab == 5)
                    print("DEBUG: HomeFile is now active! selectedTab = \(selectedTab)")
                    print("[DEBUG] HomeFile appeared")
                    print("[DEBUG] Managed Object Context in HomeFile: \(dataController.container.viewContext)")
                }

                .onDisappear {
                    print("DEBUG: HomeFile disappeared!")
                    DispatchQueue.main.async {
                        isHomeVisible = false
                        showHomeFile = false
                        selectedTab = -1  // ✅ Reset to avoid conflicts
                    }
                }

            }

        
    
    private var bibleVerseToggleButton: some View {
        Button(action: {
            isBibleVerseEnabled.toggle() // Toggle UI state
            NotificationManager.receiveBibleVerseNotifications = isBibleVerseEnabled // Save to UserDefaults

            if isBibleVerseEnabled {
                NotificationManager.scheduleDailyBibleVerseNotification() // Schedule notifications
            } else {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["bibleVerseNotification"]) // Remove notifications
            }
        }) {
            Text(isBibleVerseEnabled ? "Disable Daily Bible Verses" : "Enable Daily Bible Verses")
                .padding()
                .frame(maxWidth: .infinity)
                .background(isBibleVerseEnabled ? Color.red : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }


    
    //
        // ✅ Handle Page Navigation
    var currentPage: some View {
        Group {
            switch selectedTab {
            case 0:
                ContentView()
            case 1:
                ChatView(userInput: $userInput, messages: $messages, isTyping: $isTyping)
            case 2:
                JournalHomeView()
            case 3:
                HomeScreenView()
            case 4:
                BibleView()
            default:
                Color.clear // ✅ Ensures no SwiftUI Placeholder
//                EmptyView()
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
        .id(selectedTab) // ✅ Ensures UI updates when switching tabs
    }
    
//    
//    private var prayerRemindersSection: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("Set Prayer Reminders")
//                .font(.system(size: 18, weight: .bold))
//                .foregroundColor(.white)
//                .padding(.leading, 12)
//
//            Button(action: {
//                requestNotificationPermission { granted in
//                    if granted {
//                        showPrayerSettings = true
//                    } else {
//                        print("[DEBUG] Notifications permission denied for Prayer Reminders")
//                    }
//                }
//            }) {
//                HStack(alignment: .center, spacing: 16) {
//                    Image("Prayerpic")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 55, height: 55)
//                        .clipShape(RoundedRectangle(cornerRadius: 12))
//                        .padding(.leading, 10)
//
//                    VStack(alignment: .leading, spacing: 6) {
//                        Text("Schedule personalized reminders to keep your prayer life on track.")
//                            .font(.system(size: 14, weight: .medium))
//                            .foregroundColor(.white.opacity(0.95))
//                            .fixedSize(horizontal: false, vertical: true)
//
//                        Text("Never forget to pause and pray throughout your day.")
//                            .font(.system(size: 12))
//                            .foregroundColor(.white.opacity(0.75))
//                    }
//                    Spacer()
//                }
//                .padding()
//                .background(
//                    RoundedRectangle(cornerRadius: 16)
//                        .fill(Color.white.opacity(0.07))
//                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12), lineWidth: 1))
//                )
//                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
//                .scaleEffect(0.98, anchor: .center)
//                .animation(.easeOut(duration: 0.15), value: showPrayerSettings)
//            }
//            .sheet(isPresented: $showPrayerSettings) {
//                PrayerReminderSettingsView()
//            }
//        }
//        .padding(.vertical, 10)
//    }
//    private var bibleVerseSection: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("Daily Bible Verses")
//                .font(.system(size: 18, weight: .bold))
//                .foregroundColor(.white)
//                .padding(.leading, 12)
//
//            Button(action: {
//                requestNotificationPermission { granted in
//                    if granted {
//                        isBibleVerseEnabled.toggle()
//                        NotificationManager.receiveBibleVerseNotifications = isBibleVerseEnabled
//                        if isBibleVerseEnabled {
//                            NotificationManager.scheduleDailyBibleVerseNotification()
//                        } else {
//                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyBibleVerse"])
//                        }
//                    } else {
//                        print("[DEBUG] Notifications permission denied for Bible Verses")
//                    }
//                }
//            }) {
//                HStack(alignment: .center, spacing: 16) {
//                    Image("Biblepic")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 55, height: 55)
//                        .clipShape(RoundedRectangle(cornerRadius: 12))
//                        .padding(.leading, 10)
//
//                    VStack(alignment: .leading, spacing: 6) {
//                        Text("Receive a daily verse for encouragement and inspiration.")
//                            .font(.system(size: 14, weight: .medium))
//                            .foregroundColor(.white.opacity(0.95))
//                            .fixedSize(horizontal: false, vertical: true)
//
//                        Text("Simple reminders of God’s Word delivered straight to you.")
//                            .font(.system(size: 12))
//                            .foregroundColor(.white.opacity(0.75))
//                    }
//                    Spacer()
//                }
//                .padding()
//                .background(
//                    RoundedRectangle(cornerRadius: 16)
//                        .fill(Color.white.opacity(0.07))
//                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12), lineWidth: 1))
//                )
//                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
//                .scaleEffect(0.98, anchor: .center)
//                .animation(.easeOut(duration: 0.15), value: isBibleVerseEnabled)
//            }
//        }
//        .padding(.vertical, 10)
//    }
    
    
    private var prayerRemindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Set Prayer Reminders")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.leading, 12)

            Button(action: {
                requestNotificationPermission { granted in
                    if granted {
                        showPrayerSettings = true
                    }
                }
            }) {
                HStack(spacing: 16) {
                    Image("Prayerpic")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Schedule personalized reminders to keep your prayer life on track.")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                        
//                        Text("Never forget to pause and pray throughout your day.")
//                            .font(.system(size: 12))
//                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(.all, 14)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                )
                .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                .padding(.horizontal, 12) // Ensures both sides match!
            }
            .sheet(isPresented: $showPrayerSettings) {
                PrayerReminderSettingsView()
            }
        }
    }
    private var bibleVerseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Bible Verses")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.leading, 12)

            Button(action: {
                requestNotificationPermission { granted in
                    if granted {
                        isBibleVerseEnabled.toggle()
                        NotificationManager.receiveBibleVerseNotifications = isBibleVerseEnabled
                        if isBibleVerseEnabled {
                            NotificationManager.scheduleDailyBibleVerseNotification()
                        } else {
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyBibleVerse"])
                        }
                    }
                }
            }) {
                HStack(spacing: 16) {
                    Image("Biblepic")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Receive a daily verse for encouragement and inspiration.")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)

//                        Text("Simple reminders of God’s Word delivered straight to you.")
//                            .font(.system(size: 12))
//                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(.all, 14)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                )
                .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                .padding(.horizontal, 12)
            }
        }
    }
//    private var bibleVerseSection: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            Text("Daily Bible Verses")
//                .font(.system(size: 18, weight: .bold))
//                .foregroundColor(.white)
//                .padding(.leading, 12)
//
//            Button(action: {
//                requestNotificationPermission { granted in
//                    if granted {
//                        isBibleVerseEnabled.toggle()
//                        NotificationManager.receiveBibleVerseNotifications = isBibleVerseEnabled
//                        print("[DEBUG] Notifications granted: \(isBibleVerseEnabled)")
//
//                        if isBibleVerseEnabled {
//                            NotificationManager.scheduleDailyBibleVerseNotification()
//                        } else {
//                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyBibleVerse"])
//                        }
//                    } else {
//                        print("[DEBUG] Notifications permission denied for Bible Verses")
//                    }
//                }
//            }) {
//                HStack {
//                    Image("Biblepic")
//                        .resizable()
//                        .scaledToFill()
//                        .frame(width: 60, height: 60)
//                        .clipShape(RoundedRectangle(cornerRadius: 16))
//
//                    VStack(alignment: .leading, spacing: 6) {
//                        Text("Try out our Daily Bible Verse notifications!")
//                            .font(.system(size: 14, weight: .medium))
//                            .foregroundColor(.white.opacity(0.9))
//                            .fixedSize(horizontal: false, vertical: true)
//                    }
//                    Spacer()
//                }
//                .padding()
//                .background(isBibleVerseEnabled ? Color.green.opacity(0.3) : Color.white.opacity(0.12))
//                .cornerRadius(16)
//                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2) // ✅ Adds depth
//            }
//        }
//    }
//    private var prayerRemindersSection: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            Text("Set Prayer Reminders")
//                .font(.system(size: 18, weight: .bold))
//                .foregroundColor(.white)
//                .padding(.leading, 12)
//
//            Button(action: {
//                requestNotificationPermission { granted in
//                    if granted {
//                        showPrayerSettings = true
//                    } else {
//                        print("[DEBUG] Notifications permission denied for Prayer Reminders")
//                    }
//                }
//            }) {
//                HStack {
//                    Image("Prayerpic")
//                        .resizable()
//                        .scaledToFill()
//                        .frame(width: 60, height: 60)
//                        .clipShape(RoundedRectangle(cornerRadius: 16))
//
//                    VStack(alignment: .leading, spacing: 6) {
//                        Text("Schedule Prayer Reminders!")
//                            .font(.system(size: 14, weight: .medium))
//                            .foregroundColor(.white.opacity(0.9))
//                            .fixedSize(horizontal: false, vertical: true)
//                    }
//                    Spacer()
//                }
//                .padding()
//                .background(Color.white.opacity(0.12))
//                .cornerRadius(16)
//                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2) // ✅ Adds depth
//            }
//            .sheet(isPresented: $showPrayerSettings) {
//                PrayerReminderSettingsView()
//            }
//        }
//    }

    // 🔹 Function to Check Push Notification Status
//    private func checkNotificationStatus(onSuccess: @escaping () -> Void) {
//        if notificationsEnabled {
//            onSuccess()  // ✅ If already enabled, proceed without alert
//        } else {
//            UNUserNotificationCenter.current().getNotificationSettings { settings in
//                DispatchQueue.main.async {
//                    if settings.authorizationStatus == .authorized {
//                        notificationsEnabled = true  // ✅ Store state so we don't ask again
//                        onSuccess()
//                    } else {
//                        showNotificationAlert = true  // ❌ Show alert if notifications are OFF
//                    }
//                }
//            }
//        }
//    }
    
    private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        print("[DEBUG] Requesting notification permission...")

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                print("[DEBUG] Notifications already authorized ✅")
                DispatchQueue.main.async {
                    completion(true)
                }
            case .notDetermined:
                print("[DEBUG] Notifications not determined. Requesting authorization prompt...")
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                    if let error = error {
                        print("[DEBUG] Error requesting notification permissions: \(error.localizedDescription)")
                    }
                    print("[DEBUG] Permission granted: \(granted)")
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            case .denied:
                print("[DEBUG] Notifications denied previously ❌. Redirecting to Settings...")
                DispatchQueue.main.async {
                    // Open App Settings
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                    completion(false)
                }
            default:
                print("[DEBUG] Notifications status unknown")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }

    private func checkNotificationStatus(onSuccess: @escaping () -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    // 🚨 First-time request
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                        DispatchQueue.main.async {
                            if granted {
                                print("✅ Notifications granted by user!")
                                notificationsEnabled = true
                                onSuccess()
                            } else {
                                print("❌ Notifications permissions denied.")
                                showNotificationAlert = true
                            }
                        }
                    }
                case .denied:
                    print("❌ Notifications previously denied. Showing alert to open Settings.")
                    showNotificationAlert = true // Shows manual alert
                case .authorized, .provisional, .ephemeral:
                    print("✅ Notifications already authorized.")
                    notificationsEnabled = true
                    onSuccess()
                @unknown default:
                    print("❓ Unknown notification status")
                }
            }
        }
    }
    // 🔹 Function to Update Notification Status on Launch
    private func updateNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = (settings.authorizationStatus == .authorized)
            }
        }
    }





    // 🔹 Function to Subscribe to Bible Verse Notifications
    private func subscribeToBibleVerseNotifications() {
        // ✅ Handle the logic for subscribing the user to Bible verse notifications
        print("✅ User is now subscribed to Bible verse notifications!")
    }

    // 🔹 Function to Open App Settings for Notifications
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }



}

struct PrayerReminderSettingsView: View {
    @State private var prayerReminders: [[String: Any]] = NotificationManager.prayerReminders
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // 🔹 Background Gradient for a modern look
            LinearGradient(gradient: Gradient(colors: [Color(hex: "#0B1E30"), Color(hex: "#1D4038")]),
                           startPoint: .top,
                           endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // 🔹 Top Navigation Bar with Back Button
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                            .padding()
                            .padding(.leading, 30) // ✅ Move slightly right
                    }
                    Spacer()
                    Text("Prayer Reminders")
                        .font(.system(size: 24, weight: .bold)) // ✅ Default Apple font, bolded
                        .foregroundColor(.white)
                        .padding(.leading, -80) // ✅ Move slightly right
                    Spacer()
                }
                
                // 🔹 List of Reminders
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(prayerReminders.indices, id: \.self) { index in
                            prayerReminderCard(index: index)
                                .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // 🔹 Add Reminder Button (Light Gray)
                Button(action: {
                    if prayerReminders.count < 10 {
                        withAnimation {
                            prayerReminders.append([
                                "name": "New Reminder",
                                "time": "08:00",
                                "days": [false, false, false, false, false, false, false],
                                "notes": ""
                            ])
                        }
                    }
                }) {
                    Text("Add Reminder")
                        .font(.system(size: 18, weight: .bold))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
            }
        }
        .onDisappear {
            NotificationManager.prayerReminders = prayerReminders
            NotificationManager.schedulePrayerReminders()
        }
    }
    
    // 🔹 Prayer Reminder Card UI
    private func prayerReminderCard(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 🔹 Editable Reminder Name (Looks Normal, No Box)
            TextField("", text: Binding(
                get: { prayerReminders[index]["name"] as? String ?? "Reminder \(index + 1)" },
                set: { prayerReminders[index]["name"] = $0 }
            ))
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(.white)
            .textFieldStyle(PlainTextFieldStyle()) // Removes box effect

            // 🔹 "Days to Notify" Label (Moved to Left)
            Text("Days to Notify")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.leading, 5)

            // 🔹 Repeat Days Selection
            HStack(spacing: 10) {
                ForEach(0..<7, id: \.self) { day in
                    Button(action: {
                        var days = prayerReminders[index]["days"] as? [Bool] ?? Array(repeating: false, count: 7)
                        days[day].toggle()
                        prayerReminders[index]["days"] = days
                    }) {
                        Text(daySymbol(for: day))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor((prayerReminders[index]["days"] as? [Bool] ?? [])[day] ? .white : .gray)
                            .frame(width: 35, height: 35)
                            .background((prayerReminders[index]["days"] as? [Bool] ?? [])[day] ? Color.blue : Color.clear)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
            }

            // 🔹 Reveal Time Picker & Notes When Days Are Set
            let showExtraFields = (prayerReminders[index]["days"] as? [Bool] ?? []).contains(true)
            
            if showExtraFields {
                withAnimation(.easeInOut(duration: 0.5)) {
                    VStack(alignment: .leading, spacing: 8) {
                        // 🔹 Time Label
                        Text("Time")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.leading, 5)

                        DatePicker("", selection: Binding(
                            get: { timeStringToDate(prayerReminders[index]["time"] as? String ?? "08:00") },
                            set: { prayerReminders[index]["time"] = dateToTimeString($0) }
                        ), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(WheelDatePickerStyle())
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white) // ✅ Fix black text issue
                        .colorScheme(.dark) // ✅ Ensures dark mode is applied
                        .tint(.white) // ✅ Force the text to white
                        // 🔹 Reveal Prayer Notes After Time Is Set
                        Text("Prayer Notes")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.leading, 5)

                        TextField("Write Prayer Notes", text: Binding(
                            get: { prayerReminders[index]["notes"] as? String ?? "" },
                            set: { prayerReminders[index]["notes"] = $0 }
                        ))
                        .font(.system(size: 16))
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white) // ✅ Fix black text issue
                    }
                    .transition(.opacity) // ✅ Fade in for 0.5s
                }
            }

            // 🔹 Delete Button
            deleteButtonView(index: index)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
    }
    
    // 🔹 Delete Button View
    private func deleteButtonView(index: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))

            Button(action: {
                withAnimation {
                    DispatchQueue.main.async {
                        if prayerReminders.indices.contains(index) {
                            prayerReminders.remove(at: index)
                        }
                    }
                }
            }) {
                Text("Remove")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.red)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 40)
            }
        }
        .frame(height: 50)
    }

    // 🔹 Converts index to day symbol (Sunday to Saturday)
    private func daySymbol(for index: Int) -> String {
        let symbols = ["S", "M", "T", "W", "T", "F", "S"]
        return symbols[index]
    }

    // 🔹 Converts "HH:mm" string to Date object
    private func timeStringToDate(_ time: String) -> Date {
        let formatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            return f
        }()
        return formatter.date(from: time) ?? Date()
    }

    // 🔹 Converts Date object to "HH:mm" string
    private func dateToTimeString(_ date: Date) -> String {
        let formatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            return f
        }()
        return formatter.string(from: date)
    }
}


struct LottieCheckmarkView: View {
    var body: some View {
        DotLottieAnimation(
            webURL: "https://lottie.host/87309b75-da92-43c3-9361-6d692b134dfd/Twxlzi4NCg.lottie",
            config: AnimationConfig(autoplay: true, loop: false)
        ).view()
        .frame(width: 100, height: 100)
    }
}

struct GradientText: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.custom("Georgia", size: 28))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: "#F8C471"), .yellow],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
}
//
//struct TopNavigationBar: View {
//    @Binding var selectedTab: Int
//    @Binding var showHomeFile: Bool
//    @State private var isPresentingEditHabitView = false // ✅ State to control the plus button sheet
//    @EnvironmentObject var dataController: DataController // ✅ Inject Core Data
//
//    var body: some View {
//        HStack {
//            // 🏠 Home Button - Only Shows When showHomeFile is False
//            Button(action: {
//                print("DEBUG: Home button tapped! Navigating to HomeFile...")
//                withAnimation {
//                    showHomeFile = true
//                    selectedTab = 5
//                }
//            }) {
//                Image(systemName: "house.fill")
//                    .font(.system(size: 22))
//                    .foregroundColor(Color(hex: "#D4DDE1"))
//                    .padding(8)
//                    .background(Color.clear)
//            }
//
//            Spacer()
//
//            // "Apologist" Title - ✅ Adjusted for Centering
//            Text("Apologist")
//                .font(.custom("Georgia", size: 28))
//                .foregroundColor(Color(hex: "#FFFFFF"))
//                .offset(x: selectedTab == 0 ? 0 : -20) // ✅ Shift right slightly when Plus button is visible
//
//            Spacer()
//
//            // ➕ Plus Button (Only When `selectedTab == 0`)
//            if selectedTab == 0 {
//                Button(action: {
//                    print("DEBUG: Plus Button Tapped! Opening Habit Creation.")
//                    isPresentingEditHabitView = true // ✅ Show habit creation screen
//                }) {
//                    Image(systemName: "plus")
//                        .font(.system(size: 22))
//                        .foregroundColor(Color(hex: "#F8C471")) // ✅ Golden Yellow color
//                        .padding(8)
//                }
//                .sheet(isPresented: $isPresentingEditHabitView) {
//                    EditHabitView(habit: nil) // ✅ Open habit creation screen
//                        .environment(\.managedObjectContext, dataController.container.viewContext) // ✅ FIXED
//                }
//            }
//        }
//        .padding(.horizontal, 20)
//        .padding(.top, 25)
//        .background(Color(hex: "#0B1E30"))
//    }
//}


import SuperwallKit

struct TopNavigationBar: View {
    @Binding var selectedTab: Int
    @Binding var showHomeFile: Bool
    @State private var isPresentingEditHabitView = false
    @EnvironmentObject var dataController: DataController
    @ObservedObject private var superwall = Superwall.shared

    var body: some View {
        HStack {
            // 🏠 Home Button - Only Shows When showHomeFile is False
            Button(action: {
                print("DEBUG: Home button tapped! Navigating to HomeFile...")
                withAnimation {
                    showHomeFile = true
                    selectedTab = 5
                }
            }) {
                Image(systemName: "house.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color(hex: "#D4DDE1"))
                    .padding(8)
                    .background(Color.clear)
            }

            Spacer()

            // Title
            if Superwall.shared.subscriptionStatus.isActive {
                GradientText(text: "Apologist Pro+")
                    .font(.custom("Georgia", size: 28))
                    .foregroundColor(Color(hex: "#FFFFFF"))
                    .offset(x: -20)
            } else {
                Text("Apologist")
                    .font(.custom("Georgia", size: 28))
                    .foregroundColor(Color(hex: "#FFFFFF"))
                    .offset(x: selectedTab == 0 ? 0 : -20)
            }

            Spacer()

            // ➕ Plus Button (Only When `selectedTab == 0`)
            if selectedTab == 0 {
                Button(action: {
                    print("DEBUG: Plus Button Tapped! Opening Habit Creation.")
                    isPresentingEditHabitView = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "#F8C471"))
                        .padding(8)
                }
                .sheet(isPresented: $isPresentingEditHabitView) {
                    EditHabitView(habit: nil)
                        .environment(\.managedObjectContext, dataController.container.viewContext)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 25)
        .background(Color(hex: "#0B1E30"))
    }
}






struct HomeCardView: View {
    var title: String
    var subtitle: String
    var imageName: String
    var buttonText: String // ✅ Call-to-action button text
    
    var body: some View {
        VStack(spacing: 8) {
            // Title & Subtitle above the image
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            
            // Image with call-to-action button
            ZStack {
                // Background Image (16:9 Aspect Ratio)
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width - 32, height: (UIScreen.main.bounds.width - 32) * 9 / 16)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Call-to-action button at bottom center
                VStack {
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.6)) // ✅ Semi-transparent background
                        .frame(width: 180, height: 40)
                        .overlay(
                            Text(buttonText)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .padding(.bottom, 12)
                }
            }
            .frame(width: UIScreen.main.bounds.width - 32, height: (UIScreen.main.bounds.width - 32) * 9 / 16)
        }
        .onAppear {
            print("DEBUG: HomeCardView Loaded - Title: \(title)")

        }
    }
}


private func getOrCreateUserID() -> String {
    let key = "com.apologist.uniqueUserID"
    
    // 🔹 Try to retrieve existing User ID from Keychain
    if let existingUserID = KeychainHelper.load(key: key) {
        return existingUserID
    }
    
    // 🔹 If not found, generate a new one
    let newUserID = UUID().uuidString
    KeychainHelper.save(key: key, value: newUserID)
    return newUserID
}

// 🔹 Helper for Keychain Storage
class KeychainHelper {
    static func save(key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary) // Ensure we don't duplicate
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &dataTypeRef) == noErr {
            if let data = dataTypeRef as? Data {
                return String(data: data, encoding: .utf8)
            }
        }
        return nil
    }
}


private func saveSliderValueToFirestore(_ level: Double) {
    let db = Firestore.firestore()
    let userID = getOrCreateUserID() // 🔥 Persistent user ID

    let data: [String: Any] = [
        "timestamp": Timestamp(date: Date()), // 🕒 Stores date for graphing later
        "connectionLevel": level
    ]

    db.collection("users").document(userID).collection("sliderData").addDocument(data: data) { error in
        if let error = error {
            print("🔥 Error saving slider value: \(error.localizedDescription)")
        } else {
            print("✅ Successfully saved slider value: \(level) for user: \(userID)")
        }
    }
}


