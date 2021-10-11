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
    
    private let titleViewHeight: CGFloat = 25
    static let metricsViewHeight: CGFloat = 70
    
    private let chartLoadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        configureSubviews()
        configureChartLoadingIndicator()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private
    
    private func configureSubviews() {
        addSubviews(titleView, chartView, metricsView)
        let leadingPadding: CGFloat = 20.0
        let trailingPadding: CGFloat = -20.0
        
        titleView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            titleView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: trailingPadding),
            titleView.topAnchor.constraint(equalTo: topAnchor, constant: 20.0),
            titleView.heightAnchor.constraint(equalToConstant: titleViewHeight)
        ])
        
        chartView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chartView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leadingPadding),
            chartView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: trailingPadding),
            chartView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 10.0)
        ])
        
        metricsView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            metricsView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leadingPadding),
            metricsView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: trailingPadding),
            metricsView.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 20.0),
            metricsView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20.0),
            metricsView.heightAnchor.constraint(equalToConstant: StockDetailHeaderView.metricsViewHeight)
        ])
    }
    
    private func configureChartLoadingIndicator() {
        chartView.addSubview(chartLoadingIndicator)
        chartLoadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        chartLoadingIndicator.startAnimating()
    }
    
    // MARK: - Public
    
    /// Reset and configure data used by subviews of this view.
    /// - Parameters:
    ///   - titleViewModel: View model of the title view.
    ///   - chartViewModel: View model of the chart view.
    ///   - metricViewModels: View model of the metrics view.
    func configure(stockData: StockData, metricsData: Metrics?) {
        titleView.configure(viewModel: .init(
            quote: stockData.quote?.current,
            previousClose: stockData.quote?.prevClose,
                                showAddingButton: !PersistenceManager.shared.watchlist.keys.contains(stockData.symbol))
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
        metricsView.configure(viewModel: .init(
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
                                eps: metricsData?.eps)
        )
    }
    
}
