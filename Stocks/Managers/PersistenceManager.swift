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
    
    // MARK: - Properties
    
    struct Constants {
        /// Key to access onboard status stored in the `UserDefaults`
        static let onboardKey = "isOnboarded"
        
        /// Key to access stock watchlist stored in the `UserDefaults`
        static let watchlistKey = "watchList"
        
        static let stocksDataFileName = "StocksData"
        
        static var persistingFileUrl: URL {
            let documentUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileUrl = documentUrl.appendingPathComponent(Constants.stocksDataFileName, isDirectory: false)
            return fileUrl
        }
    }
    
    private let userDefaults: UserDefaults = .standard
    
    /// The default stocks to be persisted in the `UserDefaults` if the App is launched for the first time.
    let defaultWatchList: [String: String] = [
        "AAPL": "Apple Inc.",
        "MSFT": "Microsoft Corporation",
        "GOOG": "Alphabet Inc.",
        "AMZN": "Amazon Inc.",
        "FB": "Facebook Inc."
    ]
    
    // MARK: - Init
    
    private init() {
        if !isOnboarded {
            for (symbol, companyName) in defaultWatchList {
                watchList.append(symbol)
                userDefaults.set(companyName, forKey: symbol)
            }
        }
    }
    
    // MARK: - Public
    
    /// Array of company symbols saved in defaults database.
    @UserDefaultsPersisted(wrappedValue: [], key: Constants.watchlistKey)
    private(set) var watchList: [String]
    
    /// Returns if it's the first time the watchlist is accessed.
    @UserDefaultsPersisted(wrappedValue: false, key: Constants.onboardKey)
    var isOnboarded: Bool
    
    /// Save specified company symbol and name to the watchlist.
    /// - Parameters:
    ///   - symbol: Company's stock ticker symbol.
    ///   - companyName: The company's formal name.
    func addToWatchlist(symbol: String, companyName: String) {
        watchList.append(symbol)
        userDefaults.set(companyName, forKey: symbol)
    }
    
    /// Remove specified company from the watchlist.
    /// - Parameter symbol: Stock ticker symbol of the company to be removed from the watchlist.
    func removeFromWatchlist(symbol: String) {
        watchList.removeAll(where: { $0 == symbol} )
    }
    
}
