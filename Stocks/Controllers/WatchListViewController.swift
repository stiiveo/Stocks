//
//  WatchListViewController.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import UIKit
import FloatingPanel

class WatchListViewController: UIViewController {
    
    static let sharedInstance = WatchListViewController()
    
    private var panel: FloatingPanelController?
    
    static var maxPriceLabelWidth: CGFloat = 0
    
    private var watchListData: [String: StockData] = [:]
    
    private var viewModels = [WatchListTableViewCell.ViewModel]()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(WatchListTableViewCell.self,
                       forCellReuseIdentifier: WatchListTableViewCell.identifier)
        return table
    }()
    
    private var observer: NSObjectProtocol?
    
    private var lastContentOffset: CGFloat = 0
    
    private let calendarManager = CalendarManager.shared
    
    private var dataFetchingTimer: Timer?
    
    private var searchTimer: Timer?
    private var prevSearchBarQuery = ""
    
    private let footerView = WatchlistFooterView()
    
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
        fetchWatchlistData()
        setUpFloatingPanel()
        setUpFooterView()
        setUpObserver()
    }
    
    // MARK: - Public
    
    func initiateDataFetchingTimer() {
        // Update the watchlist data before initiating the timer.
        updateWatchlistData()
        dataFetchingTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] _ in
            self?.updateWatchlistData()
        }
    }
    
    func invalidateDataFetchingTimer() {
        dataFetchingTimer?.invalidate()
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
    
    /// Fetch the quote and candle sticks data of all the stocks saved in the watchlist.
    /// - Parameter timeSpan: The time span of the candle stick data.
    private func fetchWatchlistData() {
        let symbols = PersistenceManager.shared.watchList
        let group = DispatchGroup()
        
        for symbol in symbols {
            group.enter()
            
            APICaller.shared.fetchStockData(
                symbol: symbol,
                timeSpan: .day) { [weak self] result in
                
                defer {
                    group.leave()
                }
                
                switch result {
                case .success(let stockData):
                    self?.watchListData[symbol] = stockData
                    self?.footerView.updateMarketStatusLabel()
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
            let lineChartData: [StockChartView.StockLineChartData] = stockData.priceHistory.map{
                .init(timeInterval: $0.time, price: $0.close)
            }
            let currentPrice = stockData.quote.current
            let previousClose = stockData.quote.prevClose
            let priceChange = (currentPrice / previousClose) - 1
            let priceChangePercentage = priceChange.signedPercentageString()
            
            let model = WatchListTableViewCell.ViewModel(
                symbol: symbol,
                companyName: UserDefaults.standard.string(forKey: symbol) ?? symbol,
                price: currentPrice.stringFormatted(by: .decimalFormatter),
                changeColor: priceChange < 0 ? .systemRed : .systemGreen,
                changePercentage: priceChangePercentage,
                chartViewModel: .init(
                    data: lineChartData,
                    previousClose: previousClose,
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
        tableView.frame = CGRect(x: 0, y: 0,
                                 width: view.width,
                                 height: view.height - 175)
    }
    
    private func setUpFloatingPanel() {
        let vc = NewsViewController()
        let panel = FloatingPanelController()
        panel.layout = MyFullScreenLayout()
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
    
    /// Update any data in the watchlist if its quote time is before the market closing time.
    private func updateWatchlistData() {
        let marketCloseTime = calendarManager.latestTradingTime.close.timeIntervalSince1970
        for (symbol, stockData) in watchListData {
            let quoteTime = stockData.quote.time
            if TimeInterval(quoteTime) < marketCloseTime {
                APICaller.shared.fetchStockData(symbol: symbol, timeSpan: .day) { [weak self] result in
                    switch result {
                    case .success(let stockData):
                        self?.watchListData[symbol] = stockData
                        self?.createViewModels()
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                        }
                        self?.footerView.updateMarketStatusLabel()
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
    }

}

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
        // Present stock details VC for the selected stock.
        navigationItem.searchController?.searchBar.resignFirstResponder()
        HapticsManager.shared.vibrateForSelection()
        
        let stockDetailVC = StockDetailsViewController(
            symbol: searchResult.displaySymbol,
            companyName: searchResult.description
        )
        stockDetailVC.title = searchResult.description
        
        let navVC = UINavigationController(rootViewController: stockDetailVC)
        present(navVC, animated: true, completion: nil)
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
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            
            let symbol = viewModels[indexPath.row].symbol
            watchListData[symbol] = nil
            PersistenceManager.shared.removeFromWatchlist(symbol: symbol)
            viewModels.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            tableView.endUpdates()
        }
    }
    
    /// This method is called if the user selects one of the tableView cells.
    /// - Parameters:
    ///   - tableView: TableView used to layout the cells containing each company's data.
    ///   - indexPath: IndexPath pointing to the selected tableView row.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        HapticsManager.shared.vibrateForSelection()
        
        // Show selected stock details
        let viewModel = viewModels[indexPath.row]
        let stockDetailsVC = StockDetailsViewController(
            symbol: viewModel.symbol,
            companyName: viewModel.companyName,
            priceHistory: watchListData[viewModel.symbol]?.priceHistory ?? []
        )
        let navVC = UINavigationController(rootViewController: stockDetailsVC)
        present(navVC, animated: true, completion: nil)
    }
    
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

extension WatchListViewController: WatchListTableViewCellDelegate {
    func didUpdateMaxWidth() {
        // Optimize: Only refresh rows prior to the current row that changes the max width.
        tableView.reloadData()
    }
}

class MyFullScreenLayout: FloatingPanelLayout {
    var position: FloatingPanelPosition {
        return .bottom
    }
    
    var initialState: FloatingPanelState {
        return .half
    }
    
    var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 150.0, edge: .top, referenceGuide: .superview),
            .half: FloatingPanelLayoutAnchor(fractionalInset: 0.45, edge: .bottom, referenceGuide: .superview),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: 175.0, edge: .bottom, referenceGuide: .superview),
        ]
        
    }
}
