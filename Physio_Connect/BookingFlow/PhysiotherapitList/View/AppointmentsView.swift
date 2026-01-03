//
//  AppointmentsView.swift
//  Physio_Connect
//
//  Created by user@8 on 02/01/26.
//

import UIKit

final class AppointmentsView: UIView {

    // MARK: - Callbacks (MVC friendly)
    var onProfileTapped: (() -> Void)?
    var onCancelTapped: (() -> Void)?
    var onRescheduleTapped: (() -> Void)?
    var onBookTapped: (() -> Void)?

    // Completed actions (per row)
    var onCompletedRebookTapped: ((CompletedAppointmentVM) -> Void)?
    var onCompletedReportTapped: ((CompletedAppointmentVM) -> Void)?

    // MARK: - UI
    private let topBar = UIView()
    private let titleLabel = UILabel()
    let profileButton = UIButton(type: .system)

    let segmented = UISegmentedControl(items: ["Upcoming", "Completed"])

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    // Cards (Upcoming tab)
    let upcomingCard = UpcomingAppointmentTabCardView()
    let bookCard = BookHomeVisitsCardView()
    private var hasUpcoming = false

    // Completed list (Completed tab)
    let completedList = CompletedAppointmentsListView()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hex: "E3F0FF")
        build()
        wireActions()
        applyDefaultUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func applyDefaultUI() {
        titleLabel.text = "Appointments"

        segmented.selectedSegmentIndex = 0
        segmented.selectedSegmentTintColor = UIColor(hex: "1E6EF7")
        segmented.backgroundColor = .white
        segmented.layer.cornerRadius = 16
        segmented.layer.masksToBounds = true
        segmented.setTitleTextAttributes(
            [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)],
            for: .selected
        )
        segmented.setTitleTextAttributes(
            [.foregroundColor: UIColor.black.withAlphaComponent(0.65), .font: UIFont.systemFont(ofSize: 14, weight: .semibold)],
            for: .normal
        )

        upcomingCard.isHidden = false
        bookCard.isHidden = false
        completedList.isHidden = true
    }

    private func wireActions() {
        profileButton.addTarget(self, action: #selector(profileTapped), for: .touchUpInside)
        segmented.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        upcomingCard.cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        upcomingCard.rescheduleButton.addTarget(self, action: #selector(rescheduleTapped), for: .touchUpInside)
        bookCard.bookButton.addTarget(self, action: #selector(bookTapped), for: .touchUpInside)

        // completed per-row callbacks
        completedList.onRebookTapped = { [weak self] vm in
            self?.onCompletedRebookTapped?(vm)
        }
        completedList.onReportTapped = { [weak self] vm in
            self?.onCompletedReportTapped?(vm)
        }
    }

    private func build() {
        // Top bar
        topBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topBar)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center

        profileButton.translatesAutoresizingMaskIntoConstraints = false
        profileButton.setImage(UIImage(systemName: "person.circle"), for: .normal)
        profileButton.tintColor = UIColor.black.withAlphaComponent(0.65)

        topBar.addSubview(titleLabel)
        topBar.addSubview(profileButton)

        // Segmented control
        segmented.translatesAutoresizingMaskIntoConstraints = false
        addSubview(segmented)

        // Scroll
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        // Add views into stack
        upcomingCard.translatesAutoresizingMaskIntoConstraints = false
        bookCard.translatesAutoresizingMaskIntoConstraints = false
        completedList.translatesAutoresizingMaskIntoConstraints = false

        contentStack.addArrangedSubview(upcomingCard)
        contentStack.addArrangedSubview(bookCard)
        contentStack.addArrangedSubview(completedList)

        upcomingCard.setContentHuggingPriority(.required, for: .vertical)
        upcomingCard.setContentCompressionResistancePriority(.required, for: .vertical)
        upcomingCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 220).isActive = true

        // Layout
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 6),
            topBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            topBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            topBar.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),

            profileButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor),
            profileButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            profileButton.widthAnchor.constraint(equalToConstant: 34),
            profileButton.heightAnchor.constraint(equalToConstant: 34),

            segmented.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 10),
            segmented.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            segmented.heightAnchor.constraint(equalToConstant: 44),

            scrollView.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 14),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),

            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),

            // completed list gets enough space
            completedList.heightAnchor.constraint(greaterThanOrEqualToConstant: 520)
        ])
    }

    // MARK: - Public API (Controller calls these)

    struct UpcomingCardVM {
        let dateTimeText: String
        let physioName: String
        let ratingText: String
        let distanceText: String
        let specializationText: String
        let feeText: String
        let image: UIImage?
    }

    func setUpcoming(_ vm: UpcomingCardVM?) {
        if let vm {
            hasUpcoming = true
            upcomingCard.isHidden = false
            upcomingCard.apply(vm: vm)
        } else {
            hasUpcoming = false
            upcomingCard.isHidden = true
        }
    }

    func setCancelEnabled(_ enabled: Bool) {
        upcomingCard.cancelButton.isEnabled = enabled
        upcomingCard.cancelButton.alpha = enabled ? 1.0 : 0.6
    }

    func setCompleted(_ items: [CompletedAppointmentVM]) {
        completedList.set(items: items)
    }

    // MARK: - Actions
    @objc private func profileTapped() { onProfileTapped?() }
    @objc private func cancelTapped() { onCancelTapped?() }
    @objc private func rescheduleTapped() { onRescheduleTapped?() }
    @objc private func bookTapped() { onBookTapped?() }

    @objc private func segmentChanged() {
        let isUpcoming = segmented.selectedSegmentIndex == 0

        upcomingCard.isHidden = !(isUpcoming && hasUpcoming)
        bookCard.isHidden = !isUpcoming
        completedList.isHidden = isUpcoming
    }
}

// MARK: - UpcomingAppointmentTabCardView (your working card)

final class UpcomingAppointmentTabCardView: UIView {

    private let container = UIView()
    private let dateLabel = UILabel()

    private let cardRow = UIStackView()
    private let avatar = UIImageView()

    private let infoStack = UIStackView()
    private let nameLabel = UILabel()

    private let ratingRow = UILabel()
    private let distanceRow = UILabel()
    private let specRow = UILabel()
    private let feeRow = UILabel()

    private let buttonsRow = UIStackView()
    let cancelButton = UIButton(type: .system)
    let rescheduleButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        translatesAutoresizingMaskIntoConstraints = false

        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        container.layer.cornerRadius = 18
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.06
        container.layer.shadowRadius = 10
        container.layer.shadowOffset = CGSize(width: 0, height: 6)
        addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        dateLabel.textColor = UIColor.black.withAlphaComponent(0.7)

        cardRow.axis = .horizontal
        cardRow.alignment = .top
        cardRow.spacing = 12
        cardRow.translatesAutoresizingMaskIntoConstraints = false

        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 10
        avatar.backgroundColor = UIColor.black.withAlphaComponent(0.06)
        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: 76),
            avatar.heightAnchor.constraint(equalToConstant: 76)
        ])

        infoStack.axis = .vertical
        infoStack.spacing = 6
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .systemFont(ofSize: 16, weight: .bold)
        nameLabel.textColor = UIColor(hex: "1E2A44")

        [ratingRow, distanceRow, specRow, feeRow].forEach {
            $0.font = .systemFont(ofSize: 13, weight: .semibold)
            $0.textColor = UIColor.black.withAlphaComponent(0.65)
            $0.numberOfLines = 1
        }

        specRow.textColor = UIColor(hex: "1E6EF7")
        feeRow.textColor = UIColor(hex: "1E6EF7")

        infoStack.addArrangedSubview(nameLabel)
        infoStack.addArrangedSubview(specRow)
        infoStack.addArrangedSubview(ratingRow)
        infoStack.addArrangedSubview(distanceRow)
        infoStack.addArrangedSubview(feeRow)

        cardRow.addArrangedSubview(avatar)
        cardRow.addArrangedSubview(infoStack)

        buttonsRow.axis = .horizontal
        buttonsRow.spacing = 12
        buttonsRow.distribution = .fillEqually
        buttonsRow.translatesAutoresizingMaskIntoConstraints = false

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.backgroundColor = UIColor.systemRed
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.layer.cornerRadius = 14
        cancelButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        cancelButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

        rescheduleButton.setTitle("Reschedule", for: .normal)
        rescheduleButton.backgroundColor = UIColor(hex: "1E6EF7")
        rescheduleButton.setTitleColor(.white, for: .normal)
        rescheduleButton.layer.cornerRadius = 14
        rescheduleButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        rescheduleButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

        buttonsRow.addArrangedSubview(cancelButton)
        buttonsRow.addArrangedSubview(rescheduleButton)

        container.addSubview(dateLabel)
        container.addSubview(cardRow)
        container.addSubview(buttonsRow)

        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            dateLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            dateLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),

            cardRow.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 12),
            cardRow.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            cardRow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),

            buttonsRow.topAnchor.constraint(equalTo: cardRow.bottomAnchor, constant: 14),
            buttonsRow.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            buttonsRow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            buttonsRow.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),
        ])
    }

    func apply(vm: AppointmentsView.UpcomingCardVM) {
        dateLabel.text = vm.dateTimeText
        nameLabel.text = vm.physioName
        ratingRow.text = vm.ratingText
        distanceRow.text = vm.distanceText
        specRow.text = vm.specializationText
        feeRow.text = vm.feeText
        if let image = vm.image {
            avatar.image = image
        } else {
            avatar.image = UIImage(systemName: "person.fill")
            avatar.tintColor = UIColor.black.withAlphaComponent(0.25)
        }
    }
}

// MARK: - BookHomeVisitsCardView

final class BookHomeVisitsCardView: UIView {

    private let container = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    let bookButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        translatesAutoresizingMaskIntoConstraints = false

        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        container.layer.cornerRadius = 18
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.06
        container.layer.shadowRadius = 10
        container.layer.shadowOffset = CGSize(width: 0, height: 6)
        addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Book home visits"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = UIColor(hex: "1E2A44")

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Get certified physiotherapy at your doorsteps"
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        subtitleLabel.textColor = UIColor.black.withAlphaComponent(0.6)
        subtitleLabel.numberOfLines = 2

        bookButton.translatesAutoresizingMaskIntoConstraints = false
        bookButton.setTitle("Book appointment", for: .normal)
        bookButton.setTitleColor(.white, for: .normal)
        bookButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        bookButton.backgroundColor = UIColor(hex: "1E6EF7")
        bookButton.layer.cornerRadius = 14
        bookButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)
        container.addSubview(bookButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            bookButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12),
            bookButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            bookButton.widthAnchor.constraint(equalToConstant: 150),
            bookButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
    }
}

// =======================================================
// ✅ COMPLETED SEGMENT UI BELOW
// =======================================================

struct CompletedAppointmentVM {
    enum Status {
        case completed
        case cancelled

        var text: String {
            switch self {
            case .completed: return "Completed"
            case .cancelled: return "Cancelled"
            }
        }

        var pillBg: UIColor {
            switch self {
            case .completed: return UIColor(hex: "E6F5EA")
            case .cancelled: return UIColor(hex: "FCE4E4")
            }
        }

        var pillText: UIColor {
            switch self {
            case .completed: return UIColor(hex: "2E7D32")
            case .cancelled: return UIColor(hex: "E53935")
            }
        }

        var pillBorder: UIColor {
            switch self {
            case .completed: return UIColor(hex: "BFE3C7")
            case .cancelled: return UIColor(hex: "F2B8B8")
            }
        }
    }

    let appointmentID: UUID
    let physioID: UUID
    let status: Status

    let physioName: String
    let ratingText: String
    let distanceText: String
    let specializationText: String
    let feeText: String
    let image: UIImage?
}

final class CompletedAppointmentsListView: UIView, UITableViewDataSource, UITableViewDelegate {

    var onRebookTapped: ((CompletedAppointmentVM) -> Void)?
    var onReportTapped: ((CompletedAppointmentVM) -> Void)?

    private let table = UITableView(frame: .zero, style: .plain)
    private var items: [CompletedAppointmentVM] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        translatesAutoresizingMaskIntoConstraints = false

        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.dataSource = self
        table.delegate = self
        table.showsVerticalScrollIndicator = false
        table.isScrollEnabled = false
        table.register(CompletedAppointmentCell.self, forCellReuseIdentifier: "CompletedAppointmentCell")
        addSubview(table)

        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: topAnchor),
            table.leadingAnchor.constraint(equalTo: leadingAnchor),
            table.trailingAnchor.constraint(equalTo: trailingAnchor),
            table.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func set(items: [CompletedAppointmentVM]) {
        self.items = items
        table.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let vm = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CompletedAppointmentCell", for: indexPath) as! CompletedAppointmentCell
        cell.apply(vm: vm)

        cell.onRebook = { [weak self] in self?.onRebookTapped?(vm) }
        cell.onReport = { [weak self] in self?.onReportTapped?(vm) }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        250
    }
}

final class CompletedAppointmentCell: UITableViewCell {

    var onRebook: (() -> Void)?
    var onReport: (() -> Void)?

    private let card = UIView()

    private let statusPill = UIView()
    private let statusLabel = UILabel()

    private let headerRow = UIStackView()
    private let avatar = UIImageView()

    private let infoStack = UIStackView()
    private let nameLabel = UILabel()
    private let ratingLabel = UILabel()
    private let distanceLabel = UILabel()
    private let specLabel = UILabel()
    private let feeLabel = UILabel()

    private let buttonsRow = UIStackView()
    private let rebookButton = UIButton(type: .system)
    private let reportButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        build()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .white
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowRadius = 10
        card.layer.shadowOffset = CGSize(width: 0, height: 6)
        contentView.addSubview(card)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])

        statusPill.translatesAutoresizingMaskIntoConstraints = false
        statusPill.layer.cornerRadius = 10
        statusPill.layer.borderWidth = 1

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .systemFont(ofSize: 14, weight: .bold)
        statusLabel.textAlignment = .left
        statusLabel.numberOfLines = 1
        statusPill.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: statusPill.topAnchor, constant: 6),
            statusLabel.bottomAnchor.constraint(equalTo: statusPill.bottomAnchor, constant: -6),
            statusLabel.leadingAnchor.constraint(equalTo: statusPill.leadingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: statusPill.trailingAnchor, constant: -12)
        ])

        headerRow.axis = .horizontal
        headerRow.alignment = .top
        headerRow.spacing = 14
        headerRow.translatesAutoresizingMaskIntoConstraints = false

        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.backgroundColor = UIColor.black.withAlphaComponent(0.06)
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 12
        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: 74),
            avatar.heightAnchor.constraint(equalToConstant: 74)
        ])

        infoStack.axis = .vertical
        infoStack.spacing = 6
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .systemFont(ofSize: 16, weight: .bold)
        nameLabel.textColor = UIColor(hex: "1E2A44")

        [ratingLabel, distanceLabel, specLabel].forEach {
            $0.font = .systemFont(ofSize: 13, weight: .semibold)
            $0.textColor = UIColor.black.withAlphaComponent(0.65)
            $0.numberOfLines = 1
        }

        specLabel.textColor = UIColor(hex: "1E6EF7")
        feeLabel.font = .systemFont(ofSize: 13, weight: .bold)
        feeLabel.textColor = UIColor(hex: "1E6EF7")
        feeLabel.numberOfLines = 1

        infoStack.addArrangedSubview(nameLabel)
        infoStack.addArrangedSubview(specLabel)
        infoStack.addArrangedSubview(ratingLabel)
        infoStack.addArrangedSubview(distanceLabel)
        infoStack.addArrangedSubview(feeLabel)

        headerRow.addArrangedSubview(avatar)
        headerRow.addArrangedSubview(infoStack)

        buttonsRow.axis = .horizontal
        buttonsRow.spacing = 14
        buttonsRow.distribution = .fillEqually
        buttonsRow.translatesAutoresizingMaskIntoConstraints = false

        rebookButton.setTitle("Re-book", for: .normal)
        rebookButton.backgroundColor = UIColor(hex: "1E6EF7")
        rebookButton.setTitleColor(.white, for: .normal)
        rebookButton.layer.cornerRadius = 14
        rebookButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        rebookButton.heightAnchor.constraint(equalToConstant: 46).isActive = true
        rebookButton.addTarget(self, action: #selector(rebookTapped), for: .touchUpInside)

        reportButton.setTitle("View Report", for: .normal)
        reportButton.backgroundColor = .white
        reportButton.setTitleColor(UIColor(hex: "1E6EF7"), for: .normal)
        reportButton.layer.cornerRadius = 14
        reportButton.layer.borderWidth = 1
        reportButton.layer.borderColor = UIColor(hex: "1E6EF7").cgColor
        reportButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        reportButton.heightAnchor.constraint(equalToConstant: 46).isActive = true
        reportButton.addTarget(self, action: #selector(reportTapped), for: .touchUpInside)

        buttonsRow.addArrangedSubview(rebookButton)
        buttonsRow.addArrangedSubview(reportButton)

        card.addSubview(statusPill)
        card.addSubview(headerRow)
        card.addSubview(buttonsRow)

        NSLayoutConstraint.activate([
            statusPill.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            statusPill.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            statusPill.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            statusPill.heightAnchor.constraint(equalToConstant: 28),

            headerRow.topAnchor.constraint(equalTo: statusPill.bottomAnchor, constant: 14),
            headerRow.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            headerRow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),

            buttonsRow.topAnchor.constraint(equalTo: headerRow.bottomAnchor, constant: 18),
            buttonsRow.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            buttonsRow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            buttonsRow.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }

    func apply(vm: CompletedAppointmentVM) {
        statusPill.backgroundColor = vm.status.pillBg
        statusLabel.textColor = vm.status.pillText
        statusLabel.text = vm.status.text
        statusPill.layer.borderColor = vm.status.pillBorder.cgColor

        avatar.image = vm.image
        nameLabel.text = vm.physioName
        ratingLabel.text = vm.ratingText
        distanceLabel.text = vm.distanceText
        specLabel.text = vm.specializationText
        feeLabel.text = vm.feeText
    }

    @objc private func rebookTapped() { onRebook?() }
    @objc private func reportTapped() { onReport?() }
}
