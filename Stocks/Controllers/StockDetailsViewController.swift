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
    
    private var stockData: StockData
    private var metrics: Metrics?
    private var stories: [NewsStory] = []
    var symbol: String {
        return stockData.symbol
    }
    
    // MARK: - UI Properties
    
    private lazy var headerView = StockDetailHeaderView()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(NewsHeaderView.self,
                       forHeaderFooterViewReuseIdentifier: NewsHeaderView.identifier)
        table.register(NewsStoryTableViewCell.self,
                       forCellReuseIdentifier: NewsStoryTableViewCell.identifier)
        return table
    }()

    // MARK: - Init

    init(
        stockData: StockData
    ) {
        self.stockData = stockData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = stockData.companyName.localizedCapitalized
        setUpCloseButton()
        setUpHeaderView()
        setUpTableView()
        DispatchQueue.main.async {
            self.configureHeaderView()
        }
        
        fetchMetricsData()
        fetchNews()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(addStockToWatchlist),
            name: .didTapAddToWatchlist,
            object: nil
        )
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
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
//                    self.configureHeaderView()
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
//                    self.configureHeaderView()
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
                    self.configureHeaderView()
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
    
    private func configureHeaderView() {
        headerView.configure(stockData: stockData, metricsData: metrics)
    }
    
    @objc private func addStockToWatchlist() {
        HapticsManager.shared.vibrate(for: .success)
        PersistenceManager.shared.addToWatchlist(symbol: symbol, companyName: stockData.companyName)
        showAlert(withTitle: "Added to Watchlist", message: "", actionTitle: "OK")
    }
    
}

// MARK: - Delegate Methods

extension StockDetailsViewController: WatchlistViewControllerDelegate {
    
    func didUpdateData(stockData: StockData) {
        self.stockData.quote = stockData.quote
        self.stockData.priceHistory = stockData.priceHistory
        DispatchQueue.main.async {
            self.configureHeaderView()
        }
        print("didUpdateData")
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
