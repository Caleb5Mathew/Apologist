//
//  ApologistApp.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/6/24.
//

//
//  ApologistApp.swift
//  Apologist
//
//  Created by Caleb Matthews on 12/6/24.
//

import UserNotifications
import SwiftUI

class AppState: ObservableObject {
    @Published var isUpdateAvailable: Bool = false
}

@main
struct ApologistApp: App {
    @StateObject private var dataController = DataController() // Initialize DataController
    @StateObject private var appState = AppState() // Centralized app state

    init() {
        // Register the SecureDictionaryTransformer
        ValueTransformer.setValueTransformer(SecureDictionaryTransformer(), forName: NSValueTransformerName("SecureDictionaryTransformer"))

        // Request notification permissions
        NotificationManager.requestNotificationPermissions()
    }

    var body: some Scene {
        WindowGroup {
            APContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext) // Provide Core Data context
                .environmentObject(dataController) // Provide DataController to child views
                .environmentObject(appState) // Provide AppState to child views
                .onAppear {
                    checkForAppUpdate()
                }
                .alert(isPresented: $appState.isUpdateAvailable) {
                    Alert(
                        title: Text("Update Available"),
                        message: Text("A new version of the app is available. Please update to enjoy the latest features."),
                        primaryButton: .default(Text("Update"), action: {
                            if let url = URL(string: "https://apps.apple.com/app/id6739737481") {
                                UIApplication.shared.open(url)
                            }
                        }),
                        secondaryButton: .cancel()
                    )
                }
        }
    }

    // Function to check for updates
    private func checkForAppUpdate() {
        let appID = "6739737481" // Your App Store ID
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(appID)") else {
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard error == nil, let data = data else {
                print("DEBUG: Error fetching app update information - \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]],
               let appStoreVersion = results.first?["version"] as? String {
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
                let isUpdateNeeded = currentVersion.compare(appStoreVersion, options: .numeric) == .orderedAscending

                print("DEBUG: Current Version: \(currentVersion), App Store Version: \(appStoreVersion), Update Needed: \(isUpdateNeeded)")

                DispatchQueue.main.async {
                    appState.isUpdateAvailable = isUpdateNeeded
                }
            } else {
                print("DEBUG: Failed to parse app update information.")
            }
        }.resume()
    }
}
