//
//  StockChartView.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/13.
//

import UIKit
import Charts

class StockChartView: UIView {
    
    struct ViewModel {
        let data: [Double]
        let showLegend: Bool
        let showAxis: Bool
    }
    
    private let chartView: LineChartView = {
        let chartView = LineChartView()
        chartView.pinchZoomEnabled = false
        chartView.legend.enabled = false
        chartView.setScaleEnabled(true)
        chartView.xAxis.enabled = false
        chartView.leftAxis.enabled = false
        chartView.rightAxis.enabled = false
        chartView.drawGridBackgroundEnabled = false
        return chartView
    }()
    
    // MARK: - Int
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(chartView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        chartView.frame = bounds
    }
    
    // Reset chart view
    func reset() {
        chartView.data = nil
    }
    
    func configure(with viewModel: ViewModel) {
        // Chart Data Entries
        var entries = [ChartDataEntry]()
        for (index, value) in viewModel.data.enumerated() {
            entries.append(
                .init(
                    x: Double(index),
                    y: value
                )
            )
        }
        
        chartView.rightAxis.enabled = viewModel.showAxis
        chartView.legend.enabled = viewModel.showLegend
        
        let latestValue = viewModel.data.last ?? 1.0
        let startValue = viewModel.data.first ?? 1.0
        let valueChange = (latestValue / startValue) - 1
        let fillColor: UIColor = valueChange < 0 ? .stockPriceDown : .stockPriceUp
        
        let dataSet = LineChartDataSet(entries: entries, label: "Place duration here")
        dataSet.drawCirclesEnabled = false
        dataSet.drawIconsEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.drawFilledEnabled = true
        dataSet.fillColor = fillColor
        
        let data = LineChartData(dataSet: dataSet)
        chartView.data = data
    }

}
