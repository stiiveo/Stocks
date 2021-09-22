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
    weak var delegate: StockDetailsViewControllerDelegate?
    private var addedToWatchlist = false
    
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
        companyName: String
    ) {
        self.stockData = stockData
        super.init(nibName: nil, bundle: nil)
        self.title = companyName
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setUpCloseButton()
        setUpHeaderView()
        setUpTableView()
        fetchQuoteData()
        fetchChartData()
        fetchMetricsData()
        fetchNews()
        initiateDataUpdateTimer()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        dataUpdateTimer?.invalidate()
        if addedToWatchlist {
            // Send the cached data to WatchlistVC.
            delegate?.addLatestCachedData(stockData: self.stockData)
        }
    }

    // MARK: - Private
    
    private var dataUpdateTimer: Timer?
    
    private func initiateDataUpdateTimer() {
        dataUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [unowned self] _ in
            let currentSecondComponent = CalendarManager().newYorkCalendar.component(.second, from: Date())
            if currentSecondComponent == 0 {
                fetchQuoteData()
                fetchChartData()
            } else if currentSecondComponent == 30 {
                fetchQuoteData()
            }
        }
    }
    
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
    
    private func fetchQuoteData() {
        APICaller().fetchStockQuote(for: symbol) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let quoteData):
                self.stockData.quote = quoteData
                DispatchQueue.main.async {
                    self.configureHeaderView()
                }
            case .failure(let error):
                print(error)
            }
        }
    }

    private func fetchChartData() {
        APICaller().fetchPriceHistory(symbol, timeSpan: .day) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.stockData.priceHistory = response.priceHistory
                DispatchQueue.main.async {
                    self.configureHeaderView()
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
                    self.configureHeaderView()
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
        headerView.frame = CGRect(x: 0, y: 0, width: view.width, height: view.width)
        tableView.tableHeaderView = headerView
        DispatchQueue.main.async {
            self.configureHeaderView()
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(addStockToWatchlist),
            name: .didTapAddToWatchlist,
            object: nil
        )
    }
    
    private func configureHeaderView() {
        headerView.configure(stockData: stockData, metricsData: metrics)
    }
    
    @objc private func addStockToWatchlist() {
        HapticsManager().vibrate(for: .success)
        PersistenceManager().addToWatchlist(symbol: symbol, companyName: stockData.companyName)
        addedToWatchlist = true
        showAlert(withTitle: "Added to Watchlist", message: "", actionTitle: "OK")
    }
    
}

protocol StockDetailsViewControllerDelegate: AnyObject {
    func addLatestCachedData(stockData: StockData)
}

// MARK: - Delegate Methods

extension StockDetailsViewController: WatchlistViewControllerDelegate {
    
    func didUpdateData(stockData: StockData) {
        self.stockData.quote = stockData.quote
        self.stockData.priceHistory = stockData.priceHistory
        DispatchQueue.main.async {
            self.configureHeaderView()
        }
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
        HapticsManager().vibrateForSelection()
        open(url: url, withPresentationStyle: .overFullScreen)
    }
}
