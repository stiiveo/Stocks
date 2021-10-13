//
//  WatchlistViewControllerViewModel.swift
//  Stocks
//
//  Created by Jason Ou on 2021/10/13.
//

import Foundation

protocol WatchlistViewControllerViewModelDelegate: AnyObject {
    func didAddViewModel(at index: Int)
    func didUpdateViewModel(at index: Int)
}

class WatchlistViewControllerViewModel {
    static let shared = WatchlistViewControllerViewModel()
    weak var delegate: WatchlistViewControllerViewModelDelegate?
    
    @DiskPersisted(fileURL: PersistenceManager.persistedDataUrl)
    var stocksData = PersistenceManager.defaultData
    
    // Settings on the minimum interval of the data updating.
    // Note: Setting these values too small yields little benefit
    // and could consumes the limited quotas of api calls quickly
    // since there's quite big interval between each data provided
    // by Finnhub.
    private let quoteUpdatingInterval: TimeInterval = 30
    private let chartUpdatingInterval: TimeInterval = 60
    
    private var isUpdateSuspended = false
    private var updateTimer: Timer?
    private(set) var lastQuoteDataUpdatedTime: TimeInterval = 0
    private(set) var lastChartDataUpdatedTime: TimeInterval = 0
    
    private init() {
        observeNotifications()
    }
    
    private func observeNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(addNewStockData),
            name: .didAddNewStockData, object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onApiLimitReached),
            name: .apiLimitReached,
            object: nil
        )
    }
    
    @objc private func addNewStockData(_ notification: NSNotification) {
        if let data = notification.userInfo?["data"] as? StockData {
            stocksData.append(data)
            delegate?.didAddViewModel(at: stocksData.count - 1)
        }
    }
    
    @objc private func onApiLimitReached() {
        // Suspend data updating operation.
        isUpdateSuspended = true
        
        /// Set `isUpdateSuspended` to `false` after a preset time when the quota limit should be reset.
        /// Note: This timer must be added to `RunLoop` for the timer to be fired properly after the specified
        /// time interval for unknown reason.
        let dataUpdateResumeTimer = Timer(timeInterval: 60.0, target: self, selector: #selector(liftDataUpdateSuspension), userInfo: nil, repeats: false)
        RunLoop.main.add(dataUpdateResumeTimer, forMode: .common)
    }
    
    @objc private func liftDataUpdateSuspension() {
        isUpdateSuspended = false
    }
}

// MARK: - Data Update Operations

extension WatchlistViewControllerViewModel {
    func initiateDataUpdater() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
            [unowned self] _ in
            guard !isUpdateSuspended else { return }
            updateOutdatedData()
        }
    }
    
    private func updateOutdatedData() {
        let currentTime = Date().timeIntervalSince1970
        let timeSinceQuoteUpdated = currentTime - lastQuoteDataUpdatedTime
        let timeSinceChartUpdated = currentTime - lastChartDataUpdatedTime
        
        if timeSinceQuoteUpdated >= quoteUpdatingInterval &&
            timeSinceChartUpdated >= chartUpdatingInterval {
            updateChartData()
            updateQuoteData()
        } else if timeSinceQuoteUpdated >= quoteUpdatingInterval {
            updateQuoteData()
        } else if timeSinceChartUpdated >= chartUpdatingInterval {
            updateChartData()
        }
    }
    
    func invalidateDataUpdater() {
        updateTimer?.invalidate()
    }
    
    func updateQuoteData() {
        lastQuoteDataUpdatedTime = Date().timeIntervalSince1970
        stocksData.forEach {
            let symbol = $0.symbol
            APICaller().fetchStockQuote(for: symbol) { [unowned self] result in
                switch result {
                case .success(let quoteData):
                    // Make sure cached data with the symbol value still exists.
                    guard let index = stocksData.firstIndex(where: { $0.symbol == symbol }) else {
                        print("Data updating is aborted since no data with symbol \(symbol) is stored.")
                        return
                    }
                    // Update cached data and tableView cell.
                    stocksData[index].quote = quoteData
                    delegate?.didUpdateViewModel(at: index)
                case .failure(let error):
                    print("Failed to fetch quote data of stock \(symbol):\n\(error)")
                }
            }
        }
    }
    
    func updateChartData() {
        lastChartDataUpdatedTime = Date().timeIntervalSince1970
        stocksData.forEach {
            let symbol = $0.symbol
            APICaller().fetchPriceHistory(symbol, timeSpan: .day) { [unowned self] result in
                switch result {
                case .success(let candlesResponse):
                    // Make sure cached data with the symbol value still exists.
                    guard let index = stocksData.firstIndex(where: { $0.symbol == symbol }) else {
                        print("Data updating is aborted since no data with symbol \(symbol) is stored.")
                        return
                    }
                    // Update cached data and tableView cell.
                    stocksData[index].priceHistory = candlesResponse.priceHistory
                    delegate?.didUpdateViewModel(at: index)
                case .failure(let error):
                    print("Failed to fetch price history data of stock \(symbol):\n\(error)")
                }
            }
        }
    }
}
