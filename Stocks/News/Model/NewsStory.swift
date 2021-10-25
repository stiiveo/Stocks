//
//  NewsStory.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/11.
//

import Foundation

struct NewsStory: Codable {
    let category: String
    let date: TimeInterval
    let headline: String
    let id: Int
    let image: String
    let related: String
    let source: String
    let summary: String
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case date = "datetime"
        case category
        case headline
        case id
        case image
        case related
        case source
        case summary
        case url
    }
}
