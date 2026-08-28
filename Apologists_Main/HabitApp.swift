//
//  HabitApp.swift
//  Habit
//
//  Created by Nazarii Zomko on 13.05.2023.
//
import SwiftUI


struct HabitApp: App {
    @StateObject var dataController = DataController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(dataController)
        }
    }
}
