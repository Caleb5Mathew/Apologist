//
//  BibleListViews.swift
//  Apologist
//
//  Created by Caleb Matthews  on 1/10/25.
//

//
//  BibleListViews.swift
//  Apologist
//

import SwiftUI

struct BibleVersionListView: View {
    let bibles: [Bible]
    @Binding var selectedBibleId: String?
    let onSelect: () -> Void

    var body: some View {
        VStack {
            Text("Select a Bible Version")
                .font(.headline)
                .padding(.vertical)

            List(bibles) { bible in
                HStack {
                    Text(bible.name)
                        .font(.system(size: 16))
                    Spacer()
                    if selectedBibleId == bible.id {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedBibleId = bible.id
                }
            }
            .listStyle(InsetGroupedListStyle())

            Button(action: onSelect) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedBibleId == nil ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .disabled(selectedBibleId == nil)
        }
    }
}

struct BookListView: View {
    @Binding var books: [Book]
    @Binding var isLoading: Bool
    let onSelect: (Book) -> Void

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading Books...")
            } else {
                List(books) { book in
                    HStack {
                        Text(book.name)
                            .font(.body)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(book)
                    }
                }
            }
        }
    }
}

struct ChapterListView: View {
    let book: Book
    let apiKey: String
    let bibleId: String
    @State private var chapters: [Chapter] = []
    @State private var isLoading = true
    let onSelect: (Chapter) -> Void

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading Chapters...")
            } else {
                List(chapters) { chapter in
                    HStack {
                        Text("Chapter \(chapter.number)")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(chapter)
                    }
                }
            }
        }
        .onAppear {
            fetchChapters()
        }
    }

    private func fetchChapters() {
        isLoading = true
        guard let url = URL(string: "https://api.scripture.api.bible/v1/bibles/\(bibleId)/books/\(book.id)/chapters") else {
            print("DEBUG: Failed to construct Chapters URL.")
            return
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "api-key")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("DEBUG: Error fetching chapters: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("DEBUG: No data received.")
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(ChapterResponse.self, from: data)
                DispatchQueue.main.async {
                    self.chapters = decodedResponse.data.filter { $0.isNumeric }
                    self.isLoading = false
                }
            } catch {
                print("DEBUG: Failed to decode Chapters response: \(error.localizedDescription)")
            }
        }.resume()
    }
}
