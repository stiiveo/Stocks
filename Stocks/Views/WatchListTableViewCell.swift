//
//  WatchListTableViewCell.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/13.
//

import UIKit

protocol WatchListTableViewCellDelegate: AnyObject {
    func didUpdateMaxWidth()
}

class WatchListTableViewCell: UITableViewCell {

    static let identifier = "WatchListTableViewCell"
    static let preferredHeight: CGFloat = 70
    weak var delegate: WatchListTableViewCellDelegate?
    
    struct ViewModel {
        let symbol: String
        let companyName: String
        let price: String // formatted
        let changeColor: UIColor // red or green
        let changePercentage: String // formatted
        let chartViewModel: StockChartView.ViewModel
    }
    
    private let symbolLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .gray
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .right
        return label
    }()
    
    private let priceChangeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .right
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        return label
    }()
    
    private let miniChartView: StockChartView = {
        let chart = StockChartView()
        chart.clipsToBounds = true
        chart.isUserInteractionEnabled = false
        return chart
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.clipsToBounds = true
        addSubviews(symbolLabel, nameLabel, priceLabel, priceChangeLabel, miniChartView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        symbolLabel.sizeToFit()
        nameLabel.sizeToFit()
        priceLabel.sizeToFit()
        priceChangeLabel.sizeToFit()
        
        let yStart: CGFloat = (contentView.height - symbolLabel.height - nameLabel.height) / 2
        
        symbolLabel.frame = CGRect(
            x: separatorInset.left,
            y: yStart,
            width: symbolLabel.width,
            height: symbolLabel.height
        )
        
        nameLabel.frame = CGRect(
            x: separatorInset.left,
            y: symbolLabel.bottom,
            width: nameLabel.width,
            height: nameLabel.height
        )
        
        let priceLabelWidth = max(
            priceLabel.width + 5,
            WatchListViewController.maxPriceLabelWidth
        )
        
        if priceLabelWidth > WatchListViewController.maxPriceLabelWidth {
            WatchListViewController.maxPriceLabelWidth = priceLabelWidth
            delegate?.didUpdateMaxWidth()
        }
        
        priceLabel.frame = CGRect(
            x: contentView.width - priceLabelWidth - 15,
            y: (contentView.height - priceLabel.height - priceChangeLabel.height) / 2,
            width: priceLabelWidth,
            height: priceLabel.height
        )
        
        priceChangeLabel.frame = CGRect(
            x: contentView.width - priceLabelWidth - 15,
            y: priceLabel.bottom + 2,
            width: priceLabelWidth,
            height: priceChangeLabel.height + 6
        )
        
        miniChartView.frame = CGRect(
            x: priceLabel.left - miniChartView.width - 10,
            y: 6 ,
            width: contentView.width / 4,
            height: contentView.height - 12
        )
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        symbolLabel.text = nil
        nameLabel.text = nil
        priceLabel.text = nil
        priceChangeLabel.text = nil
        miniChartView.reset()
    }
    
    public func configure(with viewModel: ViewModel) {
        symbolLabel.text = viewModel.symbol
        nameLabel.text = viewModel.companyName
        priceLabel.text = viewModel.price
        priceChangeLabel.text = viewModel.changePercentage
        priceChangeLabel.backgroundColor = viewModel.changeColor
        
        miniChartView.configure(with: viewModel.chartViewModel)
    }

}
