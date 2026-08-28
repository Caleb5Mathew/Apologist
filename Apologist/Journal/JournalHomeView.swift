import SwiftUI

// MARK: - JournalHomeView
struct JournalHomeView: View {
    @State private var selectedMode: String? = nil
    @ObservedObject var manager = JournalEntryManager()
    @State private var journaledDates: [DateComponents] = []

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#0B1E30"), Color(hex: "#1D4038")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 16) {
                // Header Styled Like "Habits"
                HStack {
                    Text("Journaling")
                        .font(.largeTitle.bold())
                        .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                        .padding(.leading, 20) // Move to the right
                    
                    Spacer()

                    // Calendar Icon Button
                    NavigationLink(destination: JournalCalendarView(journaledDates: $journaledDates)) {
                        Image(systemName: "calendar")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "#F8C471")) // Star Glow Yellow
                            .padding()
                    }
                }
                .padding(.top, 16)

                // Divider
                Divider()
                    .background(Color.white.opacity(0.2)) // Line below header
                    .padding(.horizontal)

                // MARK: - Navigation Buttons with Explanations
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        NavigationLink(destination: FreewriteView(), tag: "Freewrite", selection: $selectedMode) {
                            JournalCardButton(
                                icon: "pencil.line",
                                title: "Freewrite"
                            )
                        }
                        .onTapGesture { selectedMode = "Freewrite" }

                        Text("Write your thoughts freely, with no structure or prompts.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 4)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        NavigationLink(destination: GuidedJournalingView(), tag: "Guided", selection: $selectedMode) {
                            JournalCardButton(
                                icon: "list.bullet.rectangle",
                                title: "Guided Journaling"
                            )
                        }
                        .onTapGesture { selectedMode = "Guided" }

                        Text("Answer specific prompts to reflect on your day or thoughts.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 4)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        NavigationLink(destination: JournalingHistoryView(), tag: "History", selection: $selectedMode) {
                            JournalCardButton(
                                icon: "clock.arrow.circlepath",
                                title: "Journaling History"
                            )
                        }
                        .onTapGesture { selectedMode = "History" }

                        Text("Review your past journal entries and reflect on your journey.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 4)
                    }

                    Spacer().frame(height: 16)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "#F8C471").opacity(0.5))
                            Text("Advice & Analyze")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.2))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#132D42").opacity(0.6))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )

                        Text("Coming soon!")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 4)
                    }
                }

                Spacer() // Push everything up
            }
            .padding(.horizontal)
        }
        .navigationBarHidden(true) // Hides the navigation bar
        .onAppear {
            updateJournaledDates()
        }
        .onChange(of: manager.entries) { _ in
            updateJournaledDates() // Automatically refreshes when entries change
        }
    }

    // MARK: - Update Journaled Dates
    private func updateJournaledDates() {
        journaledDates = manager.entries.map { entry in
            Calendar.current.dateComponents([.year, .month, .day], from: entry.date ?? Date())
        }
    }
}

private struct JournalCardButton: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "#F8C471").opacity(0.9))
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            Spacer()
            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(hex: "#132D42"))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
