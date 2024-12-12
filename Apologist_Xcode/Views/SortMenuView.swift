//
//  SortMenuView.swift
//  Habit
//
//  Created by Nazarii Zomko on 19.07.2023.
//

import SwiftUI

enum SortingOption: String, CaseIterable, Identifiable {
    var id: Self { self }
    case byDate = "Sort by Date"
    case byName = "Sort by Name"
    
    func localizedString() -> LocalizedStringKey {
        LocalizedStringKey(self.rawValue)
    }
}

struct SortMenuView: View {
    @Binding var selectedSortingOption: SortingOption
    @Binding var isSortingOrderAscending: Bool
    
    var sorting: Binding<SortingOption> {
        .init(
            get: { self.selectedSortingOption },
            set: { newValue in
                withAnimation {
                    if self.selectedSortingOption == newValue {
                        self.isSortingOrderAscending.toggle()
                        self.selectedSortingOption = newValue
                    } else {
                        self.isSortingOrderAscending = false
                        self.selectedSortingOption = newValue
                    }
                }
            }
        )
    }
    
    var body: some View {
        Menu {
            Picker("Sorting", selection: sorting) {
                ForEach(SortingOption.allCases) { sortingOption in
                    HStack {
                        Text(sortingOption.localizedString())
                            .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                        if selectedSortingOption == sortingOption {
                            Image(systemName: isSortingOrderAscending ? "chevron.up" : "chevron.down")
                                .foregroundColor(Color(hex: "#F8C471")) // Star Glow Yellow
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
        }

    }
}

struct OptionsMenuView_Previews: PreviewProvider {
    static var previews: some View {
        SortMenuView(selectedSortingOption: .constant(.byDate), isSortingOrderAscending: .constant(false))
    }
}
