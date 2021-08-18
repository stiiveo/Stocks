//
//  FinancialMetricsResponse.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/15.
//

import Foundation

struct FinancialMetricsResponse: Codable {
    let metric: Metrics
}

struct Metrics: Codable {
    let tenDayAverageVolume: Double
    let annualHigh: Double
    let annualLow: Double
    let annualLowDate: String
    let annualWeekPriceReturnDaily: Double
    let beta: Double
    
    enum CodingKeys: String, CodingKey {
        case tenDayAverageVolume = "10DayAverageTradingVolume"
        case annualHigh = "52WeekHigh"
        case annualLow = "52WeekLow"
        case annualLowDate = "52WeekLowDate"
        case annualWeekPriceReturnDaily = "52WeekPriceReturnDaily"
        case beta
    }
}
