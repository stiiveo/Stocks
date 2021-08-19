//
//  SearchResponse.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/10.
//

import Foundation

struct SearchResponse: Codable {
    let count: Int
    let result: [SearchResult]
}

struct SearchResult: Codable {
    let description: String
    let displaySymbol: String
    let symbol: String
}
