//
//  Persistence_Manager_Tests.swift
//  StocksUnitTests
//
//  Created by Jason Ou on 2021/8/20.
//

@testable import U_S__Stocks
import XCTest

class Persistence_Manager_Tests: XCTestCase {
    
    private let manager = PersistenceManager()
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
        XCTAssert(storedWatchlist.difference(from: originalWatchlist).isEmpty,
                  "Watchlist after deletion is not identical to the original one")
    }
    
    func test_contains_func() {
        let originalWatchlist = storedWatchlist
        
        // Add test symbol to the watchlist
        var list = storedWatchlist
        list.append(testSymbol)
        userDefaults.setValue(list, forKey: watchlistKey)
        
        // Assertion
        let containsTestSymbol = manager.watchList.contains(testSymbol)
        XCTAssert(containsTestSymbol,
                  "Contains function returns false even though the watchlist contains test symbol")
        
        // Restore the watchlist
        userDefaults.setValue(originalWatchlist, forKey: watchlistKey)
    }
    
    func test_persisted_data_retrieval() {
        let watchlist = manager.watchList
        let persistedList = try! manager.persistedStocksData().map({ $0.symbol })
        XCTAssertTrue(watchlist.difference(from: persistedList).isEmpty)
    }

}
