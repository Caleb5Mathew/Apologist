//
//  ApologistApp.swift
//  Apologist
//
//  Created by Caleb Matthews on 12/6/24.
//

import SwiftUI
//import Firebase
import UserNotifications

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
        }
    }
}
