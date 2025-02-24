
//
//  ApologistApp.swift
//  Apologist
//
//  Created by Caleb Matthews on 12/6/24.
//

import SwiftUI
import Firebase
import UserNotifications
import StoreKit // Import StoreKit for review prompt functionality
import SuperwallKit // Import SuperwallKit

// Custom AppDelegate to enforce portrait orientation
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // Restrict to portrait mode only
        return .portrait
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure Superwall with your API key
        Superwall.configure(apiKey: "pk_e7000e4aad725f2d7a6eae7dc7633538b4c05d32c96afde3")
        return true
    }
}

@main
struct ApologistApp: App {
    // Use custom AppDelegate to control orientation
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var dataController = DataController() // Initialize DataController
    @State private var hasPromptedReview = false // Track if the review prompt has been shown

    // Initializer for app-wide setup
    init() {
        // Configure Firebase
        FirebaseApp.configure()

        // Register the SecureDictionaryTransformer
        ValueTransformer.setValueTransformer(SecureDictionaryTransformer(), forName: NSValueTransformerName("SecureDictionaryTransformer"))

        // Request notification permissions
        NotificationManager.requestNotificationPermissions()
    }

    var body: some Scene {
        WindowGroup {
            APContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(dataController)
                .onAppear {
                    print("[DEBUG] Checking for app updates...")

                    AppVersionManager.checkForUpdate(bundleId: "DeepDev.Apologist") { isUpdateAvailable in
                        DispatchQueue.main.async {
                            if isUpdateAvailable {
                                // Notify `APContentView` about the update
                                NotificationCenter.default.post(name: .appUpdateAvailable, object: nil)
                            }
                        }
                    }
                }
        }
    }


    // MARK: - Review Prompt Logic

    /// Starts a timer to show the review prompt after 2 minutes of app usage.
    private func startAppUsageTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 120) { // 120 seconds = 2 minutes
            print("[DEBUG] Timer triggered. Attempting to request a review.")
            promptForReview()
        }
    }

    /// Prompts the user for a review using SKStoreReviewController.
    private func promptForReview() {
        // Ensure the prompt is shown only once
        guard !hasPromptedReview else {
            print("[DEBUG] Review prompt already shown. Skipping.")
            return
        }

        // Check if a UIWindowScene exists
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            print("[DEBUG] UIWindowScene found. Requesting review.")
            SKStoreReviewController.requestReview(in: windowScene)
            hasPromptedReview = true // Mark that the review has been prompted
        } else {
            print("[DEBUG] No UIWindowScene found. Cannot request a review.")
        }
    }
}
