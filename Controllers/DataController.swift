////
////  DataController.swift
////  Habit
////
////  Created by Nazarii Zomko on 13.05.2023.
////
//
//import CoreData
//import UIKit
//
///// The `DataController` class is responsible for managing the Core Data stack and providing methods to interact with the data store.
/////
///// It is implemented as a singleton using the static `shared` property, allowing access to the same instance across the application.
/////
///// The `DataController` class provides the following functionalities:
///// - Loading the persistent stores for the Core Data stack.
///// - Saving changes made to the managed object context.
///// - Deleting objects from the managed object context.
///// - Creating a preview instance for testing and previewing purposes.
/////
///// To use the `DataController`, simply access its shared instance using `DataController.shared`.
/////
///// Example usage:
///// ```
///// let dataController = DataController.shared
///// dataController.save()
///// ```
//class DataController: ObservableObject {
//    
//    /// The shared instance of the `DataController`.
//    static let shared = DataController()
//    
//    /// The persistent container representing the Core Data stack.
//    let container: NSPersistentContainer
//    
//    /// Initializes the `DataController` instance, either in memory (for temporary use such as testing and previewing), or on permanent storage (for use in regular app runs).
//    ///
//    /// - Parameter inMemory: A Boolean value indicating whether to use an in-memory database.
//    ///                       Defaults to `false` which uses a persistent store on disk.
//    ///
//    /// - Note: When `inMemory` is `true`, a temporary, in-memory database is created. Data written to this database is destroyed after the app finishes running.
//    init(inMemory: Bool = false) {
//        container = NSPersistentContainer(name: "Habit")
//        let url = URL.storeURL(for: "group.com.mat.apologist", databaseName: "HabitDatabase")
//
//        let storeDescription = NSPersistentStoreDescription(url: url)
//        container.persistentStoreDescriptions = [storeDescription]
//
//        
//        if inMemory {
//            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
//        }
//        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
//            if let error = error as NSError? {
//                fatalError("Unresolved error \(error), \(error.userInfo)")
//            }
//            #if DEBUG
//            if CommandLine.arguments.contains("enable-testing") {
//                self.deleteAll()
//                UIView.setAnimationsEnabled(false)
//            }
//            #endif
//        })
//        container.viewContext.automaticallyMergesChangesFromParent = true
//    }
//    
//    /// Saves Core Data context iff (if and only if) there are changes.
//    ///
//    /// This method checks if the managed object context has any changes and attempts to save them.
//    /// - Note: Errors during the save operation are ignored, but this should be fine because the attributes are optional.
//    func save() {
//        if container.viewContext.hasChanges {
//            try? container.viewContext.save()
//        }
//    }
//    
//    /// Deletes an object from the managed object context.
//    ///
//    /// - Parameter object: The `NSManagedObject` to be deleted.
//    func delete(_ object: NSManagedObject) {
//        container.viewContext.delete(object)
//    }
//    
//    func deleteAll() {
//        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Habit.fetchRequest()
//        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
//        _ = try? container.viewContext.execute(batchDeleteRequest)
//    }
//    
//    /// The preview instance of the `DataController`.
//    ///
//    /// This instance is created with an in-memory database and populated with example data for testing and previewing purposes.
//    static var preview: DataController = {
//        let dataController = DataController(inMemory: true)
//        
//        do {
//            try dataController.createSampleData()
//        } catch {
//            fatalError("Fatal error creating preview: \(error.localizedDescription)")
//        }
//        
//        return dataController
//    }()
//    
//    
//    /// Creates example habits for testing and previewing purposes.
//    ///
//    /// This method generates example `Habit` objects with sample data and saves them to the managed object context.
//    ///
//    /// - Throws: An NSError sent from calling save() on the NSManagedObjectContext.
//    func createSampleData() throws {
//        let viewContext = container.viewContext
//        
//        for i in 0..<10 {
//            let _ = Habit(context: viewContext, title: "Habit \(i)", motivation: "", color: HabitColor.randomColor)
//        }
//        
//        try viewContext.save()
//    }
//    
//}
//
//
//extension DataController {
//    
//    func getAllHabits() -> [Habit] {
//        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
//        do {
//            return try container.viewContext.fetch(request).sorted(by:  { $0.creationDate < $1.creationDate })
//        } catch {
//            print("Couldn't fetch all habits: \(error.localizedDescription)")
//            return []
//        }
//    }
//    
//    func findHabit(withId id: UUID) throws -> Habit {
//        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
//        request.fetchLimit = 1
//        request.predicate = NSPredicate(format: "id_ = %@", id as CVarArg)
//        
//        do {
//            guard let foundHabit = try container.viewContext.fetch(request).first else {
//                throw Error.notFound
//            }
//            return foundHabit
//        } catch {
//            throw Error.notFound
//        }
//    }
//    
//}
//
//
//extension URL {
//    static func storeURL (for groupName: String, databaseName : String) -> URL {
//        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupName) else {
//            fatalError("Could not create URL for \(groupName.lowercased())")
//        }
//        return fileContainer.appendingPathComponent("\(databaseName).sqlite")
//    }
//}




//
//  DataController.swift
//  Habit
//
//  Created by Nazarii Zomko on 13.05.2023.
//
//
//  DataController.swift
//  Habit
//
//  Created by Nazarii Zomko on 13.05.2023.
//

//import CoreData
//import UIKit
//
//class DataController: ObservableObject {
//    
//    /// The shared instance of the `DataController`.
//    static let shared = DataController()
//    
//    /// The persistent container representing the Core Data stack.
//    let container: NSPersistentContainer
//    
//    /// Initializes the `DataController` instance, either in memory (for testing) or permanent storage.
//    init(inMemory: Bool = false) {
//        print("📦 Initializing DataController... (inMemory: \(inMemory))")
//
//        container = NSPersistentContainer(name: "Habit")
//
//        let url = URL.storeURL(for: "group.com.mat.apologist", databaseName: "HabitDatabase")
//        let storeDescription = NSPersistentStoreDescription(url: url)
//        container.persistentStoreDescriptions = [storeDescription]
//
//        if inMemory {
//            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
//        }
//
//        container.loadPersistentStores { (storeDescription, error) in
//            if let error = error as NSError? {
//                print("❌ ERROR: Persistent Store Failed to Load → \(error), \(error.userInfo)")
//                fatalError("Unresolved error \(error), \(error.userInfo)")
//            } else {
//                print("✅ Persistent Store Loaded Successfully at: \(storeDescription.url?.absoluteString ?? "Unknown URL")")
//            }
//
//            #if DEBUG
//            if CommandLine.arguments.contains("enable-testing") {
//                print("🧹 Testing Mode Enabled - Deleting All Core Data Records")
//                self.deleteAll()
//                UIView.setAnimationsEnabled(false)
//            }
//            #endif
//        }
//
//        container.viewContext.automaticallyMergesChangesFromParent = true
//    }
//    
//    /// Saves Core Data context only if changes exist.
//    func save() {
//        if container.viewContext.hasChanges {
//            do {
//                try container.viewContext.save()
//                print("✅ Core Data Save Successful!")
//            } catch {
//                print("❌ ERROR: Core Data Save Failed → \(error.localizedDescription)")
//            }
//        } else {
//            print("⚠️ No changes to save in Core Data.")
//        }
//    }
//
//    /// Deletes an object from the managed object context.
//    func delete(_ object: NSManagedObject) {
//        print("🗑️ Deleting object: \(object)")
//        container.viewContext.delete(object)
//    }
//
//    func deleteAll() {
//        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Habit.fetchRequest()
//        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
//        do {
//            try container.viewContext.execute(batchDeleteRequest)
//            print("🧹 Successfully deleted all Habit records.")
//        } catch {
//            print("❌ ERROR: Failed to delete all habits → \(error.localizedDescription)")
//        }
//    }
//
//    /// The preview instance of the `DataController` (for SwiftUI previews).
//    static var preview: DataController = {
//        let dataController = DataController(inMemory: true)
//
//        do {
//            try dataController.createSampleData()
//        } catch {
//            fatalError("Fatal error creating preview: \(error.localizedDescription)")
//        }
//
//        return dataController
//    }()
//
//    /// Creates example habits for testing.
//    func createSampleData() throws {
//        let viewContext = container.viewContext
//
//        for i in 0..<10 {
//            let _ = Habit(context: viewContext, title: "Habit \(i)", motivation: "", color: HabitColor.randomColor)
//        }
//
//        try viewContext.save()
//        print("✅ Sample Data Created Successfully")
//    }
//}
//
//extension DataController {
//    
//    /// Fetches all habits sorted by creation date.
//    func getAllHabits() -> [Habit] {
//        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
//        do {
//            let habits = try container.viewContext.fetch(request)
//            print("📊 Fetched \(habits.count) habits from Core Data.")
//            return habits.sorted(by: { $0.creationDate < $1.creationDate })
//        } catch {
//            print("❌ ERROR: Couldn't fetch all habits → \(error.localizedDescription)")
//            return []
//        }
//    }
//    
//    /// Finds a habit by its UUID.
//    func findHabit(withId id: UUID) throws -> Habit {
//        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
//        request.fetchLimit = 1
//        request.predicate = NSPredicate(format: "id_ = %@", id as CVarArg)
//
//        do {
//            guard let foundHabit = try container.viewContext.fetch(request).first else {
//                throw Error.notFound
//            }
//            print("🔍 Found habit with ID: \(id)")
//            return foundHabit
//        } catch {
//            print("❌ ERROR: Could not find habit with ID \(id)")
//            throw Error.notFound
//        }
//    }
//}
//


//
//  DataController.swift
//  Habit
//
//  Created by Nazarii Zomko on 13.05.2023.
//

import CoreData
import UIKit

/// The `DataController` class is responsible for managing the Core Data stack and providing methods to interact with the data store.
///
/// It is implemented as a singleton using the static `shared` property, allowing access to the same instance across the application.
///
/// The `DataController` class provides the following functionalities:
/// - Loading the persistent stores for the Core Data stack.
/// - Saving changes made to the managed object context.
/// - Deleting objects from the managed object context.
/// - Creating a preview instance for testing and previewing purposes.
///
/// To use the `DataController`, simply access its shared instance using `DataController.shared`.
///
/// Example usage:
/// ```
/// let dataController = DataController.shared
/// dataController.save()
/// ```
class DataController: ObservableObject {
    
    /// The shared instance of the `DataController`.
    static let shared = DataController()

    /// The persistent container representing the Core Data stack.
    let container: NSPersistentContainer
    
    /// Initializes the `DataController` instance, either in memory (for temporary use such as testing and previewing), or on permanent storage (for use in regular app runs).
    ///
    /// - Parameter inMemory: A Boolean value indicating whether to use an in-memory database.
    ///                       Defaults to `false` which uses a persistent store on disk.
    ///
    /// - Note: When `inMemory` is `true`, a temporary, in-memory database is created. Data written to this database is destroyed after the app finishes running.
    init(inMemory: Bool = false) {
        print("📂 Initializing Core Data...")

        
        let modelNames = Bundle.main.paths(forResourcesOfType: "momd", inDirectory: nil)
        print("📂 Available Core Data Models: \(modelNames)")

        container = NSPersistentContainer(name: "Habit")

        let url = URL.storeURL(for: "group.com.mat.apologist", databaseName: "HabitDatabase")
        print("📂 Core Data Storage Location: \(url.absoluteString)")

        let storeDescription = NSPersistentStoreDescription(url: url)
        container.persistentStoreDescriptions = [storeDescription]

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        let storeURL = URL.storeURL(for: "group.com.mat.apologist", databaseName: "HabitDatabase")
            print("📂 Checking if persistent store exists at: \(storeURL)")

        if !FileManager.default.fileExists(atPath: storeURL.path) {
            print("❌ ERROR: Persistent Store File is Missing!")
        } else {
            print("✅ Persistent Store File Found at \(storeURL.path)")
        }

        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("❌ ERROR: Failed to load persistent store: \(error.localizedDescription)")
                print("🔍 ERROR DETAILS: \(error.userInfo)")
                fatalError("💀 Fatal error loading persistent store!")
            } else {
                print("✅ Persistent Store Loaded Successfully at: \(storeDescription.url?.absoluteString ?? "unknown location")")
            }

            // ✅ Fix by explicitly using 'self.container'
            let model = self.container.managedObjectModel.entities
            print("📂 Available Entities in Core Data Model:")
            for entity in model {
                print("- \(entity.name ?? "Unknown")")
            }
        }



        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    
    /// Saves Core Data context iff (if and only if) there are changes.
    ///
    /// This method checks if the managed object context has any changes and attempts to save them.
    /// - Note: Errors during the save operation are ignored, but this should be fine because the attributes are optional.
    func save() {
        if container.viewContext.hasChanges {
            try? container.viewContext.save()
        }
    }
    
    /// Deletes an object from the managed object context.
    ///
    /// - Parameter object: The `NSManagedObject` to be deleted.
    func delete(_ object: NSManagedObject) {
        container.viewContext.delete(object)
    }
    
    func deleteAll() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Habit.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        _ = try? container.viewContext.execute(batchDeleteRequest)
    }
    
    /// The preview instance of the `DataController`.
    ///
    /// This instance is created with an in-memory database and populated with example data for testing and previewing purposes.
    static var preview: DataController = {
        let dataController = DataController(inMemory: true)
        
        do {
            try dataController.createSampleData()
        } catch {
            fatalError("Fatal error creating preview: \(error.localizedDescription)")
        }
        
        return dataController
    }()
    
    
    /// Creates example habits for testing and previewing purposes.
    ///
    /// This method generates example `Habit` objects with sample data and saves them to the managed object context.
    ///
    /// - Throws: An NSError sent from calling save() on the NSManagedObjectContext.
    func createSampleData() throws {
        let viewContext = container.viewContext
        
        for i in 0..<10 {
            let _ = Habit(context: viewContext, title: "Habit \(i)", motivation: "", color: HabitColor.randomColor)
        }
        
        try viewContext.save()
    }
    
}


extension DataController {
    
    func getAllHabits() -> [Habit] {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        do {
            return try container.viewContext.fetch(request).sorted(by:  { $0.creationDate < $1.creationDate })
        } catch {
            print("Couldn't fetch all habits: \(error.localizedDescription)")
            return []
        }
    }
    
    func findHabit(withId id: UUID) throws -> Habit {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id_ = %@", id as CVarArg)
        
        do {
            guard let foundHabit = try container.viewContext.fetch(request).first else {
                throw Error.notFound
            }
            return foundHabit
        } catch {
            throw Error.notFound
        }
    }
    
}


extension URL {
    static func storeURL (for groupName: String, databaseName : String) -> URL {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupName) else {
            fatalError("Could not create URL for \(groupName.lowercased())")
        }
        return fileContainer.appendingPathComponent("\(databaseName).sqlite")
    }
}
