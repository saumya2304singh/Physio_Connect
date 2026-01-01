//
//  HomeHeroCardView.swift
//  Physio_Connect
//
//  Created by Ayush Rai on 31/12/25.
//

import UIKit

final class HomeHeroCardView: UIView {

    enum State {
        case bookHomeVisit
        case upcoming(HomeUpcomingAppointment)
    }

    // MARK: - UI

    private let container = UIView()

    // Top: calendar badge + pill
    private let topRow = UIStackView()
    private let badgeIconWrap = UIView()
    private let badgeIcon = UIImageView()

    private let pill = UIView()
    private let pillLabel = UILabel()
    private let pillIcon = UIImageView()

    // Main content row
    private let contentRow = UIStackView()
    private let avatarWrap = UIView()
    private let avatarIcon = UIImageView()

    private let textStack = UIStackView()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let metaStack = UIStackView()
    private let dateRow = MetaRow(icon: "calendar", text: "")
    private let timeRow = MetaRow(icon: "clock", text: "")

    // Button
    let primaryButton = UIButton(type: .system)
    private let buttonChevron = UIImageView()

    private var gradientLayer: CAGradientLayer?

    private var currentState: State = .bookHomeVisit

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
        apply(state: .bookHomeVisit)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Build

    private func build() {
        backgroundColor = .clear

        // Container
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        container.layer.cornerRadius = 22
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.08
        container.layer.shadowRadius = 14
        container.layer.shadowOffset = CGSize(width: 0, height: 8)
        addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // --- Top row ---
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = 10
        topRow.translatesAutoresizingMaskIntoConstraints = false

        badgeIconWrap.translatesAutoresizingMaskIntoConstraints = false
        badgeIconWrap.backgroundColor = UIColor(hex: "1E6EF7").withAlphaComponent(0.12)
        badgeIconWrap.layer.cornerRadius = 18

        badgeIcon.translatesAutoresizingMaskIntoConstraints = false
        badgeIcon.image = UIImage(systemName: "calendar")
        badgeIcon.tintColor = UIColor(hex: "1E6EF7")
        badgeIcon.contentMode = .scaleAspectFit

        badgeIconWrap.addSubview(badgeIcon)

        NSLayoutConstraint.activate([
            badgeIconWrap.widthAnchor.constraint(equalToConstant: 36),
            badgeIconWrap.heightAnchor.constraint(equalToConstant: 36),
            badgeIcon.centerXAnchor.constraint(equalTo: badgeIconWrap.centerXAnchor),
            badgeIcon.centerYAnchor.constraint(equalTo: badgeIconWrap.centerYAnchor)
        ])

        pill.translatesAutoresizingMaskIntoConstraints = false
        pill.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.14)
        pill.layer.cornerRadius = 14

        pillIcon.translatesAutoresizingMaskIntoConstraints = false
        pillIcon.image = UIImage(systemName: "clock")
        pillIcon.tintColor = UIColor.systemGreen
        pillIcon.contentMode = .scaleAspectFit

        pillLabel.translatesAutoresizingMaskIntoConstraints = false
        pillLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        pillLabel.textColor = UIColor.systemGreen
        pillLabel.text = "Upcoming"

        pill.addSubview(pillIcon)
        pill.addSubview(pillLabel)

        NSLayoutConstraint.activate([
            pillIcon.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 10),
            pillIcon.centerYAnchor.constraint(equalTo: pill.centerYAnchor),
            pillIcon.widthAnchor.constraint(equalToConstant: 14),
            pillIcon.heightAnchor.constraint(equalToConstant: 14),

            pillLabel.leadingAnchor.constraint(equalTo: pillIcon.trailingAnchor, constant: 6),
            pillLabel.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -12),
            pillLabel.topAnchor.constraint(equalTo: pill.topAnchor, constant: 6),
            pillLabel.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -6)
        ])

        topRow.addArrangedSubview(badgeIconWrap)
        topRow.addArrangedSubview(pill)

        // --- Content row ---
        contentRow.axis = .horizontal
        contentRow.alignment = .top
        contentRow.spacing = 14
        contentRow.translatesAutoresizingMaskIntoConstraints = false

        avatarWrap.translatesAutoresizingMaskIntoConstraints = false
        avatarWrap.backgroundColor = UIColor(hex: "1E6EF7").withAlphaComponent(0.16)
        avatarWrap.layer.cornerRadius = 30

        avatarIcon.translatesAutoresizingMaskIntoConstraints = false
        avatarIcon.image = UIImage(systemName: "stethoscope")
        avatarIcon.tintColor = UIColor(hex: "1E6EF7")
        avatarIcon.contentMode = .scaleAspectFit

        avatarWrap.addSubview(avatarIcon)

        NSLayoutConstraint.activate([
            avatarWrap.widthAnchor.constraint(equalToConstant: 60),
            avatarWrap.heightAnchor.constraint(equalToConstant: 60),

            avatarIcon.centerXAnchor.constraint(equalTo: avatarWrap.centerXAnchor),
            avatarIcon.centerYAnchor.constraint(equalTo: avatarWrap.centerYAnchor),
            avatarIcon.widthAnchor.constraint(equalToConstant: 28),
            avatarIcon.heightAnchor.constraint(equalToConstant: 28)
        ])

        textStack.axis = .vertical
        textStack.spacing = 6
        textStack.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .systemFont(ofSize: 22, weight: .bold)
        nameLabel.textColor = .black

        subtitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        subtitleLabel.textColor = UIColor.black.withAlphaComponent(0.55)

        metaStack.axis = .vertical
        metaStack.spacing = 10
        metaStack.translatesAutoresizingMaskIntoConstraints = false
        metaStack.addArrangedSubview(dateRow)
        metaStack.addArrangedSubview(timeRow)

        textStack.addArrangedSubview(nameLabel)
        textStack.addArrangedSubview(subtitleLabel)
        textStack.addArrangedSubview(metaStack)

        contentRow.addArrangedSubview(avatarWrap)
        contentRow.addArrangedSubview(textStack)

        // --- Button ---
        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        primaryButton.setTitle("View Details", for: .normal)
        primaryButton.setTitleColor(.white, for: .normal)
        primaryButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        primaryButton.layer.cornerRadius = 14
        primaryButton.clipsToBounds = true
        primaryButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)

        buttonChevron.translatesAutoresizingMaskIntoConstraints = false
        buttonChevron.image = UIImage(systemName: "chevron.right")
        buttonChevron.tintColor = .white

        primaryButton.addSubview(buttonChevron)

        NSLayoutConstraint.activate([
            buttonChevron.centerYAnchor.constraint(equalTo: primaryButton.centerYAnchor),
            buttonChevron.trailingAnchor.constraint(equalTo: primaryButton.trailingAnchor, constant: -16)
        ])

        // Add to container
        container.addSubview(topRow)
        container.addSubview(contentRow)
        container.addSubview(primaryButton)

        NSLayoutConstraint.activate([
            topRow.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            topRow.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            topRow.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -16),

            contentRow.topAnchor.constraint(equalTo: topRow.bottomAnchor, constant: 14),
            contentRow.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            contentRow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            primaryButton.topAnchor.constraint(equalTo: contentRow.bottomAnchor, constant: 16),
            primaryButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            primaryButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            primaryButton.heightAnchor.constraint(equalToConstant: 52),
            primaryButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyButtonGradient()
    }

    private func applyButtonGradient() {
        gradientLayer?.removeFromSuperlayer()

        let g = CAGradientLayer()
        g.frame = primaryButton.bounds
        g.cornerRadius = primaryButton.layer.cornerRadius

        // Normal app scheme (blue gradient, not purple)
        g.colors = [
            UIColor(hex: "1E6EF7").cgColor,
            UIColor(hex: "4E8CFF").cgColor
        ]
        g.startPoint = CGPoint(x: 0, y: 0.5)
        g.endPoint = CGPoint(x: 1, y: 0.5)

        primaryButton.layer.insertSublayer(g, at: 0)
        gradientLayer = g
    }

    // MARK: - State

    func apply(state: State) {
        currentState = state

        switch state {

        case .bookHomeVisit:
            // Hide pill in book state (like your current logic)
            pill.isHidden = true

            nameLabel.text = "Book home visits"
            subtitleLabel.text = "Get certified physiotherapy at your doorsteps"
            dateRow.isHidden = true
            timeRow.isHidden = true

            primaryButton.setTitle("Book appointment", for: .normal)

        case .upcoming(let appt):
            pill.isHidden = false
            pillLabel.text = "Upcoming"

            nameLabel.text = "Dr. \(appt.physioName)"
            subtitleLabel.text = "Healthcare Professional"

            dateRow.isHidden = false
            timeRow.isHidden = false

            let df1 = DateFormatter()
            df1.dateFormat = "EEEE, dd MMM"

            let df2 = DateFormatter()
            df2.dateFormat = "h:mm a"

            dateRow.setText(df1.string(from: appt.startTime))
            timeRow.setText(df2.string(from: appt.startTime))

            primaryButton.setTitle("View Details", for: .normal)
        }

        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
    }
}

// MARK: - MetaRow (icon + text)

private final class MetaRow: UIView {

    private let iconView = UIImageView()
    private let label = UILabel()
    private let stack = UIStackView()

    init(icon: String, text: String) {
        super.init(frame: .zero)
        build(icon: icon, text: text)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setText(_ text: String) {
        label.text = text
    }

    private func build(icon: String, text: String) {
        translatesAutoresizingMaskIntoConstraints = false

        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = UIColor(hex: "1E6EF7")
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18)
        ])

        label.text = text
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = UIColor.black.withAlphaComponent(0.75)

        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(label)
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
