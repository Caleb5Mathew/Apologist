//
//  Habit+Utils.swift
//  Habit
//
//  Created by Nazarii Zomko on 28.07.2023.
//

import Foundation

extension Habit {
    // The number of days to look back when calculating the habit's strength percentage, aiming for 100%.
    // This value defines the time period within which completed dates are considered for strength calculation.
    var strengthCalculationPeriod: Int { 60 }
    
    var strengthPercentage: Int {
        calculateStrengthPercentage(completedDates: completedDates)
    }
    
    var streak: Int {
        let dates = processDatesForStreakCalculation(completedDates)
        // Check if there are any completed dates
        guard let firstDate = dates.first else { return 0 }
        // If the most recent completion date is not today, there's no current streak
        guard firstDate.isInSameDay(as: Date()) else { return 0 }
        
        var previousDate = firstDate
        
        var streak = 1

        for date in dates.dropFirst() {
            let daysBetweenDates = previousDate.days(from: date)
            if daysBetweenDates <= 1 {
                streak += 1
            } else {
                return streak
            }
            previousDate = date
        }
        return streak
    }
    
    var longestStreak: Int {
        let dates = processDatesForStreakCalculation(completedDates)
        // Check if there are any completed dates
        guard let firstDate = dates.first else { return 0 }
        
        var previousDate = firstDate

        var currentStreak = 1
        var longestStreak = 0
         
        for date in dates.dropFirst() {
            let daysBetweenDates = previousDate.days(from: date)
            if daysBetweenDates <= 1 {
                currentStreak += 1
            } else {
                // Check if the current streak is longer than the longest streak so far
                longestStreak = max(currentStreak, longestStreak)
                currentStreak = 1
            }
            previousDate = date
        }
        // Check if the last streak is the longest streak
        return max(currentStreak, longestStreak)
    }
    
    func processDatesForStreakCalculation(_ dates: [Date]) -> [Date] {
        let dates = dates.map { Calendar.current.startOfDay(for: $0) }
        // Filter dates without days after today
        let datesWithoutDaysAfterToday = dates.filter { $0 <= Date.now }
        // Remove duplicates
        let uniqueDatesWithinPeriod = datesWithoutDaysAfterToday.removingDuplicates()
        // Sort from newest to oldest
        let sortedDates = uniqueDatesWithinPeriod.sorted { $0 > $1 }
        return sortedDates
    }

    func isCompleted(for date: Date) -> Bool {
        completedDates.contains { Calendar.current.isDate($0, inSameDayAs: date) }
    }
    
    func isCompleted(daysAgo: Int) -> Bool {
        isCompleted(for: Date.todayMinusDaysAgo(daysAgo: daysAgo))
    }
    
    /// Adds a date to the list of completed dates for the habit.
    ///
    /// - Parameter date: The date to add.
    func addCompletedDate(_ date: Date) {
        if !self.isCompleted(for: date) {
            self.completedDates.append(date)
        }
    }
    
    /// Removes a date from the list of completed dates for the habit.
    ///
    /// - Parameter date: The date to remove.
    func removeCompletedDate(_ date: Date) {
        self.completedDates.removeAll(where: { $0.isInSameDay(as: date) } )
    }
    
    func toggleCompletion(daysAgo: Int) {
        let todayMinusDaysAgo = Date.todayMinusDaysAgo(daysAgo: daysAgo)
        self.isCompleted(daysAgo: daysAgo) ? self.removeCompletedDate(todayMinusDaysAgo) : self.addCompletedDate(todayMinusDaysAgo)
    }
    
    
    // TODO: Calculate percentage from 0 to 1 instead of 0 to 100
    /// The strength percentage of the habit.
    ///
    /// Represents the strength percentage of the habit based on the number of completed dates. The calculation is performed using a logarithmic formula.
    /// - Returns: An integer representing the strength percentage of the habit, ranging from 0 to 100.
    func calculateStrengthPercentage(completedDates: [Date]) -> Int {
        let startDate = Calendar.current.startOfDay(for: creationDate)
        let today = Calendar.current.startOfDay(for: Date())

        let totalDaysSinceCreation = Calendar.current.dateComponents([.day], from: startDate, to: today).day ?? 0

        guard totalDaysSinceCreation > 0 else { return 50 }

        let regularityMultiplier: Double
        switch regularity?.lowercased() {
        case "everyday":
            regularityMultiplier = 7.0 / 7.0
        case "6 times a week":
            regularityMultiplier = 6.0 / 7.0
        case "5 times a week":
            regularityMultiplier = 5.0 / 7.0
        case "4 times a week":
            regularityMultiplier = 4.0 / 7.0
        case "3 times a week":
            regularityMultiplier = 3.0 / 7.0
        case "2 times a week":
            regularityMultiplier = 2.0 / 7.0
        case "once a week":
            regularityMultiplier = 1.0 / 7.0
        default:
            regularityMultiplier = 1.0
        }

        let expectedCompletions = Double(totalDaysSinceCreation) * regularityMultiplier

        let uniqueCompletedDates = completedDates.map { Calendar.current.startOfDay(for: $0) }
            .removingDuplicates()

        let habitPercentage = (Double(uniqueCompletedDates.count) / expectedCompletions) * 100

        // Cap the percentage at 100
        return min(Int(habitPercentage), 100)
    }






    
    func calculateLogarithmBase(value: Double, result: Double) -> Double {
        return pow(value, 1/result)
    }
    
    func strengthGainedWithinLastDays(daysAgo: Int) -> Int {
        let habitStrength = calculateStrengthPercentage(completedDates: completedDates)
        let completedDatesWithoutLast30Days = completedDates.filter { $0.isWithinLastDays(daysAgo: daysAgo) == false }
        let habitStrengthWithoutLast30Days = calculateStrengthPercentage(completedDates: completedDatesWithoutLast30Days)
        let strengthGainedInMonth = habitStrength - habitStrengthWithoutLast30Days
        return strengthGainedInMonth
    }
    
    func completionsWithinLastDays(daysAgo: Int) -> Int {
        completedDates.filter { $0.isWithinLastDays(daysAgo: daysAgo) }.count
    }
}
