//
//  ournalEntryManager.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/16/24.
//


import Foundation
import CoreData
import SwiftUI

class JournalEntryManager: ObservableObject {
    private let container: NSPersistentContainer
    @Published var entries: [JournalEntri] = [] // Directly using Core Data JournalEntry

    init() {
        // Initialize the Core Data stack
        container = NSPersistentContainer(name: "ApologistApp")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Error loading Core Data: \(error)")
            }
        }
        fetchEntries()
    }

    // Fetch all entries from Core Data
    func fetchEntries() {
        let request: NSFetchRequest<JournalEntri> = JournalEntri.fetchRequest()
        do {
            entries = try container.viewContext.fetch(request)
        } catch {
            print("Error fetching entries: \(error)")
        }
    }

    // Add a new entry to Core Data
    func addEntry(title: String, content: String, type: String) {
        let newEntry = JournalEntri(context: container.viewContext)
        newEntry.id = UUID()
        newEntry.title = title
        newEntry.content = content
        newEntry.type = type
        newEntry.date = Date()

        saveContext()
        fetchEntries()
    }

    // Delete an entry
    func deleteEntry(entry: JournalEntri) {
        container.viewContext.delete(entry)
        saveContext()
        fetchEntries()
    }

    // Save changes to Core Data
    private func saveContext() {
        do {
            try container.viewContext.save()
        } catch {
            print("Error saving to Core Data: \(error)")
        }
    }
}
