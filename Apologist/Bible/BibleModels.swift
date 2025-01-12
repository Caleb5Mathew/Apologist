//
//  BibleModels.swift
//  Apologist
//
//  Created by Caleb Matthews  on 1/10/25.
//

// BibleModels.swift
import Foundation

struct Book: Identifiable, Decodable {
    let id: String
    let name: String
}

struct Chapter: Identifiable, Decodable {
    let id: String
    let number: String
    let reference: String

    var isNumeric: Bool {
        return Int(number) != nil
    }
}

struct Verse: Identifiable, Decodable {
    let id: String
    let reference: String
    let content: String?
}

struct VerseResponse: Decodable {
    let data: [Verse]
}

struct FullVerseResponse: Decodable {
    let data: FullVerseData
}

struct FullVerseData: Decodable {
    let id: String
    let content: String?
}
