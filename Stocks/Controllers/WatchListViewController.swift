//
//  WatchListViewController.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import UIKit
import FloatingPanel
import SafariServices

final class WatchListViewController: UIViewController {
    
    static let shared = WatchListViewController()
    
    private var panel: FloatingPanelController?
    
    static var maxPriceLabelWidth: CGFloat = 0
    
    private var watchlistData = [StockData]()
    
    private var viewModel = WatchlistTableViewCellViewModel()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(WatchListTableViewCell.self,
                       forCellReuseIdentifier: WatchListTableViewCell.identifier)
        return table
    }()
    private let footerView = WatchlistFooterView()
    
    private var lastContentOffset: CGFloat = 0
    
    private let persistenceManager = PersistenceManager.shared
    private let calendarManager = CalendarManager.shared
    private let apiCaller = APICaller.shared
    
    private var watchlistDataUpdateTimer: Timer?
    private var searchTimer: Timer?
    private var prevSearchBarQuery = ""
    
    private var selectedCellIndex = 0
    private var shownStockDetailsVC: StockDetailsViewController?
    
    
    // MARK: - Init
    
    private init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setUpNavigationBar()
        setUpSearchController()
        setUpTableView()
        fetchStockData()
        setUpFloatingPanel()
        setUpFooterView()
        persistenceManager.delegate = self
    }
    
    // MARK: - Public
    
    func initiateDataFetchingTimer() {
        // Update the watchlist data before initiating the timer.
        updateWatchlistData()
        // Update watchlist's data every 20 seconds.
        watchlistDataUpdateTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] _ in
            self?.updateWatchlistData()
        }
    }
    
    func invalidateDataFetchingTimer() {
        watchlistDataUpdateTimer?.invalidate()
    }
    
    // MARK: - Private Methods
    
    private func setUpTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = CGRect(x: 0, y: 0,
                                 width: view.width,
                                 height: view.height - 175)
    }
    
    private func setUpFloatingPanel() {
        let vc = NewsViewController()
        let panel = FloatingPanelController()
        panel.layout = WatchlistFloatingPanelLayout()
        panel.surfaceView.backgroundColor = .secondarySystemBackground
        panel.set(contentViewController: vc)
        panel.addPanel(toParent: self)
        panel.delegate = self
        panel.track(scrollView: vc.tableView)
        self.panel = panel
    }
    
    private func setUpNavigationBar() {
        navigationController?.navigationBar.isTranslucent = false
        extendedLayoutIncludesOpaqueBars = true
        setUpTitleView()
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
        let label = UILabel(
            frame: CGRect(x: 10, y: 10,
                          width: titleView.width - 20,
                          height: titleView.height - 20)
        )
        label.text = "U.S. Stocks"
        label.font = .systemFont(ofSize: 26, weight: .heavy)
        titleView.addSubview(label)
        
        navigationItem.titleView = titleView
    }

    private func setUpSearchController() {
        let resultVC = SearchResultViewController()
        resultVC.delegate = self
        let searchVC = UISearchController(searchResultsController: resultVC)
        searchVC.searchResultsUpdater = self
        searchVC.delegate = self
        navigationItem.searchController = searchVC
    }
    
    private func setUpFooterView() {
        view.addSubviews(footerView)
        footerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            footerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            footerView.heightAnchor.constraint(equalToConstant: 86)
        ])
    }

}

extension WatchListViewController: StockDetailsViewControllerDelegate {
    func stockDetailsViewControllerIsShown() {
        invalidateDataFetchingTimer()
    }
    
    func stockDetailsViewControllerWillBeDismissed() {
        initiateDataFetchingTimer()
    }
}

// MARK: - Persistence Manager Delegate

extension WatchListViewController: PersistenceManagerDelegate {
    func didAddNewCompanyToWatchlist(symbol: String) {
        apiCaller.fetchQuoteAndCandlesData(symbol: symbol, timeSpan: .day) {
            [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let stockData):
                self.watchlistData.append(stockData)
                self.viewModel.add(with: stockData)
                DispatchQueue.main.async {
                    let newRowIndex = self.watchlistData.count - 1
                    self.tableView.insertRows(at: [IndexPath(row: newRowIndex, section: 0)],
                                              with: .automatic)
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}

// MARK: - Search Related Delegate

extension WatchListViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        self.panel?.hide(animated: true)
    }
    func willDismissSearchController(_ searchController: UISearchController) {
        self.panel?.show(animated: true)
    }
}

extension WatchListViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text,
              query != prevSearchBarQuery, // Make sure the new query is diff from the prev one.
              let resultVC = searchController.searchResultsController as? SearchResultViewController,
              !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        // Reset timer
        searchTimer?.invalidate()
        prevSearchBarQuery = query // Save the current query for comparison later.
        
        // Kick off new timer
        // Optimize to reduce number of searches for when user stops typing
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            // Call API to search
            self?.apiCaller.search(query: query) { result in
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
        }
    }
    
}

extension WatchListViewController: SearchResultViewControllerDelegate {
    
    func searchResultViewControllerDidSelect(searchResult: SearchResult) {
        // Present stock details VC for the selected stock.
        navigationItem.searchController?.searchBar.resignFirstResponder()
        HapticsManager.shared.vibrateForSelection()
        
        apiCaller.fetchQuoteAndCandlesData(symbol: searchResult.symbol, timeSpan: .day) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let stockData):
                // Present stock details view controller initialized with fetched stock data.
                DispatchQueue.main.async {
                    self.shownStockDetailsVC = StockDetailsViewController(
                        symbol: stockData.symbol,
                        quoteData: stockData.quote,
                        chartData: stockData.priceHistory)
                    self.shownStockDetailsVC!.title = searchResult.description
                    self.shownStockDetailsVC!.delegate = self

                    let navVC = UINavigationController(rootViewController: self.shownStockDetailsVC!)
                    self.present(navVC, animated: true, completion: nil)
                }
            case .failure(let error):
                print("Failed to present details view controller due to data fetching error: \(error)")
                DispatchQueue.main.async {
                    self.presentAPIErrorAlert()
                }
            }
        }
        
        
    }
    
    func scrollViewWillBeginDragging() {
        // Dismiss the keyboard when the result table view is about to be scrolled.
        if let searchBar = navigationItem.searchController?.searchBar,
           searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
        }
    }
    
}

extension WatchListViewController: FloatingPanelControllerDelegate {
    func floatingPanelDidChangeState(_ fpc: FloatingPanelController) {
        navigationItem.titleView?.isHidden = fpc.state == .full
    }
}

// MARK: - Table View Data Source & Delegate

extension WatchListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.all.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: WatchListTableViewCell.identifier,
            for: indexPath
        ) as? WatchListTableViewCell else {
            fatalError()
        }
        cell.reset()
        cell.configure(with: viewModel.all[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.performBatchUpdates {
                let symbol = viewModel.all[indexPath.row].symbol
                if let index = watchlistData.firstIndex(where: { $0.symbol == symbol }) {
                    watchlistData.remove(at: index)
                    do {
                        try viewModel.remove(from: index)
                    } catch {
                        print(error)
                    }
                }
                PersistenceManager.shared.removeFromWatchlist(symbol: symbol)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
    }
    
    /// This method is called if the user selects one of the tableView cells.
    /// - Parameters:
    ///   - tableView: TableView used to layout the cells containing each company's data.
    ///   - indexPath: IndexPath pointing to the selected tableView row.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        HapticsManager.shared.vibrateForSelection()
        
        // Show selected stock's details view controller.
        selectedCellIndex = indexPath.row
        let stockData = watchlistData[indexPath.row]
        shownStockDetailsVC = StockDetailsViewController(symbol: stockData.symbol,
                                                         quoteData: stockData.quote,
                                                         chartData: stockData.priceHistory)
        shownStockDetailsVC?.delegate = self
        let navVC = UINavigationController(rootViewController: shownStockDetailsVC!)
        present(navVC, animated: true, completion: nil)
    }
    
    // MARK: - ScrollView Delegate Methods
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset.y
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Move the floating panel to the bottom when tableView is scrolled up.
        guard let panel = panel else { return }
        if scrollView.contentOffset.y > self.lastContentOffset {
            if panel.state == .full || panel.state == .half {
                panel.move(to: .tip, animated: true)
            }
        }
    }
}

// MARK: - Data Fetching & Updating Methods

extension WatchListViewController {
    
    /// Fetch the quote and candle sticks data of all the stocks saved in the watchlist.
    /// - Parameter timeSpan: The time span of the candle stick data.
    /// - Note: The order of the list is determined by the order the data is fetched.
    private func fetchStockData() {
        for symbol in persistenceManager.watchList {
            apiCaller.fetchQuoteAndCandlesData(symbol: symbol, timeSpan: .day) {
                [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let stockData):
                    self.watchlistData.append(stockData)
                    self.viewModel.add(with: stockData)
                    DispatchQueue.main.async {
                        self.footerView.updateMarketStatusLabel()
                        self.tableView.reloadData()
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    /// Update any data in the watchlist if its quote time is before the market closing time.
    private func updateWatchlistData() {
        let marketCloseTime = calendarManager.latestTradingTime.close.timeIntervalSince1970
        for index in 0..<watchlistData.count {
            let data = watchlistData[index]
            let quoteTime = data.quote.time
            if TimeInterval(quoteTime) < marketCloseTime {
                apiCaller.fetchQuoteAndCandlesData(symbol: data.symbol, timeSpan: .day) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let stockData):
                        self.watchlistData[index] = stockData
                        do {
                            try self.viewModel.update(index, with: stockData)
                        } catch {
                            print(error)
                        }
                        DispatchQueue.main.async {
                            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)],
                                                      with: .automatic)
                            self.footerView.updateMarketStatusLabel()
                        }
                        
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
    }
    
}
