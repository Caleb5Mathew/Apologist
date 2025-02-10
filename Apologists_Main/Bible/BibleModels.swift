//
//  BibleModels.swift
//  Apologist
//
//  Created by Caleb Matthews  on 1/10/25.
//
import Foundation

// Bible Data Models

struct Bible: Identifiable, Decodable {
    let id: String
    let name: String
}

enum ReadingStep {
    case bibles
    case books
    case chapters
    case reading

    var navigationTitle: String {
        switch self {
        case .bibles:
            return "Select Bible Version"
        case .books:
            return "Books"
        case .chapters:
            return "Chapters"
        case .reading:
            return "Reading"
        }
    }
}

// Book and BookResponse Models

struct Book: Identifiable, Decodable {
    let id: String
    let name: String
}

struct BookResponse: Decodable {
    let data: [Book]? // Mark `data` as optional to handle missing or null responses
}


// Chapter and ChapterResponse Models

struct Chapter: Identifiable, Decodable {
    let id: String
    let number: String
    let reference: String

    var isNumeric: Bool {
        return Int(number) != nil
    }
}

struct ChapterResponse: Decodable {
    let data: [Chapter]
}

// Verse and VerseResponse Models

struct Verse: Identifiable, Decodable {
    let id: String
    let reference: String
    var content: String? // Change this to var to allow modification
}


struct VerseResponse: Decodable {
    let data: [Verse]
}
struct VerseContentResponse: Decodable {
    let data: VerseContentData
}

struct VerseContentData: Decodable {
    let content: String?
}

// FullVerse and FullVerseResponse Models

struct FullVerseResponse: Decodable {
    let data: FullVerseData
}

struct FullVerseData: Decodable {
    let id: String
    let content: String?
}


struct Section: Identifiable, Decodable {
    let id: String
    let title: String
    let startVerseId: String
}

struct SectionResponse: Decodable {
    let data: [Section]
}
