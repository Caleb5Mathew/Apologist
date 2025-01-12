import SwiftUI

struct ReadingView: View {
    let book: Book
    let chapter: Chapter
    let apiKey: String
    let bibleId: String
    @State private var verses: [Verse] = []
    @State private var isLoading = true
    let onBack: () -> Void // Closure to handle back navigation

    var body: some View {
        ZStack {
            // Background color for the entire screen
            Color(hex: "#0B1E30") // Deep Midnight Blue
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 16) { // Added spacing for better layout
                // Header with Back Button and Title
                HStack {
                    Button(action: {
                        // Show loading when going back
                        onBackWithLoading()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(Color(hex: "#ECEFF4")) // MoonlightWhite
                    }
                    .padding(.leading, 45) // Increased padding to move the arrow further to the right
                    .padding(.top, 10) // Increased padding to move the arrow further to the right


                    Spacer()

                    Text("\(book.name) - Chapter \(chapter.number)")
                        .font(.custom("Avenir Next", size: 24))
                        .foregroundColor(Color(hex: "#ECEFF4")) // MoonlightWhite
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.top, 12) // Increased padding to scoot the chapter text further down
                        .padding(.leading, -52) // Added padding to move the text slightly to the right

                    Spacer()
                }
                .frame(height: 30) // Adjusted height to ensure proper spacing
                .padding(.vertical, 8) // Adjusted padding for the overall header
                .background(Color(hex: "#0B1E30")) // Maintain the Midnight Blue background

       // Content
                ScrollView {
                    if isLoading {
                        LeftwardLoadingView(message: "Loading Chapter...")
                    } else {
                        VStack(alignment: .leading, spacing: 16) { // Added spacing between verses
                            Text(createAttributedContent())
                                .font(.custom("Avenir Next", size: 18)) // Slightly larger font for better readability
                                .foregroundColor(Color(hex: "#ECEFF4")) // Moonlight White
                                .padding()
                                .background(Color(hex: "#0B1E30").opacity(0.9)) // Subtle Midnight Blue
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.5), radius: 5, x: 0, y: 4) // Subtle shadow for better contrast
                        }
                        .padding(.horizontal, 16) // Adjusted padding for more breathing room
                    }
                }
                .background(Color(hex: "#0B1E30")) // Deep Midnight Blue
            }
        }
        .onAppear {
            fetchVerses()
        }
        .navigationBarHidden(true)
    }

    private func onBackWithLoading() {
        // Show loading state immediately
        isLoading = true

        // Delay navigation to simulate loading time
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onBack() // Call the back navigation closure
        }

        // Clear the loading state after navigation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isLoading = false
        }
    }

    private func createAttributedContent() -> AttributedString {
        var result = AttributedString()

        let sortedVerses = verses.sorted {
            let firstRef = Int($0.reference.split(separator: ":").last ?? "") ?? 0
            let secondRef = Int($1.reference.split(separator: ":").last ?? "") ?? 0
            return firstRef < secondRef
        }

        for verse in sortedVerses {
            if let reference = verse.reference.split(separator: ":").last,
               let content = verse.content {
                var subscriptNumber = AttributedString(String(reference))
                subscriptNumber.font = .custom("Avenir Next", size: 14) // Slightly larger font for verse numbers
                subscriptNumber.baselineOffset = 6
                subscriptNumber.foregroundColor = Color(hex: "#FFD79D") // Starry Sky Yellow

                let sanitizedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                    .drop(while: { $0.isNumber || $0.isWhitespace })
                var verseText = AttributedString(" \(sanitizedContent)")
                verseText.font = .custom("Avenir Next", size: 18) // Slightly larger font for readability
                verseText.foregroundColor = Color(hex: "#ECEFF4") // Moonlight White

                result.append(subscriptNumber)
                result.append(verseText)
            }
        }

        return result
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
                    self.verses = []
                    let group = DispatchGroup()
                    for verse in decodedResponse.data {
                        group.enter()
                        self.fetchVerseContent(verseId: verse.id) { content in
                            var verseWithContent = verse
                            verseWithContent.content = content
                            self.verses.append(verseWithContent)
                            group.leave()
                        }
                    }
                    group.notify(queue: .main) {
                        self.isLoading = false
                    }
                }
            } catch {
                print("DEBUG: Failed to decode Verses response: \(error.localizedDescription)")
            }
        }.resume()
    }

    private func fetchVerseContent(verseId: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://api.scripture.api.bible/v1/bibles/\(bibleId)/verses/\(verseId)") else {
            print("DEBUG: Failed to construct Verse Content URL.")
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "api-key")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("DEBUG: Error fetching verse content: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("DEBUG: No data received.")
                completion(nil)
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(VerseContentResponse.self, from: data)
                if let rawContent = decodedResponse.data.content {
                    let sanitizedContent = self.sanitizeHTML(rawContent)
                    completion(sanitizedContent)
                } else {
                    completion(nil)
                }
            } catch {
                print("DEBUG: Failed to decode Verse Content response: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }

    private func sanitizeHTML(_ html: String) -> String {
        guard let data = html.data(using: .utf16) else { return html }
        do {
            let attributedString = try NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil
            )
            return attributedString.string
        } catch {
            print("DEBUG: Error sanitizing HTML: \(error.localizedDescription)")
            return html
        }
    }
}
