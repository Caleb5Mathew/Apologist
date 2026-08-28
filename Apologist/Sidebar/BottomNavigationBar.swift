import SwiftUI

import SwiftUI

struct BottomNavigationBar: View {
    @Binding var selectedTab: Int

    private let accentGold = Color(hex: "#F8C471")

    let icons = [
        (title: "Habits", icon: "checkmark.circle", index: 0),
        (title: "Questions", icon: "questionmark.circle", index: 1),
        (title: "Journal", icon: "book", index: 2),
        (title: "Bible", icon: "cross", index: 4)
    ]

    var body: some View {
        HStack {
            ForEach(icons, id: \.index) { item in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = item.index
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .font(.system(size: 22, weight: selectedTab == item.index ? .medium : .regular))
                            .foregroundColor(selectedTab == item.index ? accentGold : Color.gray)
                        Text(item.title)
                            .font(.caption)
                            .foregroundColor(selectedTab == item.index ? accentGold : Color.gray)
                        if selectedTab == item.index {
                            Circle()
                                .fill(accentGold)
                                .frame(width: 4, height: 4)
                        } else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 4, height: 4)
                        }
                    }
                    .padding(.vertical, 10)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(hex: "#0B1E30"))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1),
            alignment: .top
        )
        .edgesIgnoringSafeArea(.bottom)
    }
}
