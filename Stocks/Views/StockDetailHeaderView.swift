//
//  StockDetailHeaderView.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/15.
//

import UIKit
import Charts

class StockDetailHeaderView: UIView {
    
    // MARK: - Properties
    
    private let titleView = StockDetailHeaderTitleView()

    private let chartView: StockChartView = {
        let chart = StockChartView()
        chart.isUserInteractionEnabled = false
        return chart
    }()
    
    private let metricsView = StockMetricsView()
    
    private let titleViewHeight: CGFloat = 25
    static let metricsViewHeight: CGFloat = 70
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        addSubviews(titleView, chartView, metricsView)
        setUpSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private
    
    private func setUpSubviews() {
        let leadingPadding: CGFloat = 20.0
        let trailingPadding: CGFloat = -20.0
        
        titleView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20.0),
            titleView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: trailingPadding),
            titleView.topAnchor.constraint(equalTo: self.topAnchor, constant: 20.0),
            titleView.heightAnchor.constraint(equalToConstant: titleViewHeight)
        ])
        
        chartView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chartView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: leadingPadding),
            chartView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: trailingPadding),
            chartView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 10.0)
        ])
        
        metricsView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            metricsView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: leadingPadding),
            metricsView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: trailingPadding),
            metricsView.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 20.0),
            metricsView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20.0),
            metricsView.heightAnchor.constraint(equalToConstant: StockDetailHeaderView.metricsViewHeight)
        ])
    }
    
    // MARK: - Public
    
    /// Reset and configure data used by subviews of this view.
    /// - Parameters:
    ///   - titleViewModel: View model of the title view.
    ///   - chartViewModel: View model of the chart view.
    ///   - metricViewModels: View model of the metrics view.
    func configure(
        titleViewModel: StockDetailHeaderTitleView.ViewModel,
        chartViewModel: StockChartView.ViewModel,
        metricsViewModels: StockMetricsView.ViewModel
    ) {
        titleView.resetData()
        titleView.configure(viewModel: titleViewModel)
        
        chartView.resetData()
        chartView.configure(with: chartViewModel)
        
        metricsView.resetData()
        metricsView.configure(viewModel: metricsViewModels)
    }
    
}
