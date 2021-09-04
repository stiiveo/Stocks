//
//  StockDetailsViewController.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import UIKit
import SafariServices

class StockDetailsViewController: UIViewController, StockDetailHeaderTitleViewDelegate {

    // MARK: - Properties
    
    private lazy var headerView = StockDetailHeaderView()

    private var stockData: StockData
    
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
    
    private var companyName: String {
        return UserDefaults.standard.string(forKey: stockData.symbol) ?? stockData.symbol
    }

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
        title = companyName
        setUpCloseButton()
        setUpHeaderView()
        setUpTableView()
        configureHeaderViewData()
        fetchFinancialData()
        fetchNews()
    }
    
    // MARK: - Public
    
    func updateHeaderViewData(with data: StockData) {
        self.stockData = data
        DispatchQueue.main.async { [weak self] in
            self?.configureHeaderViewData()
        }
    }

    // MARK: - Private
    
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

    /// Fetch financial metrics.
    private func fetchFinancialData() {
        APICaller.shared.fetchStockMetrics(symbol: stockData.symbol) { [weak self] result in
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
        APICaller.shared.fetchNews(for: .company(symbol: stockData.symbol)) { [weak self] result in
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
        let chartHeight = view.width * 0.7
        headerView.frame = CGRect(
            x: 0,
            y: 0,
            width: view.width,
            height: StockDetailHeaderView.titleViewHeight + chartHeight + StockDetailHeaderView.metricsViewHeight
        )
        tableView.tableHeaderView = headerView
    }
    
    private func configureHeaderViewData() {
        let lineChartData: [StockChartView.StockLineChartData] = stockData.priceHistory.map{
            .init(timeInterval: $0.time, price: $0.close)
        }
        
        let metricsViewModel: StockMetricsView.ViewModel = {
            .init(openPrice: stockData.quote.open,
                  highestPrice: stockData.quote.high,
                  lowestPrice: stockData.quote.low,
                  marketCap: metrics?.marketCap,
                  priceEarningsRatio: metrics?.priceToEarnings,
                  priceSalesRatio: metrics?.priceToSales,
                  annualHigh: metrics?.annualHigh,
                  annualLow: metrics?.annualLow,
                  previousPrice: stockData.quote.prevClose,
                  yield: metrics?.yield,
                  beta: metrics?.beta,
                  eps: metrics?.eps)
        }()
        
        headerView.configure(
            titleViewModel: .init(
                quote: stockData.quote.current,
                priceChange: (stockData.quote.current / stockData.quote.prevClose) - 1,
                showAddingButton: !PersistenceManager.shared.watchListContains(stockData.symbol),
                delegate: self
            ),
            chartViewModel: .init(
                data: lineChartData,
                previousClose: stockData.quote.prevClose,
                showAxis: true
            ),
            metricsViewModels: metricsViewModel
        )
        
    }
    
    // MARK: - Delegate Methods
    
    func didTapAddingButton() {
        HapticsManager.shared.vibrate(for: .success)
        PersistenceManager.shared.addToWatchlist(symbol: stockData.symbol, companyName: companyName)
        showAlert(withTitle: "Added to Watchlist", message: "", actionTitle: "OK")
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
