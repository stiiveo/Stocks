//
//  WatchlistTableViewCellViewModel.swift
//  Stocks
//
//  Created by Jason Ou on 2021/8/29.
//

import Foundation
import UIKit

class WatchlistTableViewCellViewModel {
    
    struct ViewModel {
        let symbol: String
        let companyName: String
        let price: String // formatted
        let changeColor: UIColor // red or green
        let changePercentage: String // formatted
        let chartViewModel: StockChartView.ViewModel
    }
    
    // MARK: - Properties
    
    private var viewModels = [ViewModel]()
    
    // MARK: - Public Methods
    
    func all() -> [ViewModel] {
        return viewModels
    }
    
    func add(with stockData: StockData) {
        viewModels.append(viewModel(from: stockData))
    }
    
    enum ViewModelError: Error {
        case indexNotFound
    }
    
    func update(_ index: Int, with stockData: StockData) throws {
        if index >= 0 && index < viewModels.count {
            viewModels[index] = viewModel(from: stockData)
        } else {
            throw ViewModelError.indexNotFound
        }
    }
    
    func remove(from index: Int) throws {
        if index >= 0 && index < viewModels.count {
            viewModels.remove(at: index)
        } else {
            throw ViewModelError.indexNotFound
        }
    }
    
    func viewModel(from stockData: StockData) -> ViewModel {
        let currentPrice = stockData.quote.current
        let previousClose = stockData.quote.prevClose
        let priceChange = (currentPrice / previousClose) - 1
        let priceChangePercentage = priceChange.signedPercentageString()
        
        let model = ViewModel(
            symbol: stockData.symbol,
            companyName: UserDefaults.standard.string(forKey: stockData.symbol) ?? stockData.symbol,
            price: currentPrice.stringFormatted(by: .decimalFormatter),
            changeColor: priceChange < 0 ? .systemRed : .systemGreen,
            changePercentage: priceChangePercentage,
            chartViewModel: .init(
                data: stockData.priceHistory.map{
                    .init(timeInterval: $0.time, price: $0.close)},
                previousClose: previousClose,
                showAxis: false
            )
        )
        return model
    }
}
