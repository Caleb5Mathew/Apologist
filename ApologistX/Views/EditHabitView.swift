//
//  EditHabitView.swift
//  Habit
//
//  Created by Nazarii Zomko on 15.05.2023.
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

    private var motivationPrompt = Constants.motivationPrompts.randomElement() ?? "Yes, you can! 💪"

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
                VStack(spacing: 0) {
                    nameTextField
                    motivationTextField
                    colorPicker
                    regularityPicker
                }
            }
            .toolbar {
                saveToolbarItem
                if habit != nil {
                    deleteToolbarItem
                }
            }
            .toolbarBackground(Color(hex: "#1F5F4E"), for: .navigationBar) // Emerald Green for toolbar
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle(habit == nil ? "Add New Habit" : "Edit a Habit")
            .navigationBarTitleDisplayMode(.inline)
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
        VStack {
            HStack {
                Text("NAME")
                    .padding(.horizontal)
                    .font(.caption.bold())
                    .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver for text
                Spacer()
            }
            .accessibilityHidden(true)
            TextField("Name", text: $title, prompt: Text("Read a book, Meditate etc.")
                .foregroundColor(Color(hex: "#D4DDE1").opacity(0.6))) // Lighter Moonlight Silver for placeholder
                .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver for text
                .focused($isNameTextFieldFocused)
                .padding(.horizontal)
                .accessibilityIdentifier("nameTextField")
        }
        .padding(.top, 40)
        .padding(.bottom, 15)
        .background(alignment: .bottom, content: {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#0B1E30"), Color(hex: "#274E45")]), // Midnight Blue to Soft Pine Green
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 500)
        })
    }

    var motivationTextField: some View {
        VStack {
            HStack {
                Text("MOTIVATE YOURSELF")
                    .padding(.horizontal)
                    .font(.caption.bold())
                    .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                Spacer()
            }
            .accessibilityHidden(true)
            .padding(.top)
            TextField("Motivation", text: $motivation, prompt: Text(motivationPrompt)
                .foregroundColor(Color(hex: "#D4DDE1").opacity(0.6))) // Lighter Moonlight Silver for placeholder
                .focused($isMotivationTextFieldFocused)
                .font(.callout)
                .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver for text
                .padding(.horizontal)
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
        .padding()
        .onTapGesture {
            isPresentingColorsPicker = true
        }
        .accessibilityHidden(true)
    }

    var regularityPicker: some View {
        VStack {
            HStack {
                Text("REGULARITY")
                    .padding(.horizontal)
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
            .padding(.horizontal)
        }
        .padding(.top)
    }

    var saveToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                save()
                dismiss()
            }
            .foregroundColor(Color(hex: "#F8C471")) // Star Glow Yellow for Save button
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
