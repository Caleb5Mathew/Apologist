//
//  FreewriteHistoryView.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/17/24.
//

import SwiftUI

struct FreewriteHistoryView: View {
    @ObservedObject var manager = JournalEntryManager()

    // Filter entries where type == "Freewrite"
    var freewriteEntries: [JournalEntri] {
        manager.entries.filter { $0.type == "Freewrite" }
    }

    var body: some View {
        VStack {
            Text("Past Freewrite Entries")
                .font(.largeTitle)
                .bold()
                .padding()

            if freewriteEntries.isEmpty {
                Text("No Freewrite entries yet.")
                    .foregroundColor(.gray)
                    .italic()
                    .padding()
            } else {
                List(freewriteEntries, id: \.id) { entry in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(entry.title ?? "No Title")
                            .font(.headline)
                        Text(entry.content ?? "No Content")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Text("Date: \(entry.date?.formatted() ?? "Unknown Date")")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 5)
                }
            }
        }
    }
}
