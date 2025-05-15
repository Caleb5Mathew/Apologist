//
//  SecureDictionaryTransformer.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/31/24.
//

import Foundation

@objc(SecureDictionaryTransformer)
class SecureDictionaryTransformer: ValueTransformer {
    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let dictionary = value as? [String: String] else { return nil }
        do {
            return try NSKeyedArchiver.archivedData(withRootObject: dictionary, requiringSecureCoding: true)
        } catch {
            print("Error archiving dictionary: \(error)")
            return nil
        }
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: NSDictionary.self, from: data) as? [String: String]
        } catch {
            print("Error unarchiving dictionary: \(error)")
            return nil
        }
    }
}
