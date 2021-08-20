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
    private let testSymbol = "SYMBOL"
    private let testCompanyName = "Company Inc."
    
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
    
    func test_watchlist_retrieval_and_default_list_setup() {
        // Set onboard status to false and trigger defaults set up.
        userDefaults.setValue(false, forKey: onboardKey)
        let retrievedWatchlist = manager.watchList
        
        // Assertion
        XCTAssert(retrievedWatchlist == watchlist,
                  "Retrieved watchlist does not match with the actual one.")
        
        let defaultSymbols = defaultStocks.map{ $0.key }
        XCTAssert(watchlist.containsSameElement(as: defaultSymbols),
                  "Watchlist (\(watchlist)) does not contain same elements as the default one.")
    }
    
    func test_watchlist_retrieving() {
        XCTAssert(manager.watchList == watchlist,
                  "Retrieved watchlist (\(watchlist)) does not match with the stored one.")
    }
    
    func test_watchlist_addition() {
        let originalWatchlist = watchlist
        
        // Correct watchlist
        var correctList = userDefaults.stringArray(forKey: watchlistKey) ?? []
        correctList.append(testSymbol)
        
        manager.addToWatchlist(symbol: testSymbol, companyName: testCompanyName)
        
        // Assertion
        XCTAssert(watchlist == correctList)
        
        let retrievedCompanyName = userDefaults.string(forKey: testSymbol)
        XCTAssert(retrievedCompanyName == testCompanyName)
        
        // Restore the watchlist and remove test company name.
        userDefaults.setValue(originalWatchlist, forKey: watchlistKey)
        userDefaults.setValue(nil, forKey: testSymbol)
    }
    
    func test_watchlist_deletion() {
        let originalWatchlist = watchlist
        
        // Add test company symbol and name to watchlist before deletion test.
        var testSymbolAddedWatchlist = watchlist
        testSymbolAddedWatchlist.append(testSymbol)
        userDefaults.setValue(testSymbolAddedWatchlist, forKey: watchlistKey)
        userDefaults.setValue(testCompanyName, forKey: testSymbol)
        
        // Deletion
        manager.removeFromWatchlist(symbol: testSymbol)
        
        // Assertion
        XCTAssert(watchlist == originalWatchlist,
                  "Watchlist after deletion is not identical to the original one")
        XCTAssert(userDefaults.string(forKey: testSymbol) == nil,
                  "Company name is not removed.")
    }
    
    func test_contains_func() {
        let originalWatchlist = watchlist
        
        // Add test symbol to the watchlist
        var list = watchlist
        list.append(testSymbol)
        userDefaults.setValue(list, forKey: watchlistKey)
        
        // Assertion
        let containsTestSymbol = manager.watchListContains(testSymbol)
        XCTAssert(containsTestSymbol,
                  "Contains function returns false even though the watchlist contains test symbol")
        
        // Restore the watchlist
        userDefaults.setValue(originalWatchlist, forKey: watchlistKey)
    }

}

extension Array where Element: Comparable {
    func containsSameElement(as other: [Element]) -> Bool {
        return self.count == other.count && self.sorted() == other.sorted()
    }
}
