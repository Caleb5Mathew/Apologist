//
//  JournalEntri+CoreDataProperties.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/17/24.
//
//

import Foundation
import CoreData


extension JournalEntri {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<JournalEntri> {
        return NSFetchRequest<JournalEntri>(entityName: "JournalEntri")
    }

    @NSManaged public var content: String?
    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var type: String?

}

extension JournalEntri : Identifiable {

}
