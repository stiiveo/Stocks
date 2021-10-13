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
    let viewModel = WatchlistViewControllerViewModel.shared
    
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
        viewModel.delegate = self
        view.backgroundColor = .systemBackground
        configureNavigationBar()
        configureSearchController()
        configureTableView()
        configureFloatingPanel()
        configureFooterView()
        
        if !persistenceManager.isOnboarded {
            persistenceManager.isOnboarded = true
        }
        
        observeNotifications()
        viewModel.updateQuoteData()
        viewModel.updateChartData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Edit Button Actions
    
    @objc private func editButtonDidTap() {
        if !tableView.isEditing {
            // Enter editing mode.
            viewModel.invalidateDataUpdater()
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
            viewModel.initiateDataUpdater()
        }
        
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
        
        // Notify all table view cells the table view's editing status.
        NotificationCenter.default.post(name: .didChangeEditingMode, object: tableView.isEditing)
    }
    
    // MARK: - UI Setting
    
    private func configureTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        tableView.snp.makeConstraints { make in
            make.top.left.right.equalTo(view)
            make.bottom.equalTo(view.bottom).offset(-175.0)
        }
    }
    
    private func configureFloatingPanel() {
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
    
    private func configureNavigationBar() {
        navigationController?.navigationBar.isTranslucent = false
        extendedLayoutIncludesOpaqueBars = true
        configureTitleView()
        
        // Add system edit bar button to the NavBar.
        let buttonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editButtonDidTap))
        navigationItem.rightBarButtonItem = buttonItem
    }
    
    private func configureTitleView() {
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 400, height: 30)
        
        let label = UILabel(frame: CGRect(x: 10, y: 0, width: 200, height: 30))
        label.text = "U.S. Stocks"
        label.font = .systemFont(ofSize: 26, weight: .heavy)
        titleView.addSubview(label)
        
        navigationItem.titleView = titleView
    }

    private func configureSearchController() {
        let resultVC = SearchResultViewController()
        resultVC.delegate = self
        let searchVC = UISearchController(searchResultsController: resultVC)
        searchVC.searchResultsUpdater = self
        searchVC.delegate = self
        navigationItem.searchController = searchVC
    }
    
    private func configureFooterView() {
        view.addSubviews(footerView)
        footerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(86)
        }
    }
    
    // MARK: - Notification Center Operations
    
    private func observeNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onApiLimitReached),
            name: .apiLimitReached,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onDidDismissStockDetailsVC),
            name: .didDismissStockDetailsViewController,
            object: nil
        )
    }
    
    @objc private func onApiLimitReached() {
        // Present alert to the user.
        DispatchQueue.main.async { [unowned self] in
            guard presentedViewController == nil else { return }
            presentApiAlert(type: .apiLimitReached)
        }
    }
    
    @objc private func onDidDismissStockDetailsVC() {
        if let searchController = navigationItem.searchController,
           !searchController.isActive {
            viewModel.initiateDataUpdater()
        }
    }

}

// MARK: - View Model Delegate

extension WatchListViewController: WatchlistViewControllerViewModelDelegate {
    func didUpdateViewModel(at index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        DispatchQueue.main.async { [unowned self] in
            if let cell = tableView.cellForRow(at: indexPath) as? WatchListTableViewCell {
                cell.configure(with: viewModel.stocksData[index],
                               showChartAxis: false,
                               isEditing: tableView.isEditing)
            }
        }
    }
    
    func didAddViewModel(at index: Int) {
        DispatchQueue.main.async { [unowned self] in
            tableView.insertRows(
                at: [IndexPath(row: index, section: 0)],
                with: .automatic
            )
        }
    }
}

// MARK: - Search Controller Delegate

extension WatchListViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        viewModel.invalidateDataUpdater()
        isSearchControllerPresented = true
    }
    func willDismissSearchController(_ searchController: UISearchController) {
        viewModel.initiateDataUpdater()
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
            if let cachedData = viewModel.stocksData.first(where: { $0.symbol == symbol }) {
                stockData = cachedData
                isDataCached = true
            }
            let vc = StockDetailsViewController(viewModel: .init(
                stockData: stockData,
                companyName: searchResult.description.localizedCapitalized,
                lastQuoteDataUpdatedTime: isDataCached ? viewModel.lastQuoteDataUpdatedTime : 0,
                lastChartDataUpdatedTime: isDataCached ? viewModel.lastChartDataUpdatedTime : 0)
            )
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
        return viewModel.stocksData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: WatchListTableViewCell.identifier,
            for: indexPath
        ) as? WatchListTableViewCell else {
            fatalError()
        }
        cell.configure(with: viewModel.stocksData[indexPath.row],
                       showChartAxis: false,
                       isEditing: tableView.isEditing)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        viewModel.stocksData.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.performBatchUpdates {
                let index = indexPath.row
                let symbol = viewModel.stocksData[index].symbol
                viewModel.stocksData.remove(at: index)
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
        viewModel.invalidateDataUpdater()
        tableView.deselectRow(at: indexPath, animated: true)
        HapticsManager().vibrateForSelection()
        
        // Present stock details view controller initialized with cached stock data.
        let data = viewModel.stocksData[indexPath.row]
        let vc = StockDetailsViewController(viewModel: .init(
            stockData: data,
            companyName: data.companyName,
            lastQuoteDataUpdatedTime: viewModel.lastQuoteDataUpdatedTime,
            lastChartDataUpdatedTime: viewModel.lastChartDataUpdatedTime)
        )
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true, completion: nil)
    }
    
    // MARK: - ScrollView Delegate Methods
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset.y
        
        // Deactivate search controller if it's active.
        if let searchController = navigationItem.searchController {
            if searchController.isActive {
                searchController.isActive = false
            }
        }
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
