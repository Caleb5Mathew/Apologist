import SwiftUI

struct BibleView: View {
    @State private var selectedBibleId: String? = nil
    @State private var books: [Book] = []
    @State private var isLoadingBooks = false
    @State private var selectedBook: Book?
    @State private var selectedChapter: Chapter?
    @State private var currentStep: ReadingStep = .bibles

    // Unified loading state
    @State private var loadingState: String? // Contains the loading message or nil if not loading

    let apiKey = "e74e820c094d4811417a64fcaab34d45" // Your API Key

    /// Predefined Bible versions
    let predefinedBibles: [Bible] = [
        Bible(id: "06125adad2d5898a-01", name: "New International Version (NIV)"),
        Bible(id: "de4e12af7f28f599-02", name: "King James Version (KJV)"),
        Bible(id: "bba9f40183526463-01", name: "Berean Standard Bible"),              // Protestant
        Bible(id: "de4e12af7f28f599-01", name: "New King James Version (NKJV)"),     // Protestant
        Bible(id: "179568874c45066f-01", name: "Douay-Rheims American 1899")         // Catholic
    ]






    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if currentStep == .bibles {
                        BibleVersionListView(
                            bibles: predefinedBibles,
                            selectedBibleId: $selectedBibleId,
                            onSelect: { bibleId in
                                setLoadingState("Loading Books...")
                                selectedBibleId = bibleId
                                currentStep = .books
                                fetchBooks()
                            }
                        )
                    } else if currentStep == .books {
                        if isLoadingBooks {
                            LeftwardLoadingView(message: "Loading Books...")
                        } else if books.isEmpty {
                            VStack {
                                Text("No books available for this Bible version.")
                                    .font(.custom("Avenir Next", size: 18))
                                    .foregroundColor(Color(hex: "#ECEFF4")) // MoonlightWhite
                                    .padding()
                                    .multilineTextAlignment(.center)

                                Button(action: {
                                    currentStep = .bibles
                                    selectedBibleId = nil
                                }) {
                                    Text("Go Back")
                                        .font(.custom("Avenir Next", size: 16))
                                        .foregroundColor(Color(hex: "#FFD79D")) // StarrySkyYellow
                                        .padding(.horizontal)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            BookListView(
                                books: $books,
                                isLoading: $isLoadingBooks,
                                onSelect: { book in
                                    setLoadingState("Loading Chapters...")
                                    selectedBook = book
                                    currentStep = .chapters
                                    clearLoadingState()
                                },
                                onBack: {
                                    handleBackNavigation("Loading Bible Versions...", targetStep: .bibles)
                                }
                            )
                        }
                    }
 else if currentStep == .chapters {
                        if let selectedBook = selectedBook, let selectedBibleId = selectedBibleId {
                            ChapterListView(
                                book: selectedBook,
                                apiKey: apiKey,
                                bibleId: selectedBibleId,
                                onSelect: { chapter in
                                    setLoadingState("Loading Chapter...")
                                    selectedChapter = chapter
                                    currentStep = .reading
                                    clearLoadingState()
                                },
                                onBack: {
                                    handleBackNavigation("Loading Books...", targetStep: .books)
                                }
                            )
                        }
                    } else if currentStep == .reading {
                        if let selectedBook = selectedBook, let selectedChapter = selectedChapter, let selectedBibleId = selectedBibleId {
                            ReadingView(
                                book: selectedBook,
                                chapter: selectedChapter,
                                apiKey: apiKey,
                                bibleId: selectedBibleId,
                                onBack: {
                                    handleBackNavigation("Loading Chapters...", targetStep: .chapters)
                                }
                            )
                        }
                    }
                }

                // Full-screen loading overlay
                if let loadingMessage = loadingState {
                    ZStack {
                        Color.black.opacity(0.8)
                            .edgesIgnoringSafeArea(.all)
                        VStack {
                            ProgressView(loadingMessage)
                                .font(.custom("Avenir Next", size: 18))
                                .foregroundColor(Color(hex: "#FFD79D")) // StarrySkyYellow
                                .padding()
                        }
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3))
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Loading State Management
    private func setLoadingState(_ message: String) {
        // Prevent duplicate loading states
        DispatchQueue.main.async {
            if loadingState != message {
                loadingState = message
            }
        }
    }

    private func clearLoadingState() {
        // Clear loading state with a delay to ensure smooth transitions
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            loadingState = nil
        }
    }

    // MARK: - Handle Back Navigation
    private func handleBackNavigation(_ message: String, targetStep: ReadingStep) {
        DispatchQueue.main.async {
            // Set loading state only if it's different
            if loadingState != message {
                setLoadingState(message)
            }

            // Navigate back after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                currentStep = targetStep
            }

            // Clear loading state after navigation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if loadingState == message {
                    clearLoadingState()
                }
            }
        }
    }

    private func fetchBooks() {
        guard let selectedBibleId = selectedBibleId else {
            print("DEBUG: Bible ID is nil.")
            clearLoadingState()
            return
        }

        isLoadingBooks = true
        guard let url = URL(string: "https://api.scripture.api.bible/v1/bibles/\(selectedBibleId)/books") else {
            print("DEBUG: Failed to construct Books URL.")
            clearLoadingState()
            return
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "api-key")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("DEBUG: Error fetching books: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.books = [] // Clear books in case of an error
                    self.isLoadingBooks = false
                    clearLoadingState()
                }
                return
            }

            guard let data = data else {
                print("DEBUG: No data received.")
                DispatchQueue.main.async {
                    self.books = [] // Clear books if no data is received
                    self.isLoadingBooks = false
                    clearLoadingState()
                }
                return
            }

            do {
                // Attempt to decode the response
                let decodedResponse = try JSONDecoder().decode(BookResponse.self, from: data)
                DispatchQueue.main.async {
                    self.books = decodedResponse.data ?? [] // Handle optional `data` field gracefully
                    self.isLoadingBooks = false
                    clearLoadingState()
                }
            } catch {
                print("DEBUG: Failed to decode Books response: \(error.localizedDescription)")
                print("DEBUG: Raw Response - \(String(data: data, encoding: .utf8) ?? "No readable data")")
                DispatchQueue.main.async {
                    self.books = [] // Clear books on decoding failure
                    self.isLoadingBooks = false
                    clearLoadingState()
                }
            }
        }.resume()
    }

}
