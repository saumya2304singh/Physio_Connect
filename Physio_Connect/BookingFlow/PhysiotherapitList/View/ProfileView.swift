//
//  ProfileView.swift
//  Physio_Connect
//
//  Created by user@8 on 03/01/26.
//

import UIKit

final class ProfileView: UIView {

    var onBack: (() -> Void)?
    var onEdit: (() -> Void)?
    var onPrivacyTapped: (() -> Void)?
    var onTermsTapped: (() -> Void)?
    var onSignOut: (() -> Void)?
    var onNotificationsChanged: ((Bool) -> Void)?
    var onRefresh: (() -> Void)?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    private let refreshControl = UIRefreshControl()

    private let topBar = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let editButton = UIButton(type: .system)

    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()

    private let emailRow = ProfileRowView(title: "Email")
    private let phoneRow = ProfileRowView(title: "Phone")
    private let addressRow = ProfileRowView(title: "Address")
    private let genderRow = ProfileRowView(title: "Gender")
    private let dobRow = ProfileRowView(title: "Date of Birth")

    private let conditionRow = ProfileRowView(title: "Medical Condition")

    private let locationRow = ProfileRowView(title: "Location")
    private let notificationRow = ProfileToggleRowView(title: "Notifications")

    private let privacyButton = ProfileActionRowButton(title: "Privacy Policy")
    private let termsButton = ProfileActionRowButton(title: "Terms of Service")

    private let signOutButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hex: "E8EEF5")
        build()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(_ data: ProfileViewData) {
        nameLabel.text = data.name
        emailRow.setValue(data.email)
        phoneRow.setValue(data.phone)
        addressRow.setValue(data.address)
        genderRow.setValue(data.gender)
        dobRow.setValue(data.dateOfBirth)
        conditionRow.setValue(data.healthIdentifier)
        locationRow.setValue(data.location)
        notificationRow.setOn(data.notificationsEnabled)
    }

    func setRefreshing(_ isRefreshing: Bool) {
        if isRefreshing {
            if !refreshControl.isRefreshing {
                refreshControl.beginRefreshing()
            }
        } else {
            refreshControl.endRefreshing()
        }
    }

    private func build() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.alwaysBounceVertical = true
        scrollView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)

        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])

        buildTopBar()
        buildHeader()
        buildPersonalInfo()
        buildMedicalCondition()
        buildSettings()
        buildPrivacy()
        buildSignOut()
    }

    private func buildTopBar() {
        topBar.translatesAutoresizingMaskIntoConstraints = false

        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = UIColor(hex: "1E6EF7")
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "Profile"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = UIColor.black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        editButton.setTitle("Edit", for: .normal)
        editButton.setTitleColor(UIColor(hex: "1E6EF7"), for: .normal)
        editButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        editButton.translatesAutoresizingMaskIntoConstraints = false

        topBar.addSubview(backButton)
        topBar.addSubview(titleLabel)
        topBar.addSubview(editButton)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            backButton.heightAnchor.constraint(equalToConstant: 32),
            backButton.widthAnchor.constraint(equalToConstant: 32),

            titleLabel.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),

            editButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor),
            editButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor)
        ])

        topBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
        stackView.addArrangedSubview(topBar)
    }

    private func buildHeader() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
        avatarImageView.tintColor = UIColor(hex: "96A7BD")
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 46
        avatarImageView.layer.masksToBounds = true
        avatarImageView.layer.borderWidth = 4
        avatarImageView.layer.borderColor = UIColor(hex: "D1D9E5").cgColor
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        nameLabel.textColor = UIColor.black
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(avatarImageView)
        container.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: container.topAnchor),
            avatarImageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 92),
            avatarImageView.heightAnchor.constraint(equalToConstant: 92),

            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        stackView.addArrangedSubview(container)
    }

    private func buildPersonalInfo() {
        let card = makeCardView()
        let stack = makeCardStack()

        stack.addArrangedSubview(emailRow)
        stack.addArrangedSubview(makeSeparator())
        stack.addArrangedSubview(phoneRow)
        stack.addArrangedSubview(makeSeparator())
        stack.addArrangedSubview(addressRow)
        stack.addArrangedSubview(makeSeparator())
        stack.addArrangedSubview(genderRow)
        stack.addArrangedSubview(makeSeparator())
        stack.addArrangedSubview(dobRow)

        card.addSubview(stack)
        pinCardStack(stack, to: card)

        stackView.addArrangedSubview(card)
    }

    private func buildMedicalCondition() {
        let card = makeCardView()
        let stack = makeCardStack()

        stack.addArrangedSubview(conditionRow)
        card.addSubview(stack)
        pinCardStack(stack, to: card)

        stackView.addArrangedSubview(card)
    }

    private func buildSettings() {
        let sectionLabel = makeSectionLabel("Settings")
        stackView.addArrangedSubview(sectionLabel)

        let card = makeCardView()
        let stack = makeCardStack()

        stack.addArrangedSubview(locationRow)
        stack.addArrangedSubview(makeSeparator())
        stack.addArrangedSubview(notificationRow)

        notificationRow.onToggleChanged = { [weak self] isOn in
            self?.onNotificationsChanged?(isOn)
        }

        card.addSubview(stack)
        pinCardStack(stack, to: card)

        stackView.addArrangedSubview(card)
    }

    private func buildPrivacy() {
        let sectionLabel = makeSectionLabel("Privacy & Security")
        stackView.addArrangedSubview(sectionLabel)

        let card = makeCardView()
        let stack = makeCardStack()

        privacyButton.addTarget(self, action: #selector(privacyTapped), for: .touchUpInside)
        termsButton.addTarget(self, action: #selector(termsTapped), for: .touchUpInside)

        stack.addArrangedSubview(privacyButton)
        stack.addArrangedSubview(makeSeparator())
        stack.addArrangedSubview(termsButton)

        card.addSubview(stack)
        pinCardStack(stack, to: card)

        stackView.addArrangedSubview(card)
    }

    private func buildSignOut() {
        signOutButton.setTitle("Sign Out", for: .normal)
        signOutButton.setTitleColor(UIColor(hex: "E54848"), for: .normal)
        signOutButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        signOutButton.backgroundColor = UIColor.white
        signOutButton.layer.cornerRadius = 16
        signOutButton.layer.shadowColor = UIColor.black.cgColor
        signOutButton.layer.shadowOpacity = 0.05
        signOutButton.layer.shadowRadius = 10
        signOutButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        signOutButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        signOutButton.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)

        stackView.addArrangedSubview(signOutButton)
    }

    private func makeCardView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 18
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowRadius = 10
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        return view
    }

    private func makeCardStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    private func pinCardStack(_ stack: UIStackView, to container: UIView) {
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4)
        ])
    }

    private func makeSeparator() -> UIView {
        let sep = UIView()
        sep.backgroundColor = UIColor.black.withAlphaComponent(0.06)
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return sep
    }

    private func makeSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor.black
        return label
    }

    @objc private func backTapped() {
        onBack?()
    }

    @objc private func editTapped() {
        onEdit?()
    }

    @objc private func privacyTapped() {
        onPrivacyTapped?()
    }

    @objc private func termsTapped() {
        onTermsTapped?()
    }

    @objc private func signOutTapped() {
        onSignOut?()
    }

    @objc private func refreshPulled() {
        onRefresh?()
    }
}

final class ProfileRowView: UIView {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    init(title: String) {
        super.init(frame: .zero)

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.55)

        valueLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        valueLabel.textColor = UIColor.black.withAlphaComponent(0.9)
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 2

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setValue(_ value: String) {
        valueLabel.text = value
    }
}

final class ProfileToggleRowView: UIView {
    private let titleLabel = UILabel()
    private let toggle = UISwitch()
    var onToggleChanged: ((Bool) -> Void)?

    init(title: String) {
        super.init(frame: .zero)

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.55)

        toggle.onTintColor = UIColor(hex: "38A169")
        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)

        let stack = UIStackView(arrangedSubviews: [titleLabel, toggle])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        toggle.setContentHuggingPriority(.required, for: .horizontal)
        toggle.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setOn(_ isOn: Bool) {
        toggle.setOn(isOn, animated: true)
    }

    @objc private func toggleChanged() {
        onToggleChanged?(toggle.isOn)
    }
}

final class ProfileActionRowButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)

        setTitle(title, for: .normal)
        setTitleColor(UIColor(hex: "1E6EF7"), for: .normal)
        titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        contentHorizontalAlignment = .left

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = UIColor.black.withAlphaComponent(0.35)
        chevron.translatesAutoresizingMaskIntoConstraints = false

        addSubview(chevron)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 48),
            chevron.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            chevron.widthAnchor.constraint(equalToConstant: 12)
        ])

        contentEdgeInsets = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 32)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
