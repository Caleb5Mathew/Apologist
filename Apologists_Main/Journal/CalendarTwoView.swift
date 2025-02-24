//
//  CalendarTwoView.swift
//  Apologist
//
//  Created by user940225 on 1/17/25.
//

import SwiftUI

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

        calendarView.backgroundColor = .clear
        calendarView.tintColor = UIColor(tintColor)

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
            completedDates.removeAll(where: { $0.isEqualTo(dateComponents) })
        }
    }
}

struct JournalCalendarView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var journaledDates: [DateComponents]
    @State private var showExplanation: Bool = false
    @State private var percentage: Double = 0.0 // Track percentage
    private let sixMonthDates = calculateLastSixMonths()

    var body: some View {
        VStack {
            // Custom Header with Chevron and Question Mark
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.leading)
                }

                Text("Journaled Days")
                    .font(.title.bold())
                    .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.trailing, -5) // Adjusted for perfect centering

                Spacer()

                Button(action: {
                    withAnimation {
                        showExplanation.toggle()
                    }
                }) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.trailing)
                }
            }
            .padding(.top)

            // Main Content
            ScrollView {
                VStack(spacing: 20) {
                    // Explanation Text (Toggled Above the Calendar)
                    if showExplanation {
                        Text("This calendar displays the days you journaled over the past year. Selected dates are highlighted.")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .transition(.opacity)
                    }

                    // Calendar View
                    CalendarViewTwo(
                        dateInterval: DateInterval(start: Calendar.current.date(byAdding: .year, value: -1, to: Date())!, end: Date()),
                        completedDates: $journaledDates,
                        tintColor: Color(hex: "#F8C471") // Star Glow Yellow
                    )
                    .frame(height: 370)
                    .padding(.horizontal)
                    .padding(.top, 10)

                    // Journal Percentage and 6-Month Progress
                    VStack(alignment: .center, spacing: 30) {
                        // Journaled Days Percentage
                        VStack(spacing: 10) {
                            Text("Days Journaled in the past 6 months")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Text("\(String(format: "%.1f", percentage))%")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(Color(hex: "#F8C471"))
                        }

                        Spacer().frame(height: 0)

                        // Six-Month Progress Section
                        Text("6-Month Progress")
                            .font(.headline)
                            .foregroundColor(.white)

                        ProgressGridView(journaledDates: $journaledDates)
                            .padding(.horizontal)
                    }
                    .padding(.top, 30)
                }
                .padding(.bottom, 20)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#0B1E30"), Color(hex: "#1D4038")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
        )
        .navigationBarBackButtonHidden(true)
        .onAppear {
            cleanJournaledDates()
            updatePercentage()
        }
        .onChange(of: journaledDates) { _ in
            cleanJournaledDates()
            updatePercentage()
        }
    }

    private func updatePercentage() {
        let journaledDays = journaledDates.filter { date in
            sixMonthDates.contains(where: { $0.isEqualTo(date) })
        }.count
        let calculatedPercentage = sixMonthDates.count > 0 ? Double(journaledDays) / Double(sixMonthDates.count) * 100 : 0.0
        percentage = calculatedPercentage

        // Debugging Logs
        print("Total Days: \(sixMonthDates.count), Journaled Days: \(journaledDays), Percentage: \(percentage)")
    }

    private func cleanJournaledDates() {
        // Filter and deduplicate journaledDates
        journaledDates = journaledDates.filter { date in
            sixMonthDates.contains(where: { $0.isEqualTo(date) })
        }.removingDuplicates()
    }

    private static func calculateLastSixMonths() -> [DateComponents] {
        var dates: [DateComponents] = []
        let calendar = Calendar.current
        var currentDate = calendar.date(byAdding: .month, value: -6, to: Date())!

        while currentDate <= Date() {
            dates.append(calendar.dateComponents([.year, .month, .day], from: currentDate))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return dates
    }
}

// MARK: - Remove Duplicates Extension
extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}






// MARK: - Progress Grid View
struct ProgressGridView: View {
    @Binding var journaledDates: [DateComponents]

    private let columns = 30 // Number of columns for the grid (30 days in a row)

    var body: some View {
        let sixMonthDates = Array(calculateLastSixMonths().reversed()) // Convert to array
        let totalCells = (sixMonthDates.count + columns - 1) / columns * columns // Total cells (full rows)

        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: columns), spacing: 2) {
            ForEach(0..<totalCells, id: \.self) { cellIndex in
                if cellIndex < sixMonthDates.count {
                    let date = sixMonthDates[cellIndex]
                    let isJournaled = journaledDates.contains(where: { $0.isEqualTo(date) })

                    RoundedRectangle(cornerRadius: 2)
                        .fill(isJournaled ? Color(hex: "#F8C471") : Color(hex: "#0B1E30"))
                        .frame(width: 10, height: 10)
                } else {
                    // Empty cells for padding
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "#0B1E30"))
                        .frame(width: 10, height: 10)
                }
            }
        }
        .padding(.horizontal)
    }

    private func calculateLastSixMonths() -> [DateComponents] {
        var dates: [DateComponents] = []
        let calendar = Calendar.current
        var currentDate = calendar.date(byAdding: .month, value: -6, to: Date())!

        while currentDate <= Date() {
            dates.append(calendar.dateComponents([.year, .month, .day], from: currentDate))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return dates
    }
}

// MARK: - Extension for Date Comparison
extension DateComponents {
    func isEqualTo(_ other: DateComponents) -> Bool {
        guard let selfDate = Calendar.current.date(from: self),
              let otherDate = Calendar.current.date(from: other) else {
            return false
        }
        return Calendar.current.isDate(selfDate, inSameDayAs: otherDate)
    }
}
