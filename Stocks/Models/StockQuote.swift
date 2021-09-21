//
//  StockQuote.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/14.
//

import UIKit

struct StockQuote: Codable, Equatable {
    let open: Double
    let high: Double
    let low: Double
    let current: Double
    let prevClose: Double
    let time: Int
    
    enum CodingKeys: String, CodingKey {
        case open = "o"
        case high = "h"
        case low = "l"
        case current = "c"
        case prevClose = "pc"
        case time = "t"
    }
}

extension StockQuote {
    var changeColor: UIColor {
        return (current - prevClose) >= 0 ? .stockPriceUp : .stockPriceDown
    }
    
    var changePercentage: Double {
        return (current / prevClose) - 1
    }
}
