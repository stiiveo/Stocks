//
//  WatchListTableViewCell.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/13.
//

import UIKit

class WatchListTableViewCell: UITableViewCell {
    
    // MARK: - Properties

    static let identifier = "WatchListTableViewCell"
    
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
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .gray
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
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .right
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()
    
    private let priceChangeButton: UIButton = {
        let button = UIButton()
        button.tintColor = .white
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.titleLabel?.textAlignment = .right
        button.layer.cornerRadius = 5
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 13, bottom: 4, right: 4)
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
        setUpPriceStackView()
        setUpChartView()
        setUpTitleStackView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        symbolLabel.text = nil
        nameLabel.text = nil
        priceLabel.text = nil
        priceChangeButton.setTitle(nil, for: .normal)
        chartView.reset()
    }
    
    // MARK: - Public
    
    func configure(with viewModel: WatchlistTableViewCellViewModel.ViewModel) {
        symbolLabel.text = viewModel.symbol
        nameLabel.text = viewModel.companyName
        priceLabel.text = viewModel.price
        priceChangeButton.setTitle(viewModel.changePercentage, for: .normal)
        priceChangeButton.backgroundColor = viewModel.changeColor
        chartView.configure(with: viewModel.chartViewModel)
    }
    
    // MARK: - Private
    
    private let topMargin: CGFloat = 15.0
    private let bottomMargin: CGFloat = -15.0
    private let leadingMargin: CGFloat = 19.0
    private let trailingMargin: CGFloat = -19.0
    
    private func setUpPriceStackView() {
        priceStackView.addArrangedSubviews(priceLabel, priceChangeButton)
        addSubview(priceStackView)
        priceStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            priceStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: topMargin),
            priceStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: bottomMargin),
            priceStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: trailingMargin),
            priceStackView.widthAnchor.constraint(equalToConstant: 75)
        ])
    }
    
    private func setUpChartView() {
        addSubview(chartView)
        chartView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(equalTo: self.topAnchor, constant: topMargin + 5.0),
            chartView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: bottomMargin - 5.0),
            chartView.trailingAnchor.constraint(equalTo: priceStackView.leadingAnchor, constant: -15),
            chartView.widthAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func setUpTitleStackView() {
        titleStackView.addArrangedSubviews(symbolLabel, nameLabel)
        addSubview(titleStackView)
        titleStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: topMargin),
            titleStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: bottomMargin),
            titleStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: leadingMargin),
            titleStackView.trailingAnchor.constraint(equalTo: chartView.leadingAnchor, constant: -15)
        ])
    }

}
