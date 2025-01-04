//
//  ApologistApp.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/6/24.
//

import UserNotifications
import SwiftUI

@main
struct ApologistApp: App {
    @StateObject private var dataController = DataController() // Initialize DataController

    // Add an initializer for app-wide setup
    init() {
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
