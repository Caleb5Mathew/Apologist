//
//  BibleView.swift
//  Apologist
//
//  Created by Caleb Matthews on 1/9/25.
//

import SwiftUI

struct BibleView: View {
    @State private var selectedBibleId: String? = nil
    @State private var books: [Book] = []
    @State private var isLoadingBooks = false
    @State private var selectedBook: Book?
    @State private var selectedChapter: Chapter?
    @State private var verses: [Verse] = []
    @State private var isLoadingVerses = true
    @State private var currentStep: ReadingStep = .bibles

    let apiKey = "e74e820c094d4811417a64fcaab34d45" // Your API Key

    /// Predefined Bible versions
    let predefinedBibles: [Bible] = [
        Bible(id: "06125adad2d5898a-01", name: "New International Version (NIV)"),
        Bible(id: "de4e12af7f28f599-02", name: "King James Version (KJV)"),
        Bible(id: "01b28e5b000d1987-01", name: "English Standard Version (ESV)"),
        Bible(id: "e3c121f6c3d7b2e4-01", name: "New Living Translation (NLT)"),
        Bible(id: "be4e24b44edc4c84-01", name: "Catholic Public Domain Version (CPDV)")
    ]

    var body: some View {
        NavigationView {
            VStack {
                if currentStep == .bibles {
                    BibleVersionListView(
                        bibles: predefinedBibles,
                        selectedBibleId: $selectedBibleId,
                        onSelect: {
                            currentStep = .books
                            fetchBooks()
                        }
                    )
                } else if currentStep == .books {
                    BookListView(
                        books: $books,
                        isLoading: $isLoadingBooks,
                        onSelect: { book in
                            selectedBook = book
                            currentStep = .chapters
                        }
                    )
                } else if currentStep == .chapters {
                    if let selectedBook = selectedBook, let selectedBibleId = selectedBibleId {
                        ChapterListView(
                            book: selectedBook,
                            apiKey: apiKey,
                            bibleId: selectedBibleId,
                            onSelect: { chapter in
                                selectedChapter = chapter
                                currentStep = .reading
                            }
                        )
                    }
                } else if currentStep == .reading {
                    if let selectedBook = selectedBook, let selectedChapter = selectedChapter, let selectedBibleId = selectedBibleId {
                        ReadingView(
                            book: selectedBook,
                            chapter: selectedChapter,
                            apiKey: apiKey,
                            bibleId: selectedBibleId
                        )
                    }
                }
            }
            .navigationBarTitle(currentStep.navigationTitle, displayMode: .inline)
        }
    }

    private func fetchBooks() {
        guard let selectedBibleId = selectedBibleId else {
            print("DEBUG: Bible ID is nil.")
            return
        }

        isLoadingBooks = true
        guard let url = URL(string: "https://api.scripture.api.bible/v1/bibles/\(selectedBibleId)/books") else {
            print("DEBUG: Failed to construct Books URL.")
            return
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "api-key")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("DEBUG: Error fetching books: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("DEBUG: No data received.")
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(BookResponse.self, from: data)
                DispatchQueue.main.async {
                    self.books = decodedResponse.data
                    self.isLoadingBooks = false
                }
            } catch {
                print("DEBUG: Failed to decode Books response: \(error.localizedDescription)")
            }
        }.resume()
    }
}
