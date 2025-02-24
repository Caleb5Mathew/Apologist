//
//  QuestionView.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/6/24.
//

import SwiftUI

struct QuestionView: View {
    @State private var question: String = ""
    @State private var answer: String = ""

    var body: some View {
        VStack {
            Text("Ask Your Question")
                .font(.title2)
                .padding()

            TextField("Type your question here...", text: $question)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: handleQuestion) {
                Text("Get Answer")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()

            if !answer.isEmpty {
                Text("Answer:")
                    .font(.headline)
                    .padding(.top)

                Text(answer)
                    .font(.body)
                    .padding()
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Ask a Question")
    }

    func handleQuestion() {
        // Placeholder logic for answering the question
        answer = "This is where the LLM would provide a response based on your question: '\(question)'"
    }
}
