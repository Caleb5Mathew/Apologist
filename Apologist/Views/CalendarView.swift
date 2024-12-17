//
//  CalendarView.swift
//  Habit
//
//  Created by Nazarii Zomko on 21.07.2023.
//

import SwiftUI

struct CalendarView: UIViewRepresentable {
    let dateInterval: DateInterval
    @Binding var completedDates: [DateComponents]
    var color: HabitColor
    
    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.tintColor = UIColor(Color(hex: "#1F5F4E")) // Emerald Green for general tint
        calendarView.calendar = Calendar(identifier: .gregorian)
        calendarView.availableDateRange = dateInterval
        
        let dateSelection = UICalendarSelectionMultiDate(delegate: context.coordinator)
        dateSelection.setSelectedDates(completedDates, animated: true)
        calendarView.selectionBehavior = dateSelection
        
        // Apply custom styling to match the Midnight Forest theme
        calendarView.backgroundColor = UIColor(Color(hex: "#1E1E1E")) // Deep Midnight Blue background
        calendarView.layer.cornerRadius = 12
        calendarView.layer.masksToBounds = true
        
        return calendarView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, completedDates: $completedDates, color: color)
    }
    
    func updateUIView(_ uiView: UICalendarView, context: Context) {
        let dateSelection = UICalendarSelectionMultiDate(delegate: context.coordinator)
        dateSelection.setSelectedDates(completedDates, animated: true)
        uiView.selectionBehavior = dateSelection
        
        uiView.tintColor = UIColor(Color(hex: "#1F5F4E")) // Ensure consistent tint color
    }
    
    class Coordinator: NSObject, UICalendarSelectionMultiDateDelegate {
        var parent: CalendarView
        @Binding var completedDates: [DateComponents]
        var color: HabitColor
        
        init(parent: CalendarView, completedDates: Binding<[DateComponents]>, color: HabitColor) {
            self.parent = parent
            self._completedDates = completedDates
            self.color = color
        }
        
        func multiDateSelection(_ selection: UICalendarSelectionMultiDate, didSelectDate dateComponents: DateComponents) {
            completedDates.append(dateComponents)
        }
        
        func multiDateSelection(_ selection: UICalendarSelectionMultiDate, didDeselectDate dateComponents: DateComponents) {
            completedDates.removeAll(where: { $0.isInSameDay(as: dateComponents) } )
        }
        
        func multiDateSelection(_ selection: UICalendarSelectionMultiDate, canSelectDate dateComponents: DateComponents) -> Bool {
            return true
        }
    }
}
