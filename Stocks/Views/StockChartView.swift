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
        chart.setScaleEnabled(true)
        chart.xAxis.enabled = false
        chart.leftAxis.enabled = false
        chart.rightAxis.enabled = false
        chart.drawGridBackgroundEnabled = false
        chart.rightAxis.labelFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        chart.xAxis.labelPosition = .bottom
        chart.xAxis.valueFormatter = XAxisNameFormatter(resolution: 1)
        chart.xAxis.granularity = 1
        chart.xAxis.labelFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        return chart
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
        let dataEntries = viewModel.data.map({
            ChartDataEntry(
                x: $0.timeInterval,
                y: $0.price
            )
        })
        
        chartView.rightAxis.enabled = viewModel.showAxis
        chartView.xAxis.enabled = viewModel.showAxis
        
        let startPrice = viewModel.data.first?.price ?? 0.0
        let latestValue = viewModel.data.last?.price ?? 0.0
        let valueChange = latestValue - startPrice
        let fillColor: UIColor = valueChange < 0 ? .stockPriceDown : .stockPriceUp
        
        let dataSet = LineChartDataSet(entries: dataEntries)
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

final class XAxisNameFormatter: IAxisValueFormatter {
    var resolution = 0
    init(resolution: Int) {
        self.resolution = resolution
    }
    
    func stringForValue( _ value: Double, axis _: AxisBase?) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar.current
        formatter.dateFormat = "dd"
        
        return formatter.string(from: Date(timeIntervalSince1970: value))
    }
}
