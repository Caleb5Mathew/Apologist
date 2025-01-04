//
//  ContentView.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/6/24.
//

import SwiftUI

struct APContentView: View {
    @State private var isLoaded = false
    @Environment(\.managedObjectContext) private var context // Access Core Data context

    var body: some View {
        Group {
            if isLoaded {
                MainAppView()
            } else {
                LaunchScreenView(isLoaded: $isLoaded)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isLoaded = true
                        }
                    }
            }
        }
        .onAppear {
            // Check and schedule notifications when the app appears
            NotificationManager.checkAndScheduleNotifications(context: context)
        }
    }
}
