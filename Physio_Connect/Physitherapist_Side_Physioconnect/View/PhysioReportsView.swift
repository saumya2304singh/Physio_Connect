//
//  PhysioReportsView.swift
//  Physio_Connect
//
//  Created by Codex on 21/01/26.
//

import UIKit

final class PhysioReportsView: UIView {
    struct PatientVM {
        let id: UUID
        let name: String
        let age: String
        let location: String
        let contact: String
        let programs: [String]
        let lastInteractionText: String
    }

    let tableView = UITableView(frame: .zero, style: .plain)
    let searchBar = UISearchBar()
    let refreshControl = UIRefreshControl()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let statsStack = UIStackView()
    private let patientsStat = ReportStatView()
    private let programsStat = ReportStatView()
    private let assignmentsStat = ReportStatView()
    private let emptyLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        backgroundColor = UIColor(hex: "E6F1FF")

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Reports"
        titleLabel.font = .systemFont(ofSize: 30, weight: .bold)
        titleLabel.textColor = UIColor(hex: "102A43")

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Monitor every patient assigned to you and the programs they’re following."
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        subtitleLabel.textColor = UIColor.black.withAlphaComponent(0.55)
        subtitleLabel.numberOfLines = 0

        statsStack.translatesAutoresizingMaskIntoConstraints = false
        statsStack.axis = .horizontal
        statsStack.spacing = 12
        statsStack.distribution = .fillEqually
        statsStack.addArrangedSubview(patientsStat)
        statsStack.addArrangedSubview(programsStat)
        statsStack.addArrangedSubview(assignmentsStat)

        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search patients or programs..."
        searchBar.backgroundImage = UIImage()

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 220
        tableView.register(ReportPatientCell.self, forCellReuseIdentifier: ReportPatientCell.reuseID)
        tableView.refreshControl = refreshControl

        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = "No patients linked yet.\nAssign a program to see their summary here."
        emptyLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        emptyLabel.textColor = UIColor.black.withAlphaComponent(0.55)
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        emptyLabel.isUserInteractionEnabled = false

        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(statsStack)
        addSubview(searchBar)
        addSubview(tableView)
        addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            statsStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 14),
            statsStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            statsStack.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            statsStack.heightAnchor.constraint(equalToConstant: 100),

            searchBar.topAnchor.constraint(equalTo: statsStack.bottomAnchor, constant: 12),
            searchBar.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            emptyLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40)
        ])
    }

    func setStats(totalPatients: Int, activePrograms: Int, assignments: Int) {
        patientsStat.configure(title: "Assigned Patients", value: totalPatients)
        programsStat.configure(title: "Active Programs", value: activePrograms)
        assignmentsStat.configure(title: "Total Assignments", value: assignments)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let compact = bounds.width < 380
        statsStack.axis = compact ? .vertical : .horizontal
        statsStack.distribution = compact ? .fillEqually : .fillEqually
    }

    func showEmptyState(_ show: Bool) {
        emptyLabel.isHidden = !show
        if show { bringSubviewToFront(emptyLabel) }
    }
}

private final class ReportStatView: UIView {
    private let valueLabel = UILabel()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.white
        layer.cornerRadius = 14
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 4)

        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = .systemFont(ofSize: 26, weight: .bold)
        valueLabel.textColor = UIColor(hex: "1E6EF7")

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.6)
        titleLabel.numberOfLines = 2

        addSubview(valueLabel)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),

            titleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: valueLabel.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: valueLabel.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, value: Int) {
        titleLabel.text = title
        valueLabel.text = "\(value)"
    }
}

final class ReportPatientCell: UITableViewCell {
    static let reuseID = "ReportPatientCell"

    private let card = UIView()
    private let nameLabel = UILabel()
    private let agePill = UILabel()
    private let locationLabel = UILabel()
    private let contactLabel = UILabel()
    private let programStack = UIStackView()
    private let lastInteractionLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        build()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        selectionStyle = .none
        backgroundColor = .clear

        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowRadius = 10
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        contentView.addSubview(card)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 17, weight: .bold)
        nameLabel.textColor = UIColor(hex: "102A43")

        agePill.translatesAutoresizingMaskIntoConstraints = false
        agePill.font = .systemFont(ofSize: 12, weight: .semibold)
        agePill.textColor = UIColor(hex: "1E6EF7")
        agePill.backgroundColor = UIColor(hex: "E6F1FF")
        agePill.textAlignment = .center
        agePill.layer.cornerRadius = 12
        agePill.clipsToBounds = true
        agePill.setContentHuggingPriority(.required, for: .horizontal)

        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.font = .systemFont(ofSize: 13, weight: .medium)
        locationLabel.textColor = UIColor.black.withAlphaComponent(0.7)
        locationLabel.numberOfLines = 0

        contactLabel.translatesAutoresizingMaskIntoConstraints = false
        contactLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        contactLabel.textColor = UIColor(hex: "1E6EF7")
        contactLabel.numberOfLines = 0

        programStack.translatesAutoresizingMaskIntoConstraints = false
        programStack.axis = .vertical
        programStack.spacing = 6

        lastInteractionLabel.translatesAutoresizingMaskIntoConstraints = false
        lastInteractionLabel.font = .systemFont(ofSize: 12, weight: .medium)
        lastInteractionLabel.textColor = UIColor.black.withAlphaComponent(0.55)

        card.addSubview(nameLabel)
        card.addSubview(agePill)
        card.addSubview(locationLabel)
        card.addSubview(contactLabel)
        card.addSubview(programStack)
        card.addSubview(lastInteractionLabel)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: agePill.leadingAnchor, constant: -10),

            agePill.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            agePill.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            agePill.heightAnchor.constraint(equalToConstant: 24),
            agePill.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),

            locationLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            locationLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            locationLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),

            contactLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 6),
            contactLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            contactLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),

            programStack.topAnchor.constraint(equalTo: contactLabel.bottomAnchor, constant: 10),
            programStack.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            programStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),

            lastInteractionLabel.topAnchor.constraint(equalTo: programStack.bottomAnchor, constant: 10),
            lastInteractionLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            lastInteractionLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            lastInteractionLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        programStack.arrangedSubviews.forEach { view in
            programStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    func apply(_ vm: PhysioReportsView.PatientVM) {
        nameLabel.text = vm.name
        let ageValue = vm.age.trimmingCharacters(in: .whitespacesAndNewlines)
        agePill.isHidden = ageValue.isEmpty || ageValue == "—"
        agePill.text = ageValue.isEmpty ? nil : "  \(ageValue)  "

        locationLabel.text = "Location • \(vm.location)"
        contactLabel.text = "Contact • \(vm.contact)"
        lastInteractionLabel.text = vm.lastInteractionText

        addProgramChips(vm.programs)
    }

    private func addProgramChips(_ programs: [String]) {
        if programs.isEmpty {
            let label = UILabel()
            label.font = .systemFont(ofSize: 13, weight: .medium)
            label.textColor = UIColor.black.withAlphaComponent(0.5)
            label.text = "No programs assigned yet."
            programStack.addArrangedSubview(label)
            return
        }

        let maxVisible = 3
        for title in programs.prefix(maxVisible) {
            programStack.addArrangedSubview(makeChip(text: title))
        }
        if programs.count > maxVisible {
            programStack.addArrangedSubview(makeChip(text: "+\(programs.count - maxVisible) more", isMuted: true))
        }
    }

    private func makeChip(text: String, isMuted: Bool = false) -> UIView {
        let label = PaddingLabel(insets: UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10))
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = isMuted ? UIColor.black.withAlphaComponent(0.55) : UIColor(hex: "1E6EF7")
        label.backgroundColor = isMuted ? UIColor(hex: "EEF2F7") : UIColor(hex: "E6F1FF")
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        return label
    }
}

private final class PaddingLabel: UILabel {
    private let insets: UIEdgeInsets

    init(insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right,
                      height: size.height + insets.top + insets.bottom)
    }
}
