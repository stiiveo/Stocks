//
//  NewsViewController.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import UIKit
import SafariServices

/// Controller used to present market news.
class NewsViewController: UIViewController {
    
    // MARK: - Properties
    
    private var stories = [NewsStory]()
    
    let tableView: UITableView = {
        let table = UITableView()
        table.register(NewsHeaderView.self, forHeaderFooterViewReuseIdentifier: NewsHeaderView.identifier)
        table.register(NewsStoryTableViewCell.self, forCellReuseIdentifier: NewsStoryTableViewCell.identifier)
        table.backgroundColor = .clear
        return table
    }()
    
    private var headerView: NewsHeaderView!
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        configureTableView()
        fetchNews()
        observeNetworkStatus()
    }
    
    private func observeNetworkStatus() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(displayNormalHeaderView),
            name: .networkIsAvailable,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(displayNoInternetMessage),
            name: .networkIsUnavailable,
            object: nil
        )
    }
    
    // MARK: - UI Configuration
    
    private func configureTableView() {
        tableView.frame = view.bounds
        tableView.delegate = self
        tableView.dataSource = self
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = .zero
        }
        headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: NewsHeaderView.identifier) as? NewsHeaderView
    }
    
    @objc private func fetchNews() {
        DispatchQueue.global(qos: .userInteractive).async {
            APICaller().fetchNews(type: .topStories) { [weak self] result in
                switch result {
                case .success(let stories):
                    self?.stories = stories
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                case .failure(let error):
                    switch error {
                    case let networkError as NetworkError:
                        if networkError == .noConnection {
                            self?.displayNoInternetMessage()
                        }
                    case let apiError as APIError:
                        print("API error occurred:", apiError)
                    default:
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    @objc private func displayNoInternetMessage() {
        headerView.status = .noInternetConnection
    }
    
    @objc private func displayNormalHeaderView() {
        headerView.status = .normal
        fetchNews()
    }

}

// MARK: - TableView Data Source, Delegate

extension NewsViewController: UITableViewDelegate, UITableViewDataSource {
    
    // Header View Settings
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        headerView.configure(with: .init(title: "Top Stories"))
        return headerView
    }
    
    // Cells Settings
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
                withIdentifier: NewsStoryTableViewCell.identifier,
                for: indexPath)
                as? NewsStoryTableViewCell else {
            fatalError()
        }
        cell.reset()
        cell.configure(with: .init(news: stories[indexPath.row]))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Open news story
        let story = stories[indexPath.row]
        guard let url = URL(string: story.url) else {
            HapticsManager().vibrate(for: .error)
            showAlert(
                withTitle: "Unable to Open",
                message: "Something went wrong and the article could not be opened.",
                actionTitle: "Dismiss"
            )
            return
        }
        open(url: url, withPresentationStyle: .overFullScreen)
    }
    
}
