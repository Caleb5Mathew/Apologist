
//
//  AppVersionManager.swift
//  Apologist
//
//  Created by Caleb Matthews  on 1/17/25.
//

import Foundation

//import Foundation
//
//class AppVersionManager {
//    static func checkForUpdate(bundleId: String, completion: @escaping (Bool) -> Void) {
//        // Simulate App Store version as 2.0 for testing
//        let appStoreVersion = "2.0"
//
//        // Get the current app version from Info.plist
//        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
//
//        print("[DEBUG] Simulating App Store version: \(appStoreVersion), Current version: \(currentVersion)")
//
//        // Compare versions and determine if an update is available
//        let isUpdateAvailable = currentVersion.compare(appStoreVersion, options: .numeric) == .orderedAscending
//
//        print("[DEBUG] Update available: \(isUpdateAvailable)")
//        completion(isUpdateAvailable)
//    }
//}


class AppVersionManager {
    static func checkForUpdate(bundleId: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)") else {
            print("[DEBUG] Invalid URL for App Store lookup.")
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                print("[DEBUG] Failed to fetch App Store data: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let appStoreVersion = results.first?["version"] as? String {

                    // Get the current app version
                    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

                    // Compare versions numerically
                    if appStoreVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                        print("[DEBUG] Update available: App Store version \(appStoreVersion), Current version \(currentVersion)")
                        completion(true)
                    } else {
                        print("[DEBUG] No update available: App Store version \(appStoreVersion), Current version \(currentVersion)")
                        completion(false)
                    }
                } else {
                    print("[DEBUG] Failed to parse App Store JSON response.")
                    completion(false)
                }
            } catch {
                print("[DEBUG] JSON parsing error: \(error.localizedDescription)")
                completion(false)
            }
        }.resume()
    }
}
