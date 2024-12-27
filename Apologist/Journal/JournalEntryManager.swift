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
    let container: NSPersistentContainer
    @Published var entries: [JournalEntri] = [] // Array of JournalEntri Core Data objects
    @Published var currentEntry: JournalEntri? // Current entry being modified

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

    func addEntry(title: String, content: String, type: String, questionsAndAnswers: [String: String]? = nil) {
        let newEntry = JournalEntri(context: container.viewContext)
        newEntry.id = UUID()
        newEntry.title = title
        newEntry.content = content
        newEntry.type = type
        newEntry.date = Date()
        if let questionsAndAnswers = questionsAndAnswers {
            newEntry.questionsAndAnswers = NSDictionary(dictionary: questionsAndAnswers)
        }
        saveContext()
        fetchEntries()
    }

    func updateEntry(entry: JournalEntri, newContent: String? = nil, newQuestionsAndAnswers: [String: String]? = nil) {
        if let newContent = newContent {
            entry.content = newContent
        }
        if let newQuestionsAndAnswers = newQuestionsAndAnswers {
            entry.questionsAndAnswers = NSDictionary(dictionary: newQuestionsAndAnswers)
        }
        saveContext()
        fetchEntries()
    }


    // Delete a journal entry
    func deleteEntry(entry: JournalEntri) {
        container.viewContext.delete(entry)
        saveContext()
        fetchEntries()
    }

    // Save Core Data context
    func saveContext() {
        do {
            try container.viewContext.save()
        } catch {
            print("Error saving to Core Data: \(error)")
        }
    }


    // Set the current entry (used for guided journaling)
    func setCurrentEntry(_ entry: JournalEntri) {
        currentEntry = entry
    }

    // Clear the current entry
    func clearCurrentEntry() {
        currentEntry = nil
    }

    // Save the current guided journaling progress
    func saveCurrentGuidedProgress(
        question: String,
        answer: String
    ) {
        guard let currentEntry = currentEntry else { return }

        // Safely cast questionsAndAnswers to a Swift dictionary or start with an empty one
        var updatedQuestionsAndAnswers = (currentEntry.questionsAndAnswers as? [String: String]) ?? [:]

        // Update the dictionary with the new question and answer
        updatedQuestionsAndAnswers[question] = answer

        // Convert the Swift dictionary back to NSDictionary and assign it to the Core Data property
        currentEntry.questionsAndAnswers = NSDictionary(dictionary: updatedQuestionsAndAnswers)

        // Save the changes to Core Data
        saveContext()
        fetchEntries()

    }
}
