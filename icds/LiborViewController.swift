//
//  LiborViewController.swift
//  icds
//
//  Created by Jim Zucker on 5/10/16.
//  Copyright © 2016-2026 James A. Zucker All rights reserved.
//

import UIKit

class LiborViewController: UIViewController {

    // SOFR-based USD swap reference curve (approximate mid-market, 2024)
    private let curve: [(tenor: String, rate: String)] = [
        ("1M",  "5.31%"),
        ("3M",  "5.33%"),
        ("6M",  "5.20%"),
        ("1Y",  "4.88%"),
        ("2Y",  "4.42%"),
        ("3Y",  "4.25%"),
        ("5Y",  "4.15%"),
        ("7Y",  "4.18%"),
        ("10Y", "4.22%"),
        ("20Y", "4.48%"),
        ("30Y", "4.38%"),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        buildUI()
    }

    private func buildUI() {
        view.subviews.forEach { $0.removeFromSuperview() }
        let orange = UIColor(red: 1, green: 0.502, blue: 0, alpha: 1)

        let title = makeLabel("USD Reference Curve", size: 24, color: orange, bold: true)
        title.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(title)

        let note = makeLabel("LIBOR discontinued Jun 2023 · Rates shown are SOFR-based USD swap mid-market reference (2024)",
                             size: 11, color: .lightGray)
        note.numberOfLines = 0
        note.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(note)

        let table = UITableView(frame: .zero, style: .plain)
        table.backgroundColor = .black
        table.separatorColor = UIColor(white: 0.2, alpha: 1)
        table.dataSource = self
        table.register(RateCell.self, forCellReuseIdentifier: "rate")
        table.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(table)

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            title.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            note.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            note.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            note.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            table.topAnchor.constraint(equalTo: note.bottomAnchor, constant: 12),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func makeLabel(_ text: String, size: CGFloat, color: UIColor, bold: Bool = false) -> UILabel {
        let l = UILabel()
        l.text = text
        l.textColor = color
        l.font = bold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size)
        l.textAlignment = .center
        return l
    }
}

extension LiborViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        curve.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rate", for: indexPath) as! RateCell
        let entry = curve[indexPath.row]
        cell.configure(tenor: entry.tenor, rate: entry.rate)
        return cell
    }
}

private class RateCell: UITableViewCell {
    private let tenorLabel = UILabel()
    private let rateLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .black
        selectionStyle = .none

        tenorLabel.textColor = UIColor(white: 0.7, alpha: 1)
        tenorLabel.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)

        rateLabel.textColor = UIColor(red: 1, green: 0.502, blue: 0, alpha: 1)
        rateLabel.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .semibold)
        rateLabel.textAlignment = .right

        [tenorLabel, rateLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            tenorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            tenorLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            rateLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(tenor: String, rate: String) {
        tenorLabel.text = tenor
        rateLabel.text = rate
    }
}
