//
//  TipView.swift
//  Habit
//
//  Created by Nazarii Zomko on 18.07.2023.
//

import SwiftUI

struct TipView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var isExpanded = false
    @State private var isViewShowing = true
    
    var icon: Image?
    var title: LocalizedStringKey
    var tutorialText: LocalizedStringKey
    
    var body: some View {
        if isViewShowing {
            HStack(spacing: 0) {
                VStack(alignment: .leading) {
                    HStack(spacing: 0) {
                        icon
                            .font(.system(size: 19))
                            .foregroundColor(Color(hex: "#F8C471")) // Star Glow Yellow
                            .bold()
                            .padding(.trailing, 6)
                        Text(title)
                            .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                            .font(.callout)
                            .bold()
                    }
                    .padding(.bottom, 1)
                    DisclosureGroup("Tutorial", isExpanded: $isExpanded) {
                        Text(tutorialText)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                    }
                    .font(.subheadline)
                    .tint(Color(hex: "#F8C471")) // Star Glow Yellow for links
                    .padding(.horizontal, 1)

                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(Color(hex: "#1F5F4E")) // Emerald Green for a calm background
            }
            .overlay(alignment: .topTrailing) {
                Image(systemName: "xmark")
                    .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                    .font(.subheadline)
                    .padding(18)
                    .onTapGesture {
                        withAnimation {
                            isViewShowing = false
                        }
                    }
            }
        }
    }
}

struct TipView_Previews: PreviewProvider {
    static var previews: some View {
        TipView(
            icon: Image(systemName: "wave.3.right.circle"),
            title: "Complete habits with NFC tags",
            tutorialText: "**Step 1:** Open the \"Shortcuts\" app → Automation → Press \"+\" Button → Create Personal Automation → NFC \n\n**Step 2:** Scan your NFC Tag \n\n**Step 3:** Add Action → Search for \"Complete a Habit\" shortcut → Press on the \"Habit\" field → Choose from a list of your habits \n\n**Step 4:** Press \"Next\" → Turn off \"Ask Before Running\" → Turn on \"Notify When Run\" (Optional) → Press \"Done\""
        )
        .padding()
    }
}
