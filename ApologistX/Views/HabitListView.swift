//
//  HabitListView.swift
//  Habit
//
//  Created by Nazarii Zomko on 30.07.2023.
//
//
//  HabitListView.swift
//  Habit
//
//  Created by Nazarii Zomko on 30.07.2023.
//

import CoreData
import SwiftUI

struct HabitListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isSuggestedHabitVisible = true

    @EnvironmentObject var dataController: DataController
    
    @FetchRequest var habits: FetchedResults<Habit>
    
    init(sortingOption: SortingOption, isSortingOrderAscending: Bool) {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        
        switch sortingOption {
        case .byDate:
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Habit.creationDate_, ascending: isSortingOrderAscending)]
        case .byName:
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Habit.title_, ascending: isSortingOrderAscending)]
        }
        
        _habits = FetchRequest<Habit>(fetchRequest: request)
    }
    
    var body: some View {
        ZStack {
            // Gradient background for the light green area (vertical)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#274E45"), // Starting green (top)
                    Color(hex: "#2F726A")  // Slightly lighter green (bottom)
                ]),
                startPoint: .top,
                endPoint: .bottom // Vertical gradient
            )
            .ignoresSafeArea()
            
            List {
                // List of existing habits
                ForEach(habits) { habit in
                    HabitRowView(habit: habit)
                        .listRowBackground(Color.clear) // Keep background clear
                        .padding(8)
                }
                .onDelete(perform: deleteItems)
                .listRowSeparator(.hidden)
                .buttonStyle(.plain)
                .listRowInsets(.init(top: 8, leading: 16, bottom: 6, trailing: 16))

                // Suggested Habit
                if isSuggestedHabitVisible {
                    SuggestedHabitRowView(
                        title: "Read Bible for 15 mins a day",
                        isVisible: $isSuggestedHabitVisible,
                        onCreate: createSuggestedHabit
                    )
                    .padding(.horizontal)
                    .listRowBackground(Color.clear) // Fix for row background
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init(top: 8, leading: 16, bottom: 6, trailing: 16))
                }
            }
            .listStyle(.plain) // Ensure no grouped style
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#274E45"), // Starting green (top)
                        Color(hex: "#2F726A")  // Slightly lighter green (bottom)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom // Vertical gradient
                )
            ) // Apply gradient to the list background
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        offsets.map { habits[$0] }.forEach(dataController.delete(_:))
        dataController.save()
    }
    
    private func createSuggestedHabit() {
        let suggestedHabit = Habit(context: viewContext)
        suggestedHabit.title = "Read Bible for 15 mins a day"
        suggestedHabit.motivation = "Grow spiritually"
        suggestedHabit.color = HabitColor.blue // Assuming HabitColor is an enum or model.
        suggestedHabit.creationDate = Date()
        suggestedHabit.regularity = "Everyday"
        
        dataController.save()
    }
}


struct SuggestedHabitRowView: View {
    var title: String
    @Binding var isVisible: Bool
    var onCreate: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Match HabitRowView background and layout
            Color(hex: "#D4D4D4") // Same light gray background
                .clipShape(
                    RoundedRectangle(cornerRadius: 10, style: .continuous) // Match rounded corners
                )
                .onTapGesture {
                    onCreate() // Trigger habit creation
                    isVisible = false // Hide the suggested habit
                }

            HStack {
                Text("💡 Suggested Habit: \(title)")
                    .font(.system(size: 14, weight: .regular)) // Reduced text size
                    .foregroundColor(.black) // Text color is black

                Spacer()

                Button(action: {
                    isVisible = false // Hide the suggested habit when "X" is tapped
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.black) // "X" color is black
                        .font(.body) // Smaller font for the button
                }
                .padding(8) // Position the "X" button
            }
            .padding(.horizontal, 22) // Match horizontal padding of HabitRowView
            .padding(.vertical, 8) // Adjusted vertical padding to fit smaller height
        }
        .frame(height: 37.5) // Height is now half of HabitRowView (75 / 2 = 37.5)
        .frame(maxWidth: .infinity) // Ensure it spans the full width of the parent container
        .padding(.horizontal, 16) // Match the outer padding of HabitRowView
    }
}







struct HabitListView_Previews: PreviewProvider {
    static var previews: some View {
        HabitListView(sortingOption: .byDate, isSortingOrderAscending: false)
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
    }
}
