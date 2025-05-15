import SwiftUI

// MARK: - JournalHomeView
struct JournalHomeView: View {
    @State private var selectedMode: String? = nil
    @ObservedObject var manager = JournalEntryManager()
    @State private var journaledDates: [DateComponents] = []

    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#0B1E30"), Color(hex: "#1D4038")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    // HEADER
                    HStack {
                        Text("Journaling")
                            .font(.largeTitle.bold())
                            .foregroundColor(Color(hex: "#D4DDE1"))
                            .padding(.leading, 20)

                        Spacer()

                        // Calendar Icon Button
                        NavigationLink(destination: JournalCalendarView(journaledDates: $journaledDates)) {
                            Image(systemName: "calendar")
                                .font(.system(size: 24))
                                .foregroundColor(Color(hex: "#F8C471"))
                                .padding()
                        }
                    }
                    .padding(.top, 10)

                    // Divider
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.horizontal)

                    // MARK: - Journal Navigation Buttons
                    VStack(spacing: 24) {
                        // ✅ Freewrite FIX: Uses direct NavigationLink
                        NavigationLink(destination: FreewriteView()) {
                            JournalButton(title: "Freewrite", description: "Write your thoughts freely, with no structure or prompts.")
                        }

                        Button(action: { selectedMode = "Guided" }) {
                            JournalButton(title: "Guided Journaling", description: "Answer specific prompts to reflect on your day or thoughts.")
                        }
                        .navigationDestination(isPresented: Binding(
                            get: { selectedMode == "Guided" },
                            set: { if !$0 { selectedMode = nil } }
                        )) {
                            GuidedJournalingView()
                        }

                        Button(action: { selectedMode = "History" }) {
                            JournalButton(title: "Journaling History", description: "Review your past journal entries and reflect on your journey.")
                        }
                        .navigationDestination(isPresented: Binding(
                            get: { selectedMode == "History" },
                            set: { if !$0 { selectedMode = nil } }
                        )) {
                            JournalingHistoryView()
                        }
                    }

                    Spacer().frame(height: 24)

                    // Disabled Feature Button
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.5))
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

                    Spacer()
                }
                .padding(.horizontal)
            }

            .onAppear {
                DispatchQueue.main.async {
                    selectedMode = nil
                    updateJournaledDates()
                    
                    // Force a small re-layout adjustment
                    withAnimation {
                        UIApplication.shared.windows.first?.rootViewController?.view.setNeedsLayout()
                    }
                }
            }

            .onChange(of: manager.entries) { _ in
                updateJournaledDates()
            }
        }
    }

    // MARK: - Update Journaled Dates
    private func updateJournaledDates() {
        journaledDates = manager.entries.map { entry in
            Calendar.current.dateComponents([.year, .month, .day], from: entry.date ?? Date())
        }
    }
}

// MARK: - Journal Button Component
struct JournalButton: View {
    var title: String
    var description: String

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white, lineWidth: 2)
                .background(Color.clear)
                .frame(height: 75 * 0.75)
                .overlay(
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                )
                .padding(.horizontal, 30)

            Text(description)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
