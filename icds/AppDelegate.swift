//
//  AppDelegate.swift
//  icds
//
//  Created by Jim Zucker on 5/10/16.
//  Copyright © 2010-2026 James A. Zucker.
//  Licensed under the Apache License, Version 2.0 — see LICENSE in project root.
//
// NOTE: Entry point is iCDSApp.swift (@main SwiftUI App struct).
// This file is retained for UIApplicationDelegate callbacks if needed.
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    #if targetEnvironment(macCatalyst)
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)

        let privacyItem = UICommand(
            title: "Privacy Policy",
            action: #selector(openPrivacy)
        )
        let docsItem = UICommand(
            title: "Documentation & Source",
            action: #selector(openDocs)
        )
        let issuesItem = UICommand(
            title: "Report an Issue",
            action: #selector(openIssues)
        )
        let helpLinks = UIMenu(
            identifier: UIMenu.Identifier("com.ijaz.icds.help.links"),
            options: .displayInline,
            children: [docsItem, privacyItem, issuesItem]
        )
        builder.insertChild(helpLinks, atStartOfMenu: .help)
    }

    @objc func openPrivacy() {
        UIApplication.shared.open(URL(string: "https://jimzucker.github.io/iCDS/PRIVACY")!)
    }

    @objc func openDocs() {
        UIApplication.shared.open(URL(string: "https://jimzucker.github.io/iCDS/")!)
    }

    @objc func openIssues() {
        UIApplication.shared.open(URL(string: "https://github.com/jimzucker/iCDS/issues")!)
    }
    #endif
}
