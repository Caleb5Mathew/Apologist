//
//  JournalingHistoryView.swift
//  Apologist
//
//  Created by Caleb Matthews on 12/17/24.
//

import SwiftUI

struct JournalingHistoryView: View {
    @ObservedObject var manager = JournalEntryManager()
    @State private var selectedTab = "Freewrite"

    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#0B1E30"), Color(hex: "#1D4038")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Journaling History")
                        .font(.largeTitle.bold())
                        .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 16)

                // Tab Picker
                Picker("Journal Type", selection: $selectedTab) {
                    Text("Freewrite").tag("Freewrite")
                    Text("Guided Journaling").tag("Guided Journaling")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                // Filtered and Ordered Entries
                let filteredEntries = manager.entries
                    .filter { $0.type == selectedTab }
                    .sorted(by: { ($0.date ?? Date()) > ($1.date ?? Date()) })

                if filteredEntries.isEmpty {
                    Spacer()
                    Text("No \(selectedTab) entries yet.")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.headline)
                    Spacer()
                } else {
                    List(filteredEntries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.title ?? "Untitled")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text(entry.content ?? "")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(2)

                            Text(entry.date?.formatted(date: .abbreviated, time: .shortened) ?? "")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.clear) // Transparent background for list
                    }
                    .listStyle(PlainListStyle())
                }
            }
        }
    }
}
