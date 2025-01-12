//
//  ReadingView.swift
//  Apologist
//
//  Created by Caleb Matthews  on 1/10/25.
//

//
//  ReadingView.swift
//  Apologist
//

import SwiftUI

struct ReadingView: View {
    let book: Book
    let chapter: Chapter
    let apiKey: String
    let bibleId: String
    @State private var verses: [Verse] = []
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading Chapter...")
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(verses) { verse in
                        Text("\(verse.reference): \(verse.content ?? "Content unavailable")")
                            .font(.body)
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            fetchVerses()
        }
    }

    private func fetchVerses() {
        isLoading = true
        guard let url = URL(string: "https://api.scripture.api.bible/v1/bibles/\(bibleId)/chapters/\(chapter.id)/verses") else {
            print("DEBUG: Failed to construct Verses URL.")
            return
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "api-key")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("DEBUG: Error fetching verses: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("DEBUG: No data received.")
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(VerseResponse.self, from: data)
                DispatchQueue.main.async {
                    self.verses = decodedResponse.data
                    self.isLoading = false
                }
            } catch {
                print("DEBUG: Failed to decode Verses response: \(error.localizedDescription)")
            }
        }.resume()
    }
}
