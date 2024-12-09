//
//  ComingSoonView.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/7/24.
//

import SwiftUI

struct ComingSoonView: View {
    var body: some View {
        VStack {
            Text("Feature Coming Soon!")
                .font(.system(size: 24, weight: .bold, design: .default))
                .foregroundColor(.white)
                .padding()

            Text("We're working hard to bring you more features. Stay tuned!")
                .font(.system(size: 18, weight: .regular, design: .default))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()

            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Coming Soon")
    }
}
