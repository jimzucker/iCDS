//
//  InfoViewController.swift
//  icds
//
//  Created by Jim Zucker on 10/7/16.
//  Copyright © 2016 Strategic Software Engineering LLC. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])

        let orange = UIColor(red: 1, green: 0.502, blue: 0, alpha: 1)

        func makeLabel(_ text: String, size: CGFloat, color: UIColor = .white) -> UILabel {
            let label = UILabel()
            label.text = text
            label.textColor = color
            label.font = UIFont(name: "Helvetica", size: size) ?? .systemFont(ofSize: size)
            label.textAlignment = .center
            label.numberOfLines = 0
            return label
        }

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

        stack.addArrangedSubview(makeLabel("iCDS", size: 48, color: orange))
        stack.addArrangedSubview(makeLabel("Credit Default Swap Calculator", size: 18))
        stack.addArrangedSubview(makeLabel("Version \(version)", size: 14, color: .lightGray))
        stack.setCustomSpacing(32, after: stack.arrangedSubviews[2])
        stack.addArrangedSubview(makeLabel("Based on the ISDA Standard CDS Model", size: 13, color: .lightGray))
        stack.addArrangedSubview(makeLabel("www.cdsmodel.com", size: 13, color: orange))
        stack.setCustomSpacing(32, after: stack.arrangedSubviews[4])
        stack.addArrangedSubview(makeLabel("© Strategic Software Engineering LLC", size: 12, color: .darkGray))
    }
}
