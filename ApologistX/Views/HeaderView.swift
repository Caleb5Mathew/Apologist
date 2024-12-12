//
//  HeaderView.swift
//  Habit
//
//  Created by Nazarii Zomko on 19.05.2023.
//

import SwiftUI

struct HeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Habits")
                    .font(.largeTitle.bold())
                    .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                    .padding(.leading, 8)
                Spacer()
                HStack(spacing: 0) {
                    ForEach(0..<7) { number in
                        let daysAgo = abs(number - 6) // reverse order
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
            .padding(.bottom, 4)
            .accessibilityHidden(true)
            
            Divider()
                .background(Color(hex: "#2F726A")) // Misty Teal for divider

            Text("WEEKLY PROGRESS")
                .font(.system(size: 14, weight: .bold))
                .kerning(1.5)
                .foregroundColor(Color(hex: "#F8C471")) // Star Glow Yellow
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#0B1E30"), Color(hex: "#274E45")]), // Same gradient as the background
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top) // Ensure it covers the top
        )
        .toolbarBackground(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#0B1E30"), Color(hex: "#274E45")]), // Same gradient as the background
                startPoint: .top,
                endPoint: .bottom
            ),
            for: .navigationBar
        )
        .toolbarColorScheme(.dark, for: .navigationBar) // Ensure it matches the dark mode theme
    }
    
    func getDayInfo(daysAgo: Int) -> (dayNumber: String, dayName: String) {
        let today = Date.now
        let todayMinusDaysAgo = Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!
        
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
        HeaderView()
            .previewLayout(.sizeThatFits)
    }
}
