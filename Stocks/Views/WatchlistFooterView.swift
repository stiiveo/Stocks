//
//  WatchlistFooterView.swift
//  Stocks
//
//  Created by Jason Ou on 2021/8/23.
//

import UIKit

class WatchlistFooterView: UIView {
    
    // MARK: - UI Properties
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textAlignment = .left
        label.textColor = .tertiaryLabel
        label.text = "'Stocks' Replica"
        return label
    }()
    
    private let marketStatusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textAlignment = .right
        label.textColor = .secondaryLabel
        label.text = ""
        return label
    }()
    
    private let footerStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .top
        view.spacing = 10
        view.backgroundColor = .secondarySystemBackground
        return view
    }()
    
    private let borderLine: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray3
        return view
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground
        setUpFooterView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private
    
    private func setUpFooterStackView() {
        footerStackView.addArrangedSubviews(titleLabel, marketStatusLabel)
        self.addSubview(footerStackView)
        footerStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            footerStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            footerStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            footerStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 15),
            footerStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20)
        ])
    }
    
    private func setUpFooterView() {
        self.addSubviews(borderLine, footerStackView)
        borderLine.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            borderLine.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            borderLine.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            borderLine.topAnchor.constraint(equalTo: self.topAnchor),
            borderLine.heightAnchor.constraint(equalToConstant: 1)
        ])
        setUpFooterStackView()
    }
    
    // MARK: - Public
    
    /// Update the market status label based on the market status and current time.
    /// If the market is open when this method is called, the formatted date in
    /// New York will be shown in the status label.
    /// - Important: Use this method in main thread only as the text property of UILabel
    ///         is used.
    func updateMarketStatusLabel() {
        let calendarManager = CalendarManager.shared
        if calendarManager.isMarketOpen {
            let formattedDate = calendarManager.currentNewYorkDate
            marketStatusLabel.text = "Updated: " + formattedDate
        }
        else {
            marketStatusLabel.text = "Market Closed"
        }
    }
    
}
