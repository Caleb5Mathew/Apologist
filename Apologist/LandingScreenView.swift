//
//  LaunchScreenView.swift
//  Apologist
//
//  Created by Caleb Matthews on 12/6/24.
//


import SwiftUI

struct LaunchScreenView: View {
    @Binding var isLoaded: Bool
    @State private var currentQuoteIndex = 0

    private let quotes = [
        ""
    ]

    var body: some View {
        ZStack {
            // Background Image
            Image("Apologist_backdrop")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // Optional: Add a semi-transparent layer to decrease contrast
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack {
                Spacer()

                Text("Apologist")
                    .font(.custom("Georgia", size: 42))
                    .foregroundColor(.white)
                    .padding(.bottom, 10)

                Text(quotes[currentQuoteIndex])
                    .font(.footnote)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
        }
        .preferredColorScheme(.dark) // Forces status bar to have white text
        .onAppear {
            startLoading()
        }
    }

    func startLoading() {
        // Simulate a delay to mimic loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            isLoaded = true
        }

        // Rotate quotes every 5 seconds
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            currentQuoteIndex = (currentQuoteIndex + 1) % quotes.count
        }
    }
}
