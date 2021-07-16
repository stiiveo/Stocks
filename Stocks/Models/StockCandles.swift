//
//  StockCandles.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/13.
//

import Foundation

struct StockCandles: Codable {
    
    let open: [Double]
    let high: [Double]
    let low: [Double]
    let close: [Double]
    let timestamp: [TimeInterval]
    let volume: [Int]
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case open = "o"
        case high = "h"
        case low = "l"
        case close = "c"
        case timestamp = "t"
        case volume = "v"
        case status = "s"
    }
    
    var candleSticks: [CandleStick] {
        var data = [CandleStick]()
        
        for index in 0..<open.count {
            data.append(
                .init(date: Date(timeIntervalSince1970: timestamp[index]),
                      open: open[index],
                      high: high[index],
                      low: low[index],
                      close: close[index])
            )
        }
        
        return data
    }
}

struct CandleStick {
    let date: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
}
