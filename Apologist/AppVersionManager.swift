//
//  AppVersionManager.swift
//  Apologist
//
//  Created by Caleb Matthews  on 1/17/25.
//

import Foundation

class AppVersionManager {
    static func checkForUpdate(bundleId: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)") else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard error == nil, let data = data else {
                completion(false)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let appStoreVersion = results.first?["version"] as? String,
                   let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    
                    // Compare current app version with App Store version
                    let isUpdateAvailable = appStoreVersion.compare(currentVersion, options: .numeric) == .orderedDescending
                    completion(isUpdateAvailable)
                } else {
                    completion(false)
                }
            } catch {
                completion(false)
            }
        }.resume()
    }
}
