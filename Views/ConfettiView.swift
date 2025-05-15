//
//  ConfettiView.swift
//  Apologist
//
//  Created by Caleb Matthews  on 1/17/25.
//

import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .animation(.linear(duration: particle.lifetime), value: particle.position)
                }
            }
            .onAppear {
                generateConfetti(in: geometry.size)
            }
        }
    }

    func generateConfetti(in size: CGSize) {
        particles = (0..<20).map { _ in
            ConfettiParticle(
                id: UUID(),
                color: Color.random(),
                size: CGFloat.random(in: 5...10),
                position: CGPoint(x: size.width / 2, y: size.height / 2),
                lifetime: Double.random(in: 1...2)
            )
        }

        for i in particles.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                withAnimation {
                    particles[i].position.x += CGFloat.random(in: -100...100)
                    particles[i].position.y += CGFloat.random(in: -100...100)
                }
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: UUID
    let color: Color
    let size: CGFloat
    var position: CGPoint
    let lifetime: Double
}

extension Color {
    static func random() -> Color {
        Color(
            red: .random(in: 0.5...1),
            green: .random(in: 0.5...1),
            blue: .random(in: 0.5...1)
        )
    }
}
