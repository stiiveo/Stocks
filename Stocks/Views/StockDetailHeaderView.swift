//
//  StockDetailHeaderView.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/15.
//

import UIKit
import Charts

class StockDetailHeaderView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Properties
    
    private let titleView: StockDetailHeaderTitleView = {
        return StockDetailHeaderTitleView()
    }()

    private let chartView: StockChartView = {
        let chart = StockChartView()
        chart.isUserInteractionEnabled = false
        return chart
    }()
    
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
        collectionView.backgroundColor = .systemBackground
        
        return collectionView
    }()
    
    private var metricViewModels = [MetricCollectionViewCell.ViewModel]()
    
    static let titleViewHeight: CGFloat = 25
    static let metricsViewHeight: CGFloat = 70
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        addSubviews(titleView, chartView, metricsView)
        metricsView.delegate = self
        metricsView.dataSource = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let sideInset: CGFloat = 15
        
        titleView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            titleView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: sideInset * -1),
            titleView.topAnchor.constraint(equalTo: self.topAnchor, constant: 15),
            titleView.heightAnchor.constraint(equalToConstant: StockDetailHeaderView.titleViewHeight)
        ])
        
        chartView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chartView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            chartView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15),
            chartView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 10)
        ])
        
        metricsView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            metricsView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: sideInset),
            metricsView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: sideInset * -1),
            metricsView.topAnchor.constraint(equalTo: chartView.bottomAnchor),
            metricsView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -15),
            metricsView.heightAnchor.constraint(equalToConstant: StockDetailHeaderView.metricsViewHeight)
        ])
    }
    
    // MARK: - Public
    
    func configure(
        titleViewModel: StockDetailHeaderTitleView.ViewModel,
        chartViewModel: StockChartView.ViewModel,
        metricViewModels: [MetricCollectionViewCell.ViewModel]
    ) {
        titleView.configure(viewModel: titleViewModel)
        chartView.configure(with: chartViewModel)
        self.metricViewModels = metricViewModels
        metricsView.reloadData()
    }
    
    // MARK: - Metrics Collection View
    
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
        return CGSize(width: width / 2,
                      height: StockDetailHeaderView.metricsViewHeight / 3)
    }
    
}
