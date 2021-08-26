//
//  StockChartView.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/13.
//

import UIKit
import Charts

class StockChartView: LineChartView {
    
    // MARK: - Properties
    
    struct ViewModel {
        let data: [StockLineChartData]
        let previousClose: Double
        let showAxis: Bool
    }
    
    struct StockLineChartData {
        let timeInterval: Double
        let price: Double
    }
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpChartView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    
    // Reset chart view
    func reset() {
        data = nil
    }
    
    func configure(with viewModel: ViewModel) {
        // Switch the appearance of the right and x axis.
        rightAxis.enabled = viewModel.showAxis
        xAxis.enabled = viewModel.showAxis
        
        // Chart Data Entries
        let entries: [ChartDataEntry] = viewModel.data.map{
            .init(x: $0.timeInterval, y: $0.price)
        }
        guard entries.count >= 2 else { return }
        
        // Set up xAxis' maximum value if the data range is less or equal to the latest trading time span.
        let latestOpenTime = CalendarManager.shared.latestTradingTime.open.timeIntervalSince1970
        let latestCloseTime = CalendarManager.shared.latestTradingTime.close.timeIntervalSince1970
        let timeSpanOnTheLatestTradingTime = latestCloseTime - latestOpenTime
        let isDataRangeWithinLatestTradingTimeRange = (entries.last!.x - entries.first!.x) <= timeSpanOnTheLatestTradingTime
        
        let startPrice = viewModel.data.first?.price ?? 0.0
        let latestValue = viewModel.data.last?.price ?? 0.0
        let valueChange = latestValue - startPrice
        
        // If the data range is within the time span of the latest trading time,
        // the fill color of the line chart is determined by the difference
        // between the previous close price and the last price in the data entry;
        // Otherwise, it's determined by the difference between the first and the
        // last price in the data entry.
        var fillColor: UIColor = .stockPriceUp
        if isDataRangeWithinLatestTradingTimeRange {
            xAxis.axisMaximum = latestCloseTime
            fillColor = (latestValue - viewModel.previousClose < 0) ? .stockPriceDown : .stockPriceUp
        } else {
            fillColor = valueChange < 0 ? .stockPriceDown : .stockPriceUp
        }
        
        let dataSet = LineChartDataSet(entries: entries)
        dataSet.drawCirclesEnabled = false
        dataSet.drawIconsEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.drawFilledEnabled = true
        dataSet.setColor(fillColor)
        dataSet.fillColor = fillColor
        dataSet.lineWidth = 1.5

        let data = LineChartData(dataSet: dataSet)
        self.data = data
    }
    
    // MARK: - Private
    
    private func setUpChartView() {
        minOffset = 0.0
        legend.enabled = false
        xAxis.enabled = false
        leftAxis.enabled = false
        rightAxis.enabled = false
        drawGridBackgroundEnabled = false
        rightAxis.labelFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        xAxis.labelPosition = .bottom
        xAxis.valueFormatter = XAxisValueFormatter()
        xAxis.labelFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        xAxis.avoidFirstLastClippingEnabled = true
        xAxis.granularity = 3600.0 // minimum interval between xAxis values
    }

}

final class XAxisValueFormatter: IAxisValueFormatter {
    func stringForValue( _ value: Double, axis _: AxisBase?) -> String {
        let formatter = DateFormatter()
        formatter.calendar = CalendarManager.shared.newYorkCalendar
        formatter.dateFormat = "h"
        
        return formatter.string(from: Date(timeIntervalSince1970: value))
    }
}
