//
//  StockMetricsView.swift
//  Stocks
//
//  Created by Jason Ou on 2021/9/3.
//

import UIKit

class StockMetricsView: UICollectionView {
    
    // MARK: - Properties
    
    private var cellsViewModels = [MetricCollectionViewCell.ViewModel]()
    
    struct ViewModel {
        let openPrice: Double?
        let highestPrice: Double?
        let lowestPrice: Double?
        let marketCap: Double?
        let priceEarningsRatio: Double?
        let priceSalesRatio: Double?
        let annualHigh: Double?
        let annualLow: Double?
        let previousPrice: Double?
        let yield: Double?
        let beta: Double?
        let eps: Double?
    }
    
    // MARK: - Init

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        let customLayout = UICollectionViewFlowLayout()
        customLayout.scrollDirection = .horizontal
        customLayout.minimumInteritemSpacing = 0
        customLayout.minimumLineSpacing = 20
        super.init(frame: frame, collectionViewLayout: customLayout)
        
        self.showsHorizontalScrollIndicator = false
        register(
            MetricCollectionViewCell.self,
            forCellWithReuseIdentifier: MetricCollectionViewCell.identifier
        )
        backgroundColor = .systemBackground
        delegate = self
        dataSource = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public
    
    func configure(viewModel: ViewModel) {
        self.cellsViewModels = cellsViewModels(from: viewModel)
        DispatchQueue.main.async { [weak self] in
            self?.reloadData()
        }
    }
    
    func resetData() {
        self.cellsViewModels.removeAll()
    }
    
    // MARK: - Private
    
    private func cellsViewModels(from modelData: ViewModel) -> [MetricCollectionViewCell.ViewModel] {
        let noDataExpression = "–"
        let cellsViewModels: [MetricCollectionViewCell.ViewModel] = [
            .init(name: "Open",
                  value: modelData.openPrice?.stringFormatted(by: .decimalFormatter) ?? noDataExpression),
            
            .init(name: "High",
                  value: modelData.highestPrice?.stringFormatted(by: .decimalFormatter) ?? noDataExpression),
            
            .init(name: "Low",
                  value: modelData.lowestPrice?.stringFormatted(by: .decimalFormatter) ?? noDataExpression),
            
            .init(name: "Mkt Cap",
                  value: modelData.marketCap != nil ? (modelData.marketCap! * pow(10, 6)).shortScaleText() : noDataExpression),
            
            .init(name: "P/E",
                  value: modelData.priceEarningsRatio?.stringFormatted(by: .decimalFormatter) ?? noDataExpression),
            
            .init(name: "P/S",
                  value: modelData.priceSalesRatio?.stringFormatted(by: .decimalFormatter) ?? noDataExpression),
            
            .init(name: "52W H",
                  value: modelData.annualHigh?.stringFormatted(by: .decimalFormatter) ?? noDataExpression),
            
            .init(name: "52W L",
                  value: modelData.annualLow?.stringFormatted(by: .decimalFormatter) ?? noDataExpression),
            
            .init(name: "Prev",
                  value: modelData.previousPrice?.stringFormatted(by: .decimalFormatter) ?? noDataExpression),
            
            .init(name: "Yield",
                  value: modelData.yield?.stringFormatted(by: .decimalFormatter).appending("%") ?? noDataExpression),
            
            .init(name: "Beta",
                  value: modelData.beta?.stringFormatted(by: .decimalFormatter) ?? noDataExpression),
            
            .init(name: "EPS",
                  value: modelData.eps?.stringFormatted(by: .decimalFormatter) ?? noDataExpression),
        ]
        
        return cellsViewModels
    }
    
}

// MARK: - Layout, Data Source & Delegate

extension StockMetricsView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cellsViewModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MetricCollectionViewCell.identifier,
            for: indexPath
        ) as? MetricCollectionViewCell else {
            fatalError()
        }
        cell.reset()
        let viewModel = cellsViewModels[indexPath.item]
        cell.configure(with: viewModel)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 130.0,
                      height: StockDetailHeaderView.metricsViewHeight / 3)
    }
    
}
