//
//  StockChartView.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/13.
//

import UIKit
import Charts

class StockChartView: UIView {
    
    // MARK: - Properties
    
    struct ViewModel {
        let data: [StockLineChartData]
        let showAxis: Bool
    }
    
    struct StockLineChartData {
        let timeInterval: Double
        let price: Double
    }
    
    private let chartView: LineChartView = {
        let chart = LineChartView()
        chart.legend.enabled = false
        chart.xAxis.enabled = false
        chart.leftAxis.enabled = false
        chart.rightAxis.enabled = false
        chart.drawGridBackgroundEnabled = false
        chart.rightAxis.labelFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        chart.xAxis.labelPosition = .bottom
        chart.xAxis.granularity = 1
        chart.xAxis.labelFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        return chart
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(chartView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        chartView.frame = bounds
    }
    
    // MARK: - Public Methods
    
    // Reset chart view
    func reset() {
        chartView.data = nil
    }
    
    func configure(with viewModel: ViewModel) {
        // Chart Data Entries
        var entries = [ChartDataEntry]()
        for (index, data) in viewModel.data.enumerated() {
            entries.append(.init(x: Double(index), y: data.price))
        }
        
        // Switch the appearance of the right axis.
        chartView.rightAxis.enabled = viewModel.showAxis
        
        let startPrice = viewModel.data.first?.price ?? 0.0
        let latestValue = viewModel.data.last?.price ?? 0.0
        let valueChange = latestValue - startPrice
        let fillColor: UIColor = valueChange < 0 ? .stockPriceDown : .stockPriceUp
        
        let dataSet = LineChartDataSet(entries: entries)
        dataSet.drawCirclesEnabled = false
        dataSet.drawIconsEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.drawFilledEnabled = true
        dataSet.setColor(fillColor)
        dataSet.fillColor = fillColor
        dataSet.lineWidth = 2.0

        let data = LineChartData(dataSet: dataSet)
        chartView.data = data
    }

}
