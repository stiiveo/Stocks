//
//  WatchListTableViewCell.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/13.
//

import UIKit

class WatchListTableViewCell: UITableViewCell {

    static let identifier = "WatchListTableViewCell"
    
    // MARK: - UI Properties
    
    private let titleStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 0
        view.alignment = .fill
        view.distribution = .fill
        return view
    }()
    
    private let symbolLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .gray
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return label
    }()
    
    private let priceStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 4
        view.alignment = .trailing
        view.distribution = .fill
        return view
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .right
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()
    
    private let priceChangeButton: UIButton = {
        let button = UIButton()
        button.tintColor = .white
        button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 14, weight: .semibold)
        button.contentHorizontalAlignment = .trailing
        button.layer.cornerRadius = 5
        button.titleEdgeInsets.left = 4 // Add title left padding.
        button.titleEdgeInsets.right = 4 // Add title right padding.
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.8
        return button
    }()
    
    private let chartView: StockChartView = {
        let chart = StockChartView()
        chart.clipsToBounds = true
        chart.isUserInteractionEnabled = false
        return chart
    }()
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.clipsToBounds = true
        setUpPriceButton()
        setUpPriceStackView()
        setUpChartView()
        setUpTitleStackView()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didChangeEditingMode),
            name: .didChangeEditingMode,
            object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public
    
    func configure(with stockData: StockData, showChartAxis: Bool, isEditing: Bool) {
        symbolLabel.text = stockData.symbol
        nameLabel.text = stockData.companyName
        priceLabel.text = stockData.quote?.current.stringFormatted(by: .decimalFormatter) ?? String.noDataExpression
        priceChangeButton.setTitle(stockData.quote?.changePercentage.signedPercentageString() ?? String.noDataExpression, for: .normal)
        priceChangeButton.backgroundColor = stockData.quote?.changeColor ?? .stockPriceUp
        chartView.configure(with: .init(data: stockData.priceHistory,
                                        previousClose: stockData.quote?.prevClose,
                                        highestClose: stockData.quote?.high,
                                        lowestClose: stockData.quote?.low,
                                        showAxis: showChartAxis))
        if isEditing {
            // Hide chart and price stack view.
            self.priceStockViewTrailingConstraint.constant = 120
            self.priceStackView.alpha = 0
            self.chartView.alpha = 0
        }
    }
    
    // MARK: - Private
    
    private let topMargin: CGFloat = 12.5
    private let bottomMargin: CGFloat = -12.5
    private let leadingMargin: CGFloat = 20.0
    private let trailingMargin: CGFloat = -20.0
    private var priceStockViewTrailingConstraint: NSLayoutConstraint!
    
    private func setUpPriceButton() {
        priceChangeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            priceChangeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 70.0),
            priceChangeButton.heightAnchor.constraint(equalToConstant: 25.0)
        ])
    }
    
    private func setUpPriceStackView() {
        priceStackView.addArrangedSubviews(priceLabel, priceChangeButton)
        contentView.addSubview(priceStackView)
        priceStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Custom bottom constraint to silence conflict warning.
        let bottomConstraint = priceStackView.bottomAnchor.constraint(
            equalTo: contentView.bottomAnchor, constant: bottomMargin)
        bottomConstraint.priority = UILayoutPriority(999)
        
        priceStockViewTrailingConstraint = priceStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: trailingMargin)
        
        NSLayoutConstraint.activate([
            priceStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: topMargin),
            priceStockViewTrailingConstraint,
            priceStackView.widthAnchor.constraint(equalToConstant: 75),
            bottomConstraint
        ])
    }
    
    private func setUpChartView() {
        contentView.addSubview(chartView)
        chartView.translatesAutoresizingMaskIntoConstraints = false
        
        // Custom bottom constraint to silence conflict warning.
        let bottomConstraint = chartView.bottomAnchor.constraint(
            equalTo: contentView.bottomAnchor, constant: bottomMargin - 3.0)
        bottomConstraint.priority = UILayoutPriority(999)
        
        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: topMargin + 3.0),
            chartView.trailingAnchor.constraint(equalTo: priceStackView.leadingAnchor, constant: -15),
            chartView.widthAnchor.constraint(equalToConstant: 80),
            bottomConstraint
        ])
    }
    
    private func setUpTitleStackView() {
        titleStackView.addArrangedSubviews(symbolLabel, nameLabel)
        contentView.addSubview(titleStackView)
        titleStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Custom bottom constraint to silence conflict warning.
        let bottomConstraint = titleStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: bottomMargin)
        bottomConstraint.priority = UILayoutPriority(999)
        
        NSLayoutConstraint.activate([
            titleStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: topMargin),
            titleStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: leadingMargin),
            titleStackView.trailingAnchor.constraint(equalTo: chartView.leadingAnchor, constant: -15),
            bottomConstraint
        ])
    }
    
    @objc private func didChangeEditingMode(_ notification: Notification) {
        guard let isEditing = notification.object as? Bool else { return }
        if isEditing {
            // Hide chart view and price stack view.
            self.priceStockViewTrailingConstraint.constant = 120
            UIView.animate(withDuration: 0.2) {
                self.priceStackView.alpha = 0
                self.chartView.alpha = 0
                self.layoutIfNeeded()
            }
        }
        else {
            // Show chart view and price stack view.
            self.priceStockViewTrailingConstraint.constant = trailingMargin
            UIView.animate(withDuration: 0.3) {
                self.priceStackView.alpha = 1
                self.chartView.alpha = 1
                self.layoutIfNeeded()
            }
        }
    }

}
