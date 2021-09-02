//
//  MetricCollectionViewCell.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/15.
//

import UIKit

class MetricCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    static let identifier = "MetricCollectionViewCell"
    
    struct ViewModel {
        let name: String
        let value: String
    }
    
    private let stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 10
        view.alignment = .center
        view.distribution = .fill
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = .monospacedDigitSystemFont(ofSize: 14.0, weight: .semibold)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.clipsToBounds = true
        setUpStackView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    
    func configure(with viewModel: ViewModel) {
        self.nameLabel.text = viewModel.name
        self.valueLabel.text = viewModel.value
    }
    
    func reset() {
        nameLabel.text = nil
        valueLabel.text = nil
    }
    
    // MARK: - Private Methods
    
    private func setUpStackView() {
        stackView.addArrangedSubviews(nameLabel, valueLabel)
        contentView.addSubview(stackView)
        stackView.frame = bounds
    }
    
}
