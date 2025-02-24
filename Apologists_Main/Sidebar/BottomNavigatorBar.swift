//
//  BottomNavigatorBar.swift
//  Apologist
//
//  Created by user940225 on 1/17/25.
//
import SwiftUI

import SwiftUI

struct BottomNavigationBar: View {
    @Binding var selectedTab: Int // Binding to track the selected tab

    // Correctly map icons to their intended indices
    let icons = [
        (title: "Habits", icon: "checkmark.circle", index: 0), // Habits
        (title: "Questions", icon: "questionmark.circle", index: 1), // Questions
        (title: "Journal", icon: "book", index: 2), // Journal
        (title: "Bible", icon: "cross", index: 4) // Bible (skip index 3 to match the BibleView case)
    ]

    var body: some View {
        HStack {
            ForEach(icons, id: \.index) { item in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) { // Smooth animation
                        selectedTab = item.index
                    }
                }) {
                    VStack {
                        Image(systemName: item.icon)
                            .font(.system(size: 24))
                            .foregroundColor(selectedTab == item.index ? .white : Color.gray)
                        Text(item.title)
                            .font(.caption)
                            .foregroundColor(selectedTab == item.index ? .white : Color.gray)
                    }
                    .padding(.vertical, 10)
                }
                .frame(maxWidth: .infinity) // Ensure equal spacing
            }
        }
        .background(Color(hex: "#0B1E30")) // Full-width dark blue background
        .edgesIgnoringSafeArea(.bottom) // Extend the bar across the entire screen width
    }
}
