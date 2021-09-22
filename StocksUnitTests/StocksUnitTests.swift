//
//  StocksUnitTests.swift
//  StocksUnitTests
//
//  Created by Jason Ou on 2021/7/16.
//

@testable import U_S__Stocks
import XCTest

class StocksUnitTests: XCTestCase {

    func testCandleStickDataConversion() {
        // given data
        let dataCount = 10
        let closeValues = Array(repeating: Double.random(in: 0...100), count: dataCount)
        let timestampValues = Array(repeating: TimeInterval.random(in: 1_000...2_000), count: dataCount)
        let volumeValues = Array(repeating: Int.random(in: 500...1_000), count: dataCount)
        
        let candleSticksData = PriceHistoryResponse(
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
    
    func test_string_formatters() {
        let price = 3456.7890
        let priceChange = 0.12345
        
        let formattedPrice = price.stringFormatted(by: .decimalFormatter)
        XCTAssert(formattedPrice == "3,456.79", "Formatted string: \(formattedPrice)")
        
        let formattedPercentage = priceChange.stringFormatted(by: .percentageFormatter)
        XCTAssert(formattedPercentage == "12.34%", "Formatted percentage string: \(formattedPercentage)")
        
        let signedPercentage = priceChange.signedPercentageString()
        XCTAssert(signedPercentage == "+12.34%", "Signed percentage string: \(signedPercentage)")
        
    }

}
