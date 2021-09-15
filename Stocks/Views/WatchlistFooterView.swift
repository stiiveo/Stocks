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
        label.text = "U.S. Stocks"
        return label
    }()
    
    private let marketStatusLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        label.textAlignment = .right
        label.textColor = .secondaryLabel
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()
    
    private let footerStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .center
        view.spacing = 10
        view.backgroundColor = .secondarySystemBackground
        return view
    }()
    
    private let borderLine: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray3
        return view
    }()
    
    // MARK: - Status Timer
    
    private var timer: Timer?
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground
        setUpFooterView()
        timer = Timer(timeInterval: 1.0, target: self, selector: #selector(updateMarketStatusLabel), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - De-init
    
    deinit {
        timer?.invalidate()
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
            footerStackView.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -20)
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
    
    /// Update the text property of the market status label based on the current time.
    /// If the market is open when this method is called, the label denotes the remaining time until the market is closed;
    /// otherwise, is denotes the remaining time until the next trading session starts.
    /// - Important: Use this method in main thread only since the text property of UILabel is used.
    @objc private func updateMarketStatusLabel() {
        let calendarManager = CalendarManager.shared
        let formattedTimeToClose = calendarManager.timeToClose.formattedString
        let formattedTimeToOpen = calendarManager.timeToOpen.formattedString
        marketStatusLabel.text = calendarManager.isMarketOpen ?
            "Market Closes in " + formattedTimeToClose :
            "Market Opens in " + formattedTimeToOpen
    }
    
}
