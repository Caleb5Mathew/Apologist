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
                    // Replace with your app's ID
                    let appId = "6739737481"
                    
                    // Replace "cn" with the appropriate country code for your app store
                    if let appURL = URL(string: "itms-apps://itunes.apple.com/cn/app/id" + appId + "?mt=8") {
                        UIApplication.shared.open(appURL, options: [.universalLinksOnly: false]) { success in
                            if success {
                                print("Successfully redirected to the App Store")
                            } else {
                                print("Failed to open the App Store")
                            }
                        }
                    } else {
                        print("Invalid URL for the App Store")
                    }
                },
                secondaryButton: .cancel(Text("Later"))
            )
        }

    }
}
