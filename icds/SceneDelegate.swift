//
//  SceneDelegate.swift
//  icds
//
//  Copyright © 2024-2026 James A Zucker All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window?.windowScene = windowScene
        window?.overrideUserInterfaceStyle = .dark
    }
}
