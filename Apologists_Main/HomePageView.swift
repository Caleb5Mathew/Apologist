//
//  HomePageView.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/7/24.
//

import SwiftUI

struct HomePageView: View {
    @State private var quote = "For God so loved the world, that He gave His only Son."

    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Apologist")
                .font(.custom("Georgia", size: 36))
                .foregroundColor(.white)
                .padding(.bottom, 10)

            // Quote of the Day
            VStack {
                Text("Quote of the Day")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.bottom, 5)

                Text(quote)
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
            .shadow(radius: 4)

            // Quick Links
            VStack(spacing: 20) {
                NavigationLink(destination: LearnMoreView()) {
                    Text("Learn More")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .cornerRadius(25)
                }

                NavigationLink(destination: ExploreTopicsView()) {
                    Text("Explore Topics")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .cornerRadius(25)
                }
            }
            .padding(.horizontal, 40)

            Spacer()

            // Optional: Add a fun or user-related stat section
            VStack {
                Text("Today's Highlight")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.bottom, 5)

                Text("Explore 5 New Questions!")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
            .shadow(radius: 4)

            Spacer()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
    }
}

// Placeholder Views for Navigation Links
struct LearnMoreView: View {
    var body: some View {
        Text("Learn More Page")
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .ignoresSafeArea()
    }
}

struct ExploreTopicsView: View {
    var body: some View {
        Text("Explore Topics Page")
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .ignoresSafeArea()
    }
}
