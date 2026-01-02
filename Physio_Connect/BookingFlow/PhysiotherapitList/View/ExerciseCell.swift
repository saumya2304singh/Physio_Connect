//
//  ExerciseCell.swift
//  Physio_Connect
//
//  Created by user@8 on 03/01/26.
//

import UIKit

final class ExerciseCell: UITableViewCell {

    static let reuseID = "ExerciseCell"

    private let card = UIView()
    private let heroImageView = UIImageView()
    private let playButton = UIButton(type: .system)
    private let levelBadge = UILabel()
    private let durationPill = UILabel()
    private let titleLabel = UILabel()
    private let subLabel = UILabel()
    private let descLabel = UILabel()

    private var imageTask: URLSessionDataTask?
    private(set) var thumbnailPath: String?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        build()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        thumbnailPath = nil
        heroImageView.image = UIImage(systemName: "video")
    }

    func configure(title: String,
                   subtitle: String,
                   description: String?,
                   durationSeconds: Int?,
                   badgeText: String,
                   thumbnailPath: String?) {
        titleLabel.text = title
        subLabel.text = subtitle
        descLabel.text = description ?? "Follow the guided video and maintain controlled movement."
        levelBadge.text = "  \(badgeText)  "
        self.thumbnailPath = thumbnailPath

        let mins = max(1, (durationSeconds ?? 0) / 60)
        durationPill.text = "  \(mins) min  "

        heroImageView.image = UIImage(systemName: "video")
    }

    func setThumbnail(url: URL) {
        imageTask?.cancel()
        imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.heroImageView.image = image
            }
        }
        imageTask?.resume()
    }

    private func build() {
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .white
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowRadius = 10
        card.layer.shadowOffset = CGSize(width: 0, height: 6)

        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        heroImageView.contentMode = .scaleAspectFill
        heroImageView.tintColor = UIColor(hex: "1E6EF7")
        heroImageView.backgroundColor = UIColor(hex: "E3F0FF")
        heroImageView.layer.cornerRadius = 18
        heroImageView.layer.masksToBounds = true
        heroImageView.image = UIImage(systemName: "video")

        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = UIColor(hex: "1E6EF7")
        playButton.backgroundColor = .white
        playButton.layer.cornerRadius = 24
        playButton.isUserInteractionEnabled = false

        levelBadge.translatesAutoresizingMaskIntoConstraints = false
        levelBadge.font = .systemFont(ofSize: 12, weight: .semibold)
        levelBadge.textColor = UIColor(hex: "1E6EF7")
        levelBadge.backgroundColor = UIColor(hex: "DFF7E8")
        levelBadge.layer.cornerRadius = 12
        levelBadge.clipsToBounds = true
        levelBadge.textAlignment = .center

        durationPill.translatesAutoresizingMaskIntoConstraints = false
        durationPill.font = .systemFont(ofSize: 12, weight: .semibold)
        durationPill.textColor = .white
        durationPill.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        durationPill.layer.cornerRadius = 12
        durationPill.clipsToBounds = true
        durationPill.textAlignment = .center

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 2

        subLabel.translatesAutoresizingMaskIntoConstraints = false
        subLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        subLabel.textColor = UIColor(hex: "1E6EF7")
        subLabel.numberOfLines = 1

        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.font = .systemFont(ofSize: 13, weight: .regular)
        descLabel.textColor = UIColor.black.withAlphaComponent(0.65)
        descLabel.numberOfLines = 2

        contentView.addSubview(card)
        card.addSubview(heroImageView)
        card.addSubview(playButton)
        card.addSubview(levelBadge)
        card.addSubview(durationPill)
        card.addSubview(titleLabel)
        card.addSubview(subLabel)
        card.addSubview(descLabel)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            heroImageView.topAnchor.constraint(equalTo: card.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            heroImageView.heightAnchor.constraint(equalToConstant: 200),

            playButton.centerXAnchor.constraint(equalTo: heroImageView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: heroImageView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 48),
            playButton.heightAnchor.constraint(equalToConstant: 48),

            levelBadge.topAnchor.constraint(equalTo: heroImageView.topAnchor, constant: 12),
            levelBadge.leadingAnchor.constraint(equalTo: heroImageView.leadingAnchor, constant: 12),
            levelBadge.heightAnchor.constraint(equalToConstant: 24),

            durationPill.topAnchor.constraint(equalTo: heroImageView.topAnchor, constant: 12),
            durationPill.trailingAnchor.constraint(equalTo: heroImageView.trailingAnchor, constant: -12),
            durationPill.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            subLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            descLabel.topAnchor.constraint(equalTo: subLabel.bottomAnchor, constant: 6),
            descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            descLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }
}
