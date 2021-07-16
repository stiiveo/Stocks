//
//  StockDetailHeaderView.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/15.
//

import UIKit
import Charts

class StockDetailHeaderView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private var metricViewModels = [MetricCollectionViewCell.ViewModel]()

    // ChartView
    private let chartView = StockChartView()
    
    // Metrics View
    private let metricsView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(
            MetricCollectionViewCell.self,
            forCellWithReuseIdentifier: MetricCollectionViewCell.identifier
        )
        collectionView.backgroundColor = .secondarySystemBackground
        
        return collectionView
    }()
    
    static let metricsViewHeight: CGFloat = 100
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        addSubviews(chartView, metricsView)
        metricsView.delegate = self
        metricsView.dataSource = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let metricsViewHeight = StockDetailHeaderView.metricsViewHeight
        chartView.frame = CGRect(x: 0, y: 0, width: width, height: height - metricsViewHeight)
        metricsView.frame = CGRect(
            x: 0,
            y: height - metricsViewHeight,
            width: width,
            height: metricsViewHeight
        )
    }
    
    // MARK: - Public
    
    func configure(
        chartViewModel: StockChartView.ViewModel,
        metricViewModels: [MetricCollectionViewCell.ViewModel]
    ) {
        // Update chart view
        chartView.configure(with: chartViewModel)
        self.metricViewModels = metricViewModels
        metricsView.reloadData()
    }
    
    // MARK: - CollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return metricViewModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let viewModel = metricViewModels[indexPath.item]
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MetricCollectionViewCell.identifier,
            for: indexPath
        ) as? MetricCollectionViewCell else {
            fatalError()
        }
        cell.configure(with: viewModel)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(
            width: width / 2,
            height: StockDetailHeaderView.metricsViewHeight / 3)
    }
    
}
