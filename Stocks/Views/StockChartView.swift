//
//  StockChartView.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/13.
//

import UIKit
import Charts

class StockChartView: UIView, ChartViewDelegate {
    
    struct ViewModel {
        let data: [StockLineChartData]
        let showLegend: Bool
        let showAxis: Bool
    }
    
    struct StockLineChartData {
        let timeInterval: Double
        let price: Double
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
        chartView.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        chartView.frame = bounds
    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        print(entry)
    }
    
    // Reset chart view
    func reset() {
        chartView.data = nil
    }
    
    func configure(with viewModel: ViewModel) {
        // Chart Data Entries
        let dataEntries = viewModel.data.map({
            ChartDataEntry(
                x: $0.timeInterval,
                y: $0.price
            )
        })
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM"
        
        let xAxisStrings = dataEntries.map({
            dateFormatter.string(from: Date(timeIntervalSince1970: $0.x))
        })
        print(xAxisStrings)
        
        chartView.rightAxis.enabled = viewModel.showAxis
        chartView.xAxis.enabled = viewModel.showAxis
        chartView.xAxis.labelPosition = .bottom
        chartView.legend.enabled = viewModel.showLegend
        
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: xAxisStrings)
        chartView.xAxis.granularity = 1
        
        let startPrice = viewModel.data.first?.price ?? 0.0
        let latestValue = viewModel.data.last?.price ?? 0.0
        let valueChange = latestValue - startPrice
        let fillColor: UIColor = valueChange < 0 ? .stockPriceDown : .stockPriceUp
        
        let dataSet = LineChartDataSet(entries: dataEntries, label: "7 Day")
        dataSet.drawCirclesEnabled = false
        dataSet.drawIconsEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.drawFilledEnabled = true
        dataSet.fillColor = fillColor
        dataSet.highlightColor = fillColor
        dataSet.setColor(fillColor)
        dataSet.lineWidth = 2.0

        let data = LineChartData(dataSet: dataSet)
        
        chartView.data = data
    }

}
