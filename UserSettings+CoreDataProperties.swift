//
//  UserSettings+CoreDataProperties.swift
//  Apologist
//
//  Created by user269258 on 3/8/25.
//
//

import Foundation
import CoreData


extension UserSettings {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserSettings> {
        return NSFetchRequest<UserSettings>(entityName: "UserSettings")
    }

    @NSManaged public var connectionLevel: Double

}
