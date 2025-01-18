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
    @State private var showUpdateAlert = false // State to control the update alert

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
            
            // Check for app updates
            AppVersionManager.checkForUpdate(bundleId: "DeepDev.Apologist") { isUpdateAvailable in
                DispatchQueue.main.async {
                    showUpdateAlert = isUpdateAvailable
                }
            }
        }
        .alert(isPresented: $showUpdateAlert) {
            Alert(
                title: Text("Update Available"),
                message: Text("A new version is available! Update now to enjoy the latest features and improvements."),
                primaryButton: .default(Text("Update")) {
                    if let url = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID") {
                        UIApplication.shared.open(url)
                    }
                },
                secondaryButton: .cancel(Text("Later"))
            )
        }
    }
}
