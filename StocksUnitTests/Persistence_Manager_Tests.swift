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
    private let watchlistKey = UserDefaultsKey.watchlist
    
    // Watchlist stored in the persistence storage.
    private var storedWatchlist: [String: String] {
        userDefaults.dictionary(forKey: watchlistKey) as? [String: String] ?? [:]
    }
    
    func test_data_consistency() {
        let retrievedList = manager.watchlist
        XCTAssertTrue(storedWatchlist == retrievedList)
    }

}
