//
//  StockDetailsViewControllerViewModel.swift
//  Stocks
//
//  Created by Jason Ou on 2021/10/13.
//

import Foundation

protocol StockDetailsViewControllerViewModelDelegate: AnyObject {
    func didUpdateStockData(_ stockDetailsViewControllerViewModel: StockDetailsViewControllerViewModel)
    func didUpdateNewsData(_ stockDetailsViewControllerViewModel: StockDetailsViewControllerViewModel)
}

class StockDetailsViewControllerViewModel {
    
    struct ViewModel {
        let stockData: StockData
        let companyName: String
        let lastQuoteDataUpdatedTime: TimeInterval
        let lastChartDataUpdatedTime: TimeInterval
    }
    
    // Property
    private(set) var stockData: StockData {
        didSet {
            delegate?.didUpdateStockData(self)
        }
    }
    private(set) var companyName: String
    
    private(set) var metrics: Metrics? {
        didSet {
            delegate?.didUpdateStockData(self)
        }
    }
    
    private(set) var stories: [NewsStory] = [] {
        didSet {
            delegate?.didUpdateNewsData(self)
        }
    }
    
    var symbol: String {
        return stockData.symbol
    }
    
    // Data Updating Settings
    
    // Settings on the minimum interval of the data updating.
    // Note: Setting these values too small yields little benefit
    // and could consumes the limited quotas of api calls quickly
    // since there's quite big interval between each data provided
    // by Finnhub.
    private let quoteUpdatingInterval: TimeInterval = 30
    private let chartUpdatingInterval: TimeInterval = 60
    
    private var lastQuoteDataUpdatedTime: TimeInterval = 0
    private var lastChartDataUpdatedTime: TimeInterval = 0
    var dataUpdateTimer: Timer?
    
    weak var delegate: StockDetailsViewControllerViewModelDelegate?
    
    // Init
    init(viewModel: ViewModel) {
        self.stockData = viewModel.stockData
        self.companyName = viewModel.companyName
        self.lastQuoteDataUpdatedTime = viewModel.lastQuoteDataUpdatedTime
        self.lastChartDataUpdatedTime = viewModel.lastChartDataUpdatedTime
    }
}

// MARK: - Data Update Operations

extension StockDetailsViewControllerViewModel {
    func initiateDataUpdater() {
        dataUpdateTimer?.invalidate()
        dataUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
            [weak self] _ in
            self?.updateOutdatedData()
        }
    }
    
    func updateOutdatedData() {
        let currentTime = Date().timeIntervalSince1970
        let timeSinceQuoteUpdated = currentTime - lastQuoteDataUpdatedTime
        let timeSinceChartUpdated = currentTime - lastChartDataUpdatedTime
        
        if timeSinceQuoteUpdated >= quoteUpdatingInterval &&
            timeSinceChartUpdated >= chartUpdatingInterval {
            updateQuoteData()
            updateChartData()
        } else if timeSinceQuoteUpdated >= quoteUpdatingInterval {
            updateQuoteData()
        } else if timeSinceChartUpdated >= chartUpdatingInterval {
            updateChartData()
        }
    }
    
    private func updateQuoteData() {
        lastQuoteDataUpdatedTime = Date().timeIntervalSince1970
        APICaller().fetchStockQuote(for: symbol) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let quoteData):
                self.stockData.quote = quoteData
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func updateChartData() {
        lastChartDataUpdatedTime = Date().timeIntervalSince1970
        APICaller().fetchPriceHistory(symbol, timeSpan: .day) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.stockData.priceHistory = response.priceHistory
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func fetchMetricsData() {
        APICaller().fetchStockMetrics(symbol: symbol) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let metricsResponse):
                self.metrics = metricsResponse.metric
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func fetchNews() {
        APICaller().fetchNews(type: .company(symbol)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let stories):
                self.stories = stories
            case .failure(let error):
                print(error)
            }
        }
    }
}
