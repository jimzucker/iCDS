//
//  SceneDelegate.swift
//  icds
//
//  Copyright © 2010-2026 James A. Zucker.
//  Licensed under the Apache License, Version 2.0 — see LICENSE in project root.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window?.windowScene = windowScene
        // iPhone + iPad: force dark — the orange/yellow accent palette was
        // designed for a black background. Mac Catalyst: honor system
        // appearance so the window blends with the user's desktop.
        #if !targetEnvironment(macCatalyst)
        window?.overrideUserInterfaceStyle = .dark
        #endif

        // Mac Catalyst: clamp the window so the 480pt content cap always
        // has room. The default min size lets users shrink the window
        // narrow enough that the centered column collapses to nothing.
        #if targetEnvironment(macCatalyst)
        let restrictions = windowScene.sizeRestrictions
        restrictions?.minimumSize = CGSize(width: 600, height: 800)
        #endif
    }
}
