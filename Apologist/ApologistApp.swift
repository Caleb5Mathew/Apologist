import SwiftUI
import FirebaseCore
import UserNotifications
import StoreKit
import SuperwallKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        Superwall.configure(apiKey: "API-KEY")
        
        print("[DEBUG] Firebase and Superwall configured. Checking for app update...")
        checkForAppUpdate()
        return true
    }
    
    // MARK: - App Update Check
    func checkForAppUpdate() {
        print("[DEBUG] Starting checkForAppUpdate()...")
        guard let infoDictionary = Bundle.main.infoDictionary,
              let currentVersion = infoDictionary["CFBundleShortVersionString"] as? String else {
            print("[DEBUG] Could not fetch current version.")
            return
        }
        print("[DEBUG] Current app version: \(currentVersion)")
        
        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=DeepDev.Apologist") else {
            print("[DEBUG] Invalid URL for App Store lookup.")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("[DEBUG] Network error fetching App Store data: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("[DEBUG] No data received from App Store.")
                return
            }
            
            do {
                if let appData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let results = appData["results"] as? [[String: Any]],
                   let appStoreVersion = results.first?["version"] as? String {
                    
                    if self.isUpdateAvailable(currentVersion: currentVersion, appStoreVersion: appStoreVersion) {
                        print("[DEBUG] Update available! Prompting user...")
                        DispatchQueue.main.async {
                            self.promptUserToUpdate()
                        }
                    } else {
                        print("[DEBUG] App is up-to-date.")
                    }
                } else {
                    print("[DEBUG] Could not parse App Store response.")
                }
            } catch {
                print("[DEBUG] JSON parsing error: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
    
    func isUpdateAvailable(currentVersion: String, appStoreVersion: String) -> Bool {
        let result = currentVersion.compare(appStoreVersion, options: .numeric)
        print("[DEBUG] Version comparison result: \(result.rawValue)")
        return result == .orderedAscending
    }
    
    func promptUserToUpdate() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("[DEBUG] Could not access rootViewController to show update alert.")
            return
        }
        
        let alertController = UIAlertController(title: "Update Available",
                                                message: "A new version of Apologist is available. Please update to the latest version.",
                                                preferredStyle: .alert)
        
        let updateAction = UIAlertAction(title: "Update Now", style: .default) { _ in
            if let url = URL(string: "https://apps.apple.com/app/id6739737481") {
                UIApplication.shared.open(url)
                print("[DEBUG] User tapped Update Now.")
            }
        }
        
        let laterAction = UIAlertAction(title: "Later", style: .cancel) { _ in
            print("[DEBUG] User tapped Later.")
        }
        
        alertController.addAction(updateAction)
        alertController.addAction(laterAction)
        
        rootViewController.present(alertController, animated: true) {
            print("[DEBUG] Update alert presented.")
        }
    }
}

@main
struct ApologistApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var dataController = DataController()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var hasPromptedReview = false
    @State private var isLoaded: Bool = false
    @State private var showHomeFile = false
    @State private var selectedTab: Int = 5

    init() {
        print("[DEBUG] App Launched - hasCompletedOnboarding: \(hasCompletedOnboarding)")
        print("[DEBUG] DataController initialized")
        print("[DEBUG] Persistent Container: \(dataController.container)")
        ValueTransformer.setValueTransformer(SecureDictionaryTransformer(), forName: NSValueTransformerName("SecureDictionaryTransformer"))
        NotificationManager.requestNotificationPermissions()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !hasCompletedOnboarding {
                    OnboardingView(isLoaded: $isLoaded)
                        .environment(\.managedObjectContext, dataController.container.viewContext)
                        .environmentObject(dataController)
                } else {
                    HomeFile(selectedTab: $selectedTab)
                        .environment(\.managedObjectContext, dataController.container.viewContext)
                        .environmentObject(dataController)
                }
            }
            .fullScreenCover(isPresented: $showHomeFile) {
                HomeFile(selectedTab: $selectedTab)
                    .environment(\.managedObjectContext, dataController.container.viewContext)
                    .environmentObject(dataController)
            }
        }
    }

    // MARK: - Review Prompt Logic

    private func startAppUsageTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 480) {
            print("[DEBUG] Timer triggered. Attempting to request a review.")
            promptForReview()
        }
    }

    private func promptForReview() {
        guard !hasPromptedReview else {
            print("[DEBUG] Review prompt already shown. Skipping.")
            return
        }

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            print("[DEBUG] UIWindowScene found. Requesting review.")
            SKStoreReviewController.requestReview(in: windowScene)
            hasPromptedReview = true
        } else {
            print("[DEBUG] No UIWindowScene found. Cannot request a review.")
        }
    }
}

//
//import SwiftUI
//import FirebaseCore
//import UserNotifications
//import StoreKit
//import SuperwallKit
//
//// Custom AppDelegate to enforce portrait orientation
//class AppDelegate: NSObject, UIApplicationDelegate {
//    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
//        return .portrait
//    }
//    
//    func application(_ application: UIApplication,
//                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//        if FirebaseApp.app() == nil {
//            FirebaseApp.configure()
//        }
//
//        Superwall.configure(apiKey: "pk_e7000e4aad725f2d7a6eae7dc7633538b4c05d32c96afde3")
//        
//        // 🔥 Add this line:
//        checkForAppUpdate()
//        
//        return true
//    }
//    // 1. Check for App Update
//    
//    func checkForAppUpdate() {
//        let appStoreVersion = "99.0"// ← Temporarily fake version
//        guard let infoDictionary = Bundle.main.infoDictionary,
//              let currentVersion = infoDictionary["CFBundleShortVersionString"] as? String,
//              let url = URL(string: "https://itunes.apple.com/lookup?bundleId=DeepDev.Apologist") else {
//            return
//        }
//        
//        let task = URLSession.shared.dataTask(with: url) { data, response, error in
//            guard let data = data, error == nil,
//                  let appData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//                  let results = appData["results"] as? [[String: Any]],
//                  let appStoreVersion = results.first?["version"] as? String else {
//                return
//            }
//            
//            if self.isUpdateAvailable(currentVersion: currentVersion, appStoreVersion: appStoreVersion) {
//                DispatchQueue.main.async {
//                    self.promptUserToUpdate()
//                }
//            }
//        }
//        task.resume()
//    }
//    
//    // 2. Version Comparison Logic
//    func isUpdateAvailable(currentVersion: String, appStoreVersion: String) -> Bool {
//        return currentVersion.compare(appStoreVersion, options: .numeric) == .orderedAscending
//    }
//    
//    // 3. Show Alert Prompt
//    func promptUserToUpdate() {
//        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//              let rootViewController = windowScene.windows.first?.rootViewController else {
//            return
//        }
//        
//        let alertController = UIAlertController(title: "Update Available",
//                                                message: "A new version of Apologist is available. Please update to the latest version.",
//                                                preferredStyle: .alert)
//        
//        let updateAction = UIAlertAction(title: "Update Now", style: .default) { _ in
//            if let url = URL(string: "https://apps.apple.com/app/id6739737481") { // Replace this!
//                UIApplication.shared.open(url)
//            }
//        }
//        
//        let laterAction = UIAlertAction(title: "Later", style: .cancel, handler: nil)
//        
//        alertController.addAction(updateAction)
//        alertController.addAction(laterAction)
//        
//        rootViewController.present(alertController, animated: true, completion: nil)
//    }
//}
//
//@main
//struct ApologistApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//    @StateObject private var dataController = DataController()
//    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
//    @State private var hasPromptedReview = false
//    @State private var isLoaded: Bool = false
//    @State private var showHomeFile = false
//    @State private var selectedTab: Int = 5
//    
//    init() {
//        print("[DEBUG] App Launched - hasCompletedOnboarding: \(hasCompletedOnboarding)")
//        print("[DEBUG] DataController initialized")
//        print("[DEBUG] Persistent Container: \(dataController.container)")
//        ValueTransformer.setValueTransformer(SecureDictionaryTransformer(), forName: NSValueTransformerName("SecureDictionaryTransformer"))
//        NotificationManager.requestNotificationPermissions()
//    }
//    
//    
//    var body: some Scene {
//        WindowGroup {
//            ZStack {
//                if !hasCompletedOnboarding {
//                    OnboardingView(isLoaded: $isLoaded)
//                        .environment(\.managedObjectContext, dataController.container.viewContext)
//                        .environmentObject(dataController)
//                } else {
//                    //                    MainAppView()
//                    //                        .onAppear {
//                    //                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.00) {
//                    //                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//                    //                                   let rootViewController = windowScene.windows.first?.rootViewController {
//                    //                                    UIView.performWithoutAnimation {
//                    //                                        showHomeFile = true
//                    //                                        rootViewController.dismiss(animated: false)
//                    //                                    }
//                    //                                }
//                    //                            }
//                    //                        }
//                    HomeFile(selectedTab: $selectedTab)
//                        .environment(\.managedObjectContext, dataController.container.viewContext)
//                    .environmentObject(dataController)                }
//            }
//            .fullScreenCover(isPresented: $showHomeFile) {
//                HomeFile(selectedTab: $selectedTab)
//                    .environment(\.managedObjectContext, dataController.container.viewContext) // ✅ Passes context globally
//                    .environmentObject(dataController) // ✅ Inject DataController globally
//            }
//        }
//    }
//    
//    // MARK: - Review Prompt Logic
//    
//    private func startAppUsageTimer() {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 480) {
//            print("[DEBUG] Timer triggered. Attempting to request a review.")
//            promptForReview()
//        }
//    }
//    
//    private func promptForReview() {
//        guard !hasPromptedReview else {
//            print("[DEBUG] Review prompt already shown. Skipping.")
//            return
//        }
//        
//        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
//            print("[DEBUG] UIWindowScene found. Requesting review.")
//            SKStoreReviewController.requestReview(in: windowScene)
//            hasPromptedReview = true
//        } else {
//            print("[DEBUG] No UIWindowScene found. Cannot request a review.")
//        }
//    }
//    
//}




//import SwiftUI
//import FirebaseCore
//import UserNotifications
//import StoreKit
//import SuperwallKit
//
//// Custom AppDelegate to enforce portrait orientation
//class AppDelegate: NSObject, UIApplicationDelegate {
//    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
//        return .portrait
//    }
//    
//    func application(_ application: UIApplication,
//                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//        if FirebaseApp.app() == nil {
//            FirebaseApp.configure()
//        }
//        
//        Superwall.configure(apiKey: "pk_e7000e4aad725f2d7a6eae7dc7633538b4c05d32c96afde3")
//        return true
//    }
//}
//
//@main
//struct ApologistApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//    @StateObject private var dataController = DataController()
//    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
//    @State private var hasPromptedReview = false
//    @State private var isLoaded: Bool = false
//    @State private var showHomeFile = false
//    @State private var selectedTab: Int = 5
//
//    init() {
//        print("[DEBUG] App Launched - hasCompletedOnboarding: \(hasCompletedOnboarding)")
//        ValueTransformer.setValueTransformer(SecureDictionaryTransformer(), forName: NSValueTransformerName("SecureDictionaryTransformer"))
//        NotificationManager.requestNotificationPermissions()
//    }
//
//    var body: some Scene {
//        WindowGroup {
//            ZStack {
//                if !hasCompletedOnboarding {
//                    OnboardingView(isLoaded: $isLoaded)
//                        .environment(\.managedObjectContext, dataController.container.viewContext)
//                        .environmentObject(dataController)
//                } else {
//                    MainAppView()
//                        .environmentObject(dataController) // ✅ Inject DataController globally
//                        .onAppear {
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
//                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//                                   let rootViewController = windowScene.windows.first?.rootViewController {
//                                    UIView.performWithoutAnimation {
//                                        showHomeFile = true
//                                        rootViewController.dismiss(animated: false)
//                                    }
//                                }
//                            }
//                        }
//                }
//            }
//            .fullScreenCover(isPresented: $showHomeFile) {
//                HomeFile(selectedTab: $selectedTab)
//                
//            }
//        }
//    }
//
//    // MARK: - Review Prompt Logic
//
//    private func startAppUsageTimer() {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 120) {
//            print("[DEBUG] Timer triggered. Attempting to request a review.")
//            promptForReview()
//        }
//    }
//
//    private func promptForReview() {
//        guard !hasPromptedReview else {
//            print("[DEBUG] Review prompt already shown. Skipping.")
//            return
//        }
//
//        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
//            print("[DEBUG] UIWindowScene found. Requesting review.")
//            SKStoreReviewController.requestReview(in: windowScene)
//            hasPromptedReview = true
//        } else {
//            print("[DEBUG] No UIWindowScene found. Cannot request a review.")
//        }
//    }
//}
