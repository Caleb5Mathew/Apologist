//
//  ApologistApp.swift
//  Apologist
//
//  Created by Caleb Matthews on 12/6/24.
//

import SwiftUI
import FirebaseAppCheck
import FirebaseCore
import UserNotifications
import StoreKit // Import StoreKit for review prompt functionality
import SuperwallKit // Import SuperwallKit

final class ApologistAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if DEBUG && targetEnvironment(simulator)
        return AppCheckDebugProvider(app: app)
        #else
        AppAttestProvider(app: app)
        #endif
    }
}

// Custom AppDelegate to enforce portrait orientation
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // Restrict to portrait mode only
        return .portrait
    }
    
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase only once
        if FirebaseApp.app() == nil {
            AppCheck.setAppCheckProviderFactory(ApologistAppCheckProviderFactory())
            FirebaseApp.configure()
        }
        
        // Configure Superwall with your API key
        Superwall.configure(apiKey: "pk_e7000e4aad725f2d7a6eae7dc7633538b4c05d32c96afde3")
        
        return true
    }
}

@main
struct ApologistApp: App {
    // Use custom AppDelegate to control orientation
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var dataController = DataController() // ✅ Initialize DataController as @StateObject
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false // ✅ Check if onboarding has been completed
    @State private var hasPromptedReview = false // Track if the review prompt has been shown

    // Initializer for app-wide setup
    init() {
        // Register the SecureDictionaryTransformer
        ValueTransformer.setValueTransformer(SecureDictionaryTransformer(), forName: NSValueTransformerName("SecureDictionaryTransformer"))

        // Request notification permissions
        NotificationManager.requestNotificationPermissions()
    }

    var body: some Scene {
        WindowGroup {
            if !hasCompletedOnboarding {
                OnboardingView(isLoaded: Binding(
                    get: { !hasCompletedOnboarding },
                    set: { newValue in
                        // When onboarding completes, set hasCompletedOnboarding to true
                        if newValue {
                            hasCompletedOnboarding = true
                        }
                    }
                ))
                    .environment(\.managedObjectContext, dataController.container.viewContext) // ✅ Inject Core Data context
                    .environmentObject(dataController) // ✅ Inject DataController into OnboardingView
            } else {
                APContentView()
                    .environment(\.managedObjectContext, dataController.container.viewContext) // ✅ Inject Core Data context
                    .environmentObject(dataController) // ✅ Inject DataController into main content
                    .onAppear {
                        #if !DEBUG
                        print("[DEBUG] Checking for app updates...")
                        AppVersionManager.checkForUpdate(bundleId: "DeepDev.Apologist") { isUpdateAvailable in
                            DispatchQueue.main.async {
                                if isUpdateAvailable {
                                    NotificationCenter.default.post(name: .appUpdateAvailable, object: nil)
                                }
                            }
                        }
                        #endif
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
