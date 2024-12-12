//
//  ChartView.swift
//  Habit
//
//  Created by Nazarii Zomko on 25.06.2023.
//

import SwiftUI

struct ChartView: View {
    enum DisplayModes: String, Identifiable, CaseIterable {
        var id: Self { self }
        case sixMonths = "Six months"
        case oneYear = "One year"
        
        func localizedString() -> LocalizedStringKey {
            LocalizedStringKey(self.rawValue)
        }
    }
    
    // TODO: make it a Binding
    var dates: [Date]
    var color: HabitColor = .green
    
    @AppStorage("displayMode") private var displayMode: DisplayModes = .sixMonths

    private let rows: Int = 7
    private var columns: Int { getNumberOfColumns() }
    private var spacing: CGFloat { getSpacing() }
    private var cornerRadius: CGFloat { getCornerRadius() }
    private var strokeWidth: CGFloat { getStrokeWidth() }
    
    var body: some View {
        VStack {
            HStack {
                Text("HISTORY")
                    .font(.caption.bold())
                    .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                Spacer()
                Picker("Display mode", selection: $displayMode) {
                    ForEach(DisplayModes.allCases) {
                        Text($0.localizedString())
                            .foregroundColor(Color(hex: "#F8C471")) // Star Glow Yellow
                    }
                }
                .offset(x: 12)
                .pickerStyle(.menu)
                .tint(Color(hex: "#D4DDE1")) // Moonlight Silver
            }
            HStack(spacing: spacing) {
                ForEach(0..<columns, id: \.self) { column in
                    VStack(spacing: spacing) {
                        ForEach(0..<rows, id: \.self) { row in
                            let index = getIndexForCell(column: column, row: row)
                                                    
                            let daysShiftOffset = calculateDaysShiftOffset()
                            let shiftedIndex = index - daysShiftOffset
                            
                            let color = getColorForCell(index: shiftedIndex)
                            
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(color.fill)
                                .aspectRatio(1.0, contentMode: .fit)
                        }
                    }
                }
            }
        }
        .onChange(of: displayMode, perform: { _ in
            HapticController.shared.impact(style: .light)
        })
        .accessibilityHidden(true)
    }
    
    func getColorForCell(index: Int) -> (fill: Color, stroke: Color) {
        let date = getDateForCell(numberOfDaysAgo: index)
        
        if isDayAfterToday(date: date) {
            return (fill: .clear, stroke: .clear)
        } else {
            if isDateCompleted(date) {
                return (fill: Color(hex: "#1F5F4E"), stroke: Color(hex: "#274E45")) // Emerald Green and Soft Pine Green
            } else {
                return (fill: Color(hex: "#2F726A").opacity(0.3), stroke: Color(hex: "#274E45")) // Misty Teal (low opacity) and Soft Pine Green
            }
        }
    }
    
    func isDayAfterToday(date: Date) -> Bool {
        let result = Calendar.current.compare(Date.now, to: date, toGranularity: .day)
        return result == .orderedAscending ? true : false
    }
    
    func getDateForCell(numberOfDaysAgo: Int) -> Date {
        let today = Date.now
        let todayMinusDaysAgo = Calendar.current.date(byAdding: .day, value: -numberOfDaysAgo, to: today)!
        return todayMinusDaysAgo
    }
    
    func calculateDaysShiftOffset() -> Int {
        guard rows == 7 else { return 0 }
        
        let today = Date.now
        let nextSunday = today.next(.sunday)
        let offset = nextSunday.days(from: today)
        
        return offset
    }
    
    func getIndexForCell(column: Int, row: Int) -> Int {
        let index = (rows * column) + row
        let cellCount = columns * rows
        let reverseIndex = abs(index - cellCount) - 1
        return reverseIndex
    }

    func isDateCompleted(_ habitDate: Date) -> Bool {
        return dates.contains { date in
            date.isInSameDay(as: habitDate)
        }
    }
    
    func getNumberOfColumns() -> Int {
        switch displayMode {
        case .sixMonths:
            return Int(365/2/rows)
        case .oneYear:
            return Int(365/rows)
        }
    }
    
    func getSpacing() -> CGFloat {
        switch displayMode {
        case .sixMonths:
            return 2.5
        case .oneYear:
            return 1
        }
    }
    
    func getCornerRadius() -> CGFloat {
        switch displayMode {
        case .sixMonths:
            return 2
        case .oneYear:
            return 2
        }
    }
    
    func getStrokeWidth() -> CGFloat {
        switch displayMode {
        case .sixMonths:
            return 1
        case .oneYear:
            return 0.2
        }
    }
}

struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        let habit = Habit.example
        ChartView(dates: habit.completedDates, color: habit.color)
    }
}
