//
//  StockDetailHeaderTitleView.swift
//  Stocks
//
//  Created by Jason Ou on 2021/8/18.
//

import UIKit

protocol StockDetailHeaderTitleViewDelegate: AnyObject {
    func didTapAddingButton()
}

class StockDetailHeaderTitleView: UIView {
    
    // MARK: - Properties

    private let quoteLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = .systemFont(ofSize: 17, weight: .black)
        label.textAlignment = .left
        return label
    }()
    
    private let priceChangeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textAlignment = .right
        return label
    }()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12.0
        return stackView
    }()
    
    private let watchlistAddingButton: UIButton = {
        let button = UIButton()
        button.setTitle("Add to Watchlist", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .regular)
        button.backgroundColor = UIColor(red: 102/255, green: 209/255, blue: 255/255, alpha: 1.0)
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10)
        return button
    }()
    
    weak var delegate: StockDetailHeaderTitleViewDelegate?
    
    struct ViewModel {
        let quote: Double?
        let previousClose: Double?
        let showAddingButton: Bool
        let delegate: StockDetailHeaderTitleViewDelegate
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        watchlistAddingButton.addTarget(self, action: #selector(didTapAddingButton), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        addSubview(stackView)
        addSubview(watchlistAddingButton)
        setUpStackView()
        setUpAddingButton()
    }
    
    // MARK: - Public Methods
    
    func configure(viewModel: ViewModel) {
        quoteLabel.text = viewModel.quote?.stringFormatted(by: .decimalFormatter) ?? String.noDataExpression
        watchlistAddingButton.isHidden = !viewModel.showAddingButton
        delegate = viewModel.delegate
        
        if let quote = viewModel.quote,
           let previousClose = viewModel.previousClose {
            let priceChange = (quote / previousClose) - 1
            priceChangeLabel.text = priceChange.signedPercentageString()
            priceChangeLabel.textColor = priceChange >= 0 ? .stockPriceUp : .stockPriceDown
        } else {
            priceChangeLabel.text = ""
        }
    }
    
    func resetData() {
        quoteLabel.text = nil
        priceChangeLabel.text = nil
    }
    
    // MARK: - Private Methods
    
    private func setUpStackView() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: self.watchlistAddingButton.leadingAnchor, constant: -10),
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        stackView.addArrangedSubviews(quoteLabel, priceChangeLabel)
    }
    
    private func setUpAddingButton() {
        watchlistAddingButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            watchlistAddingButton.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor),
            watchlistAddingButton.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            watchlistAddingButton.topAnchor.constraint(equalTo: self.topAnchor),
            watchlistAddingButton.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
    
    @objc private func didTapAddingButton() {
        watchlistAddingButton.isHidden = true
        delegate?.didTapAddingButton()
    }
    
}
