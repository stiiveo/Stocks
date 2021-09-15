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
    
    // MARK: - Data Cache
    
    private var stocksData = [StockData]()
    private var watchlistCellViewModel = WatchlistCellViewModel()
    
    // MARK: - UI Components
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(WatchListTableViewCell.self,
                       forCellReuseIdentifier: WatchListTableViewCell.identifier)
        return table
    }()
    
    private var panel: FloatingPanelController?
    private let footerView = WatchlistFooterView()
    
    // MARK: - ScrollView Observing Properties
    
    private var lastContentOffset: CGFloat = 0
    
    // MARK: - Managers Access Points
    
    private let persistenceManager = PersistenceManager.shared
    private let calendarManager = CalendarManager.shared
    private let apiCaller = APICaller.shared
    
    // MARK: - Timer Properties
    
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
        setUpFloatingPanel()
        setUpFooterView()
        persistenceManager.delegate = self
        
        if persistenceManager.hasOnboarded {
            loadPersistedStocksData()
            updateStocksData()
        } else {
            persistenceManager.onboard()
            fetchStockData()
        }
    }
    
    // MARK: - UI Setting
    
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
        
        // Add system edit bar button to the NavBar.
        let buttonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editButtonDidTap))
        navigationItem.rightBarButtonItem = buttonItem
    }
    
    @objc private func editButtonDidTap() {
        if !tableView.isEditing {
            // Enter editing mode.
            tableView.setEditing(true, animated: true)
            navigationItem.rightBarButtonItem?.title = "Done"
            navigationItem.rightBarButtonItem?.style = .done
            panel?.hide(animated: true)
        } else {
            // Leave editing mode.
            tableView.setEditing(false, animated: true)
            navigationItem.rightBarButtonItem?.title = "Edit"
            navigationItem.rightBarButtonItem?.style = .plain
            persistStocksData()
            panel?.show(animated: true)
        }
        
        // Notify all table view cells the table view's editing status.
        NotificationCenter.default.post(name: .didChangeEditingMode, object: tableView.isEditing)
    }
    
    private func setUpTitleView() {
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 400, height: 30)
        
        let label = UILabel(frame: CGRect(x: 10, y: 0, width: 200, height: 30))
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

// MARK: - Stock Details VC Delegate

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
                self.stocksData.append(stockData)
                self.watchlistCellViewModel.add(with: stockData)
                DispatchQueue.main.async {
                    let newRowIndex = self.stocksData.count - 1
                    self.tableView.insertRows(at: [IndexPath(row: newRowIndex, section: 0)],
                                              with: .automatic)
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}

// MARK: - Search Controller Delegate

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

// MARK: - Search Result VC Delegate

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
                        companyName: searchResult.description,
                        quoteData: stockData.quote,
                        chartData: stockData.priceHistory)
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
    
    func searchResultScrollViewWillBeginDragging() {
        // Dismiss the keyboard when the result table view is about to be scrolled.
        if let searchBar = navigationItem.searchController?.searchBar,
           searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
        }
    }
    
}

// MARK: - Floating Panel Delegate

extension WatchListViewController: FloatingPanelControllerDelegate {
    func floatingPanelDidChangeState(_ fpc: FloatingPanelController) {
        navigationItem.titleView?.isHidden = fpc.state == .full
    }
}

// MARK: - TableView Data Source & Delegate

extension WatchListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return watchlistCellViewModel.models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: WatchListTableViewCell.identifier,
            for: indexPath
        ) as? WatchListTableViewCell else {
            fatalError()
        }
        cell.reset()
        cell.configure(with: watchlistCellViewModel.models[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        stocksData.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
        watchlistCellViewModel.models.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.performBatchUpdates {
                let symbol = watchlistCellViewModel.models[indexPath.row].symbol
                if let index = stocksData.firstIndex(where: { $0.symbol == symbol }) {
                    stocksData.remove(at: index)
                    watchlistCellViewModel.models.remove(at: index)
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
        let stockData = stocksData[indexPath.row]
        let companyName = UserDefaults.standard.string(forKey: stockData.symbol) ?? stockData.symbol
        shownStockDetailsVC = StockDetailsViewController(symbol: stockData.symbol,
                                                         companyName: companyName,
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
    
    // MARK: - Data-Fetching Timer
    
    /// Initiate the repeating timer which triggers data updating method after the preset time interval.
    func initiateDataFetchingTimer() {
        // Update watchlist's data every 20 seconds.
        watchlistDataUpdateTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { [unowned self] _ in
            updateStocksData()
        }
    }
    
    /// Invalidate the timer of auto data fetching.
    func invalidateDataFetchingTimer() {
        watchlistDataUpdateTimer?.invalidate()
    }
    
    /// Fetch the quote and candle sticks data of all the stocks saved in the watchlist.
    /// - Parameter timeSpan: The time span of the candle stick data.
    /// - Note: The order of the list is determined by the order the data is fetched.
    private func fetchStockData() {
        for symbol in persistenceManager.watchList {
            apiCaller.fetchQuoteAndCandlesData(symbol: symbol, timeSpan: .day) {
                [unowned self] result in
                switch result {
                case .success(let stockData):
                    stocksData.append(stockData)
                    watchlistCellViewModel.add(with: stockData)
                    DispatchQueue.main.async {
                        tableView.reloadData()
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    /// Update any data in the watchlist if its quote time is before the market closing time.
    private func updateStocksData() {
        let marketCloseTime = calendarManager.latestTradingTime.close.timeIntervalSince1970
        for index in 0..<stocksData.count {
            let data = stocksData[index]
            let quoteTime = data.quote.time
            if TimeInterval(quoteTime) < marketCloseTime {
                apiCaller.fetchQuoteAndCandlesData(symbol: data.symbol, timeSpan: .day) {
                    [unowned self] result in
                    switch result {
                    case .success(let stockData):
                        stocksData[index] = stockData
                        do {
                            try watchlistCellViewModel.update(index, with: stockData)
                        } catch {
                            print(error)
                        }
                        DispatchQueue.main.async {
                            tableView.reloadRows(
                                at: [IndexPath(row: index, section: 0)],
                                with: .automatic)
                        }
                        
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
    }
    
}

// MARK: - Stock Data Persisting

extension WatchListViewController {
    /// Persist the stocks data cached in this class.
    func persistStocksData() {
        persistenceManager.persistStocksData(stocksData)
    }
    
    /// Cache the persisted stocks data to this class and generate watchlist cell view models from it.
    func loadPersistedStocksData() {
        stocksData = persistenceManager.persistedStocksData()
        watchlistCellViewModel.models.removeAll()
        for stockData in stocksData {
            watchlistCellViewModel.add(with: stockData)
        }
    }
}
