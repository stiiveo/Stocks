//
//  StockDetailsViewController.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import UIKit
import SafariServices

class StockDetailsViewController: UIViewController {

    // MARK: - Properties
    
    private lazy var headerView = StockDetailHeaderView()
    
    // ! Use `StockData` to cache data
    
    let symbol: String
    private let companyName: String
    private var quoteData: StockQuote?
    private var chartData: [PriceHistory]
    private var metrics: Metrics?

    private let tableView: UITableView = {
        let table = UITableView()
        table.register(NewsHeaderView.self,
                       forHeaderFooterViewReuseIdentifier: NewsHeaderView.identifier)
        table.register(NewsStoryTableViewCell.self,
                       forCellReuseIdentifier: NewsStoryTableViewCell.identifier)
        return table
    }()

    private var stories: [NewsStory] = []

    // MARK: - Init

    init(
        symbol: String,
        companyName: String,
        quoteData: StockQuote?,
        chartData: [PriceHistory],
        metricsData: Metrics? = nil
    ) {
        self.symbol = symbol
        self.companyName = companyName
        self.quoteData = quoteData
        self.chartData = chartData
        self.metrics = metricsData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = companyName
        setUpCloseButton()
        setUpHeaderView()
        setUpTableView()
        DispatchQueue.main.async {
            self.configureHeaderViewData()
        }
        
        fetchMetricsData()
        fetchNews()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
//        quoteUpdateTimer?.invalidate()
//        chartUpdateTimer?.invalidate()
    }

    // MARK: - Private
    
    ///// Use date component to time when to update data
    
//    private var quoteUpdateTimer: Timer?
//    private var chartUpdateTimer: Timer?
    
//    private func initiateUpdateTimers() {
//        let quoteUpdateInterval = 20.0
//        // Set this value no less than the minimum interval of chart data to save API calling quota.
//        let chartUpdateInterval = 60.0
//        let marketCloseDate = CalendarManager.shared.latestTradingTime.close
//
//        quoteUpdateTimer = Timer.scheduledTimer(withTimeInterval: quoteUpdateInterval, repeats: true) {
//            [weak self] _ in
//            if Date() <= marketCloseDate.addingTimeInterval(quoteUpdateInterval) {
//                self?.fetchQuoteData()
//            }
//        }
//
//        chartUpdateTimer = Timer.scheduledTimer(withTimeInterval: chartUpdateInterval, repeats: true) {
//            [weak self] _ in
//            if Date() <= marketCloseDate.addingTimeInterval(chartUpdateInterval) {
//                self?.fetchMetricsData()
//            }
//        }
//    }
    
    private func setUpCloseButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(didTapCloseButton)
        )
    }
    
    @objc private func didTapCloseButton() {
        dismiss(animated: true, completion: nil)
    }

    private func setUpTableView() {
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.delegate = self
        tableView.dataSource = self
    }
    
//    private func fetchQuoteData() {
//        APICaller.shared.fetchStockQuote(for: symbol) { [weak self] result in
//            guard let self = self else { return }
//            switch result {
//            case .success(let stockQuote):
//                self.quoteData = stockQuote
//                DispatchQueue.main.async {
//                    self.configureHeaderViewData()
//                }
//            case .failure(let error):
//                print(error)
//            }
//        }
//    }
//
//    private func fetchChartData() {
//        APICaller.shared.fetchPriceHistory(symbol, timeSpan: .day) { [weak self] result in
//            guard let self = self else { return }
//            switch result {
//            case .success(let candlesData):
//                self.chartData = candlesData.priceHistory
//                DispatchQueue.main.async {
//                    self.configureHeaderViewData()
//                }
//            case .failure(let error):
//                print(error)
//            }
//        }
//    }

    /// Fetch financial metrics.
    private func fetchMetricsData() {
        APICaller.shared.fetchStockMetrics(symbol: symbol) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let metricsResponse):
                self.metrics = metricsResponse.metric
                DispatchQueue.main.async {
                    self.configureHeaderViewData()
                }
            case .failure(let error):
                print(error)
            }
        }
    }

    private func fetchNews() {
        APICaller.shared.fetchNews(for: .company(symbol: symbol)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let stories):
                DispatchQueue.main.async {
                    self.stories = stories
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func setUpHeaderView() {
        headerView = StockDetailHeaderView()
        
        // Define header view's frame.
        headerView.frame = CGRect(x: 0, y: 0, width: view.width, height: view.width)
        tableView.tableHeaderView = headerView
    }
    
    private func configureHeaderViewData() {
        let metricsViewModel: StockMetricsView.ViewModel = {
            .init(openPrice: quoteData?.open,
                  highestPrice: quoteData?.high,
                  lowestPrice: quoteData?.low,
                  marketCap: metrics?.marketCap,
                  priceEarningsRatio: metrics?.priceToEarnings,
                  priceSalesRatio: metrics?.priceToSales,
                  annualHigh: metrics?.annualHigh,
                  annualLow: metrics?.annualLow,
                  previousPrice: quoteData?.prevClose,
                  yield: metrics?.yield,
                  beta: metrics?.beta,
                  eps: metrics?.eps)
        }()
        
        headerView.configure(
            titleViewModel: .init(
                quote: quoteData?.current,
                previousClose: quoteData?.prevClose,
                showAddingButton: !PersistenceManager.shared.watchListContains(symbol),
                delegate: self
            ),
            chartViewModel: .init(
                data: chartData,
                previousClose: quoteData?.prevClose,
                highestClose: quoteData?.high,
                lowestClose: quoteData?.low,
                showAxis: true
            ),
            metricsViewModels: metricsViewModel
        )
        
    }
    
}

// MARK: - Delegate Methods

extension StockDetailsViewController: WatchlistViewControllerDelegate, StockDetailHeaderTitleViewDelegate {
    
    func didUpdateData(stockData: StockData) {
        self.quoteData = stockData.quote
        self.chartData = stockData.priceHistory
        DispatchQueue.main.async {
            self.configureHeaderViewData()
        }
        print("didUpdateData")
    }
    
    func didTapAddingButton() {
        HapticsManager.shared.vibrate(for: .success)
        PersistenceManager.shared.addToWatchlist(symbol: symbol, companyName: companyName)
        showAlert(withTitle: "Added to Watchlist", message: "", actionTitle: "OK")
        
        // ! Pass the cached data to watchlist list.
    }
    
}

// MARK: - TableView

extension StockDetailsViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: NewsStoryTableViewCell.identifier,
            for: indexPath
        ) as? NewsStoryTableViewCell else {
            fatalError()
        }
        cell.reset()
        cell.configure(with: .init(news: stories[indexPath.row]))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let url = URL(string: stories[indexPath.row].url) else { return }
        HapticsManager.shared.vibrateForSelection()
        open(url: url, withPresentationStyle: .overFullScreen)
    }
}
