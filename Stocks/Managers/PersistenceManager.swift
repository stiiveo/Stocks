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

protocol PersistenceManagerDelegate: AnyObject {
    func didAddNewCompanyToWatchlist(symbol: String)
}

final class PersistenceManager {
    
    struct StockDefaults {
        /// The default stocks to be stored in the `UserDefaults` if the App is launched for the first time.
        static let defaultStocks: [String: String] = [
            "AAPL": "Apple Inc.",
            "MSFT": "Microsoft Corporation",
            "GOOG": "Alphabet Inc.",
            "AMZN": "Amazon Inc.",
            "FB": "Facebook Inc."
        ]
    }
    
    struct Constants {
        /// Key to access onboard status stored in the `UserDefaults`
        static let onboardKey = "hasOnboarded"
        
        /// Key to access stock watchlist stored in the `UserDefaults`
        static let watchlistKey = "watchList"
        
        static let stocksDataDirectoryName = "StocksData"
        static let stocksDataFileName = "StocksData"
        static var stocksDataDirectoryUrl: URL {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let documentPath = paths[0]
            let directoryUrl = documentPath.appendingPathComponent(Constants.stocksDataDirectoryName, isDirectory: true)
            return directoryUrl
        }
    }
    
    // MARK: - Properties
    
    static let shared = PersistenceManager()
    
    private let userDefaults: UserDefaults = .standard
    
    weak var delegate: PersistenceManagerDelegate?
    
    private init() {}
    
    // MARK: - Public
    
    /// Array of company symbols saved in defaults database.
    var watchList: [String] {
        return userDefaults.stringArray(forKey: Constants.watchlistKey) ?? []
    }
    
    /// Returns if it's the first time the watchlist is accessed.
    var hasOnboarded: Bool {
        return userDefaults.bool(forKey: Constants.onboardKey)
    }
    
    /// Set `hasOnboarded` status to true and save default stocks to defaults database.
    func onboard() {
        userDefaults.set(true, forKey: Constants.onboardKey)
        savedDefaultStocks()
    }
    
    /// Save specified company symbol and name to the watchlist.
    /// - Parameters:
    ///   - symbol: Company's stock ticker symbol.
    ///   - companyName: The company's formal name.
    func addToWatchlist(symbol: String, companyName: String) {
        var currentList = watchList
        currentList.append(symbol)
        userDefaults.set(currentList, forKey: Constants.watchlistKey)
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
        userDefaults.set(newList, forKey: Constants.watchlistKey)
        userDefaults.set(nil, forKey: symbol)
    }
    
    /// Returns if the specified company symbol is saved in the watchlist.
    /// - Parameter symbol: The company's stock ticker symbol.
    /// - Returns: True if the specified company stock ticker symbol is contained in the watchlist.
    func watchListContains(_ symbol: String) -> Bool {
        return watchList.contains(symbol)
    }
    
    /// Store preset companies to the watchlist as default.
    /// - Note: Any data previously stored in the watchlist will be replaced by the default ones.
    func savedDefaultStocks() {
        // Save company symbols.
        let symbols = StockDefaults.defaultStocks.map{ $0.key }
        userDefaults.set(symbols, forKey: Constants.watchlistKey)
        
        // Save company names.
        for (symbol, name) in StockDefaults.defaultStocks {
            userDefaults.set(name, forKey: symbol)
        }
    }
    
}

// MARK: - Stock Data Persistence

extension PersistenceManager {
    
    /// Encode specified array of `StockData` in JSON and write it to preserved file path.
    /// - Parameter stocksData: Array of `StockData` to be written to preserved file path.
    func persistStocksData(_ stocksData: [StockData]) {
        let directoryUrl = Constants.stocksDataDirectoryUrl
        
        // Create a directory used to store the data if it does not exist yet.
        if !FileManager.default.fileExists(atPath: directoryUrl.path) {
            do {
                try FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false)
            } catch {
                print("Failed to create stocks data directory for persistent storage.")
                return
            }
        }
        do {
            let fileUrl = directoryUrl.appendingPathComponent(Constants.stocksDataDirectoryName)
            let encodedData = try JSONEncoder().encode(stocksData)
            try encodedData.write(to: fileUrl, options: .atomic)
        } catch {
            print("Failed to persist stocks data.\n\(error)")
        }
    }
    
    /// The array of `StockData` persisted at the preserved path of device's local disk.
    /// - Returns: Returns an empty array if the persisted file does not exist, cannot be retrieved or decoded.
    func persistedStocksData() throws -> [StockData] {
        let directoryUrl = Constants.stocksDataDirectoryUrl
        let fileUrl = directoryUrl.appendingPathComponent(Constants.stocksDataFileName)
        
        if !FileManager.default.fileExists(atPath: directoryUrl.path) {
            throw PersistError.persistingFolderNotFound
        }
        
        guard let persistedData = try? Data(contentsOf: fileUrl) else {
            throw PersistError.persistedDataNotRetrievable
        }
        guard let stocksData = try? JSONDecoder().decode([StockData].self, from: persistedData) else {
            throw PersistError.persistedDataNotDecodable
        }
        return stocksData
    }
    
    enum PersistError: Error {
        case persistingFolderNotFound
        case persistedDataNotRetrievable
        case persistedDataNotDecodable
    }
    
}
