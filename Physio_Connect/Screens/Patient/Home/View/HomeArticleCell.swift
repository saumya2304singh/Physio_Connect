//
//  HomeArticleCell.swift
//  Physio_Connect
//
//  Created by user@8 on 03/01/26.
//

import UIKit

final class HomeArticleCell: UITableViewCell {
    static let reuseID = "HomeArticleCell"

    private let card = UIView()
    private let sourcePill = UILabel()
    private let clockIconView = UIImageView()
    private let metaRow = UIStackView()
    private let sourceTimeSpacer = UIView()
    private let minutesLabel = UILabel()
    private let titleLabel = UILabel()
    private let summaryLabel = UILabel()
    private let footerLabel = UILabel()
    private let chevronView = UIImageView()
    private let footerRow = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        build()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        sourcePill.text = nil
        minutesLabel.text = nil
        titleLabel.text = nil
        summaryLabel.text = nil
    }

    func configure(with article: ArticleRow) {
        titleLabel.text = article.title
        summaryLabel.text = article.summary
        minutesLabel.text = "\(article.read_minutes ?? 0) min read"
        let sourceName = article.source_name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let sourceSlug = article.source?.trimmingCharacters(in: .whitespacesAndNewlines)
        let urlSource = sourceHost(from: article.source_url) ?? sourceHost(from: article.url)
        let fallbackTag = article.tags?.first?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedSource = (sourceName?.isEmpty == false ? sourceName :
                              (sourceSlug?.isEmpty == false ? sourceSlug :
                               (urlSource?.isEmpty == false ? urlSource :
                                (fallbackTag?.isEmpty == false ? fallbackTag : "Source"))))
        sourcePill.text = "  \(resolvedSource ?? "Source")  "
    }

    private func build() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor.white.withAlphaComponent(0.92)
        card.layer.cornerRadius = 22
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.55).cgColor
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.035
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 3)
        contentView.addSubview(card)

        sourcePill.translatesAutoresizingMaskIntoConstraints = false
        sourcePill.backgroundColor = UIColor(hex: "EAF3FF")
        sourcePill.layer.cornerRadius = 11
        sourcePill.layer.masksToBounds = true
        sourcePill.font = UITheme.Typography.meta
        sourcePill.textColor = UIColor(hex: "1E6EF7")
        sourcePill.textAlignment = .center
        sourcePill.lineBreakMode = .byTruncatingTail
        sourcePill.setContentCompressionResistancePriority(.required, for: .horizontal)
        sourcePill.setContentHuggingPriority(.required, for: .horizontal)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UITheme.Typography.cardTitle
        titleLabel.textColor = UITheme.Colors.textPrimary
        titleLabel.numberOfLines = 2

        summaryLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryLabel.font = UITheme.Typography.bodySmall
        summaryLabel.textColor = UITheme.Colors.textSecondary
        summaryLabel.numberOfLines = 2

        clockIconView.translatesAutoresizingMaskIntoConstraints = false
        clockIconView.image = UIImage(systemName: "clock")
        clockIconView.tintColor = UIColor.black.withAlphaComponent(0.45)

        minutesLabel.translatesAutoresizingMaskIntoConstraints = false
        minutesLabel.font = UITheme.Typography.caption
        minutesLabel.textColor = UIColor.black.withAlphaComponent(0.55)

        metaRow.axis = .horizontal
        metaRow.spacing = 8
        metaRow.alignment = .center
        metaRow.translatesAutoresizingMaskIntoConstraints = false
        metaRow.addArrangedSubview(sourcePill)
        metaRow.addArrangedSubview(sourceTimeSpacer)
        metaRow.addArrangedSubview(clockIconView)
        metaRow.addArrangedSubview(minutesLabel)

        footerLabel.translatesAutoresizingMaskIntoConstraints = false
        footerLabel.text = "Read more"
        footerLabel.font = UITheme.Typography.buttonSmall
        footerLabel.textColor = UIColor(hex: "1E6EF7")

        chevronView.translatesAutoresizingMaskIntoConstraints = false
        chevronView.image = UIImage(systemName: "chevron.right")
        chevronView.tintColor = UIColor(hex: "1E6EF7")
        chevronView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)

        footerRow.axis = .horizontal
        footerRow.spacing = 4
        footerRow.alignment = .center
        footerRow.translatesAutoresizingMaskIntoConstraints = false
        footerRow.addArrangedSubview(footerLabel)
        footerRow.addArrangedSubview(chevronView)

        card.addSubview(metaRow)
        card.addSubview(titleLabel)
        card.addSubview(summaryLabel)
        card.addSubview(footerRow)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            sourcePill.heightAnchor.constraint(equalToConstant: 22),
            sourcePill.widthAnchor.constraint(lessThanOrEqualToConstant: 160),

            clockIconView.widthAnchor.constraint(equalToConstant: 12),
            clockIconView.heightAnchor.constraint(equalToConstant: 12),

            metaRow.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            metaRow.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            metaRow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),

            titleLabel.topAnchor.constraint(equalTo: metaRow.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),

            summaryLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            summaryLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            summaryLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            footerRow.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 10),
            footerRow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            footerRow.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
    }

    private func sourceHost(from urlString: String?) -> String? {
        guard let raw = urlString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty,
              let url = URL(string: raw),
              let host = url.host
        else { return nil }
        return host.replacingOccurrences(of: "www.", with: "")
    }
}
