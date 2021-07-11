//
//  WatchListViewController.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import UIKit
import FloatingPanel

class WatchListViewController: UIViewController {
    
    private var searchTimer: Timer?
    
    private var panel: FloatingPanelController?

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setUpSearchController()
        setUpTitleView()
        setUpFloatingPanel()
    }
    
    // MARK: - Private
    
    private func setUpFloatingPanel() {
        let vc = NewsViewController(type: .topStories)
        let panel = FloatingPanelController()
        panel.surfaceView.backgroundColor = .secondarySystemBackground
        panel.set(contentViewController: vc)
        panel.addPanel(toParent: self)
        panel.delegate = self
        panel.track(scrollView: vc.tableView)
    }
    
    private func setUpTitleView() {
        let titleView = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: view.width,
                height: navigationController?.navigationBar.height ?? 100
            )
        )
        let label = UILabel(frame: CGRect(x: 10, y: 10, width: titleView.width - 20, height: titleView.height - 15))
        label.text = "Stocks"
        label.font = .systemFont(ofSize: 36, weight: .bold)
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
        
        // Reset timer
        searchTimer?.invalidate()
        
        // Kick off new timer
        // Optimize to reduce number of searches for when user stops typing
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { _ in
            // Call API to search
            APICaller.shared.search(query: query) { result in
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        resultVC.update(with: response.result)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        resultVC.update(with: [])
                    }
                    print(error)
                }
            }
        })
    }
    
}

extension WatchListViewController: SearchResultViewControllerDelegate {
    func searchResultViewControllerDidSelect(searchResult: SearchResult) {
        // Present stock details for given selection
        navigationItem.searchController?.searchBar.resignFirstResponder()
        
        let stockDetailVC = StockDetailViewController()
        stockDetailVC.title = searchResult.description
        
        let navVC = UINavigationController(rootViewController: stockDetailVC)
        present(navVC, animated: true, completion: nil)
    }
}

extension WatchListViewController: FloatingPanelControllerDelegate {
    func floatingPanelDidChangeState(_ fpc: FloatingPanelController) {
        navigationItem.titleView?.isHidden = fpc.state == .full
    }
}
