//
//  PersistenceManager.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import Foundation

struct UserDefaultsKey {
    static let isOnboarded = "isOnboarded"
    static let watchlist = "watchList"
}

final class PersistenceManager {
    
    static let shared = PersistenceManager()
    
    // MARK: - Properties
        
    static var persistedDataUrl: URL {
        let documentUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileUrl = documentUrl.appendingPathComponent("StocksData", isDirectory: false)
        return fileUrl
    }
    
    private let userDefaults: UserDefaults = .standard
    
    /// The default stocks to be persisted in the `UserDefaults` if the App is launched for the first time.
    static let defaultWatchlist: [String: String] = [
        "AAPL": "Apple Inc.",
        "MSFT": "Microsoft Corporation",
        "GOOG": "Alphabet Inc.",
        "AMZN": "Amazon Inc.",
        "FB": "Facebook Inc."
    ]
    
    static var defaultData: [StockData] {
        var data = [StockData]()
        PersistenceManager.defaultWatchlist.keys.sorted().forEach {
            data.append(StockData(symbol: $0))
        }
        return data
    }
    
    // MARK: - Public
    
    @UserDefaultsPersisted(key: UserDefaultsKey.isOnboarded)
    var isOnboarded: Bool = false
    
    @UserDefaultsPersisted(key: UserDefaultsKey.watchlist)
    var watchlist: [String: String] = PersistenceManager.defaultWatchlist
    
}
