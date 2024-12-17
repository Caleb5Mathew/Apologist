//
//  EditHabitView.swift
//  Habit
//

import SwiftUI
import CoreData

struct EditHabitView: View {
    let habit: Habit?

    @State private var title: String = ""
    @State private var motivation: String = ""
    @State private var color: HabitColor = HabitColor.randomColor
    @State private var regularity: String = "Everyday" // Default value

    private let regularityOptions = ["Everyday", "Once a Week", "2 Times a Week", "3 Times a Week", "4 Times a Week", "5 Times a Week", "6 Times a Week"]

    private var motivationPrompt = "Because I want to waste less time and become the best version of myself"

    @State private var isPresentingColorsPicker = false

    @FocusState private var isNameTextFieldFocused
    @FocusState private var isMotivationTextFieldFocused

    @EnvironmentObject var dataController: DataController
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.dismiss) var dismiss

    init(habit: Habit?) {
        self.habit = habit

        if let habit {
            _title = State(wrappedValue: habit.title)
            _motivation = State(wrappedValue: habit.motivation)
            _color = State(wrappedValue: habit.color)
            _regularity = State(wrappedValue: habit.regularity ?? "Everyday") // Load regularity from habit
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) { // Increased spacing between fields
                    nameTextField
                    whyTextField // Replaced motivationTextField
                    colorPicker
                    regularityPicker
                }
                .padding(.top, 20) // Reduce padding between the title and content
                .padding(.horizontal)
            }
            .navigationTitle(habit == nil ? "Add New Habit" : "Edit a Habit") // Use navigationTitle
            .navigationBarTitleDisplayMode(.inline) // Compact navigation bar height
            
            // Toolbar background and styling
            .toolbarBackground(Color(hex: "#1F5F4E"), for: .navigationBar) // Emerald Green background
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar) // Force light color scheme
            
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(habit == nil ? "Add New Habit" : "Edit a Habit")
                        .font(.headline)
                        .foregroundColor(.white) // Title to white
                }
                saveToolbarItem
                if habit != nil {
                    deleteToolbarItem
                }
            }
        }
        .sheet(isPresented: $isPresentingColorsPicker) {
            ColorsPickerView(selectedColor: $color)
        }
        .onAppear {
            if habit == nil {
                isNameTextFieldFocused = true
            }
        }
    }

    var nameTextField: some View {
        VStack(spacing: 8) { // Adjust spacing between elements in this section
            HStack {
                Text("NAME")
                    .font(.caption.bold())
                    .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver for text
                Spacer()
            }
            .accessibilityHidden(true)
            TextField("Name", text: $title, prompt: Text("Read a book, Meditate etc.")
                .foregroundColor(Color(hex: "#D4DDE1").opacity(0.6))) // Placeholder text
                .foregroundColor(Color(hex: "#D4DDE1")) // Text color
                .focused($isNameTextFieldFocused)
        }
    }

    var whyTextField: some View { // Updated field
        VStack(spacing: 8) {
            HStack {
                Text("WHY?")
                    .font(.caption.bold())
                    .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                Spacer()
            }
            .accessibilityHidden(true)
            TextField("Why?", text: $motivation, prompt: Text(motivationPrompt)
                .foregroundColor(Color(hex: "#D4DDE1").opacity(0.6))) // Updated placeholder
                .focused($isMotivationTextFieldFocused)
                .font(.callout)
                .foregroundColor(Color(hex: "#D4DDE1")) // Text color
        }
    }

    var colorPicker: some View {
        HStack {
            Text("Color")
                .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver for text
            Spacer()
            Circle()
                .frame(height: 20)
                .foregroundColor(Color(color))
        }
        .onTapGesture {
            isPresentingColorsPicker = true
        }
        .accessibilityHidden(true)
    }

    var regularityPicker: some View {
        VStack(spacing: 8) {
            HStack {
                Text("REGULARITY")
                    .font(.caption.bold())
                    .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                Spacer()
            }
            Picker("Regularity", selection: $regularity) {
                ForEach(regularityOptions, id: \.self) { option in
                    Text(option)
                        .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver for picker options
                        .tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }

    var saveToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                save()
                dismiss()
            }
            .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver for Save button
            .accessibilityIdentifier("saveHabit")
        }
    }

    var deleteToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            Button(role: .destructive) {
                delete()
                dismiss()
            } label: {
                Text("Delete Habit")
                    .foregroundColor(Color(hex: "#F8C471")) // Star Glow Yellow for Delete button
            }
            .accessibilityIdentifier("deleteHabit")
        }
    }

    func save() {
        withAnimation {
            if let habit {
                habit.title = title
                habit.motivation = motivation
                habit.color = color
                habit.regularity = regularity // Save regularity
            } else {
                let newHabit = Habit(context: managedObjectContext)
                newHabit.title = title
                newHabit.motivation = motivation
                newHabit.color = color
                newHabit.regularity = regularity // Set regularity
                newHabit.creationDate = Date()
            }
            dataController.save()
        }
    }

    func delete() {
        withAnimation {
            if let habit {
                dataController.delete(habit)
                dataController.save()
            }
        }
        dismiss()
    }
}

struct HabitView_Previews: PreviewProvider {
    static var previews: some View {
        EditHabitView(habit: Habit.example)
            .previewLayout(.sizeThatFits)
    }
}
