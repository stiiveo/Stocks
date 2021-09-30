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
        
        static let stocksDataDirectoryName = "StocksData"
        
        static let stocksDataFileName = "StocksData"
        
        static var stocksDataDirectoryUrl: URL {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let documentPath = paths[0]
            let directoryUrl = documentPath.appendingPathComponent(Constants.stocksDataDirectoryName, isDirectory: true)
            return directoryUrl
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
            isOnboarded = true
        }
    }
    
    // MARK: - Public
    
    /// Array of company symbols saved in defaults database.
    @Persisted(wrappedValue: [], key: Constants.watchlistKey)
    private(set) var watchList: [String]
    
    /// Returns if it's the first time the watchlist is accessed.
    @Persisted(wrappedValue: false, key: Constants.onboardKey)
    private(set) var isOnboarded: Bool
    
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

// MARK: - Stock Data Persistence

extension PersistenceManager {
    
    enum PersistError: Error {
        case failedToCreatePersistingFolder
        case failedToEncodeDataToJson
        case failedToWriteEncodedDataToFolder(url: URL)
        case persistingFolderNotFound
        case persistedDataNotRetrievable
        case persistedDataNotDecodable
    }
    
    /// Encode specified array of `StockData` in JSON and write it to the local document directory.
    /// - Parameter stocksData: Array of `StockData` to be written to preserved file path.
    func persistStocksData(_ stocksData: [StockData]) throws {
        // Create a directory to store the data if it does not exist yet.
        let directoryUrl = Constants.stocksDataDirectoryUrl
        if !FileManager.default.fileExists(atPath: directoryUrl.path) {
            do {
                try FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false)
            } catch {
                throw PersistError.failedToCreatePersistingFolder
            }
        }
        
        // Encode `StockData` into JSON format.
        guard let encodedData = try? JSONEncoder().encode(stocksData) else {
            throw PersistError.failedToEncodeDataToJson
        }
        
        // Write encoded data to directory.
        let fileUrl = directoryUrl.appendingPathComponent(Constants.stocksDataDirectoryName)
        do {
            try encodedData.write(to: fileUrl, options: .atomic)
        } catch {
            throw PersistError.failedToWriteEncodedDataToFolder(url: fileUrl)
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
    
}
