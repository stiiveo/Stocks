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
        extraTopOffset = viewModel.showAxis ? 8.0 : 0
        xAxis.enabled = viewModel.showAxis
        setUpChartData(with: viewModel)
    }
    
    // MARK: - Private
    
    private func setUpChartView() {
        // Remove default padding around the chart.
        minOffset = 0.0
        
        legend.enabled = false
        leftAxis.enabled = false
        drawGridBackgroundEnabled = false
        
        // Right axis
        rightAxis.enabled = false
        rightAxis.labelFont = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .semibold)
        rightAxis.setLabelCount(4, force: true)
        rightAxis.gridLineWidth = 0.25
        
        // X-Axis
        xAxis.enabled = false
        xAxis.labelPosition = .bottom
        xAxis.granularity = 3600.0 // minimum interval between xAxis values
        xAxis.valueFormatter = XAxisValueFormatter()
        xAxis.labelFont = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        xAxis.avoidFirstLastClippingEnabled = true
        xAxis.setLabelCount(6, force: true)
        xAxis.gridLineWidth = 0.25
    }
    
    private func setUpChartData(with viewModel: ViewModel) {
        // Chart Data Entries
        let entries: [ChartDataEntry] = viewModel.data.map{
            .init(x: $0.timeInterval, y: $0.price)
        }
        guard entries.count >= 2 else { return }
        
        let latestOpenTime = CalendarManager.shared.latestTradingTime.open.timeIntervalSince1970
        let latestCloseTime = CalendarManager.shared.latestTradingTime.close.timeIntervalSince1970
        let timeIntervalBetweenLatestTradingDay = latestCloseTime - latestOpenTime
        guard let firstDataTimeStamp = entries.first?.x,
              let lastDataTimeStamp = entries.last?.x else { return }
        let isTimeRangeWithinLatestTradingTimeRange = (lastDataTimeStamp - firstDataTimeStamp) <= timeIntervalBetweenLatestTradingDay
        
        guard let startPrice = viewModel.data.first?.price,
              let latestValue = viewModel.data.last?.price else { return }
        let valueChange = latestValue - startPrice
        
        /*
         Since the opening price of a stock could be higher or lower than its
         previous close price, whether the price is higher or lower than the
         previous close price cannot be determined by simply calculating the
         difference between the first and the latest price, but the previous
         close price and the latest price instead.
         
         If the data's time range is within the time span of the latest trading time,
         the fill color of the line chart is determined by the difference
         between the previous close price and the last price in the data entry;
         Otherwise, it's determined by the difference between the first and the
         last price in the data entry.
         */
        var fillColor: UIColor = .stockPriceUp
        
        // Set x-axis' maximum value if the data's time range is within the latest trading time span.
        if isTimeRangeWithinLatestTradingTimeRange {
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
        dataSet.lineWidth = 1.5
        
        // Set up gradient color fill.
        let gradientColors = [fillColor.cgColor, UIColor.clear.cgColor] as CFArray
        let gradientLocations: [CGFloat] = [1.0, 0.0]
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: gradientColors,
                                     locations: gradientLocations) {
            dataSet.fill = Fill.fillWithLinearGradient(gradient, angle: 90.0)
        }
        
        let data = LineChartData(dataSet: dataSet)
        self.data = data
    }

}

final class XAxisValueFormatter: IAxisValueFormatter {
    func stringForValue( _ value: Double, axis _: AxisBase?) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        formatter.calendar = CalendarManager.shared.newYorkCalendar
        formatter.dateFormat = "H"
        return formatter.string(from: Date(timeIntervalSince1970: value))
    }
}
