//
//  WatchListViewController.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import UIKit
import FloatingPanel
import SafariServices
import SnapKit

final class WatchListViewController: UIViewController {
    
    static let shared = WatchListViewController()
    
    // Data Cache
    @DiskPersisted(fileURL: PersistenceManager.persistedDataUrl)
    private var stocksData = PersistenceManager.defaultData
    
    // UI Components
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(WatchListTableViewCell.self,
                       forCellReuseIdentifier: WatchListTableViewCell.identifier)
        return table
    }()
    private var panel: FloatingPanelController?
    private lazy var footerView = WatchlistFooterView()
    
    // ScrollView Observing Properties
    private var lastContentOffset: CGFloat = 0
    private let persistenceManager = PersistenceManager.shared
    
    // Timer Properties
    private var searchTimer: Timer?
    private var prevSearchBarQuery = ""
    
    // Settings on the minimum interval of the data updating.
    // Note: Setting these values too small yields little benefit
    // and could consumes the limited quotas of api calls quickly
    // since there's quite big interval between each data provided
    // by Finnhub.
    private let quoteUpdatingInterval: TimeInterval = 30
    private let chartUpdatingInterval: TimeInterval = 60
    
    // Search Controller State
    private var isSearchControllerPresented = false
    
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
        
        if !persistenceManager.isOnboarded {
            persistenceManager.isOnboarded = true
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onApiLimitReached),
            name: .apiLimitReached,
            object: nil
        )
        
        updateQuoteData()
        updateChartData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Edit Button Actions
    
    @objc private func editButtonDidTap() {
        if !tableView.isEditing {
            // Enter editing mode.
            invalidateDataUpdater()
            tableView.setEditing(true, animated: true)
            tableView.snp.updateConstraints { make in
                make.bottom.equalTo(view.bottom).offset(-86)
            }
            navigationItem.rightBarButtonItem?.title = "Done"
            navigationItem.rightBarButtonItem?.style = .done
            panel?.hide(animated: true)
        } else {
            // Leave editing mode.
            tableView.setEditing(false, animated: true)
            tableView.snp.updateConstraints { make in
                make.bottom.equalTo(view).offset(-175.0)
            }
            navigationItem.rightBarButtonItem?.title = "Edit"
            navigationItem.rightBarButtonItem?.style = .plain
            panel?.show(animated: true)
            initiateDataUpdater()
        }
        
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
        
        // Notify all table view cells the table view's editing status.
        NotificationCenter.default.post(name: .didChangeEditingMode, object: tableView.isEditing)
    }
    
    // MARK: - UI Setting
    
    private func setUpTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        tableView.snp.makeConstraints { make in
            make.top.left.right.equalTo(view)
            make.bottom.equalTo(view.bottom).offset(-175.0)
        }
    }
    
    private func updateTableViewBottomOffset(avoidFloatingPanel: Bool) {
        if avoidFloatingPanel {
            tableView.snp.updateConstraints { make in
                make.bottom.equalTo(view).offset(-175.0)
            }
        } else {
            tableView.snp.updateConstraints { make in
                make.bottom.equalTo(view.bottom).offset(-86)
            }
        }
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
        footerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(86)
        }
    }
    
    // MARK: - Data Update Operations
    
    private var updateTimer: Timer?
    private var lastQuoteDataUpdatedTime: TimeInterval = 0
    private var lastChartDataUpdatedTime: TimeInterval = 0
    
    func initiateDataUpdater() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
            [unowned self] _ in
            guard !isUpdateSuspended else { return }
            updateOutdatedData()
        }
    }
    
    private func updateOutdatedData() {
        let currentTime = Date().timeIntervalSince1970
        let timeSinceQuoteUpdated = currentTime - lastQuoteDataUpdatedTime
        let timeSinceChartUpdated = currentTime - lastChartDataUpdatedTime
        
        if timeSinceQuoteUpdated >= quoteUpdatingInterval &&
            timeSinceChartUpdated >= chartUpdatingInterval {
            updateChartData()
            updateQuoteData()
        } else if timeSinceQuoteUpdated >= quoteUpdatingInterval {
            updateQuoteData()
        } else if timeSinceChartUpdated >= chartUpdatingInterval {
            updateChartData()
        }
    }
    
    func invalidateDataUpdater() {
        updateTimer?.invalidate()
    }
    
    // MARK: - Notification Selectors
    
    private var isUpdateSuspended = false
    
    @objc private func onApiLimitReached() {
        // Suspend data updating operation.
        isUpdateSuspended = true
        
        /// Set `isUpdateSuspended` to `false` after a preset time when the quota limit should be reset.
        /// Note: This timer must be added to `RunLoop` for the timer to be fired properly after the specified
        /// time interval for unknown reason.
        let dataUpdateSuspendingTimer = Timer(timeInterval: 60.0, target: self, selector: #selector(resumeDataUpdating), userInfo: nil, repeats: false)
        RunLoop.main.add(dataUpdateSuspendingTimer, forMode: .common)
        
        // Present alert to the user.
        DispatchQueue.main.async { [unowned self] in
            guard presentedViewController == nil else { return }
            presentApiAlert(type: .apiLimitReached)
        }
    }
    
    @objc private func resumeDataUpdating() {
        isUpdateSuspended = false
    }

}

// MARK: - Stock Details VC Delegate

extension WatchListViewController: StockDetailsViewControllerDelegate {
    func stockDetailsViewControllerDidAddStockData(_ stockData: StockData) {
        stocksData.append(stockData)
        DispatchQueue.main.async {
            let newRowIndex = self.stocksData.count - 1
            self.tableView.insertRows(at: [IndexPath(row: newRowIndex, section: 0)],
                                      with: .automatic)
        }
    }
    func stockDetailsViewControllerDidDisappear(_ controller: StockDetailsViewController) {
        if !isSearchControllerPresented {
            initiateDataUpdater()
        }
    }
}

// MARK: - Search Controller Delegate

extension WatchListViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        invalidateDataUpdater()
        self.panel?.hide(animated: true)
        updateTableViewBottomOffset(avoidFloatingPanel: false)
        if stocksData.count > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
        isSearchControllerPresented = true
    }
    func willDismissSearchController(_ searchController: UISearchController) {
        initiateDataUpdater()
        self.panel?.show(animated: true)
        updateTableViewBottomOffset(avoidFloatingPanel: true)
        isSearchControllerPresented = false
    }
}

extension WatchListViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text,
              let resultVC = searchController.searchResultsController
                as? SearchResultViewController else { return }
        
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            prevSearchBarQuery = ""
            DispatchQueue.main.async {
                resultVC.update([], from: query)
            }
            return
        }
        
        // Make sure the new query is diff from the prev one.
        guard query != prevSearchBarQuery else { return }
        
        // Reset timer
        searchTimer?.invalidate()
        prevSearchBarQuery = query // Save the current query for comparison later.
        
        // Kick off new timer
        // Optimize to reduce number of searches for when user stops typing
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            // Call API to search
            APICaller().search(query: query) { result in
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
    
    func didSelectSearchResult(_ searchResult: SearchResult) {
        // Present stock details VC for the selected stock.
        navigationItem.searchController?.searchBar.resignFirstResponder()
        HapticsManager().vibrateForSelection()
        
        DispatchQueue.main.async { [unowned self] in
            let symbol = searchResult.symbol
            var stockData = StockData(symbol: symbol)
            var isDataCached = false
            if let cachedData = stocksData.first(where: { $0.symbol == symbol }) {
                stockData = cachedData
                isDataCached = true
            }
            let vc = StockDetailsViewController(
                stockData: stockData,
                companyName: searchResult.description.localizedCapitalized,
                lastQuoteDataUpdatedTime: isDataCached ? lastQuoteDataUpdatedTime : 0,
                lastChartDataUpdatedTime: isDataCached ? lastChartDataUpdatedTime : 0
            )
            vc.delegate = self
            let navVC = UINavigationController(rootViewController: vc)
            present(navVC, animated: true, completion: nil)
        }
    }
    
    func searchResultScrollViewWillBeginDragging(scrollView: UIScrollView) {
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
        cell.configure(with: stocksData[indexPath.row], showChartAxis: false, onEditing: tableView.isEditing)
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
                let symbol = stocksData[index].symbol
                stocksData.remove(at: index)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                persistenceManager.watchlist[symbol] = nil
            }
        }
    }
    
    /// This method is called if the user selects one of the tableView cells.
    /// - Parameters:
    ///   - tableView: TableView used to layout the cells containing each company's data.
    ///   - indexPath: IndexPath pointing to the selected tableView row.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        invalidateDataUpdater()
        tableView.deselectRow(at: indexPath, animated: true)
        HapticsManager().vibrateForSelection()
        
        // Present stock details view controller initialized with cached stock data.
        let data = stocksData[indexPath.row]
        let vc = StockDetailsViewController(
            stockData: data,
            companyName: data.companyName,
            lastQuoteDataUpdatedTime: lastQuoteDataUpdatedTime,
            lastChartDataUpdatedTime: lastChartDataUpdatedTime
        )
        vc.delegate = self
        let navVC = UINavigationController(rootViewController: vc)
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

extension WatchListViewController {
    /// Update any data in the watchlist if its quote time is before the market closing time.
    private func updateQuoteData() {
        lastQuoteDataUpdatedTime = Date().timeIntervalSince1970
        stocksData.forEach {
            let symbol = $0.symbol
            APICaller().fetchStockQuote(for: symbol) { [unowned self] result in
                switch result {
                case .success(let quoteData):
                    // Make sure cached data with the symbol value still exists.
                    guard let index = stocksData.firstIndex(where: { $0.symbol == symbol }) else {
                        print("Data updating is aborted since no data with symbol \(symbol) is stored.")
                        return
                    }
                    // Update cached data and tableView cell.
                    stocksData[index].quote = quoteData
                    let indexPath = IndexPath(row: index, section: 0)
                    DispatchQueue.main.async {
                        if let cell = tableView.cellForRow(at: indexPath) as? WatchListTableViewCell {
                            cell.configure(with: stocksData[index],
                                           showChartAxis: false,
                                           onEditing: tableView.isEditing)
                        }
                    }
                case .failure(let error):
                    print("Failed to fetch quote data of stock \(symbol):\n\(error)")
                }
            }
        }
    }
    
    private func updateChartData() {
        lastChartDataUpdatedTime = Date().timeIntervalSince1970
        stocksData.forEach {
            let symbol = $0.symbol
            APICaller().fetchPriceHistory(symbol, timeSpan: .day) { [unowned self] result in
                switch result {
                case .success(let candlesResponse):
                    // Make sure cached data with the symbol value still exists.
                    guard let index = stocksData.firstIndex(where: { $0.symbol == symbol }) else {
                        print("Data updating is aborted since no data with symbol \(symbol) is stored.")
                        return
                    }
                    // Update cached data and tableView cell.
                    stocksData[index].priceHistory = candlesResponse.priceHistory
                    let indexPath = IndexPath(row: index, section: 0)
                    DispatchQueue.main.async {
                        if let cell = tableView.cellForRow(at: indexPath) as? WatchListTableViewCell {
                            cell.configure(with: stocksData[index],
                                           showChartAxis: false,
                                           onEditing: tableView.isEditing)
                        }
                    }
                case .failure(let error):
                    print("Failed to fetch price history data of stock \(symbol):\n\(error)")
                }
            }
        }
    }
}
