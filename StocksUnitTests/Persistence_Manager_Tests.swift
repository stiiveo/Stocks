//
//  Persistence_Manager_Tests.swift
//  StocksUnitTests
//
//  Created by Jason Ou on 2021/8/20.
//

@testable import Stocks
import XCTest

class Persistence_Manager_Tests: XCTestCase {
    
    private let manager = PersistenceManager.shared
    private let userDefaults: UserDefaults = .standard
    
    // Test use company symbol and name.
    private let companySymbol = "SYMBOL"
    private let companyName = "Company Inc."
    
    // User defaults keys.
    private let watchlistKey = "watchList"
    private let onboardKey = "hasOnboarded"
    
    // Default watchlist
    private let defaultStocks: [String: String] = [
        "AAPL": "Apple Inc.",
        "MSFT": "Microsoft Corporation",
        "GOOG": "Alphabet Inc.",
        "AMZN": "Amazon Inc.",
        "NVDA": "Nvidia Corporation",
        "FB": "Facebook Inc.",
        "SQ": "Square Inc.",
    ]
    
    // Watchlist stored in the persistence storage.
    private var watchlist: [String] {
        userDefaults.stringArray(forKey: watchlistKey) ?? []
    }
    
    func test_onboarding() {
        let hasOnboarded = userDefaults.bool(forKey: onboardKey)
        if !hasOnboarded {
            XCTAssert(defaultStocks.map{ $0.key } == watchlist,
                      "Returned watchlist: '\(watchlist)' does not match with the default one.")
        }
    }
    
    func test_watchlist_retrieving() {
        XCTAssert(manager.watchList == watchlist,
                  "Retrieved watchlist (\(watchlist)) does not match with the stored one.")
    }
    
    func test_watchlist_addition() {
        let originalWatchlist = watchlist
        
        // Correct watchlist
        var correctList = userDefaults.stringArray(forKey: watchlistKey) ?? []
        correctList.append(companySymbol)
        
        manager.addToWatchlist(symbol: companySymbol, companyName: companyName)
        
        // Assertion
        XCTAssert(watchlist == correctList)
        
        let retrievedCompanyName = userDefaults.string(forKey: companySymbol)
        XCTAssert(retrievedCompanyName == companyName)
        
        // Restore the watchlist and remove test company name.
        userDefaults.setValue(originalWatchlist, forKey: watchlistKey)
        userDefaults.setValue(nil, forKey: companySymbol)
    }
    
    func test_watchlist_deletion() {
        let originalWatchlist = watchlist
        
        // Add test company symbol and name to watchlist before deletion test.
        var testSymbolAddedWatchlist = watchlist
        testSymbolAddedWatchlist.append(companySymbol)
        userDefaults.setValue(testSymbolAddedWatchlist, forKey: watchlistKey)
        userDefaults.setValue(companyName, forKey: companySymbol)
        
        // Deletion
        manager.removeFromWatchlist(symbol: companySymbol)
        
        // Assertion
        XCTAssert(watchlist == originalWatchlist,
                  "Watchlist after deletion is not identical to the original one")
        XCTAssert(userDefaults.string(forKey: companySymbol) == nil,
                  "Company name is not removed.")
    }
    
    func test_contains_func() {
        let originalWatchlist = watchlist
        
        // Add test symbol to the watchlist
        var list = watchlist
        list.append(companySymbol)
        userDefaults.setValue(list, forKey: watchlistKey)
        
        // Assertion
        let containsTestSymbol = manager.watchListContains(companySymbol)
        XCTAssert(containsTestSymbol,
                  "Contains function returns false even though the watchlist contains test symbol")
        
        // Restore the watchlist
        userDefaults.setValue(originalWatchlist, forKey: watchlistKey)
    }

}
