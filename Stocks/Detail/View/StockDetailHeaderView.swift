//
//  StockDetailHeaderView.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/15.
//

import UIKit
import Charts
import SnapKit

class StockDetailHeaderView: UIView {
    
    // MARK: - Properties
    
    private lazy var titleView = StockDetailHeaderTitleView()

    private lazy var chartView: StockChartView = {
        let chart = StockChartView()
        chart.isUserInteractionEnabled = false
        return chart
    }()
    
    private lazy var metricsView = StockMetricsView()
    
    static let metricsViewHeight: CGFloat = 70
    
    private let chartLoadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.isHidden = true
        return label
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        configureSubviews()
        configureChartLoadingIndicator()
        observeInternetAvailability()
        if NetworkMonitor.status == .notAvailable {
            onNetworkIsUnavailable()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Private
    
    private func configureSubviews() {
        let leadingPadding: CGFloat = 20.0
        let trailingPadding: CGFloat = -20.0
        let titleViewHeight: CGFloat = 25
        
        addSubviews(titleView, chartView, messageLabel, metricsView)
        
        titleView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(leadingPadding)
            make.trailing.equalToSuperview().offset(trailingPadding)
            make.height.equalTo(titleViewHeight)
        }
        
        chartView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(leadingPadding)
            make.trailing.equalToSuperview().offset(trailingPadding)
            make.top.equalTo(titleView.snp.bottom).offset(10.0)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(leadingPadding)
            make.trailing.equalToSuperview().offset(trailingPadding)
            make.top.equalTo(titleView.snp.bottom).offset(10.0)
            make.bottom.equalTo(metricsView.snp.top).offset(-10.0)
        }
        
        metricsView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(leadingPadding)
            make.trailing.equalToSuperview().offset(trailingPadding)
            make.top.equalTo(chartView.snp.bottom).offset(20.0)
            make.bottom.equalToSuperview().offset(-20.0)
            make.height.equalTo(StockDetailHeaderView.metricsViewHeight)
        }
    }
    
    private func configureChartLoadingIndicator() {
        chartView.addSubview(chartLoadingIndicator)
        chartLoadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        chartLoadingIndicator.startAnimating()
    }
    
    @objc private func onNetworkIsAvailable() {
        DispatchQueue.main.async { [weak self] in
            self?.chartView.isHidden = false
            self?.messageLabel.isHidden = true
        }
    }
    
    @objc private func onNetworkIsUnavailable() {
        let titleAttributes: [NSAttributedString.Key : Any] = [.font: UIFont.preferredFont(forTextStyle: .headline)]
        let message = NSMutableAttributedString(string: "Chart is Unavailable\n", attributes: titleAttributes)
        
        let detailsAttributes: [NSAttributedString.Key : Any] = [.font: UIFont.preferredFont(forTextStyle: .subheadline)]
        let details = NSAttributedString(string: "U.S. Stocks is not connected to Internet.", attributes: detailsAttributes)
        
        message.append(details)
        
        DispatchQueue.main.async { [weak self] in
            self?.messageLabel.attributedText = message
            self?.chartView.isHidden = true
            self?.messageLabel.isHidden = false
        }
    }
    
    private func observeInternetAvailability() {
        NotificationCenter.default.addObserver(self, selector: #selector(onNetworkIsAvailable), name: .networkIsAvailable, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onNetworkIsUnavailable), name: .networkIsUnavailable, object: nil)
    }
    
    // MARK: - Public
    
    /// Reset and configure data used by subviews of this view.
    /// - Parameters:
    ///   - titleViewModel: View model of the title view.
    ///   - chartViewModel: View model of the chart view.
    ///   - metricViewModels: View model of the metrics view.
    func configure(stockData: StockData, metricsData: Metrics?) {
        titleView.configure(
            viewModel: .init(
                quote: stockData.quote?.current,
                previousClose:
                    stockData.quote?.prevClose,
                showAddingButton: !PersistenceManager.shared.watchlist.keys.contains(stockData.symbol)
            )
        )
        
        // Stop chart loading indicator if data used to configure it is not empty.
        if !stockData.priceHistory.isEmpty {
            chartLoadingIndicator.stopAnimating()
        }
        
        chartView.configure(with: .init(
            data: stockData.priceHistory,
            previousClose: stockData.quote?.prevClose,
            highestClose: stockData.quote?.high,
            lowestClose: stockData.quote?.low,
            showAxis: true)
        )
        
        let quote = stockData.quote
        
        metricsView.configure(
            viewModel: .init(
                openPrice: quote?.open,
                highestPrice: quote?.high,
                lowestPrice: quote?.low,
                marketCap: metricsData?.marketCap,
                priceEarningsRatio: metricsData?.priceToEarnings,
                priceSalesRatio: metricsData?.priceToSales,
                annualHigh: metricsData?.annualHigh,
                annualLow: metricsData?.annualLow,
                previousPrice: quote?.prevClose,
                yield: metricsData?.yield,
                beta: metricsData?.beta,
                eps: metricsData?.eps
            )
        )
    }
    
}
