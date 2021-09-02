//
//  NewsStoryTableViewCell.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/12.
//

import UIKit
import SDWebImage

class NewsStoryTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    
    static let identifier = "NewsStoryTableViewCell"
    
    struct ViewModel {
        let source: String
        let headline: String
        let dateString: String
        let imageURL: URL?
        
        init(news: NewsStory) {
            self.source = news.source
            self.headline = news.headline
            self.dateString = news.date.dateString(formattedBy: .mediumDateStyleFormatter)
            self.imageURL = URL(string: news.image)
        }
    }
    
    private let sourceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let headlineLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.numberOfLines = 3
        label.allowsDefaultTighteningForTruncation = true
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 12, weight: .bold)
        return label
    }()
    
    private let storyImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.backgroundColor = .secondarySystemBackground
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 6
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .secondarySystemBackground
        setUpImageView()
        setUpSourceLabel()
        setUpDateLabel()
        setUpHeadlineLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        sourceLabel.text = nil
        headlineLabel.text = nil
        dateLabel.text = nil
        storyImageView.image = nil
    }
    
    // MARK: - Public Methods
    
    public func configure(with viewModel: ViewModel) {
        headlineLabel.text = viewModel.headline
        sourceLabel.text = viewModel.source
        dateLabel.text = viewModel.dateString
        
        let scale = UIScreen.main.scale
        let thumbnailSize = CGSize(width: 100 * scale, height: 100 * scale)
        storyImageView.sd_setImage(with: viewModel.imageURL, placeholderImage: nil, context: [.imageThumbnailPixelSize: thumbnailSize])
    }
    
    // MARK: - Private Methods
    
    private let leadingPadding: CGFloat = 20.0
    private let trailingPadding: CGFloat = -20.0
    private let topPadding: CGFloat = 10.0
    private let bottomPadding: CGFloat = -10.0
    private let imageViewSize: CGFloat = 90.0
    
    private func setUpImageView() {
        contentView.addSubview(storyImageView)
        storyImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Custom width priority.
        let widthConstraint = storyImageView.widthAnchor.constraint(equalToConstant: imageViewSize)
        widthConstraint.priority = UILayoutPriority(999)
        
        NSLayoutConstraint.activate([
            storyImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: trailingPadding),
            storyImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 25.0),
            storyImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -25.0),
            storyImageView.heightAnchor.constraint(equalTo: storyImageView.widthAnchor, multiplier: 1.0),
            widthConstraint
        ])
    }
    
    private func setUpSourceLabel() {
        contentView.addSubview(sourceLabel)
        sourceLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sourceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: leadingPadding),
            sourceLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: topPadding)
        ])
    }
    
    private func setUpDateLabel() {
        contentView.addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: leadingPadding),
            dateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: bottomPadding),
        ])
    }
    
    private func setUpHeadlineLabel() {
        contentView.addSubview(headlineLabel)
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headlineLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: leadingPadding),
            headlineLabel.trailingAnchor.constraint(equalTo: storyImageView.leadingAnchor, constant: -20),
            headlineLabel.topAnchor.constraint(equalTo: sourceLabel.bottomAnchor, constant: 6.0),
            headlineLabel.bottomAnchor.constraint(lessThanOrEqualTo: dateLabel.topAnchor, constant: -10.0),
        ])
    }

}
