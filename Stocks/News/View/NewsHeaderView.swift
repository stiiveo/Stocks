//
//  NewsHeaderView.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/11.
//

import UIKit
import SnapKit

class NewsHeaderView: UITableViewHeaderFooterView {
    
    // MARK: - Properties
    
    static let identifier = "NewsHeaderView"
    
    struct ViewModel {
        let title: String
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 26, weight: .heavy)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .secondaryLabel
        label.text = "From Finnhub"
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
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
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.text = "U.S. Stocks is not connected to Internet."
        label.textAlignment = .center
        label.numberOfLines = 3
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.9
        label.textColor = .secondaryLabel
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.isHidden = true
        return label
    }()
    
    // MARK: - Init
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .secondarySystemBackground
        setUpStackView()
        configureMessageLabel()
        setUpBorderLine()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        titleLabel.text = nil
    }
    
    // MARK: - Public
    
    func configure(with viewModel: ViewModel) {
        titleLabel.text = viewModel.title
    }
    
    enum Status {
        case normal, noInternetConnection
    }
    
    var status: Status = .normal {
        didSet {
            switch status {
            case .normal:
                DispatchQueue.main.async { [weak self] in
                    self?.stackView.isHidden = false
                    self?.messageLabel.isHidden = true
                }
            case .noInternetConnection:
                DispatchQueue.main.async { [weak self] in
                    self?.stackView.isHidden = true
                    self?.messageLabel.isHidden = false
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setUpStackView() {
        stackView.addArrangedSubviews(titleLabel, subtitleLabel)
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.equalTo(contentView).offset(20)
            make.trailing.equalTo(contentView).offset(-20)
            make.top.equalTo(contentView).offset(20)
            make.bottom.equalTo(contentView).offset(-20).priority(999)
        }
    }
    
    private func configureMessageLabel() {
        contentView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.leading.equalTo(contentView).offset(20.0)
            make.trailing.equalTo(contentView).offset(-20.0)
            make.top.equalTo(contentView).offset(10.0)
            make.bottom.equalTo(contentView.bottom).offset(-10.0).priority(999)
        }
    }
    
    private func setUpBorderLine() {
        contentView.addSubview(borderLine)
        borderLine.snp.makeConstraints { make in
            make.leading.equalTo(contentView).offset(15)
            make.trailing.equalTo(contentView).offset(-15)
            make.bottom.equalTo(contentView)
            make.height.equalTo(1)
        }
    }
    
}
