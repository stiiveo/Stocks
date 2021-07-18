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

    private let symbol: String
    private let companyName: String
    private var candleStickData: [PriceHistory]

    private let tableView: UITableView = {
        let table = UITableView()
        table.register(NewsHeaderView.self,
                       forHeaderFooterViewReuseIdentifier: NewsHeaderView.identifier)
        table.register(NewsStoryTableViewCell.self,
                       forCellReuseIdentifier: NewsStoryTableViewCell.identifier)
        return table
    }()

    private var stories: [NewsStory] = []
    
    private var metrics: Metrics?

    // MARK: - Init

    init(
        symbol: String,
        companyName: String,
        candleStickData: [PriceHistory] = []
    ) {
        self.symbol = symbol
        self.companyName = companyName
        self.candleStickData = candleStickData
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
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
        tableView.tableHeaderView = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: view.width,
                height: (view.width * 0.7) + StockDetailHeaderView.metricsViewHeight
            )
        )
    }

    /// Fetch financial metrics.
    private func fetchFinancialData() {
        let group = DispatchGroup()
        
        if candleStickData.isEmpty {
            group.enter()
            APICaller.shared.fetchStockData(symbol: symbol, historyDuration: 7) {
                [weak self] result in
                defer {
                    group.leave()
                }
                
                switch result {
                case .success(let data):
                    self?.candleStickData = data.priceHistory
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
        
        // Fetch financial metrics
        group.enter()
        APICaller.shared.fetchFinancialMetrics(symbol: symbol) { [weak self] result in
            defer {
                group.leave()
            }
            
            switch result {
            case .success(let response):
                self?.metrics = response.metric
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.updateChartAndFinancialsData()
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
                print(error.localizedDescription)
            }
        }
    }
    
    private func updateChartAndFinancialsData() {
        let headerView = StockDetailHeaderView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: view.width,
                height: (view.width * 0.7) + 100
            )
        )
        
        var viewModels = [MetricCollectionViewCell.ViewModel]()
        if let metrics = metrics {
            viewModels.append(.init(name: "52W High", value: "\(metrics.annualHigh)"))
            viewModels.append(.init(name: "52W Low", value: "\(metrics.annualLow)"))
            viewModels.append(.init(name: "52W Low Date", value: "\(metrics.annualLowDate)"))
            viewModels.append(.init(name: "52W Return", value: "\(metrics.annualWeekPriceReturnDaily)"))
            viewModels.append(.init(name: "10D Volume", value: "\(metrics.tenDayAverageVolume)"))
            viewModels.append(.init(name: "Beta", value: "\(metrics.beta)"))
        }
        
        let lineChartData: [StockChartView.StockLineChartData] = candleStickData.map({
            .init(timeInterval: $0.time, price: $0.close)
        })
        
        headerView.configure(
            chartViewModel: .init(
                data: lineChartData,
                showAxis: true
            ),
            metricViewModels: viewModels
        )
        
        tableView.tableHeaderView = headerView
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
        cell.configure(with: .init(news: stories[indexPath.row]))
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return NewsStoryTableViewCell.preferredHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: NewsHeaderView.identifier
        ) as? NewsHeaderView else {
            return nil
        }
        header.delegate = self
        header.configure(
            with: .init(
                title: symbol.uppercased(),
                shouldShowAddButton: !PersistenceManager.shared.watchListContains(symbol))
        )
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return NewsHeaderView.preferredHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let url = URL(string: stories[indexPath.row].url) else { return }
        HapticsManager.shared.vibrateForSelection()
        open(url: url, withPresentationStyle: .overFullScreen)
    }
}

extension StockDetailsViewController: NewsHeaderViewDelegate {
    func newsHeaderViewDidTapAddButton(_ headerView: NewsHeaderView) {
        HapticsManager.shared.vibrate(for: .success)
        headerView.button.isHidden = true
        PersistenceManager.shared.addToWatchlist(
            symbol: symbol,
            companyName: companyName
        )
        showAlert(withTitle: "Added to Watch List", message: "", actionTitle: "OK")
    }
}
