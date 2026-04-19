//
//  InfoView.swift
//  icds
//
//  Copyright © 2016-2026 James A. Zucker All rights reserved.
//

import SwiftUI

struct InfoView: View {

    private let orange = Color(red: 1, green: 0.502, blue: 0)
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("iCDS")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundColor(orange)

                Text("Credit Default Swap Calculator")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Version \(version)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Divider().background(Color(white: 0.2)).padding(.vertical, 8)

                Text("Based on the ISDA Standard CDS Model")
                    .font(.footnote)
                    .foregroundColor(.gray)

                Text("www.cdsmodel.com")
                    .font(.footnote)
                    .foregroundColor(orange)

                Divider().background(Color(white: 0.2)).padding(.vertical, 8)

                Text("© James A. Zucker")
                    .font(.caption)
                    .foregroundColor(Color(white: 0.35))
            }
            .padding(.horizontal, 32)
        }
    }
}
