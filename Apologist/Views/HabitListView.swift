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
                    HabitRowView(habit: habit)
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
    }
    
    private func deleteItems(offsets: IndexSet) {
        offsets.map { habits[$0] }.forEach(dataController.delete(_:))
        dataController.save()
    }
    
    private func navigateToCreateHabit() {
        let newHabitView = EditHabitView(habit: nil)
        if let window = UIApplication.shared.windows.first {
            window.rootViewController?.present(
                UIHostingController(rootView: newHabitView), animated: true
            )
        }
    }
}

struct SuggestedHabitRowView: View {
    @Binding var isVisible: Bool
    var onNavigate: () -> Void

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(Color.white, lineWidth: 2) // White border
            .background(Color.clear) // Transparent background
            .frame(height: 75) // Match HabitRowView height
            .overlay(
                Text("Create your first habit")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            )
            .onTapGesture {
                onNavigate() // Trigger navigation
                isVisible = false // Hide suggested habit
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
    }
}

struct HabitListView_Previews: PreviewProvider {
    static var previews: some View {
        HabitListView(sortingOption: .byDate, isSortingOrderAscending: false)
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
    }
}
