//
//  SearchResultViewController.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import UIKit

protocol SearchResultViewControllerDelegate: AnyObject {
    func searchResultViewControllerDidSelect(searchResult: SearchResult)
    func searchResultScrollViewWillBeginDragging()
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
    
    private let noResultHint: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.textColor = .secondaryLabel
        label.isHidden = true
        return label
    }()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setUpTable()
        setUpNoResultHint()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        results.removeAll()
        tableView.reloadData()
    }
    
    // MARK: - Private Methods
    
    private func setUpTable() {
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setUpNoResultHint() {
        view.addSubview(noResultHint)
        noResultHint.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noResultHint.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            noResultHint.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 130),
        ])
    }
    
    // MARK: - Public Methods
    
    public func update(_ results: [SearchResult], from query: String) {
        self.results = results
        tableView.reloadData()
        if !results.isEmpty {
            // Scroll to the first row after data is reloaded.
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            noResultHint.isHidden = true
        } else {
            // Display the hint text unless the query is empty.
            noResultHint.text = query.isEmpty ? "" : #"No Result for "\#(query)""#
            noResultHint.isHidden = query.isEmpty ? true : false
        }
        tableView.isHidden = results.isEmpty
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
        let result = results[indexPath.row]
        delegate?.searchResultViewControllerDidSelect(searchResult: result)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.searchResultScrollViewWillBeginDragging()
    }
    
}
