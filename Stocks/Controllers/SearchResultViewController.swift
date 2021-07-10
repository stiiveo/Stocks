//
//  SearchResultViewController.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import UIKit

protocol SearchResultViewControllerDelegate: AnyObject {
    func searchResultViewControllerDidSelect(searchResult: String)
}

class SearchResultViewController: UIViewController {
    
    weak var delegate: SearchResultViewControllerDelegate?
    
    private var results: [String] = []
    
    private let tableView: UITableView = {
        let table = UITableView()
        // Register a cell
        table.register(SearchResultTableViewCell.self,
                       forCellReuseIdentifier: SearchResultTableViewCell.identifier)
        return table
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setUpTable()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    private func setUpTable() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    public func update(with results: [String]) {
        self.results = results
        tableView.reloadData()
    }

}

extension SearchResultViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultTableViewCell.identifier, for: indexPath)
        
        cell.textLabel?.text = "AAPL"
        cell.detailTextLabel?.text = "Apple Inc."
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.searchResultViewControllerDidSelect(searchResult: "AAPL")
    }
}
