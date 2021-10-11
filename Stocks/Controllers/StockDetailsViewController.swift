//
//  StockDetailsViewController.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import UIKit
import SafariServices
import SnapKit

protocol StockDetailsViewControllerDelegate: AnyObject {
    func stockDetailsViewControllerDidAddStockData(_ stockData: StockData)
    func stockDetailsViewControllerDidDisappear(_ controller: StockDetailsViewController)
}

class StockDetailsViewController: UIViewController {

    // MARK: - Properties
    
    private var stockData: StockData
    private var companyName: String
    
    private var metrics: Metrics?
    private var stories: [NewsStory] = []
    
    weak var delegate: StockDetailsViewControllerDelegate?
    
    var symbol: String {
        return stockData.symbol
    }
    
    // Settings on the minimum interval of the data updating.
    // Note: Setting these values too small yields little benefit
    // and could consumes the limited quotas of api calls quickly
    // since there's quite big interval between each data provided
    // by Finnhub.
    private let quoteUpdatingInterval: TimeInterval = 30
    private let chartUpdatingInterval: TimeInterval = 60
    
    private let newsLoadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
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
        stockData: StockData,
        companyName: String,
        lastQuoteDataUpdatedTime: TimeInterval,
        lastChartDataUpdatedTime: TimeInterval
    ) {
        self.stockData = stockData
        self.companyName = companyName
        self.lastQuoteDataUpdatedTime = lastQuoteDataUpdatedTime
        self.lastChartDataUpdatedTime = lastChartDataUpdatedTime
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = companyName
        view.backgroundColor = .systemBackground
        configureCloseButton()
        configureHeaderView()
        configureTableView()
        updateOutdatedData()
        initiateDataUpdater()
        fetchMetricsData()
        fetchNews()
        observeNotifications()
        configureNewsLoadingIndicator()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        dataUpdateTimer?.invalidate()
        delegate?.stockDetailsViewControllerDidDisappear(self)
    }
    
    private func configureNewsLoadingIndicator() {
        view.addSubview(newsLoadingIndicator)
        newsLoadingIndicator.frame = CGRect(
            x: view.width / 2 - 10,
            y: view.width + 120 - 10,
            width: 20,
            height: 20
        )
        newsLoadingIndicator.startAnimating()
    }

    // MARK: - Data Update Operations
    
    private var dataUpdateTimer: Timer?
    private var lastQuoteDataUpdatedTime: TimeInterval = 0
    private var lastChartDataUpdatedTime: TimeInterval = 0
    
    private func initiateDataUpdater() {
        dataUpdateTimer?.invalidate()
        dataUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
            [weak self] _ in
            self?.updateOutdatedData()
        }
    }
    
    private func updateOutdatedData() {
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
    
    // MARK: - UI Setting
    
    private func configureCloseButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(didTapCloseButton)
        )
    }
    
    private func configureTableView() {
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func configureHeaderView() {
        headerView.frame = CGRect(x: 0, y: 0, width: view.width, height: view.width)
        tableView.tableHeaderView = headerView
        DispatchQueue.main.async {
            self.refreshHeaderView()
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(addStockToWatchlist),
            name: .didTapAddToWatchlist,
            object: nil
        )
    }
    
    private func refreshHeaderView() {
        headerView.configure(stockData: stockData, metricsData: metrics)
    }
    
    // MARK: - Data Fetching
    
    private func updateQuoteData() {
        lastQuoteDataUpdatedTime = Date().timeIntervalSince1970
        APICaller().fetchStockQuote(for: symbol) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let quoteData):
                self.stockData.quote = quoteData
                DispatchQueue.main.async {
                    self.refreshHeaderView()
                }
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
                DispatchQueue.main.async {
                    self.refreshHeaderView()
                }
            case .failure(let error):
                print(error)
            }
        }
    }

    private func fetchMetricsData() {
        APICaller().fetchStockMetrics(symbol: symbol) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let metricsResponse):
                self.metrics = metricsResponse.metric
                DispatchQueue.main.async {
                    self.refreshHeaderView()
                }
            case .failure(let error):
                print(error)
            }
        }
    }

    private func fetchNews() {
        APICaller().fetchNews(for: .company(symbol: symbol)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let stories):
                DispatchQueue.main.async {
                    self.newsLoadingIndicator.stopAnimating()
                    self.stories = stories
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // MARK: - Selector Operations
    
    private func observeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(presentApiLimitAlert), name: .apiLimitReached, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(presentApiNoAccessAlert), name: .dataAccessDenied, object: nil)
    }
    
    @objc private func addStockToWatchlist() {
        HapticsManager().vibrate(for: .success)
        PersistenceManager.shared.watchlist[symbol] = companyName
        delegate?.stockDetailsViewControllerDidAddStockData(stockData)
        showAlert(withTitle: "Added to Watchlist", message: "", actionTitle: "OK")
    }
    
    @objc private func didTapCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func presentApiLimitAlert() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  self.presentedViewController == nil else { return }
            self.presentApiAlert(type: .apiLimitReached)
        }
    }
    
    @objc private func presentApiNoAccessAlert() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  self.presentedViewController == nil else { return }
            self.presentApiAlert(type: .noAccessToData)
        }
    }
    
}

// MARK: - TableView Data Source & Delegate

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
        HapticsManager().vibrateForSelection()
        open(url: url, withPresentationStyle: .overFullScreen)
    }
}
