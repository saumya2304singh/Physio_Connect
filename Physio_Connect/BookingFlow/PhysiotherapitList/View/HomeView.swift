//
//  HomeView.swift
//  Physio_Connect
//
//  Created by Ayush Rai on 31/12/25.
//

import UIKit

final class HomeView: UIView {

    // MARK: - UI
    private let topBar = UIView()
    private let locationIcon = UIImageView()
    private let locationLabel = UILabel()
    let profileButton = UIButton(type: .system)

    private let titleLabel = UILabel()

    let card = HomeHeroCardView()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hex: "E3F0FF")
        build()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        // Top bar
        locationIcon.image = UIImage(systemName: "mappin.and.ellipse")
        locationIcon.tintColor = UIColor(hex: "1E6EF7")
        locationIcon.translatesAutoresizingMaskIntoConstraints = false

        locationLabel.text = "Chennai"
        locationLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        locationLabel.textColor = .black.withAlphaComponent(0.7)
        locationLabel.translatesAutoresizingMaskIntoConstraints = false

        profileButton.setImage(UIImage(systemName: "person.circle"), for: .normal)
        profileButton.tintColor = .black.withAlphaComponent(0.7)
        profileButton.translatesAutoresizingMaskIntoConstraints = false

        topBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topBar)
        topBar.addSubview(locationIcon)
        topBar.addSubview(locationLabel)
        topBar.addSubview(profileButton)

        // Title
        titleLabel.text = "Home"
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        // Card
        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
            topBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            topBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            topBar.heightAnchor.constraint(equalToConstant: 30),

            locationIcon.leadingAnchor.constraint(equalTo: topBar.leadingAnchor),
            locationIcon.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            locationIcon.widthAnchor.constraint(equalToConstant: 18),
            locationIcon.heightAnchor.constraint(equalToConstant: 18),

            locationLabel.leadingAnchor.constraint(equalTo: locationIcon.trailingAnchor, constant: 6),
            locationLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),

            profileButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor),
            profileButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            profileButton.widthAnchor.constraint(equalToConstant: 34),
            profileButton.heightAnchor.constraint(equalToConstant: 34),

            titleLabel.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 8),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            card.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            card.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
            // ✅ No fixed height here → card height becomes dynamic automatically.
        ])
    }
}
