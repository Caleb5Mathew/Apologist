//
//  ColorsPickerView.swift
//  Habit
//
//  Created by Nazarii Zomko on 18.05.2023.
//

import SwiftUI

struct ColorsPickerView: View {
    let colors = HabitColor.allCases
    
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedColor: HabitColor
    
    let gridItemLayout = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: gridItemLayout) {
            ForEach(colors) { color in
                GeometryReader { geo in
                    Circle()
                        .foregroundColor(Color(color))
                        .overlay {
                            if selectedColor == color {
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .foregroundColor(Color(hex: "#F8C471")) // Star Glow Yellow
                                    .frame(width: geo.size.width / 3, height: geo.size.height / 3)
                                    .padding()
                            }
                        }
                        .onTapGesture {
                            self.selectedColor = color
                            HapticController.shared.impact(style: .rigid)
                            dismiss()
                        }
                }
                .aspectRatio(1, contentMode: .fit)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#0B1E30"), Color(hex: "#274E45")]), // Midnight Blue to Soft Pine Green
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
    }
}

struct ColorsPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ColorsPickerView(selectedColor: .constant(.blue))
            .previewLayout(.sizeThatFits)
        
        ColorsPickerView(selectedColor: .constant(.blue))
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
            .previewDisplayName("iPhone 14 Pro Max")
    }
}
