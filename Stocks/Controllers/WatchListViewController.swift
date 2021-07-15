//
//  WatchListViewController.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import UIKit
import FloatingPanel

class WatchListViewController: UIViewController {
    
    private var searchTimer: Timer?
    
    private var panel: FloatingPanelController?
    
    static var maxPriceLabelWidth: CGFloat = 0
    
    private var watchListData: [String: StockData] = [:]
    
    private var viewModels = [WatchListTableViewCell.ViewModel]()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(WatchListTableViewCell.self, forCellReuseIdentifier: WatchListTableViewCell.identifier)
        return table
    }()
    
    private var observer: NSObjectProtocol?

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setUpSearchController()
        setUpTableView()
        fetchWatchlistData()
        setUpFloatingPanel()
        setUpTitleView()
        setUpObserver()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    // MARK: - Private
    
    private func setUpObserver() {
        observer = NotificationCenter.default.addObserver(
            forName: .didAddToWatchList,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.viewModels.removeAll()
            self?.fetchWatchlistData()
        }
    }
    
    private func fetchWatchlistData(forDays days: TimeInterval = 7) {
        let symbols = PersistenceManager.shared.watchList
        let group = DispatchGroup()
        
        for symbol in symbols where watchListData[symbol] == nil {
            // Fetch data of the companies listed in the watch list in which the data is absent.
            group.enter()
            
            APICaller.shared.getStockData(
                for: symbol,
                historyDuration: days) { [weak self] result in
                
                defer {
                    group.leave()
                }
                
                switch result {
                case .success(let stockData):
                    self?.watchListData[symbol] = stockData
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.createViewModels()
            self?.tableView.reloadData()
        }
    }
    
    private func createViewModels() {
        var viewModels = [WatchListTableViewCell.ViewModel]()
            
        for (symbol, stockData) in watchListData {
            let currentPrice = stockData.quote.current
            let previousClose = stockData.quote.prevClose
            let priceChange = (currentPrice / previousClose) - 1
            let priceChangePercentage = String.stockPriceChangePercentage(from: priceChange)
            
            let model = WatchListTableViewCell.ViewModel(
                symbol: symbol,
                companyName: UserDefaults.standard.string(forKey: symbol) ?? symbol,
                price: String.decimalFormatted(from: currentPrice),
                changeColor: priceChange < 0 ? .systemRed : .systemGreen,
                changePercentage: priceChangePercentage,
                chartViewModel: .init(
                    data: stockData.candleSticks.map{ $0.close },
                    showLegend: false,
                    showAxis: false
                )
            )
            viewModels.append(model)
        }
        
        self.viewModels = viewModels.sorted(by: { $0.symbol < $1.symbol })
    }
    
    private func setUpTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setUpFloatingPanel() {
        let vc = NewsViewController(type: .topStories)
        let panel = FloatingPanelController()
        panel.surfaceView.backgroundColor = .secondarySystemBackground
        panel.set(contentViewController: vc)
        panel.addPanel(toParent: self)
        panel.delegate = self
        panel.track(scrollView: vc.tableView)
    }
    
    private func setUpTitleView() {
        let titleView = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: view.width,
                height: navigationController?.navigationBar.height ?? 100
            )
        )
        let label = UILabel(frame: CGRect(x: 10, y: 10, width: titleView.width - 20, height: titleView.height - 15))
        label.text = "Stocks"
        label.font = .systemFont(ofSize: 36, weight: .bold)
        titleView.addSubview(label)
        
        navigationItem.titleView = titleView
    }

    private func setUpSearchController() {
        let resultVC = SearchResultViewController()
        resultVC.delegate = self
        
        let searchVC = UISearchController(searchResultsController: resultVC)
        searchVC.searchResultsUpdater = self
        navigationItem.searchController = searchVC
    }

}

extension WatchListViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text,
              let resultVC = searchController.searchResultsController as? SearchResultViewController,
              !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        // Reset timer
        searchTimer?.invalidate()
        
        // Kick off new timer
        // Optimize to reduce number of searches for when user stops typing
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { _ in
            // Call API to search
            APICaller.shared.search(query: query) { result in
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        resultVC.update(with: response.result)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        resultVC.update(with: [])
                    }
                    print(error)
                }
            }
        })
    }
    
}

extension WatchListViewController: SearchResultViewControllerDelegate {
    
    func searchResultViewControllerDidSelect(searchResult: SearchResult) {
        // Present stock details for given selection
        navigationItem.searchController?.searchBar.resignFirstResponder()
        
        let stockDetailVC = StockDetailsViewController(
            symbol: searchResult.displaySymbol,
            companyName: searchResult.description
        )
        stockDetailVC.title = searchResult.description
        
        let navVC = UINavigationController(rootViewController: stockDetailVC)
        present(navVC, animated: true, completion: nil)
    }
    
}

extension WatchListViewController: FloatingPanelControllerDelegate {
    func floatingPanelDidChangeState(_ fpc: FloatingPanelController) {
        navigationItem.titleView?.isHidden = fpc.state == .full
    }
}

extension WatchListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: WatchListTableViewCell.identifier,
            for: indexPath
        ) as? WatchListTableViewCell else {
            fatalError()
        }
        cell.delegate = self
        cell.configure(with: viewModels[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return WatchListTableViewCell.preferredHeight
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            
            // Update persistence
            PersistenceManager.shared.removeFromWatchlist(symbol: viewModels[indexPath.row].symbol)
            
            // Update ViewModels
            viewModels.remove(at: indexPath.row)
            
            // Delete Row
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Show selected stock details
        let viewModel = viewModels[indexPath.row]
        let stockDetailsVC = StockDetailsViewController(
            symbol: viewModel.symbol,
            companyName: viewModel.companyName,
            candleStickData: watchListData[viewModel.symbol]?.candleSticks ?? []
        )
        let navVC = UINavigationController(rootViewController: stockDetailsVC)
        present(navVC, animated: true, completion: nil)
    }
}

extension WatchListViewController: WatchListTableViewCellDelegate {
    func didUpdateMaxWidth() {
        // Optimize: Only refresh rows prior to the current row that changes the max width.
        tableView.reloadData()
    }
}
