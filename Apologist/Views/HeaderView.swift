//
//  HeaderView.swift
//  Habit
//
//  Created by Nazarii Zomko on 19.05.2023.
//
//
//  HeaderView.swift
//  Habit
//
//  Created by Nazarii Zomko on 19.05.2023.
//

import SwiftUI

struct HeaderView: View {
    var onAddHabit: () -> Void
    var onSortOptionChanged: (SortingOption, Bool) -> Void

    @State private var selectedSortingOption: SortingOption = .byDate
    @State private var isSortingOrderAscending: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            
            // Row 1: "Habits" Title and Week Days
            HStack {
                
                Text("Habits")
                    .font(.largeTitle.bold())
                    .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                    .padding(.leading, 8)
                Spacer()
                HStack(spacing: 0) {
                    ForEach(0..<7) { number in
                        let daysAgo = abs(number - 6) // Reverse order
                        let dayInfo = getDayInfo(daysAgo: daysAgo)

                        VStack(spacing: 0) {
                            Text("\(dayInfo.dayNumber)")
                                .foregroundColor(daysAgo == 0 ? Color(hex: "#F8C471") : Color(hex: "#D4DDE1")) // Highlight today
                            Text("\(dayInfo.dayName)")
                                .foregroundColor(daysAgo == 0 ? Color(hex: "#F8C471") : Color(hex: "#D4DDE1")) // Highlight today
                        }
                        .frame(width: Constants.dayOfTheWeekFrameSize, height: Constants.dayOfTheWeekFrameSize)
                        .font(.system(size: 11, weight: .bold))
                        .opacity(daysAgo == 0 ? 1 : 0.5)
                    }
                }
                .padding(.trailing, 10)
            }
            .padding([.top, .leading, .trailing])
            .padding(.bottom, 8)

            Divider()
                .background(Color.white.opacity(0.08))
            HStack {
                Spacer()
                Text("WEEKLY PROGRESS")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .kerning(1.2)
                    .foregroundColor(Color(hex: "#F8C471"))
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding([.leading, .trailing], 8)
            .padding(.bottom, 8)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#0B1E30"), Color(hex: "#14283A")]), // Same gradient as the background
                startPoint: .top,
                endPoint: .bottom
            )//the background of habits gradient
            .ignoresSafeArea(edges: .top) // Ensure it covers the top
        )
    }

    func getDayInfo(daysAgo: Int) -> (dayNumber: String, dayName: String) {
        let today = Date.now
        let todayMinusDaysAgo = Calendar.current.date(byAdding: .day, value: -daysAgo, to: today) ?? today

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEEEE"
        let dayName = dateFormatter.string(from: todayMinusDaysAgo)

        dateFormatter.dateFormat = "d"
        let dayNumber = dateFormatter.string(from: todayMinusDaysAgo)

        return (dayNumber: dayNumber, dayName: dayName)
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView(
            onAddHabit: { print("Add Habit Action Triggered") },
            onSortOptionChanged: { newSort, isAscending in
                print("Sorting Changed: \(newSort.rawValue), Ascending: \(isAscending)")
            }
        )
        .previewLayout(.sizeThatFits)
    }
}
