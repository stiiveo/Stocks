//
//  StockData.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/14.
//

import Foundation

struct StockData: Codable {
    let symbol: String
    let quote: StockQuote
    let priceHistory: [PriceHistory]
}

extension StockData: Equatable {
    static func == (lhs: StockData, rhs: StockData) -> Bool {
        return lhs.symbol == rhs.symbol &&
            lhs.quote == rhs.quote &&
            lhs.priceHistory == rhs.priceHistory
    }
}
