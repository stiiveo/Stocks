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
    private var candleStickData: [CandleStick]

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
        candleStickData: [CandleStick] = []
    ) {
        self.symbol = symbol
        self.companyName = companyName
        self.candleStickData = candleStickData
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setUpTable()
        fetchFinancialData()
        fetchNews()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        title = companyName
    }

    // MARK: - Private

    private func setUpTable() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
    }

    private func fetchFinancialData() {
        // financial data
        // candle sticks data

        renderChart()
    }

    private func fetchNews() {
        APICaller.shared.news(for: .company(symbol: symbol)) { [weak self] result in
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

    private func renderChart() {

    }
    
    private func open(url: URL) {
        
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
        cell.configure(with: .init(model: stories[indexPath.row]))
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return NewsStoryTableViewCell.preferredHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: NewsHeaderView.identifier
        ) as? NewsHeaderView else {
            return nil
        }
        headerView.delegate = self
        headerView.configure(
            with: .init(
                title: symbol.uppercased(),
                shouldShowAddButton: !PersistenceManager.shared.watchListContains(symbol))
        )
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return NewsHeaderView.preferredHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let url = URL(string: stories[indexPath.row].url) else { return }
        let vc = SFSafariViewController(url: url)
        vc.modalPresentationStyle = .overFullScreen
        present(vc, animated: true, completion: nil)
    }
}

extension StockDetailsViewController: NewsHeaderViewDelegate {
    func newsHeaderViewDidTapAddButton(_ headerView: NewsHeaderView) {
        headerView.button.isHidden = true
        PersistenceManager.shared.addToWatchlist(
            symbol: symbol,
            companyName: companyName
        )
        showAlert(withTitle: "Added to Watch List", message: "", actionTitle: "OK")
    }
}
