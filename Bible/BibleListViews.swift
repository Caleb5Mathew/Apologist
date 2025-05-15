import SwiftUI

struct BibleVersionListView: View {
    let bibles: [Bible]
    @Binding var selectedBibleId: String?
    let onSelect: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Spacer() // Maintain spacing on the left
                Text("Select Bible Version")
                    .font(.custom("Avenir Next", size: 22))
                    .foregroundColor(Color(hex: "#ECEFF4")) // MoonlightWhite
                Spacer() // Maintain spacing on the right
            

            }
            .padding()
            .background(Color(hex: "#0B1E30")) // Deep Midnight Blue
            .navigationBarHidden(true) // Hide the default navigation bar

            // Bible List
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(bibles, id: \.id) { bible in
                        Button(action: {
                            withAnimation {
                                onSelect(bible.id)
                            }
                        }) {
                            HStack {
                                Text(bible.name)
                                    .font(.custom("Avenir Next", size: 18))
                                    .foregroundColor(Color(hex: "#ECEFF4")) // MoonlightWhite
                                    .padding(.vertical, 12)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Color(hex: "#FFD79D")) // StarrySkyYellow

                            }
                            .padding(.horizontal)
                            .background(Color(hex: "#0B1E30")) // Deep Midnight Blue
                        }
                        .overlay(
                            Rectangle()
                                .frame(height: 0.5)
                                .foregroundColor(Color(hex: "#3D426B").opacity(0.8)), // Subtle divider
                            alignment: .bottom
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color(hex: "#0B1E30").edgesIgnoringSafeArea(.all)) // Deep Midnight Blue
    }
}


struct BookListView: View {
    @Binding var books: [Book]
    @Binding var isLoading: Bool
    let onSelect: (Book) -> Void
    let onBack: () -> Void // Closure for handling back button navigation

    var body: some View {
        VStack(spacing: 0) {
            // Header with Back Button
            HStack {
                Button(action: onBack) { // Use the provided onBack closure
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(Color(hex: "#ECEFF4")) // MoonlightWhite
                        .padding(.leading, 25) // Increased padding to move the arrow further to the right

                }
                Spacer()
                Text("Books")
                    .font(.custom("Avenir Next", size: 22))
                    .foregroundColor(Color(hex: "#ECEFF4")) // MoonlightWhite
                    .padding(.leading, -20) // Adjust the value to move it to the left

                Spacer()
            }
            .padding()
            .background(Color(hex: "#0B1E30")) // Deep Midnight Blue

            if isLoading {
                LeftwardLoadingView(message: "Loading Books...")
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(books, id: \.id) { book in
                            Button(action: {
                                withAnimation {
                                    onSelect(book)
                                }
                            }) {
                                HStack {
                                    Text(book.name)
                                        .font(.custom("Avenir Next", size: 18))
                                        .foregroundColor(Color(hex: "#ECEFF4")) // MoonlightWhite
                                        .padding(.vertical, 12)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color(hex: "#FFD79D")) // StarrySkyYellow
                                }
                                .padding(.horizontal)
                                .background(Color(hex: "#0B1E30")) // Deep Midnight Blue
                            }
                            .overlay(
                                Rectangle()
                                    .frame(height: 0.5)
                                    .foregroundColor(Color(hex: "#3D426B").opacity(0.8)), // Subtle divider
                                alignment: .bottom
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .background(Color(hex: "#0B1E30").edgesIgnoringSafeArea(.all)) // Deep Midnight Blue
    }
}


struct LeftwardLoadingView: View {
    let message: String

    var body: some View {
        HStack {
            Spacer()
            Text(message)
                .font(.custom("Avenir Next", size: 18))
                .foregroundColor(Color(hex: "#ECEFF4")) // MoonlightWhite
                .transition(.move(edge: .trailing)) // Leftward animation
                .animation(.easeInOut(duration: 0.6), value: true)
            Spacer()
        }
        .padding()
    }
}


struct ChapterListView: View {
    let book: Book
    let apiKey: String
    let bibleId: String
    let onSelect: (Chapter) -> Void
    let onBack: () -> Void // Closure for handling back button navigation

    @State private var chapters: [Chapter] = []
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            // Header with Back Button
            HStack {
                Button(action: onBack) { // Use the provided onBack closure
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(Color(hex: "#ECEFF4")) // MoonlightWhite
                        .padding(.leading, 25) // Increased padding to move the arrow further to the right

                }
                Spacer()
                Text("\(book.name) - Chapters")
                    .font(.custom("Avenir Next", size: 22))
                    .foregroundColor(Color(hex: "#ECEFF4")) // MoonlightWhite
                Spacer()
            }
            .padding()
            .background(Color(hex: "#0B1E30")) // Deep Midnight Blue

            if isLoading {
                LeftwardLoadingView(message: "Loading Chapters...")
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(chapters, id: \.id) { chapter in
                            Button(action: {
                                withAnimation {
                                    onSelect(chapter)
                                }
                            }) {
                                HStack {
                                    Text("Chapter \(chapter.number)")
                                        .font(.custom("Avenir Next", size: 18))
                                        .foregroundColor(Color(hex: "#ECEFF4")) // MoonlightWhite
                                        .padding(.vertical, 12)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color(hex: "#FFD79D")) // StarrySkyYellow
                                }
                                .padding(.horizontal)
                                .background(Color(hex: "#0B1E30")) // Deep Midnight Blue
                            }
                            .overlay(
                                Rectangle()
                                    .frame(height: 0.5)
                                    .foregroundColor(Color(hex: "#3D426B").opacity(0.8)), // Subtle divider
                                alignment: .bottom
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .onAppear {
            fetchChapters()
        }
        .background(Color(hex: "#0B1E30").edgesIgnoringSafeArea(.all)) // Deep Midnight Blue
    }

    private func fetchChapters() {
        guard let url = URL(string: "https://api.scripture.api.bible/v1/bibles/\(bibleId)/books/\(book.id)/chapters") else {
            print("Failed to construct URL for Chapters.")
            return
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "api-key")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching chapters: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data received.")
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(ChapterResponse.self, from: data)
                DispatchQueue.main.async {
                    self.chapters = decodedResponse.data
                    self.isLoading = false
                }
            } catch {
                print("Failed to decode chapters: \(error.localizedDescription)")
            }
        }.resume()
    }
}
