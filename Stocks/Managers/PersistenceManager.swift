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

struct StockDefaults {
    /// Key to access onboard status stored in the `UserDefaults`
    static let onboardKey = "hasOnboarded"
    
    /// Key to access stock watchlist stored in the `UserDefaults`
    static let watchlistKey = "watchList"
    
    /// The default stocks to be stored in the `UserDefaults` if the App is launched for the first time.
    static let defaultStocks: [String: String] = [
        "AAPL": "Apple Inc.",
        "MSFT": "Microsoft Corporation",
        "GOOG": "Alphabet Inc.",
        "AMZN": "Amazon Inc.",
        "FB": "Facebook Inc.",
        "NVDA": "Nvidia Corporation",
        "SQ": "Square Inc.",
    ]
}

protocol PersistenceManagerDelegate: AnyObject {
    func didAddNewCompanyToWatchlist(symbol: String)
}

final class PersistenceManager {
    
    // MARK: - Properties
    
    static let shared = PersistenceManager()
    
    private let userDefaults: UserDefaults = .standard
    
    weak var delegate: PersistenceManagerDelegate?
    
    private init() {}
    
    // MARK: - Public
    
    /// Array of company symbols saved in local device.
    /// - Note: If the user has not onboarded yet, a default watchlist will be stored and returned
    ///         and the `onboard` status will be switched to `true`.
    var watchList: [String] {
        if !hasOnboarded {
            userDefaults.set(true, forKey: StockDefaults.onboardKey)
            setUpDefaults()
        }
        return userDefaults.stringArray(forKey: StockDefaults.watchlistKey) ?? [] 
    }
    
    /// Save specified company symbol and name to the watchlist.
    /// - Parameters:
    ///   - symbol: Company's stock ticker symbol.
    ///   - companyName: The company's formal name.
    func addToWatchlist(symbol: String, companyName: String) {
        var currentList = watchList
        currentList.append(symbol)
        userDefaults.set(currentList, forKey: StockDefaults.watchlistKey)
        userDefaults.set(companyName, forKey: symbol)
        delegate?.didAddNewCompanyToWatchlist(symbol: symbol)
    }
    
    /// Remove specified company from the watchlist.
    /// - Parameter symbol: Stock ticker symbol of the company to be removed from the watchlist.
    func removeFromWatchlist(symbol: String) {
        var newList = [String]()
        for item in watchList where item != symbol {
            newList.append(item)
        }
        userDefaults.set(newList, forKey: StockDefaults.watchlistKey)
        userDefaults.set(nil, forKey: symbol)
    }
    
    /// Returns if the specified company symbol is saved in the watchlist.
    /// - Parameter symbol: The company's stock ticker symbol.
    /// - Returns: True if the specified company stock ticker symbol is contained in the watchlist.
    func watchListContains(_ symbol: String) -> Bool {
        return watchList.contains(symbol)
    }
    
    // MARK: - Private
    
    /// Returns if it's the first time the watchlist is accessed.
    private var hasOnboarded: Bool {
        return userDefaults.bool(forKey: StockDefaults.onboardKey)
    }
    
    /// Store preset companies to the watchlist as default.
    /// - Note: Any data previously stored in the watchlist will be replaced by the default ones.
    private func setUpDefaults() {
        // Save all company's symbol.
        let symbols = StockDefaults.defaultStocks.map{ $0.key }
        userDefaults.set(symbols, forKey: StockDefaults.watchlistKey)
        
        // Save each company's name.
        for (symbol, name) in StockDefaults.defaultStocks {
            userDefaults.set(name, forKey: symbol)
        }
    }
    
}
