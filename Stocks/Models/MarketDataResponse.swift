//
//  MarketDataResponse.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/13.
//

import Foundation

struct MarketDataResponse: Codable {
    let close: [Double]
    let high: [Double]
    let low: [Double]
    let open: [Double]
    let status: String
    let timestamp: [TimeInterval]
    let volume: [Int]
    
    enum CodingKeys: String, CodingKey {
        case close = "c"
        case high = "h"
        case low = "l"
        case open = "o"
        case status = "s"
        case timestamp = "t"
        case volume = "v"
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
        
        let dataSortedByDate = data.sorted(by: { $0.date < $1.date } )
        return dataSortedByDate
    }
}

struct CandleStick {
    let date: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
}
