//
//  StockDetailsViewController.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import UIKit
import SafariServices
import SnapKit

class StockDetailsViewController: UIViewController {

    private let viewModel: StockDetailsViewControllerViewModel
    
    // UI Properties
    private lazy var headerView = StockDetailHeaderView()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(NewsHeaderView.self,
                       forHeaderFooterViewReuseIdentifier: NewsHeaderView.identifier)
        table.register(NewsStoryTableViewCell.self,
                       forCellReuseIdentifier: NewsStoryTableViewCell.identifier)
        return table
    }()
    
    private let newsLoadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.isHidden = true
        
        let titleAttributes: [NSAttributedString.Key : Any] = [.font: UIFont.preferredFont(forTextStyle: .headline)]
        let message = NSMutableAttributedString(
            string: "News Feed is Unavailable\n",
            attributes: titleAttributes
        )
        let detailsAttributes: [NSAttributedString.Key : Any] = [.font: UIFont.preferredFont(forTextStyle: .subheadline)]
        let details = NSAttributedString(
            string: "U.S. Stocks is not connected to Internet.",
            attributes: detailsAttributes
        )
        message.append(details)
        label.attributedText = message
        
        return label
    }()
    
    // Init
    init(viewModel: StockDetailsViewControllerViewModel.ViewModel) {
        self.viewModel = .init(viewModel: viewModel)
        super.init(nibName: nil, bundle: nil)
        observeNetworkCondition()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func observeNetworkCondition() {
        NotificationCenter.default.addObserver(self, selector: #selector(onNetworkIsUnavailable), name: .networkIsUnavailable, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onNetworkIsAvailable), name: .networkIsAvailable, object: nil)
        
        if NetworkMonitor.status == .notAvailable {
            onNetworkIsUnavailable()
        }
    }
    
    @objc private func onNetworkIsAvailable() {
        DispatchQueue.main.async { [weak self] in
            self?.messageLabel.isHidden = true
        }
    }
    
    @objc private func onNetworkIsUnavailable() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.newsLoadingIndicator.stopAnimating()
            if self.viewModel.newsStories.isEmpty {
                self.messageLabel.isHidden = false
            }
        }
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        
        self.title = viewModel.companyName
        view.backgroundColor = .systemBackground
        configureCloseButton()
        configureHeaderView()
        configureTableView()
        configureNewsLoadingIndicator()
        configureMessageLabel()
        
        viewModel.updateOutdatedData()
        viewModel.initiateDataUpdating()
        
        observeNotifications()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.stopDataUpdating()
        NotificationCenter.default.post(name: .didDismissStockDetailsViewController, object: nil)
    }
    
    private func refreshHeaderView() {
        headerView.configure(stockData: viewModel.stockData,
                             metricsData: viewModel.metricsData)
    }
    
    // MARK: - UI Setting
    
    private func configureCloseButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(didTapCloseButton)
        )
    }
    
    private func configureTableView() {
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func configureHeaderView() {
        headerView.frame = CGRect(x: 0, y: 0, width: view.width, height: view.width)
        tableView.tableHeaderView = headerView
        DispatchQueue.main.async {
            self.refreshHeaderView()
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(addStockToWatchlist),
            name: .didTapAddToWatchlist,
            object: nil
        )
    }
    
    private func configureNewsLoadingIndicator() {
        view.addSubview(newsLoadingIndicator)
        newsLoadingIndicator.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(20.0)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20.0)
            make.leading.equalTo(view.safeAreaLayoutGuide.snp.leading).offset(20.0)
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).offset(-20.0)
        }
    }
    
    private func configureMessageLabel() {
        view.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(20.0)
            make.leading.equalTo(view.safeAreaLayoutGuide.snp.leading).offset(20.0)
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).offset(-20.0)
            make.height.equalTo(120.0)
        }
    }
    
    // MARK: - Selector Operations
    
    private func observeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(presentApiLimitAlert), name: .apiLimitReached, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(presentApiNoAccessAlert), name: .dataAccessDenied, object: nil)
    }
    
    @objc private func addStockToWatchlist() {
        HapticsManager().vibrate(for: .success)
        PersistenceManager.shared.watchlist[viewModel.symbol] = viewModel.companyName
        let dataDict = ["data": viewModel.stockData]
        NotificationCenter.default.post(
            name: .didAddNewStockData,
            object: nil,
            userInfo: dataDict
        )
        showAlert(withTitle: "Added to Watchlist", message: "", actionTitle: "OK")
    }
    
    @objc private func didTapCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func presentApiLimitAlert() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  self.presentedViewController == nil else { return }
            self.presentApiAlert(type: .apiLimitReached)
        }
    }
    
    @objc private func presentApiNoAccessAlert() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  self.presentedViewController == nil else { return }
            self.presentApiAlert(type: .noAccessToData)
        }
    }
    
}

// MARK: - TableView Data Source & Delegate

extension StockDetailsViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.newsStories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: NewsStoryTableViewCell.identifier,
            for: indexPath
        ) as? NewsStoryTableViewCell else {
            fatalError()
        }
        cell.reset()
        cell.configure(with: .init(news: viewModel.newsStories[indexPath.row]))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let url = URL(string: viewModel.newsStories[indexPath.row].url) else { return }
        HapticsManager().vibrateForSelection()
        open(url: url, withPresentationStyle: .overFullScreen)
    }
}

// MARK: - View Model Delegate Methods

extension StockDetailsViewController: StockDetailsViewControllerViewModelDelegate {
    func didUpdateStockData(_ stockDetailsViewControllerViewModel: StockDetailsViewControllerViewModel) {
        DispatchQueue.main.async { [weak self] in
            self?.refreshHeaderView()
        }
    }
    
    func didUpdateNewsData(_ stockDetailsViewControllerViewModel: StockDetailsViewControllerViewModel) {
        DispatchQueue.main.async { [weak self] in
            self?.newsLoadingIndicator.stopAnimating()
            self?.tableView.reloadData()
        }
    }
    
    func newsDataWillBeUpdated(_ stockDetailsViewControllerViewModel: StockDetailsViewControllerViewModel) {
        if NetworkMonitor.status == .available {
            DispatchQueue.main.async { [weak self] in
                self?.newsLoadingIndicator.startAnimating()
            }
        }
    }
}
