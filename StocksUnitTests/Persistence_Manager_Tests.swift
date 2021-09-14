//
//  Persistence_Manager_Tests.swift
//  StocksUnitTests
//
//  Created by Jason Ou on 2021/8/20.
//

@testable import U_S__Stocks
import XCTest

class Persistence_Manager_Tests: XCTestCase {
    
    private let manager = PersistenceManager.shared
    private let userDefaults: UserDefaults = .standard
    
    // Test use company symbol and name.
    private let testSymbol = "SYMBOL"
    private let testCompanyName = "Company Inc."
    
    // User defaults keys.
    private let watchlistKey = PersistenceManager.Constants.watchlistKey
    private let onboardKey = PersistenceManager.Constants.onboardKey
    
    // Watchlist stored in the persistence storage.
    private var storedWatchlist: [String] {
        userDefaults.stringArray(forKey: watchlistKey) ?? []
    }
    
    func test_watchlist_retrieval_and_default_list_setup() {
        // Set onboard status to false and trigger defaults set up.
        userDefaults.setValue(false, forKey: onboardKey)
        let retrievedWatchlist = manager.watchList
        
        // Assertion
        XCTAssert(retrievedWatchlist == storedWatchlist,
                  "Retrieved watchlist does not match with the actual one.")
        
        let defaultSymbols = PersistenceManager.StockDefaults.defaultStocks.map{ $0.key }
        XCTAssert(storedWatchlist.containsSameElement(as: defaultSymbols),
                  "Watchlist (\(storedWatchlist)) does not contain same elements as the default one.")
    }
    
    func test_watchlist_retrieving() {
        XCTAssert(manager.watchList == storedWatchlist,
                  "Retrieved watchlist (\(storedWatchlist)) does not match with the stored one.")
    }
    
    func test_watchlist_addition() {
        let originalWatchlist = storedWatchlist
        
        // Correct watchlist
        var correctList = userDefaults.stringArray(forKey: watchlistKey) ?? []
        correctList.append(testSymbol)
        
        manager.addToWatchlist(symbol: testSymbol, companyName: testCompanyName)
        
        // Assertion
        XCTAssert(storedWatchlist == correctList)
        
        let retrievedCompanyName = userDefaults.string(forKey: testSymbol)
        XCTAssert(retrievedCompanyName == testCompanyName)
        
        // Restore the watchlist and remove test company name.
        userDefaults.setValue(originalWatchlist, forKey: watchlistKey)
        userDefaults.setValue(nil, forKey: testSymbol)
    }
    
    func test_watchlist_deletion() {
        let originalWatchlist = storedWatchlist
        
        // Add test company symbol and name to watchlist before deletion test.
        var testSymbolAddedWatchlist = storedWatchlist
        testSymbolAddedWatchlist.append(testSymbol)
        userDefaults.setValue(testSymbolAddedWatchlist, forKey: watchlistKey)
        userDefaults.setValue(testCompanyName, forKey: testSymbol)
        
        // Deletion
        manager.removeFromWatchlist(symbol: testSymbol)
        
        // Assertion
        XCTAssert(storedWatchlist.sorted() == originalWatchlist.sorted(),
                  "Watchlist after deletion is not identical to the original one")
        XCTAssert(userDefaults.string(forKey: testSymbol) == nil,
                  "Company name is not removed.")
    }
    
    func test_contains_func() {
        let originalWatchlist = storedWatchlist
        
        // Add test symbol to the watchlist
        var list = storedWatchlist
        list.append(testSymbol)
        userDefaults.setValue(list, forKey: watchlistKey)
        
        // Assertion
        let containsTestSymbol = manager.watchListContains(testSymbol)
        XCTAssert(containsTestSymbol,
                  "Contains function returns false even though the watchlist contains test symbol")
        
        // Restore the watchlist
        userDefaults.setValue(originalWatchlist, forKey: watchlistKey)
    }
    
    func test_persisting_stocks_data() {
        let dataToPersist = [
            StockData(symbol: "AAPL",
                      quote: StockQuote(open: 90, high: 110, low: 80, current: 100, prevClose: 50, time: 123456780),
                      priceHistory: [PriceHistory(time: 123456789.0, close: 100)]),
            StockData(symbol: "TSLA",
                      quote: StockQuote(open: 800, high: 1100, low: 500, current: 1000, prevClose: 500, time: 123456780),
                      priceHistory: [PriceHistory(time: 123456789.0, close: 500)]),
        ]
        manager.persistStocksData(dataToPersist)
        let persistedData = manager.persistedStocksData()
        
        XCTAssertEqual(persistedData, dataToPersist)
    }

}

extension Array where Element: Comparable {
    func containsSameElement(as other: [Element]) -> Bool {
        return self.count == other.count && self.sorted() == other.sorted()
    }
}
