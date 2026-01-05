//
//  ArticleCardCell.swift
//  Physio_Connect
//
//  Created by user@8 on 03/01/26.
//

import UIKit

final class ArticleCardCell: UITableViewCell {

    static let reuseID = "ArticleCardCell"

    private let card = UIView()
    private let coverImageView = UIImageView()
    private let trendingPill = UILabel()
    private let bookmarkButton = UIButton(type: .system)

    private let sourcePill = UIView()
    private let sourceIcon = UIImageView()
    private let sourceLabel = UILabel()
    private let dateLabel = UILabel()

    private let titleLabel = UILabel()
    private let summaryLabel = UILabel()

    private let tagsStack = UIStackView()
    private let metaStack = UIStackView()
    private let ratingLabel = UILabel()
    private let viewsLabel = UILabel()
    private let timeLabel = UILabel()
    private let readButton = UIButton(type: .system)

    var onBookmarkTapped: (() -> Void)?
    var onReadTapped: (() -> Void)?
    private var isBookmarked = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        build()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.image = UIImage(systemName: "photo")
        trendingPill.isHidden = true
        sourceLabel.text = nil
        dateLabel.text = nil
        titleLabel.text = nil
        summaryLabel.text = nil
        setTags([])
        setBookmarked(false)
    }

    private func build() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowRadius = 10
        card.layer.shadowOffset = CGSize(width: 0, height: 6)
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(hex: "E6EDF9").cgColor
        contentView.addSubview(card)

        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.backgroundColor = UIColor(hex: "E9EEF7")
        coverImageView.image = UIImage(systemName: "photo")
        coverImageView.tintColor = UIColor.black.withAlphaComponent(0.15)
        card.addSubview(coverImageView)

        trendingPill.translatesAutoresizingMaskIntoConstraints = false
        trendingPill.text = "Trending"
        trendingPill.font = .systemFont(ofSize: 12, weight: .semibold)
        trendingPill.textColor = .white
        trendingPill.backgroundColor = UIColor(hex: "FF4D4F")
        trendingPill.layer.cornerRadius = 14
        trendingPill.layer.masksToBounds = true
        trendingPill.textAlignment = .center
        trendingPill.isHidden = true
        card.addSubview(trendingPill)

        bookmarkButton.translatesAutoresizingMaskIntoConstraints = false
        bookmarkButton.backgroundColor = .white
        bookmarkButton.layer.cornerRadius = 18
        let bookmarkConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        bookmarkButton.setImage(UIImage(systemName: "bookmark", withConfiguration: bookmarkConfig), for: .normal)
        bookmarkButton.tintColor = UIColor.black.withAlphaComponent(0.6)
        bookmarkButton.addTarget(self, action: #selector(bookmarkTapped), for: .touchUpInside)
        card.addSubview(bookmarkButton)

        sourcePill.translatesAutoresizingMaskIntoConstraints = false
        sourcePill.backgroundColor = UIColor(hex: "EAF9F1")
        sourcePill.layer.cornerRadius = 14
        card.addSubview(sourcePill)

        sourceIcon.translatesAutoresizingMaskIntoConstraints = false
        sourceIcon.image = UIImage(systemName: "checkmark.seal.fill")
        sourceIcon.tintColor = UIColor(hex: "16A34A")

        sourceLabel.translatesAutoresizingMaskIntoConstraints = false
        sourceLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        sourceLabel.textColor = UIColor(hex: "15803D")

        sourcePill.addSubview(sourceIcon)
        sourcePill.addSubview(sourceLabel)

        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = .systemFont(ofSize: 13, weight: .medium)
        dateLabel.textColor = UIColor.black.withAlphaComponent(0.45)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 0

        summaryLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryLabel.font = .systemFont(ofSize: 14, weight: .regular)
        summaryLabel.textColor = UIColor.black.withAlphaComponent(0.6)
        summaryLabel.numberOfLines = 2

        tagsStack.translatesAutoresizingMaskIntoConstraints = false
        tagsStack.axis = .horizontal
        tagsStack.spacing = 8
        tagsStack.alignment = .leading

        metaStack.translatesAutoresizingMaskIntoConstraints = false
        metaStack.axis = .horizontal
        metaStack.spacing = 12
        metaStack.alignment = .center

        ratingLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        ratingLabel.textColor = UIColor.black.withAlphaComponent(0.6)

        viewsLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        viewsLabel.textColor = UIColor.black.withAlphaComponent(0.6)

        timeLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        timeLabel.textColor = UIColor.black.withAlphaComponent(0.6)

        readButton.setTitle("Read", for: .normal)
        readButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        readButton.setTitleColor(UIColor(hex: "1E6EF7"), for: .normal)
        readButton.addTarget(self, action: #selector(readTapped), for: .touchUpInside)

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        metaStack.addArrangedSubview(ratingLabel)
        metaStack.addArrangedSubview(viewsLabel)
        metaStack.addArrangedSubview(timeLabel)
        metaStack.addArrangedSubview(spacer)
        metaStack.addArrangedSubview(readButton)

        [sourcePill, dateLabel, titleLabel, summaryLabel, tagsStack, metaStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview($0)
        }

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            coverImageView.topAnchor.constraint(equalTo: card.topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            coverImageView.heightAnchor.constraint(equalToConstant: 180),

            trendingPill.topAnchor.constraint(equalTo: coverImageView.topAnchor, constant: 12),
            trendingPill.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor, constant: 12),
            trendingPill.heightAnchor.constraint(equalToConstant: 28),
            trendingPill.widthAnchor.constraint(greaterThanOrEqualToConstant: 84),

            bookmarkButton.topAnchor.constraint(equalTo: coverImageView.topAnchor, constant: 12),
            bookmarkButton.trailingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: -12),
            bookmarkButton.widthAnchor.constraint(equalToConstant: 36),
            bookmarkButton.heightAnchor.constraint(equalToConstant: 36),

            sourcePill.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 12),
            sourcePill.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            sourceIcon.leadingAnchor.constraint(equalTo: sourcePill.leadingAnchor, constant: 10),
            sourceIcon.centerYAnchor.constraint(equalTo: sourcePill.centerYAnchor),
            sourceIcon.widthAnchor.constraint(equalToConstant: 14),
            sourceIcon.heightAnchor.constraint(equalToConstant: 14),

            sourceLabel.leadingAnchor.constraint(equalTo: sourceIcon.trailingAnchor, constant: 6),
            sourceLabel.trailingAnchor.constraint(equalTo: sourcePill.trailingAnchor, constant: -12),
            sourceLabel.centerYAnchor.constraint(equalTo: sourcePill.centerYAnchor),

            sourcePill.heightAnchor.constraint(equalToConstant: 28),

            dateLabel.centerYAnchor.constraint(equalTo: sourcePill.centerYAnchor),
            dateLabel.leadingAnchor.constraint(equalTo: sourcePill.trailingAnchor, constant: 12),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: sourcePill.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            summaryLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            summaryLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            summaryLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            tagsStack.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 10),
            tagsStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            tagsStack.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -16),

            metaStack.topAnchor.constraint(equalTo: tagsStack.bottomAnchor, constant: 12),
            metaStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            metaStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            metaStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }

    func configure(with article: ArticleRow) {
        titleLabel.text = article.title
        summaryLabel.text = article.summary
        sourceLabel.text = article.source_name ?? "Source"
        dateLabel.text = article.published_at ?? ""
        trendingPill.isHidden = !(article.is_trending ?? false)

        let ratingText = String(format: "%.1f", article.rating ?? 0.0)
        ratingLabel.text = "⭐️ \(ratingText)"
        viewsLabel.text = "👁️ \(formatViews(article.views_count ?? 0))"
        timeLabel.text = "⏱️ \(article.read_minutes ?? 0) min read"

        setTags(article.tags ?? [])
    }

    func setBookmarked(_ bookmarked: Bool) {
        isBookmarked = bookmarked
        let imageName = bookmarked ? "bookmark.fill" : "bookmark"
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        bookmarkButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
        bookmarkButton.tintColor = bookmarked ? UIColor(hex: "1E6EF7") : UIColor.black.withAlphaComponent(0.6)
    }

    private func setTags(_ tags: [String]) {
        tagsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let displayTags = Array(tags.prefix(2))
        for tag in displayTags {
            let tagView = TagPillView(text: tag)
            tagsStack.addArrangedSubview(tagView)
        }
        tagsStack.isHidden = displayTags.isEmpty
    }

    private func formatViews(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        }
        return "\(count)"
    }

    @objc private func bookmarkTapped() {
        onBookmarkTapped?()
    }

    @objc private func readTapped() {
        onReadTapped?()
    }
}

private final class TagPillView: UIView {
    private let label = UILabel()

    init(text: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor(hex: "E8F3FF")
        layer.cornerRadius = 14
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = UIColor(hex: "1E6EF7")
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
