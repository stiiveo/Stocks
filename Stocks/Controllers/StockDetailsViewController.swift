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

    private let symbol: String
    private let companyName: String
    private var stockQuote: StockQuote?
    private var priceHistory: [PriceHistory]
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
        priceHistory: [PriceHistory] = []
    ) {
        self.symbol = symbol
        self.companyName = companyName
        self.priceHistory = priceHistory
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
        setUpTable()
        fetchFinancialData()
        fetchNews()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.frame = view.bounds
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

    private func setUpTable() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
    }

    /// Fetch financial metrics.
    private func fetchFinancialData() {
        let group = DispatchGroup()
        
        group.enter()
        APICaller.shared.fetchStockQuote(for: symbol) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let quote):
                self?.stockQuote = quote
            case .failure(let error):
                print(error)
            }
        }
        
        if priceHistory.isEmpty {
            group.enter()
            APICaller.shared.fetchPriceHistory(symbol, timeSpan: .day) {
                [weak self] result in
                defer { group.leave() }
                
                switch result {
                case .success(let data):
                    self?.priceHistory = data.priceHistory
                case .failure(let error):
                    print(error)
                }
            }
        }
        
        // Fetch financial metrics
        group.enter()
        APICaller.shared.fetchStockMetrics(symbol: symbol) { [weak self] result in
            defer { group.leave() }
            
            switch result {
            case .success(let metricsResponse):
                self?.metrics = metricsResponse.metric
            case .failure(let error):
                print(error)
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.configureHeaderView()
        }
    }

    private func fetchNews() {
        APICaller.shared.fetchNews(for: .company(symbol: symbol)) { [weak self] result in
            switch result {
            case .success(let stories):
                DispatchQueue.main.async {
                    self?.stories = stories
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func configureHeaderView() {
        let headerView = StockDetailHeaderView()
        
        // Define header view's frame.
        headerView.frame = CGRect(x: 0, y: 0, width: view.width, height: view.width)
        
        let lineChartData: [StockChartView.StockLineChartData] = priceHistory.map{
            .init(timeInterval: $0.time, price: $0.close)
        }
        
        let quote = stockQuote?.current
        let prevClose = stockQuote?.prevClose
        let priceChange = (quote != nil && prevClose != nil) ? (quote! / stockQuote!.prevClose) - 1 : nil
        
        guard let metrics = metrics else { return }
        let metricsViewModels: [MetricCollectionViewCell.ViewModel] = [
            .init(name: "Open", value: stockQuote?.open.stringFormatted(by: .decimalFormatter) ?? "–"),
            .init(name: "High", value: stockQuote?.high.stringFormatted(by: .decimalFormatter) ?? "–"),
            .init(name: "Low", value: stockQuote?.low.stringFormatted(by: .decimalFormatter) ?? "–"),
            .init(name: "Mkt Cap",
                  value: metrics.marketCap != nil ? (metrics.marketCap! * pow(10, 6)).shortScaleText() : "–"),
            .init(name: "P/E", value: metrics.priceToEarnings?.stringFormatted(by: .decimalFormatter) ?? "–"),
            .init(name: "P/S", value: metrics.priceToSales?.stringFormatted(by: .decimalFormatter) ?? "–"),
            .init(name: "52W H", value: metrics.annualHigh?.stringFormatted(by: .decimalFormatter) ?? "–"),
            .init(name: "52W L", value: metrics.annualLow?.stringFormatted(by: .decimalFormatter) ?? "–"),
            .init(name: "Prev", value: prevClose?.stringFormatted(by: .decimalFormatter) ?? "–"),
            .init(name: "Yield", value: metrics.yield?.stringFormatted(by: .decimalFormatter).appending("%") ?? "–"),
            .init(name: "Beta", value: metrics.beta?.stringFormatted(by: .decimalFormatter) ?? "–"),
            .init(name: "EPS", value: metrics.eps?.stringFormatted(by: .decimalFormatter) ?? "–"),
        ]
        
        headerView.configure(
            titleViewModel: .init(
                quote: quote,
                priceChange: priceChange,
                showAddingButton: !PersistenceManager.shared.watchListContains(symbol),
                delegate: self
            ),
            chartViewModel: .init(
                data: lineChartData,
                previousClose: stockQuote?.prevClose ?? 0.0,
                showAxis: true
            ),
            metricViewModels: metricsViewModels
        )
        
        tableView.tableHeaderView = headerView
    }
    
    // MARK: - Delegate Methods
    
    func didTapAddingButton() {
        HapticsManager.shared.vibrate(for: .success)
        PersistenceManager.shared.addToWatchlist(symbol: symbol, companyName: companyName)
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
