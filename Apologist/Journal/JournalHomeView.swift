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
                VStack(spacing: 24) { // Increased spacing between buttons
                    VStack(spacing: 8) { // Button and explanation spacing
                        NavigationLink(destination: FreewriteView(), tag: "Freewrite", selection: $selectedMode) {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white, lineWidth: 2)
                                .background(Color.clear)
                                .frame(height: 75 * 0.75) // Scaled to 3/4 height
                                .overlay(
                                    Text("Freewrite")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                )
                                .padding(.horizontal, 30) // Added padding to prevent hugging edges
                                .onTapGesture {
                                    selectedMode = "Freewrite"
                                }
                        }

                        Text("Write your thoughts freely, with no structure or prompts.")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    VStack(spacing: 8) { // Button and explanation spacing
                        NavigationLink(destination: GuidedJournalingView(), tag: "Guided", selection: $selectedMode) {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white, lineWidth: 2)
                                .background(Color.clear)
                                .frame(height: 75 * 0.75) // Scaled to 3/4 height
                                .overlay(
                                    Text("Guided Journaling")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                )
                                .padding(.horizontal, 30) // Added padding to prevent hugging edges
                                .onTapGesture {
                                    selectedMode = "Guided"
                                }
                        }

                        Text("Answer specific prompts to reflect on your day or thoughts.")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    VStack(spacing: 8) { // Button and explanation spacing
                        NavigationLink(destination: JournalingHistoryView(), tag: "History", selection: $selectedMode) {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white, lineWidth: 2)
                                .background(Color.clear)
                                .frame(height: 60 * 0.75) // Scaled to 3/4 height
                                .overlay(
                                    Text("Journaling History")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                )
                                .padding(.horizontal, 30) // Added padding to prevent hugging edges
                                .onTapGesture {
                                    selectedMode = "History"
                                }
                        }

                        Text("Review your past journal entries and reflect on your journey.")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }

                // Spacer between navigation buttons and new button
                Spacer().frame(height: 24)

                // Grayed-out Button
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.5)) // Grayed out button
                        .frame(height: 60)
                        .overlay(
                            Text("Advice & Analyze")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .padding(.horizontal, 30)

                    Text("Coming soon!")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
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
