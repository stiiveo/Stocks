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
        let data: [PriceHistory]
        let previousClose: Double?
        let highestClose: Double?
        let lowestClose: Double?
        let showAxis: Bool
    }
    
    private let calendar = CalendarManager()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpChartView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    
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
        noDataText = ""
        
        // Right axis
        rightAxis.enabled = false
        rightAxis.labelFont = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .semibold)
        rightAxis.setLabelCount(4, force: true)
        rightAxis.gridLineWidth = 0.25
        
        // X-Axis
        xAxis.enabled = false
        xAxis.labelPosition = .bottom
        xAxis.valueFormatter = XAxisValueFormatter()
        xAxis.labelFont = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .semibold)
        xAxis.avoidFirstLastClippingEnabled = true
        xAxis.setLabelCount(7, force: true)
        xAxis.gridLineWidth = 0.25
    }
    
    private func setUpChartData(with viewModel: ViewModel) {
        guard let previousClose = viewModel.previousClose,
              let highestClose = viewModel.highestClose,
              let lowestClose = viewModel.lowestClose else {
            return
        }
        
        // Chart Data Entries
        let priceDataEntries: [ChartDataEntry] = viewModel.data.map{
            .init(x: $0.time, y: $0.close)
        }
        guard priceDataEntries.count >= 2,
              let firstValue = viewModel.data.first?.close,
              let latestValue = viewModel.data.last?.close,
              let firstTimestamp = priceDataEntries.first?.x,
              let lastTimestamp = priceDataEntries.last?.x else { return }
        
        let latestOpenTime = calendar.latestTradingTime.open.timeIntervalSince1970
        let latestCloseTime = calendar.latestTradingTime.close.timeIntervalSince1970
        let latestTradingDayDuration = latestCloseTime - latestOpenTime
        
        let isTimeRangeWithinLatestTradingTimeRange = (lastTimestamp - firstTimestamp) <= latestTradingDayDuration
        
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
        let previousPriceDataSet = staticLineChartDataSet(
            value: previousClose,
            startTime: priceDataEntries[0].x,
            endTime: latestCloseTime,
            dashLengths: [2])
        var drawPreviousPriceLine = false
        
        // Set x-axis' maximum value if the data's time range is within the latest trading time span.
        if isTimeRangeWithinLatestTradingTimeRange {
            xAxis.axisMaximum = latestCloseTime
            fillColor = (latestValue - previousClose < 0) ? .stockPriceDown : .stockPriceUp
            let tolerance = 0.05 // Unit in percentage
            
            // Draw previous close dash line if it's within the tolerated price offset.
            if previousClose <= (highestClose * (1 + tolerance)) &&
                previousClose >= (lowestClose * (1 - tolerance)) {
                drawPreviousPriceLine = true
            }
        } else {
            let valueChange = latestValue - firstValue
            fillColor = valueChange < 0 ? .stockPriceDown : .stockPriceUp
        }
        
        let priceDataSet = lineChartDataSetWithGradientFill(priceDataEntries, fillColor: fillColor)
        var lineChartDataSets = [priceDataSet]
        
        if drawPreviousPriceLine {
            // Draw a horizontal dash line across the whole time line with previous close value.
            lineChartDataSets.append(previousPriceDataSet)
        }
        
        self.data = LineChartData(dataSets: lineChartDataSets)
    }
    
    /// Returns a `LineChartDataSet` object created from provided `ChartDataEntry` array filled with specified gradient color.
    /// - Parameters:
    ///   - entries: Data entries used to create a line chart data set.
    ///   - fillColor: An `UIColor` object used as the fill color.
    /// - Returns: Returns a `LineChartDataSet` object created from provided `ChartDataEntry` array filled with specified gradient color.
    private func lineChartDataSetWithGradientFill(_ entries: [ChartDataEntry], fillColor: UIColor) -> LineChartDataSet {
        let dataSet = LineChartDataSet(entries: entries)
        dataSet.drawCirclesEnabled = false
        dataSet.drawIconsEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.drawFilledEnabled = true
        dataSet.setColor(fillColor)
        dataSet.lineWidth = 1.8
        
        let gradientColors = [fillColor.cgColor, UIColor.clear.cgColor] as CFArray
        let gradientLocations: [CGFloat] = [1.0, 0.0]
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: gradientColors,
                                     locations: gradientLocations) {
            dataSet.fill = Fill.fillWithLinearGradient(gradient, angle: 90.0)
        }
        return dataSet
    }
    
    /// A `LineChartDataSet` object created from provided `value`, `startTime` and `endTime`.
    /// - Parameters:
    ///   - value: The value of the data entries.
    ///   - startTime: A `TimeInterval` value indicating the first time point of the data set.
    ///   - endTime: A `TimeInterval` value indicating the last time point of the data set.
    /// - Returns: Returns a `LineCharDataSet` object.
    private func staticLineChartDataSet(value: Double,
                                        startTime: TimeInterval,
                                        endTime: TimeInterval,
                                        dashLengths: [CGFloat]? = nil) -> LineChartDataSet {
        let entries: [ChartDataEntry] = [.init(x: startTime, y: value),
                                         .init(x: endTime, y: value)]
        let dataSet = LineChartDataSet(entries: entries)
        dataSet.drawCirclesEnabled = false
        dataSet.drawIconsEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.setColor(.systemGray)
        dataSet.lineWidth = 0.75
        dataSet.lineDashLengths = dashLengths
        return dataSet
    }

}

final class XAxisValueFormatter: IAxisValueFormatter {
    func stringForValue( _ value: Double, axis _: AxisBase?) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        formatter.calendar = CalendarManager().newYorkCalendar
        formatter.dateFormat = "H:mm"
        let formattedString = formatter.string(from: Date(timeIntervalSince1970: value))
        
        if formattedString == "9:30" || formattedString == "16:00" {
            return ""
        } else {
            return formattedString
        }
    }
}
