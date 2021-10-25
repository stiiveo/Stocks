//
//  NewsViewController.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import UIKit
import SafariServices

/// Controller used to present top and company news.
class NewsViewController: UIViewController {
    
    // MARK: - Properties
    
    private var stories = [NewsStory]()
    
    let tableView: UITableView = {
        let table = UITableView()
        // Register cell, header
        table.register(NewsHeaderView.self, forHeaderFooterViewReuseIdentifier: NewsHeaderView.identifier)
        table.register(NewsStoryTableViewCell.self, forCellReuseIdentifier: NewsStoryTableViewCell.identifier)
        table.backgroundColor = .clear
        return table
    }()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTable()
        fetchNews()
    }
    
    // MARK: - Private Functions
    
    private func setUpTable() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0.0
        }
    }
    
    private func fetchNews() {
        DispatchQueue.global(qos: .userInteractive).async {
            APICaller().fetchNews(type: .topStories) { [weak self] result in
                switch result {
                case .success(let stories):
                    self?.stories = stories
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }

}

// MARK: - TableView Data Source, Delegate

extension NewsViewController: UITableViewDelegate, UITableViewDataSource {
    
    // Header View Settings
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: NewsHeaderView.identifier) as? NewsHeaderView else {
            return nil
        }
        header.reset()
        header.configure(with: .init(title: "Top Stories")
        )
        return header
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
