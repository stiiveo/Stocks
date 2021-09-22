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
    
    // MARK: - UI Components
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(WatchListTableViewCell.self,
                       forCellReuseIdentifier: WatchListTableViewCell.identifier)
        return table
    }()
    
    private var panel: FloatingPanelController?
    private let footerView = WatchlistFooterView()
    private var shownStockDetailsVC: StockDetailsViewController?
    
    // MARK: - ScrollView Observing Properties
    
    private var lastContentOffset: CGFloat = 0
    
    // MARK: - Managers Access Points
    
    private let persistenceManager = PersistenceManager.shared
    private let calendarManager = CalendarManager.shared
    private let apiCaller = APICaller.shared
    
    // MARK: - Timer Properties
    private var searchTimer: Timer?
    private var prevSearchBarQuery = ""
    
    weak var delegate: WatchlistViewControllerDelegate?
    
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
            do {
                stocksData = try persistenceManager.persistedStocksData()
            } catch {
                // Load default stocks data if the persisted data somehow failed to be loaded.
                persistenceManager.savedDefaultStocks()
                loadDefaultTableViewCells()
                print(error)
            }
        } else {
            persistenceManager.onboard()
            loadDefaultTableViewCells()
        }
        updateWatchlistData()
        
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
            invalidateWatchlistUpdateTimer()
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
            initiateWatchlistUpdateTimer()
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
    
    private func loadDefaultTableViewCells() {
        for symbol in persistenceManager.watchList.sorted() {
            let stockData = StockData(symbol: symbol, quote: nil, priceHistory: [])
            stocksData.append(stockData)
            DispatchQueue.main.async {
                self.tableView.reloadRows(at: [IndexPath(row: self.stocksData.count - 1, section: 0)], with: .automatic)
            }
        }
    }
    
    private var updateTimer: Timer?
    
    func initiateWatchlistUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [unowned self] _ in
            let currentSecondComponent = calendarManager.newYorkCalendar.component(.second, from: Date())
            if currentSecondComponent == 0 {
                updateQuoteData()
                updateChartData()
            } else if currentSecondComponent == 30 {
                updateQuoteData()
            }
        }
    }
    
    func invalidateWatchlistUpdateTimer() {
        updateTimer?.invalidate()
    }

}

// MARK: - Persistence Manager Delegate

extension WatchListViewController: PersistenceManagerDelegate {
    func didAddNewCompanyToWatchlist(symbol: String) {
        apiCaller.fetchQuoteAndCandlesData(symbol: symbol, timeSpan: .day) {
            [unowned self] result in
            switch result {
            case .success(let stockData):
                self.stocksData.append(stockData)
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
        invalidateWatchlistUpdateTimer()
    }
    func willDismissSearchController(_ searchController: UISearchController) {
        self.panel?.show(animated: true)
        initiateWatchlistUpdateTimer()
    }
}

extension WatchListViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text,
              query != prevSearchBarQuery, // Make sure the new query is diff from the prev one.
              let resultVC = searchController.searchResultsController as? SearchResultViewController else {
            return
        }
        
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            DispatchQueue.main.async {
                resultVC.update([], from: query)
            }
            return
        }
        
        // Reset timer
        searchTimer?.invalidate()
        prevSearchBarQuery = query // Save the current query for comparison later.
        
        // Kick off new timer
        // Optimize to reduce number of searches for when user stops typing
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [unowned self] _ in
            // Call API to search
            self.apiCaller.search(query: query) { result in
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        resultVC.update(response.result, from: query)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        resultVC.update([], from: query)
                    }
                    print("Failed to get valid search response: \(error)")
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
        
        apiCaller.fetchQuoteAndCandlesData(symbol: searchResult.symbol, timeSpan: .day) { [unowned self] result in
            switch result {
            case .success(let stockData):
                // Present stock details view controller initialized with fetched stock data.
                DispatchQueue.main.async {
                    self.shownStockDetailsVC = StockDetailsViewController(stockData: stockData)
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
        return stocksData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: WatchListTableViewCell.identifier,
            for: indexPath
        ) as? WatchListTableViewCell else {
            fatalError()
        }
        cell.reset()
        cell.configure(with: stocksData[indexPath.row], showChartAxis: false)
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
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.performBatchUpdates {
                let index = indexPath.row
                PersistenceManager.shared.removeFromWatchlist(symbol: stocksData[index].symbol)
                stocksData.remove(at: index)
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
        
        // Present stock details view controller initialized with cached stock data.
        shownStockDetailsVC = StockDetailsViewController(stockData: stocksData[indexPath.row])
        delegate = shownStockDetailsVC
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

// MARK: - Data Updating Methods

protocol WatchlistViewControllerDelegate: AnyObject {
    func didUpdateData(stockData: StockData)
    var symbol: String { get }
}

extension WatchListViewController {
    
    /// Fetch the quote and candle sticks data of all the stocks saved in the watchlist.
    /// - Parameter timeSpan: The time span of the candle stick data.
    /// - Note: The order of the list is determined by the order the data is fetched.
    private func updateWatchlistData() {
        updateQuoteData()
        updateChartData()
    }
    
    /// Update any data in the watchlist if its quote time is before the market closing time.
    private func updateQuoteData() {
        print("update Quote Data")
        for index in 0..<stocksData.count {
            let symbol = stocksData[index].symbol
            apiCaller.fetchStockQuote(for: symbol) { [unowned self] result in
                switch result {
                case .success(let quoteData):
                    stocksData[index].quote = quoteData
                    DispatchQueue.main.async {
                        if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? WatchListTableViewCell {
                            cell.configure(with: stocksData[index], showChartAxis: false)
                        }
                    }
                    if delegate?.symbol == symbol {
                        delegate?.didUpdateData(stockData: stocksData[index])
                    }
                case .failure(let error):
                    print("Failed to fetch quote data of stock \(symbol):\n\(error)")
                }
            }
        }
    }
    
    private func updateChartData() {
        print("update Chart Data")
        for index in 0..<stocksData.count {
            let symbol = stocksData[index].symbol
            apiCaller.fetchPriceHistory(symbol, timeSpan: .day) { [unowned self] result in
                switch result {
                case .success(let candlesResponse):
                    stocksData[index].priceHistory = candlesResponse.priceHistory
                    DispatchQueue.main.async {
                        if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? WatchListTableViewCell {
                            cell.configure(with: stocksData[index], showChartAxis: false)
                        }
                    }
                    if delegate?.symbol == symbol {
                        delegate?.didUpdateData(stockData: stocksData[index])
                    }
                case .failure(let error):
                    print("Failed to fetch price history data of stock \(symbol):\n\(error)")
                }
            }
        }
    }
    
}

// MARK: - Stock Data Persisting

extension WatchListViewController {
    /// Persist the stocks data cached in this class.
    func persistStocksData() {
        let persistedList = persistenceManager.watchList
        let cachedList = stocksData.map({ $0.symbol })
        if persistedList.count != stocksData.count {
            // The number of stocks in persisted watchlist somehow does not match with the cached ones.
            // Append the missing data to the cache before persisting it.
            let diff = persistedList.difference(from: cachedList)
            for symbol in diff {
                if !persistedList.contains(symbol) {
                    persistenceManager.addToWatchlist(symbol: symbol, companyName: symbol)
                }
                if !cachedList.contains(symbol) {
                    let stockData = StockData(symbol: symbol, quote: nil, priceHistory: [])
                    stocksData.append(stockData)
                }
            }
        }
        
        persistenceManager.persistStocksData(stocksData)
    }
}
