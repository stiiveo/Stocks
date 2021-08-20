//
//  PersistenceManager.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

//  User Defaults Stored Data Structure:
//  )) Key: Data Type

//  1) onboardKey: Bool
//  2) watchListKey: [symbol]
//  3) companySymbol(String): companyName(String)

import Foundation

final class PersistenceManager {
    
    static let shared = PersistenceManager()
    
    private let userDefaults: UserDefaults = .standard
    
    private struct Constants {
        static let onboardKey = "hasOnboarded"
        static let watchListKey = "watchList"
    }
    
    private init() {}
    
    // MARK: - Public
    
    /// Array of company symbols saved in the watchlist.
    var watchList: [String] {
        if !hasOnboarded {
            userDefaults.set(true, forKey: Constants.onboardKey)
            setUpDefaults()
        }
        return userDefaults.stringArray(forKey: Constants.watchListKey) ?? [] 
    }
    
    /// Save specified company symbol and name to the watchlist.
    /// - Parameters:
    ///   - symbol: Company's stock ticker symbol.
    ///   - companyName: The company's formal name.
    public func addToWatchlist(symbol: String, companyName: String) {
        var currentList = watchList
        currentList.append(symbol)
        userDefaults.set(currentList, forKey: Constants.watchListKey)
        userDefaults.set(companyName, forKey: symbol)
        // Notify the observer that a new company is added to the watch list.
        NotificationCenter.default.post(name: .didAddToWatchList, object: nil)
    }
    
    /// Remove specified company from the watchlist.
    /// - Parameter symbol: Stock ticker symbol of the company to be removed from the watchlist.
    public func removeFromWatchlist(symbol: String) {
        var newList = [String]()
        for item in watchList where item != symbol {
            newList.append(item)
        }
        userDefaults.set(newList, forKey: Constants.watchListKey)
        userDefaults.set(nil, forKey: symbol)
    }
    
    /// Returns if the specified company symbol is saved in the watchlist.
    /// - Parameter symbol: The company's stock ticker symbol.
    /// - Returns: True if the specified company stock ticker symbol is contained in the watchlist.
    public func watchListContains(_ symbol: String) -> Bool {
        return watchList.contains(symbol)
    }
    
    // MARK: - Private
    
    /// Returns if it's the first time the watchlist is accessed.
    private var hasOnboarded: Bool {
        return userDefaults.bool(forKey: Constants.onboardKey)
    }
    
    /// Store preset companies to the watchlist as default.
    /// - Note: Any data previously stored in the watchlist will be replaced by the default ones.
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
        userDefaults.set(symbols, forKey: Constants.watchListKey)
        
        // Save each company's name.
        for (symbol, name) in defaultStocks {
            userDefaults.set(name, forKey: symbol)
        }
    }
    
}
