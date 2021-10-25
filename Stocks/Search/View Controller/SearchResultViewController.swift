//
//  SearchResultViewController.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import UIKit

protocol SearchResultViewControllerDelegate: AnyObject {
    func didSelectSearchResult(_ searchResult: SearchResult)
    func searchResultScrollViewWillBeginDragging(scrollView: UIScrollView)
}

class SearchResultViewController: UIViewController {
    
    weak var delegate: SearchResultViewControllerDelegate?
    
    // MARK: - Properties
    
    private var results: [SearchResult] = []
    
    private let tableView: UITableView = {
        let table = UITableView()
        // Register a cell
        table.register(SearchResultTableViewCell.self,
                       forCellReuseIdentifier: SearchResultTableViewCell.identifier)
        table.isHidden = true
        return table
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.isHidden = true
        return label
    }()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureTable()
        configureMessageLabel()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        results.removeAll()
        tableView.reloadData()
    }
    
    // MARK: - Private Methods
    
    private func configureTable() {
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func configureMessageLabel() {
        view.addSubview(messageLabel)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 130),
            messageLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Public Methods
    
    public func update(with results: [SearchResult], from query: String) {
        self.results = results
        tableView.reloadData()
        if !results.isEmpty {
            // Scroll to the first row after data is reloaded.
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            messageLabel.isHidden = true
        } else {
            // Display the hint text unless the query is empty.
            messageLabel.text = query.isEmpty ? "" : #"No Result for "\#(query)""#
            messageLabel.isHidden = query.isEmpty ? true : false
        }
        tableView.isHidden = results.isEmpty
    }
    
    public func displayNoInternetMessage() {
        // Clear tableView if there's any result
        results.removeAll()
        tableView.reloadData()
        
        let titleAttributes: [NSAttributedString.Key : Any] = [.font: UIFont.preferredFont(forTextStyle: .headline)]
        let message = NSMutableAttributedString(string: "Unable to search\n", attributes: titleAttributes)
        
        let detailsAttributes: [NSAttributedString.Key : Any] = [.font: UIFont.preferredFont(forTextStyle: .subheadline)]
        let details = NSAttributedString(string: "U.S. Stocks is not connected to Internet. Please restore the connection to search.", attributes: detailsAttributes)
        
        message.append(details)
        messageLabel.attributedText = message
        messageLabel.isHidden = false
    }

}

// MARK: - TableView Delegate, Data Source

extension SearchResultViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultTableViewCell.identifier, for: indexPath)
        let result = results[indexPath.row]
        
        cell.textLabel?.text = result.symbol
        cell.detailTextLabel?.text = result.description
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.didSelectSearchResult(results[indexPath.row])
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.searchResultScrollViewWillBeginDragging(scrollView: scrollView)
    }
    
}
