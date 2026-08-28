//
//  JournalEditView.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/29/24.
//
//
//  JournalEditView.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/29/24.
//

//
//  JournalEditView.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/29/24.
//

import SwiftUI

struct JournalEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var manager: JournalEntryManager
    @State private var title: String
    @State private var content: String
    @State private var answers: [String: String] // Store questions and answers
    let entry: JournalEntri // Core Data entity

    init(entry: JournalEntri, manager: JournalEntryManager) {
        self.entry = entry
        self.manager = manager
        _title = State(initialValue: entry.title ?? "")
        _content = State(initialValue: entry.content ?? "") // Ensure content is loaded
        _answers = State(initialValue: (entry.questionsAndAnswers as? [String: String]) ?? [:])
    }

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#0B1E30"), Color(hex: "#1D4038")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            VStack {
                // Title and Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edit Guided Journaling Entry")
                        .font(.title2.bold())
                        .foregroundColor(Color(hex: "#D4DDE1"))
                        .padding(.top, 20)

                    Text(entry.date?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown Date")
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

                Divider()
                    .background(Color.white.opacity(0.5))
                    .padding(.vertical, 10)

                // Editable Title
                VStack(alignment: .leading) {
                    Text("Title:")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)

                    TextField("Enter title", text: $title)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                        )
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 10)

                // Editable Content
                VStack(alignment: .leading) {
                    Text("Content:")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)

                    TextEditor(text: $content)
                        .scrollContentBackground(.hidden) // Hide the default background
                        .foregroundColor(.white) // Text color
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1)) // Match the Title's box opacity
                        )
                        .foregroundColor(.white)
                        .frame(height: 400) // Increase height to extend closer to the button
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 10) // Slightly reduce bottom padding





                Spacer()

                // Save Button
                Button(action: saveChanges) {
                    Text("Save Changes")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "#1B3A4B"))
                        )
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            loadEntryData()
        }
    }

    private func loadEntryData() {
        title = entry.title ?? ""
        content = entry.content ?? ""
        answers = (entry.questionsAndAnswers as? [String: String]) ?? [:]
    }

    private func saveChanges() {
        // Update the Core Data entry
        entry.title = title
        entry.content = content
        entry.questionsAndAnswers = NSDictionary(dictionary: answers)

        // Save changes to Core Data
        manager.saveContext()

        // Dismiss the view
        presentationMode.wrappedValue.dismiss()
    }
}
