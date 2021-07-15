//
//  StockChartView.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/13.
//

import UIKit

class StockChartView: UIView {
    
    struct ViewModel {
        let data: [Double]
        let showLegend: Bool
        let showAxis: Bool
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    // Reset chart view
    func reset() {
        
    }
    
    func configure(with viewModel: ViewModel) {
        
    }

}
