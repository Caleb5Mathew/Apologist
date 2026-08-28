
import CoreData
import SwiftUI

struct HabitListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isSuggestedHabitVisible = true
    @State private var isCreatingNewHabit = false // State variable for sheet

    @State private var activeHabit: Habit? // Centralized state for the selected habit

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
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#0B1E30"),
                    Color(hex: "#0B1E30")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            List {
                // List of existing habits
                ForEach(habits) { habit in
                    HabitRowView(habit: habit, activeHabit: $activeHabit) // Pass binding
                        .listRowBackground(Color.clear)
                        .padding(8)
                }
                .onDelete(perform: deleteItems)
                .listRowSeparator(.hidden)
                .buttonStyle(.plain)
                .listRowInsets(.init(top: 8, leading: 16, bottom: 6, trailing: 16))

                // Suggested Habit: Display only when no active habits exist
                if habits.isEmpty && isSuggestedHabitVisible {
                    SuggestedHabitRowView(
                        isVisible: $isSuggestedHabitVisible,
                        onNavigate: navigateToCreateHabit
                    )
                    .padding(.horizontal)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init(top: 8, leading: 16, bottom: 6, trailing: 16))
                }
            }
            .listStyle(.plain)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#14283A"),
                        Color(hex: "#1D4038")
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        // Present DetailView in a sheet
        .sheet(item: $activeHabit) { habit in
            DetailView(habit: habit)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(dataController)
        }
        // Present EditHabitView in a sheet
        .sheet(isPresented: $isCreatingNewHabit) {
            EditHabitView(habit: nil)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(dataController)
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        offsets.map { habits[$0] }.forEach(dataController.delete(_:))
        dataController.save()
    }
    
    private func navigateToCreateHabit() {
        isCreatingNewHabit = true
    }
    
    
    
    struct SuggestedHabitRowView: View {
        @Binding var isVisible: Bool
        var onNavigate: () -> Void

        var body: some View {
            Button(action: {
                onNavigate()
                isVisible = false
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "#F8C471").opacity(0.9))
                    Text("Create your first habit")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color(hex: "#132D42"))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
        }
    }

    struct HabitListView_Previews: PreviewProvider {
        static var previews: some View {
            HabitListView(sortingOption: .byDate, isSortingOrderAscending: false)
                .environment(\.managedObjectContext, DataController.preview.container.viewContext)
        }
    }}
