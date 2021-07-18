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
        var closeValues = [Double]()
        var timestampValues = [TimeInterval]()
        var volumeValues = [Int]()
        
        for _ in 0..<dataCount {
            closeValues.append(Double.random(in: 0...100))
            timestampValues.append(TimeInterval.random(in: 1_000...2_000))
            volumeValues.append(Int.random(in: 500...1_000))
        }
        
        let candleSticksData = StockCandlesResponse(
            close: closeValues,
            timestamp: timestampValues,
            volume: volumeValues,
            status: "success"
        )
        
        // converted data
        let candleSticks = candleSticksData.priceHistory
        
        // expect
        XCTAssertEqual(candleSticks.map({ $0.close }), closeValues, "Close values do not match.")
        XCTAssertEqual(candleSticks.map({ $0.time }), timestampValues, "Time values do not match.")
    }
    
    func testDoubleStringConversion() {
//        let doubleValue = 1.2
//        let formattedString = doubleValue.stringFormatted(by: .decimalFormatter)
    }

}
