//
//  LaunchScreenView.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/6/24.
//


import SwiftUI

struct LaunchScreenView: View {
    @Binding var isLoaded: Bool
    @State private var progress: CGFloat = 0.0
    @State private var currentQuoteIndex = 0

    private let quotes = [
        "Cool quote that gets ya thinking",
        "Faith is taking the first step even when you don’t see the whole staircase.",
        "With God, all things are possible. - Matthew 19:26"
    ]

    private let totalTasks = 100 // Simulated number of tasks for the app launch

    var body: some View {
        ZStack {
            Color.black
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

                ProgressBar(progress: progress)
                    .frame(height: 4)
                    .padding(.horizontal, 50)
                    .padding(.bottom, 30)
            }
        }
        .onAppear {
            startLoading()
        }
    }

    func startLoading() {
        // Simulate loading tasks using a timer
        var completedTasks = 0
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            withAnimation {
                completedTasks += 1
                progress = CGFloat(completedTasks) / CGFloat(totalTasks)
            }

            // When all tasks are completed
            if completedTasks >= totalTasks {
                timer.invalidate()
                isLoaded = true
            }
        }

        // Rotate quotes every 5 seconds
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            currentQuoteIndex = (currentQuoteIndex + 1) % quotes.count
        }
    }
}

struct ProgressBar: View {
    var progress: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: geometry.size.width, height: geometry.size.height)

                Rectangle()
                    .fill(Color.green)
                    .frame(width: geometry.size.width * progress, height: geometry.size.height)
            }
            .cornerRadius(geometry.size.height / 2)
        }
    }
}
