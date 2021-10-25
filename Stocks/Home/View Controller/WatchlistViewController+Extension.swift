//
//  WatchlistViewController+Extension.swift
//  Stocks
//
//  Created by Jason Ou on 2021/10/17.
//

import Foundation
import UIKit

extension WatchlistViewController: SearchResultViewControllerDelegate {
    func didSelectSearchResult(_ searchResult: SearchResult) {
        // Present stock details VC for the selected stock.
        navigationItem.searchController?.searchBar.resignFirstResponder()
        HapticsManager().vibrateForSelection()
        
        DispatchQueue.main.async { [unowned self] in
            let symbol = searchResult.symbol
            var stockData = StockData(symbol: symbol)
            var isDataCached = false
            if let cachedData = viewModel.stocksData.first(where: { $0.symbol == symbol }) {
                stockData = cachedData
                isDataCached = true
            }
            let vc = StockDetailsViewController(viewModel: .init(
                stockData: stockData,
                companyName: searchResult.description.localizedCapitalized,
                lastQuoteDataUpdatedTime: isDataCached ? viewModel.lastQuoteDataUpdatedTime : 0,
                lastChartDataUpdatedTime: isDataCached ? viewModel.lastChartDataUpdatedTime : 0)
            )
            let navVC = UINavigationController(rootViewController: vc)
            present(navVC, animated: true, completion: nil)
        }
    }
    
    func searchResultScrollViewWillBeginDragging(scrollView: UIScrollView) {
        // Dismiss the keyboard when the result table view is about to be scrolled.
        if let searchBar = navigationItem.searchController?.searchBar,
           searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
        }
    }
}
