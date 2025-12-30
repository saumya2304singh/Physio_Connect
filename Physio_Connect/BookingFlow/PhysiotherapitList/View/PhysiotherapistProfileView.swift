//
//  PhysiotherapistProfileView.swift
//  Physio_Connect
//
//  Created by user@8 on 30/12/25.
//

import UIKit

final class PhysiotherapistProfileView: UIView {

    // MARK: Colors
    private let bg = UIColor(hex: "E3F0FF")
    private let primaryBlue = UIColor(hex: "1E6EF7")

    // MARK: Scroll
    let scrollView = UIScrollView()
    private let contentView = UIView()

    // MARK: Header (gradient)
    private let header = UIView()
    private let headerGradient = CAGradientLayer()

    let backButton = UIButton(type: .system)

    private let avatar = UIImageView()
    private let nameLabel = UILabel()
    private let ratingLabel = UILabel()
    private let servicePlaceLabel = UILabel()

    private let onlineDot = UIView()

    // MARK: Spec + Fee card (floating)
    private let specFeeCard = UIView()
    private let specTitle = UILabel()
    private let specValue = UILabel()
    private let feeTitle = UILabel()
    private let feeValue = UILabel()

    // MARK: Stats card
    private let statsCard = UIView()
    private let statsStack = UIStackView()

    private let patientsLabel = UILabel()
    private let experienceLabel = UILabel()
    private let ratingNumLabel = UILabel()
    private let reviewsCountLabel = UILabel()

    // MARK: About
    private let aboutCard = UIView()
    private let aboutTitle = UILabel()
    private let aboutText = UILabel()

    let aboutMoreButton = UIButton(type: .system)
    private var aboutCollapsed = true
    private var needsAboutTruncationCheck = false

    // MARK: Button
    let bookButton = UIButton(type: .system)

    // MARK: Reviews header + table
    private let reviewsHeaderRow = UIView()
    private let reviewsTitle = UILabel()
    let seeAllButton = UIButton(type: .system)

    let reviewsTableView = UITableView(frame: .zero, style: .plain)
    private(set) var reviewsTableHeight: NSLayoutConstraint!

    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = bg
        build()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        headerGradient.frame = header.bounds

        if needsAboutTruncationCheck {
            needsAboutTruncationCheck = false
            updateAboutMoreVisibility()
        }
    }

    // MARK: Public
    func updateReviewsTableHeight() {
        reviewsTableView.layoutIfNeeded()
        reviewsTableHeight.constant = reviewsTableView.contentSize.height
    }

    // MARK: Stats helper (NO statItem used)
    private func makeStatCard(icon: String, label: UILabel) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView(image: UIImage(systemName: icon))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = primaryBlue
        imageView.contentMode = .scaleAspectFit

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .black
        label.numberOfLines = 2
        label.textAlignment = .center

        container.addSubview(imageView)
        container.addSubview(label)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 22),
            imageView.heightAnchor.constraint(equalToConstant: 22),

            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    // MARK: Build UI
    private func build() {

        // Scroll
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false

        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // Header (IMPORTANT: add to hierarchy)
        header.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(header)

        headerGradient.colors = [
            UIColor(hex: "1E6EF7").cgColor,
            UIColor(hex: "1E6EF7").withAlphaComponent(0.75).cgColor,
            UIColor(hex: "5EC6F5").cgColor
        ]
        headerGradient.locations = [0.0, 0.55, 1.0] as [NSNumber]
        // Diagonal gradient: top-left (primary) -> bottom-right (cyan)
        headerGradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        headerGradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        header.layer.insertSublayer(headerGradient, at: 0)

        // Back button (chevron only)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.backgroundColor = .clear

        // Avatar
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.layer.cornerRadius = 26
        avatar.clipsToBounds = true
        avatar.contentMode = .scaleAspectFill
        avatar.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        avatar.image = UIImage(named: "doctor_placeholder") ?? UIImage(systemName: "person.fill")
        avatar.tintColor = .white

        // Online dot
        onlineDot.translatesAutoresizingMaskIntoConstraints = false
        onlineDot.backgroundColor = UIColor.systemGreen
        onlineDot.layer.cornerRadius = 8
        onlineDot.layer.borderWidth = 2
        onlineDot.layer.borderColor = UIColor.white.cgColor

        // Name + rating + distance
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .boldSystemFont(ofSize: 22)
        nameLabel.textColor = .white

        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        ratingLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        ratingLabel.textColor = UIColor.white.withAlphaComponent(0.95)

        servicePlaceLabel.translatesAutoresizingMaskIntoConstraints = false
        servicePlaceLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        servicePlaceLabel.textColor = UIColor.white.withAlphaComponent(0.95)

        [backButton, avatar, onlineDot, nameLabel, ratingLabel, servicePlaceLabel].forEach { header.addSubview($0) }

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: contentView.topAnchor),
            header.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 230),

            // Back button down a bit
            backButton.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 12),
            backButton.topAnchor.constraint(equalTo: header.safeAreaLayoutGuide.topAnchor, constant: 36),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            avatar.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 12),
            avatar.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 52),
            avatar.heightAnchor.constraint(equalToConstant: 52),

            onlineDot.widthAnchor.constraint(equalToConstant: 16),
            onlineDot.heightAnchor.constraint(equalToConstant: 16),
            onlineDot.trailingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 2),
            onlineDot.bottomAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 2),

            nameLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: backButton.topAnchor, constant: 2),
            nameLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),

            ratingLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            ratingLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            ratingLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            // Distance BELOW rating
            servicePlaceLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            servicePlaceLabel.topAnchor.constraint(equalTo: ratingLabel.bottomAnchor, constant: 6),
            servicePlaceLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16)
        ])

        // Spec + Fee floating card
        specFeeCard.translatesAutoresizingMaskIntoConstraints = false
        specFeeCard.backgroundColor = .white
        specFeeCard.layer.cornerRadius = 18
        specFeeCard.layer.shadowColor = UIColor.black.cgColor
        specFeeCard.layer.shadowOpacity = 0.08
        specFeeCard.layer.shadowRadius = 10
        specFeeCard.layer.shadowOffset = CGSize(width: 0, height: 6)

        specTitle.text = "Specialization"
        specTitle.font = .systemFont(ofSize: 13, weight: .medium)
        specTitle.textColor = .darkGray

        specValue.font = .systemFont(ofSize: 15, weight: .bold)
        specValue.textColor = .black
        specValue.numberOfLines = 1

        feeTitle.text = "Consultation fees"
        feeTitle.font = .systemFont(ofSize: 13, weight: .medium)
        feeTitle.textColor = .darkGray
        feeTitle.textAlignment = .right

        feeValue.font = .systemFont(ofSize: 16, weight: .bold)
        feeValue.textColor = primaryBlue
        feeValue.textAlignment = .right

        [specTitle, specValue, feeTitle, feeValue].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            specFeeCard.addSubview($0)
        }

        contentView.addSubview(specFeeCard)

        NSLayoutConstraint.activate([
            specFeeCard.topAnchor.constraint(equalTo: header.bottomAnchor, constant: -26),
            specFeeCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            specFeeCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            specFeeCard.heightAnchor.constraint(equalToConstant: 74),

            specTitle.leadingAnchor.constraint(equalTo: specFeeCard.leadingAnchor, constant: 16),
            specTitle.topAnchor.constraint(equalTo: specFeeCard.topAnchor, constant: 14),

            specValue.leadingAnchor.constraint(equalTo: specTitle.leadingAnchor),
            specValue.topAnchor.constraint(equalTo: specTitle.bottomAnchor, constant: 6),
            specValue.trailingAnchor.constraint(lessThanOrEqualTo: feeTitle.leadingAnchor, constant: -10),

            feeTitle.trailingAnchor.constraint(equalTo: specFeeCard.trailingAnchor, constant: -16),
            feeTitle.topAnchor.constraint(equalTo: specFeeCard.topAnchor, constant: 14),

            feeValue.trailingAnchor.constraint(equalTo: feeTitle.trailingAnchor),
            feeValue.topAnchor.constraint(equalTo: feeTitle.bottomAnchor, constant: 6),
            feeValue.leadingAnchor.constraint(greaterThanOrEqualTo: specValue.trailingAnchor, constant: 10)
        ])

        // Stats card (same idea as yours, but no statItem)
        statsCard.translatesAutoresizingMaskIntoConstraints = false
        statsCard.backgroundColor = .white
        statsCard.layer.cornerRadius = 20
        statsCard.layer.shadowColor = UIColor.black.cgColor
        statsCard.layer.shadowOpacity = 0.05
        statsCard.layer.shadowRadius = 8
        statsCard.layer.shadowOffset = CGSize(width: 0, height: 4)

        statsStack.axis = .horizontal
        statsStack.distribution = .fillEqually
        statsStack.alignment = .center
        statsStack.spacing = 10
        statsStack.translatesAutoresizingMaskIntoConstraints = false

        let pView  = makeStatCard(icon: "person.2.fill", label: patientsLabel)
        let eView  = makeStatCard(icon: "rosette", label: experienceLabel)
        let rView  = makeStatCard(icon: "star.fill", label: ratingNumLabel)
        let rcView = makeStatCard(icon: "text.bubble.fill", label: reviewsCountLabel)

        [pView, eView, rView, rcView].forEach { statsStack.addArrangedSubview($0) }

        statsCard.addSubview(statsStack)
        contentView.addSubview(statsCard)

        NSLayoutConstraint.activate([
            statsCard.topAnchor.constraint(equalTo: specFeeCard.bottomAnchor, constant: 16),
            statsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statsCard.heightAnchor.constraint(equalToConstant: 110),

            statsStack.topAnchor.constraint(equalTo: statsCard.topAnchor, constant: 18),
            statsStack.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor, constant: 14),
            statsStack.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -14),
            statsStack.bottomAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: -18)
        ])

        // About card (expandable) — FIXED ORDER (prevents crash)
        aboutCard.translatesAutoresizingMaskIntoConstraints = false
        aboutCard.backgroundColor = .white
        aboutCard.layer.cornerRadius = 18
        aboutCard.layer.shadowColor = UIColor.black.cgColor
        aboutCard.layer.shadowOpacity = 0.04
        aboutCard.layer.shadowRadius = 8
        aboutCard.layer.shadowOffset = CGSize(width: 0, height: 4)

        aboutTitle.translatesAutoresizingMaskIntoConstraints = false
        aboutTitle.text = "About"
        aboutTitle.font = .boldSystemFont(ofSize: 18)
        aboutTitle.textColor = .black

        aboutText.translatesAutoresizingMaskIntoConstraints = false
        aboutText.font = .systemFont(ofSize: 13)
        aboutText.textColor = .darkGray
        aboutText.numberOfLines = 3

        aboutMoreButton.translatesAutoresizingMaskIntoConstraints = false
        aboutMoreButton.setTitle("Read more", for: .normal)
        aboutMoreButton.setTitleColor(primaryBlue, for: .normal)
        aboutMoreButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        aboutMoreButton.isHidden = true

        // Add subviews BEFORE constraints
        aboutCard.addSubview(aboutTitle)
        aboutCard.addSubview(aboutText)
        aboutCard.addSubview(aboutMoreButton)
        contentView.addSubview(aboutCard)

        NSLayoutConstraint.activate([
            aboutCard.topAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: 16),
            aboutCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            aboutCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            aboutTitle.topAnchor.constraint(equalTo: aboutCard.topAnchor, constant: 16),
            aboutTitle.leadingAnchor.constraint(equalTo: aboutCard.leadingAnchor, constant: 16),
            aboutTitle.trailingAnchor.constraint(equalTo: aboutCard.trailingAnchor, constant: -16),

            aboutText.topAnchor.constraint(equalTo: aboutTitle.bottomAnchor, constant: 10),
            aboutText.leadingAnchor.constraint(equalTo: aboutCard.leadingAnchor, constant: 16),
            aboutText.trailingAnchor.constraint(equalTo: aboutCard.trailingAnchor, constant: -16),

            aboutMoreButton.topAnchor.constraint(equalTo: aboutText.bottomAnchor, constant: 10),
            aboutMoreButton.leadingAnchor.constraint(equalTo: aboutCard.leadingAnchor, constant: 16),
            aboutMoreButton.bottomAnchor.constraint(equalTo: aboutCard.bottomAnchor, constant: -14)
        ])

        // Book button (solid pill)
        bookButton.translatesAutoresizingMaskIntoConstraints = false
        bookButton.setTitle("Book Appointment", for: .normal)
        bookButton.setTitleColor(.white, for: .normal)
        bookButton.setTitleColor(.white, for: .highlighted)
        bookButton.setTitleColor(.white, for: .disabled)
        bookButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        bookButton.backgroundColor = UIColor(hex: "2F6BFF")
        bookButton.layer.cornerRadius = 26
        bookButton.clipsToBounds = true

        contentView.addSubview(bookButton)

        NSLayoutConstraint.activate([
            bookButton.topAnchor.constraint(equalTo: aboutCard.bottomAnchor, constant: 16),
            bookButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bookButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bookButton.heightAnchor.constraint(equalToConstant: 56)
        ])

        // Reviews header row
        reviewsHeaderRow.translatesAutoresizingMaskIntoConstraints = false
        reviewsTitle.translatesAutoresizingMaskIntoConstraints = false
        seeAllButton.translatesAutoresizingMaskIntoConstraints = false

        reviewsTitle.text = "Reviews"
        reviewsTitle.font = .boldSystemFont(ofSize: 18)
        reviewsTitle.textColor = .black

        seeAllButton.setTitle("See All  >", for: .normal)
        seeAllButton.setTitleColor(primaryBlue, for: .normal)
        seeAllButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)

        reviewsHeaderRow.addSubview(reviewsTitle)
        reviewsHeaderRow.addSubview(seeAllButton)
        contentView.addSubview(reviewsHeaderRow)

        NSLayoutConstraint.activate([
            reviewsHeaderRow.topAnchor.constraint(equalTo: bookButton.bottomAnchor, constant: 18),
            reviewsHeaderRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            reviewsHeaderRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            reviewsTitle.topAnchor.constraint(equalTo: reviewsHeaderRow.topAnchor),
            reviewsTitle.leadingAnchor.constraint(equalTo: reviewsHeaderRow.leadingAnchor),
            reviewsTitle.bottomAnchor.constraint(equalTo: reviewsHeaderRow.bottomAnchor),

            seeAllButton.centerYAnchor.constraint(equalTo: reviewsTitle.centerYAnchor),
            seeAllButton.trailingAnchor.constraint(equalTo: reviewsHeaderRow.trailingAnchor)
        ])

        // Reviews Table
        reviewsTableView.translatesAutoresizingMaskIntoConstraints = false
        reviewsTableView.backgroundColor = .clear
        reviewsTableView.separatorStyle = .none
        reviewsTableView.isScrollEnabled = false
        reviewsTableView.showsVerticalScrollIndicator = false
        reviewsTableView.rowHeight = UITableView.automaticDimension
        reviewsTableView.estimatedRowHeight = 110
        reviewsTableView.contentInset = .zero

        reviewsTableView.register(PhysioReviewCell.self,
                                  forCellReuseIdentifier: PhysioReviewCell.reuseID)

        contentView.addSubview(reviewsTableView)

        reviewsTableHeight = reviewsTableView.heightAnchor.constraint(equalToConstant: 10)
        reviewsTableHeight.isActive = true

        NSLayoutConstraint.activate([
            reviewsTableView.topAnchor.constraint(equalTo: reviewsHeaderRow.bottomAnchor, constant: 12),
            reviewsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            reviewsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            reviewsTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }

    // MARK: Configure UI
    func configure(with model: PhysiotherapistProfileModel) {
        nameLabel.text = model.name
        ratingLabel.text = model.ratingText
        servicePlaceLabel.text = model.servicePlaceText


        specValue.text = model.specializationText
        feeValue.text = model.consultationFeeText

        patientsLabel.text = model.patientsText
        experienceLabel.text = model.experienceText
        ratingNumLabel.text = model.ratingNumberText
        reviewsCountLabel.text = model.reviewsCountText

        setAboutText(model.about)
    }

    // MARK: About expand/collapse
    func setAboutText(_ text: String) {
        aboutText.text = text
        aboutText.numberOfLines = 3
        aboutCollapsed = true
        aboutMoreButton.setTitle("Read more", for: .normal)
        aboutMoreButton.isHidden = true

        // check truncation after layout has correct width
        needsAboutTruncationCheck = true
        setNeedsLayout()
    }

    private func updateAboutMoreVisibility() {
        aboutMoreButton.isHidden = !aboutText.isTruncated(maxLines: 3)
    }

    func toggleAbout() {
        aboutCollapsed.toggle()
        aboutText.numberOfLines = aboutCollapsed ? 3 : 0
        aboutMoreButton.setTitle(aboutCollapsed ? "Read more" : "Show less", for: .normal)

        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }
}

// MARK: - UILabel truncation helper
private extension UILabel {
    func isTruncated(maxLines: Int) -> Bool {
        guard let text = self.text, let font = self.font else { return false }
        let width = bounds.width
        if width <= 0 { return false }

        let fullHeight = text.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).height

        let maxHeight = CGFloat(maxLines) * font.lineHeight
        return fullHeight > maxHeight + 2
    }
}
