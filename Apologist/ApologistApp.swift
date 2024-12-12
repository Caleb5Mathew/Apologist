//
//  ApologistApp.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/6/24.
//

import SwiftUI

@main
struct ApologistApp: App {
    @StateObject private var dataController = DataController() // Initialize DataController

    var body: some Scene {
        WindowGroup {
            APContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext) // Provide Core Data context
                .environmentObject(dataController) // Provide DataController to child views
        }
    }
}
