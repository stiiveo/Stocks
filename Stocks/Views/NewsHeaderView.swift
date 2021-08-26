//
//  NewsHeaderView.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/11.
//

import UIKit

class NewsHeaderView: UITableViewHeaderFooterView {
    
    static let identifier = "NewsHeaderView"
    
    struct ViewModel {
        let title: String
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 26, weight: .heavy)
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .secondaryLabel
        label.text = "From Finnhub"
        return label
    }()
    
    private let stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 4
        view.alignment = .leading
        view.distribution = .equalCentering
        return view
    }()
    
    private let borderLine: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray3
        return view
    }()
    
    // MARK: - Init
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .secondarySystemBackground
        setUpStackView()
        setUpBorderLine()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }
    
    public func configure(with viewModel: ViewModel) {
        titleLabel.text = viewModel.title
    }
    
    private func setUpStackView() {
        stackView.addArrangedSubviews(titleLabel, subtitleLabel)
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setUpBorderLine() {
        contentView.addSubview(borderLine)
        borderLine.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            borderLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            borderLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            borderLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            borderLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
}
