//
//  WatchListViewController.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import UIKit

class WatchListViewController: UIViewController {

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setUpSearchController()
        setUpTitleView()
    }
    
    // MARK: - Private
    
    private func setUpTitleView() {
        let titleView = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: view.width,
                height: navigationController?.navigationBar.height ?? 100
            )
        )
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: titleView.width - 20, height: titleView.height))
        label.text = "Stocks"
        label.font = .systemFont(ofSize: 40, weight: .medium)
        titleView.addSubview(label)
        
        navigationItem.titleView = titleView
    }

    private func setUpSearchController() {
        let resultVC = SearchResultViewController()
        resultVC.delegate = self
        let searchVC = UISearchController(searchResultsController: resultVC)
        searchVC.searchResultsUpdater = self
        navigationItem.searchController = searchVC
    }

}

extension WatchListViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text,
              let resultVC = searchController.searchResultsController as? SearchResultViewController,
              !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        // Optimize to reduce number of searches for when user stops typing
        
        // Call API to search
        
        // Update result controller
        resultVC.update(with: ["AAPL, AWLL, AWE, ASME"])
    }
    
}

extension WatchListViewController: SearchResultViewControllerDelegate {
    func searchResultViewControllerDidSelect(searchResult: String) {
        // Present stock details for given selection
        print(searchResult)
    }
}
