//
//  Metrics.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/15.
//

import Foundation

struct FinancialMetricsResponse: Codable {
    let metric: Metrics
}

struct Metrics: Codable {
    let open: Double?
    let high: Double?
    let low: Double?
    let marketCap: Double? // Unit: Million
    let annualHigh: Double?
    let annualLow: Double?
    let beta: Double?
    let priceToEarnings: Double?
    let priceToSales: Double?
    let yield: Double?
    let eps: Double?
    
    enum CodingKeys: String, CodingKey {
        case open, high, low, beta
        case annualHigh = "52WeekHigh"
        case annualLow = "52WeekLow"
        case marketCap = "marketCapitalization"
        case priceToEarnings = "peNormalizedAnnual"
        case priceToSales = "psTTM"
        case yield = "dividendYieldIndicatedAnnual"
        case eps = "epsInclExtraItemsTTM"
    }
}
