import SwiftUI

// MARK: - CalendarViewTwo (Marks Journaled Days)
struct CalendarViewTwo: UIViewRepresentable {
    let dateInterval: DateInterval
    @Binding var completedDates: [DateComponents]
    var tintColor: Color

    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.calendar = Calendar(identifier: .gregorian)
        calendarView.availableDateRange = dateInterval

        let dateSelection = UICalendarSelectionMultiDate(delegate: context.coordinator)
        dateSelection.setSelectedDates(completedDates, animated: true)
        calendarView.selectionBehavior = dateSelection

        // Styling for a white calendar with rounded corners
        calendarView.backgroundColor = .clear
        calendarView.tintColor = UIColor(tintColor)

        calendarView.layer.cornerRadius = 12
        calendarView.layer.masksToBounds = true
        calendarView.layer.shadowColor = UIColor.black.cgColor
        calendarView.layer.shadowOpacity = 0.2
        calendarView.layer.shadowRadius = 5
        calendarView.layer.shadowOffset = CGSize(width: 0, height: 4)

        return calendarView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, completedDates: $completedDates)
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {
        let dateSelection = UICalendarSelectionMultiDate(delegate: context.coordinator)
        dateSelection.setSelectedDates(completedDates, animated: true)
        uiView.selectionBehavior = dateSelection
        uiView.tintColor = UIColor(tintColor)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, UICalendarSelectionMultiDateDelegate {
        var parent: CalendarViewTwo
        @Binding var completedDates: [DateComponents]

        init(parent: CalendarViewTwo, completedDates: Binding<[DateComponents]>) {
            self.parent = parent
            self._completedDates = completedDates
        }

        func multiDateSelection(_ selection: UICalendarSelectionMultiDate, didSelectDate dateComponents: DateComponents) {
            completedDates.append(dateComponents)
        }

        func multiDateSelection(_ selection: UICalendarSelectionMultiDate, didDeselectDate dateComponents: DateComponents) {
            completedDates.removeAll(where: { $0.isSameDayAs(dateComponents) })
        }
    }
}

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
                }
                .padding(.top, 16)

                // Divider
                Divider()
                    .background(Color.white.opacity(0.2)) // Line below header
                    .padding(.horizontal)

                // MARK: - Navigation Buttons
                VStack(spacing: 12) {
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
                }

                // MARK: - Progress Text
                Spacer().frame(height: 16) // Added to move progress text down slightly
                Text("JOURNALING PROGRESS")
                    .font(.system(size: 14, weight: .bold))
                    .kerning(1.5)
                    .foregroundColor(Color(hex: "#F8C471")) // Star Glow Yellow
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 16) // Push the calendar down below the progress text

                // MARK: - Calendar View
                CalendarViewTwo(
                    dateInterval: DateInterval(start: Calendar.current.date(byAdding: .year, value: -1, to: Date())!, end: Date()),
                    completedDates: $journaledDates,
                    tintColor: Color.white // White Calendar
                )
                .frame(height: 180) // Smaller calendar size
                .scaleEffect(0.9) // Reduced scale
                .padding(.top, 40) // Move calendar further down
                .onAppear {
                    updateJournaledDates()
                }

                Spacer()
            }
            .padding(.horizontal)
        }
        .navigationBarHidden(true) // Hides the navigation bar
    }

    // MARK: - Update Journaled Dates
    private func updateJournaledDates() {
        journaledDates = manager.entries.map { entry in
            Calendar.current.dateComponents([.year, .month, .day], from: entry.date ?? Date())
        }
    }
}

// MARK: - Extension for Date Comparison
extension DateComponents {
    func isSameDayAs(_ other: DateComponents) -> Bool {
        guard let selfDate = Calendar.current.date(from: self),
              let otherDate = Calendar.current.date(from: other) else {
            return false
        }
        return Calendar.current.isDate(selfDate, inSameDayAs: otherDate)
    }
}
