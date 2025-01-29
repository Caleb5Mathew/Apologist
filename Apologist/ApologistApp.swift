//
//  ApologistApp.swift
//  Apologist
//
//  Created by Caleb Matthews on 12/6/24.
//

import SwiftUI
//import Firebase
import UserNotifications
import StoreKit // Import StoreKit for review prompt functionality

// Custom AppDelegate to enforce portrait orientation
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // Restrict to portrait mode only
        return .portrait
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
//        FirebaseApp.configure()

        // Register the SecureDictionaryTransformer
        ValueTransformer.setValueTransformer(SecureDictionaryTransformer(), forName: NSValueTransformerName("SecureDictionaryTransformer"))

        // Request notification permissions
        NotificationManager.requestNotificationPermissions()
    }

    var body: some Scene {
        WindowGroup {
            APContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext) // Provide Core Data context
                .environmentObject(dataController) // Provide DataController to child views
                .onAppear {
                    print("[DEBUG] App appeared. Starting timer to request a review.")
                    startAppUsageTimer() // Start timer to prompt review
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
