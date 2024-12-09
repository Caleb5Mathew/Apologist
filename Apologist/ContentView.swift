//
//  ContentView.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/6/24.
//

import SwiftUI

struct ContentView: View {
    @State private var isLoaded = false

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
    }
}
