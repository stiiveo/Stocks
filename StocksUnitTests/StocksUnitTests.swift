//
//  StocksUnitTests.swift
//  StocksUnitTests
//
//  Created by Jason Ou on 2021/7/16.
//

@testable import Stocks

import XCTest
import Foundation

class StocksUnitTests: XCTestCase {

    func testCandleStickDataConversion() {
        // given data
        let dataCount = 10
        var openValues = [Double]()
        var highValues = [Double]()
        var lowValues = [Double]()
        var closeValues = [Double]()
        var timestampValues = [TimeInterval]()
        var volumeValues = [Int]()
        
        for _ in 0..<dataCount {
            openValues.append(Double.random(in: 0...100))
            highValues.append(Double.random(in: 0...100))
            lowValues.append(Double.random(in: 0...100))
            closeValues.append(Double.random(in: 0...100))
            timestampValues.append(TimeInterval.random(in: 1_000...2_000))
            volumeValues.append(Int.random(in: 500...1_000))
        }
        
        let candleSticksData = StockCandles(
            open: openValues,
            high: highValues,
            low: lowValues,
            close: closeValues,
            timestamp: timestampValues,
            volume: volumeValues,
            status: "success"
        )
        
        // converted data
        let candleSticks = candleSticksData.candleSticks
        
        // expect
        XCTAssertEqual(candleSticks.map({ $0.open }), openValues, "Open values do not match.")
        XCTAssertEqual(candleSticks.map({ $0.high }), highValues, "High values do not match.")
        XCTAssertEqual(candleSticks.map({ $0.low }), lowValues, "Low values do not match.")
        XCTAssertEqual(candleSticks.map({ $0.close }), closeValues, "Close values do not match.")
        XCTAssertEqual(candleSticks.map({ $0.date }), timestampValues.map({ Date(timeIntervalSince1970: $0) }), "Date values converted from timestamp values do not match.")
    }
    
    func testDoubleStringConversion() {
//        let doubleValue = 1.2
//        let formattedString = doubleValue.stringFormatted(by: .decimalFormatter)
    }

}
