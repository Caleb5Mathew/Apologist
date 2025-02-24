//
//  StatusBarStyleModifier.swift
//  Apologist
//
//  Created by Caleb Matthews  on 12/11/24.
//

import Foundation
import SwiftUI
import UIKit

struct StatusBarStyleModifier: ViewModifier {
    var style: UIStatusBarStyle

    func body(content: Content) -> some View {
        content
            .background(
                StatusBarConfigurator(style: style)
            )
    }

    private struct StatusBarConfigurator: UIViewControllerRepresentable {
        var style: UIStatusBarStyle

        func makeUIViewController(context: Context) -> UIViewController {
            let controller = UIViewController()
            controller.view.backgroundColor = .clear
            controller.modalPresentationStyle = .overFullScreen
            return controller
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            windowScene?.windows.first?.overrideUserInterfaceStyle = .dark
        }
    }
}
