//
//  WatchlistTableViewCellViewModel.swift
//  Stocks
//
//  Created by Jason Ou on 2021/8/29.
//

import Foundation
import UIKit

class WatchlistCellViewModel {
    
    struct ViewModel {
        let symbol: String
        let companyName: String
        let price: String // formatted
        let changeColor: UIColor // red or green
        let changePercentage: String // formatted
        let chartViewModel: StockChartView.ViewModel
    }
    
    // MARK: - Properties
    
    /// Array of `ViewModel` used by the watchlist's table view cells as the data source.
    var models = [ViewModel]()
    
    // MARK: - Public Methods
    
    /// Append a new `ViewModel` to this class.
    /// - Parameter stockData: `StockData` object used to create the `ViewModel` object.
    func add(with stockData: StockData) {
        models.append(model(from: stockData))
    }
    
    enum ViewModelError: Error {
        case indexNotFound
    }
    
    /// Update the existing `ViewModel` stored in this class's view models array's designated index.
    /// - Parameters:
    ///   - index: The index at which the view model is stored in the array.
    ///   - stockData: The `StockData` object used to update the existing `ViewModel`.
    /// - Throws: Throws `ViewModelError` in case the operation failed.
    func update(_ index: Int, with stockData: StockData) throws {
        if index >= 0 && index < models.count {
            models[index] = model(from: stockData)
        } else {
            throw ViewModelError.indexNotFound
        }
    }
    
    // MARK: - Private Methods
    
    /// Returns a `ViewModel` created from the provided `StockData`.
    /// - Parameter stockData: `StockData` used to create `ViewModel`.
    /// - Returns: `ViewModel` used by watchlist view controller's table view cell.
    private func model(from stockData: StockData) -> ViewModel {
        let currentPrice = stockData.quote.current
        let previousClose = stockData.quote.prevClose
        let priceChange = (currentPrice / previousClose) - 1
        
        let model = ViewModel(
            symbol: stockData.symbol,
            companyName: UserDefaults.standard.string(forKey: stockData.symbol) ?? stockData.symbol,
            price: currentPrice.stringFormatted(by: .decimalFormatter),
            changeColor: (currentPrice - previousClose) < 0 ? .stockPriceDown : .stockPriceUp,
            changePercentage: priceChange.signedPercentageString(),
            chartViewModel: .init(
                data: stockData.priceHistory.map{
                    .init(timeInterval: $0.time, price: $0.close)},
                previousClose: previousClose,
                highestPrice: stockData.quote.high,
                lowestPrice: stockData.quote.low,
                showAxis: false
            )
        )
        return model
    }
}
