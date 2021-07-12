//
//  NewsViewController.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import UIKit

/// Controller to show news.
class NewsViewController: UIViewController {
    
    /// Type of news.
    enum `Type` {
        case topStories
        case company(symbol: String)
        
        var title: String {
            switch self {
            case .topStories:
                return "Top Stories"
            case .company(let symbol):
                return symbol.uppercased()
            }
        }
    }
    
    // MARK: - Properties
    
    private var stories: [NewsStory] = [
        NewsStory(category: "top news", datetime: 1625403601, headline: "Here's how much Americans are spending on food, alcohol and fireworks this Fourth of July", id: 6759941, image: "https://image.cnbcfm.com/api/v1/image/106905981-1625224556626-park-cooking-women-summer-picnic-outside-friends-grill-grilling_t20_dzEZk9.jpg?v=1625224698", related: "", source: "CNBC", summary: "Personal finance website WalletHub looked at how much Americans are planning to spend on celebrations this year. Here's where their money is going.", url: "https://www.cnbc.com/2021/07/04/how-much-americans-are-spending-on-fourth-of-july.html")
    ]
    
    private let type: Type
    
    let tableView: UITableView = {
        let table = UITableView()
        // Register cell, header
        table.register(NewsHeaderView.self, forHeaderFooterViewReuseIdentifier: NewsHeaderView.identifier)
        table.register(NewsStoryTableViewCell.self, forCellReuseIdentifier: NewsStoryTableViewCell.identifier)
        table.backgroundColor = .clear
        return table
    }()
    
    // MARK: - Initializers
    
    init(type: Type) {
        self.type = type
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTable()
        fetchNews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    // MARK: - Private Functions
    
    private func setUpTable() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func fetchNews() {
        
    }
    
    private func open(url: URL) {
        
    }

}

extension NewsViewController: UITableViewDelegate, UITableViewDataSource {
    
    // Header View Settings
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: NewsHeaderView.identifier) as? NewsHeaderView else {
            return nil
        }
        header.configure(with: .init(
                            title: self.type.title,
                            shouldShowAddButton: false)
        )
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return NewsHeaderView.preferredHeight
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
        cell.configure(with: .init(model: stories[indexPath.row]))
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return NewsStoryTableViewCell.preferredHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Open news story
    }
    
}
