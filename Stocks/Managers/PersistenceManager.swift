//
//  PersistenceManager.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import Foundation

final class PersistenceManager {
    
    static let shared = PersistenceManager()
    
    private let userDefaults: UserDefaults = .standard
    
    private struct Constants {
        static let onboardKey = "hasOnboarded"
        static let watchlistKey = "watchlist"
    }
    
    private init() {}
    
    // MARK: - Public
    
    var watchlist: [String] {
        if !hasOnboarded {
            userDefaults.set(true, forKey: Constants.onboardKey)
            setUpDefaults()
        }
        return userDefaults.stringArray(forKey: Constants.watchlistKey) ?? [] 
    }
    
    public func addToWatchlist() {
        
    }
    
    public func removeFromWatchlist() {
        
    }
    
    // MARK: - Private
    
    private var hasOnboarded: Bool {
        return userDefaults.bool(forKey: Constants.onboardKey)
    }
    
    private func setUpDefaults() {
        let defaultStocks: [String: String] = [
            "AAPL": "Apple Inc.",
            "MSFT": "Microsoft Corporation",
            "GOOG": "Alphabet Inc.",
            "AMZN": "Amazon Inc.",
            "NVDA": "Nvidia Corporation",
            "FB": "Facebook Inc.",
            "SQ": "Square Inc.",
        ]
        
        // Save all company's symbol.
        let symbols = defaultStocks.map{ $0.key }
        userDefaults.setValue(symbols, forKey: Constants.watchlistKey)
        
        // Save each company's name.
        for (symbol, name) in defaultStocks {
            userDefaults.set(name, forKey: symbol)
        }
    }
    
}
