import SwiftUI


import SwiftUI

struct JournalDetailView: View {
    @ObservedObject var entry: JournalEntri // Observe the Core Data object directly
    @ObservedObject var manager: JournalEntryManager
    @State private var isEditing = false

    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#0B1E30"), Color(hex: "#1D4038")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    Text(entry.title ?? "Untitled")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    // Date
                    Text(entry.date?.formatted(date: .long, time: .shortened) ?? "")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))

                    Divider()
                        .background(Color.white.opacity(0.5))

                    // Content
                    Text(entry.content ?? "")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)

                    // Questions and Answers
                    if let questionsAndAnswers = entry.questionsAndAnswers as? [String: String] {
                        ForEach(questionsAndAnswers.keys.sorted(), id: \.self) { question in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(question)
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text(questionsAndAnswers[question] ?? "")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(.top, 8)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline) // Keep the title inline
        .navigationBarItems(
            trailing: Button(action: {
                isEditing = true
            }) {
                HStack {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .bold))
                    Text("Edit")
                }
                .foregroundColor(Color(hex: "#D4DDE1"))
            }
        )
        .sheet(isPresented: $isEditing) {
            JournalEditView(entry: entry, manager: manager)
        }
    }
}
