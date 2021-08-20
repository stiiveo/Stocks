//
//  API_Tests.swift
//  StocksUnitTests
//
//  Created by Jason Ou on 2021/8/19.
//

@testable import Stocks
import XCTest

class API_Tests: XCTestCase {
    
    private let apiCaller = APICaller.shared
    private let testSymbol = "AAPL"
    private let testDescription = "Apple Inc."
    
    func test_Search() {
        apiCaller.search(query: testSymbol) { [weak self] result in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Search attempt failed: \(error)")
            case .success(let response):
                guard response.count > 0 else {
                    XCTAssert(false, "Search resulted with 0 match.")
                    return
                }
                guard let targetResult = response.result.filter(
                    { $0.symbol == self?.testSymbol }
                ).first else {
                    XCTAssert(false, "No symbol matched from the search result.")
                    return
                }
                XCTAssert(targetResult.description == self?.testDescription,
                          "Matched result's description did not match.")
            }
        }
    }
    
    func test_news_fetching() {
        // Top stories
        apiCaller.fetchNews(for: .topStories) { result in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Fetch result failed: \(error)")
            case .success(let stories):
                XCTAssert(stories.count > 0, "Top stories' count is 0")
            }
        }
        
        // Company stories
        apiCaller.fetchNews(for: .company(symbol: testSymbol)) { result in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Failed to fetch test company's stories: \(error)")
            case .success(let stories):
                XCTAssert(stories.count > 0, "Stories count is 0")
            }
        }
    }
    
    func test_quote_fetching() {
        apiCaller.fetchStockQuote(for: testSymbol) { result in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Quote fetching failed: \(error)")
            case .success(_):
                XCTAssert(true)
            }
        }
    }
    
    func test_stock_candles_fetching() {
        apiCaller.fetchPriceHistory(
            testSymbol,
            dataResolution: .fiveMinutes,
            days: 7
        ) { result in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Failed to fetch stock candles data: \(error)")
            case .success(_):
                XCTAssert(true)
            }
        }
    }
    
    func test_stock_metrics_fetching() {
        apiCaller.fetchFinancialMetrics(symbol: testSymbol) { result in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Failed to fetch stock metrics data: \(error)")
            case .success(_):
                XCTAssert(true)
            }
        }
    }

}
