//
//  StockCandlesResponse.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/13.
//

import Foundation

struct StockCandlesResponse: Codable {
    let close: [Double]
    let timestamp: [TimeInterval]
    let volume: [Int]
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case close = "c"
        case timestamp = "t"
        case volume = "v"
        case status = "s"
    }
    
    var priceHistory: [PriceHistory] {
        guard close.count == timestamp.count else { return [] }
        
        var data = [PriceHistory]()
        for index in 0..<close.count {
            data.append(
                .init(time: timestamp[index], close: close[index])
            )
        }
        return data
    }
}

struct PriceHistory {
    let time: TimeInterval
    let close: Double
}
