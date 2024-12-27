
import SwiftUI
struct JournalDetailView: View {
    let entry: JournalEntri // Use the Core Data entity name

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
                    Text(entry.title ?? "Untitled")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Text(entry.date?.formatted(date: .long, time: .shortened) ?? "")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))

                    Divider()
                        .background(Color.white.opacity(0.5))

                    Text(entry.content ?? "")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                }
                .padding()
            }
        }
    }
}
