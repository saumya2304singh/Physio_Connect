//
//  PhysioHomeView.swift
//  Physio_Connect
//
//  Created by Codex on 08/01/26.
//

import UIKit

final class PhysioHomeView: UIView {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let headerStack = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let statsStack = UIStackView()
    private let sessionsCard = StatCardView()
    private let tasksCard = StatCardView()

    private let upcomingTitle = UILabel()
    private let upcomingCard = UpcomingSessionCard()

    private let actionsTitle = UILabel()
    let actionsStack = UIStackView()
    let addSessionButton = UIButton(type: .system)
    let addNoteButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hex: "E3F0FF")
        build()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill
        scrollView.addSubview(contentStack)

        headerStack.axis = .vertical
        headerStack.spacing = 6
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        statsStack.axis = .horizontal
        statsStack.spacing = 12
        statsStack.distribution = .fillEqually
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        statsStack.addArrangedSubview(sessionsCard)
        statsStack.addArrangedSubview(tasksCard)
        
        // Header (centered)
        titleLabel.text = "Dashboard"
        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = UIColor(hex: "102A43")
        titleLabel.textAlignment = .center

        subtitleLabel.text = "Track sessions, patients, and tasks at a glance."
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        subtitleLabel.textColor = UIColor.black.withAlphaComponent(0.55)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center

        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(subtitleLabel)
        contentStack.addArrangedSubview(headerStack)
        contentStack.addArrangedSubview(statsStack)

        upcomingTitle.text = "Upcoming Session"
        upcomingTitle.font = .systemFont(ofSize: 18, weight: .bold)
        upcomingTitle.textColor = UIColor(hex: "102A43")
        contentStack.addArrangedSubview(upcomingTitle)
        contentStack.addArrangedSubview(upcomingCard)

        actionsTitle.text = "Quick Actions"
        actionsTitle.font = .systemFont(ofSize: 18, weight: .bold)
        actionsTitle.textColor = UIColor(hex: "102A43")
        contentStack.addArrangedSubview(actionsTitle)

        actionsStack.axis = .horizontal
        actionsStack.spacing = 12
        actionsStack.distribution = .fillEqually
        actionsStack.translatesAutoresizingMaskIntoConstraints = false

        configureActionButton(addSessionButton, title: "New Session", systemName: "plus")
        configureActionButton(addNoteButton, title: "Add Note", systemName: "square.and.pencil")
        actionsStack.addArrangedSubview(addSessionButton)
        actionsStack.addArrangedSubview(addNoteButton)
        contentStack.addArrangedSubview(actionsStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),

            upcomingCard.heightAnchor.constraint(equalToConstant: 140),
            addSessionButton.heightAnchor.constraint(equalToConstant: 54),
            addNoteButton.heightAnchor.constraint(equalTo: addSessionButton.heightAnchor)
        ])
    }

    private func configureActionButton(_ button: UIButton, title: String, systemName: String) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.backgroundColor = UIColor(hex: "1E6EF7")
        button.layer.cornerRadius = 14
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.08
        button.layer.shadowRadius = 8
        button.layer.shadowOffset = CGSize(width: 0, height: 4)

        let icon = UIImage(systemName: systemName)
        button.setImage(icon, for: .normal)
        button.tintColor = .white
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -6, bottom: 0, right: 6)
    }

    func setSummary(todaySessions: Int, pendingTasks: Int) {
        sessionsCard.configure(title: "Today’s Sessions", value: "\(todaySessions)")
        tasksCard.configure(title: "Pending Tasks", value: "\(pendingTasks)")
    }

    func setUpcoming(sessionTitle: String, patient: String, time: String, location: String) {
        upcomingCard.configure(title: sessionTitle, patient: patient, time: time, location: location)
    }

    func setAvatar(urlString: String?) { /* header avatar removed by design */ }
}

private final class StatCardView: UIView {
    private let valueLabel = UILabel()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 6)

        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = .systemFont(ofSize: 28, weight: .bold)
        valueLabel.textColor = UIColor(hex: "1E6EF7")

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.6)

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

    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }
}

private final class UpcomingSessionCard: UIView {
    private let titleLabel = UILabel()
    private let patientLabel = UILabel()
    private let timeLabel = UILabel()
    private let locationLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 6)

        [titleLabel, patientLabel, timeLabel, locationLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = UIColor(hex: "102A43")

        patientLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        patientLabel.textColor = UIColor.black.withAlphaComponent(0.75)

        timeLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        timeLabel.textColor = UIColor(hex: "1E6EF7")

        locationLabel.font = .systemFont(ofSize: 13, weight: .regular)
        locationLabel.textColor = UIColor.black.withAlphaComponent(0.6)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),

            patientLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            patientLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            patientLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            timeLabel.topAnchor.constraint(equalTo: patientLabel.bottomAnchor, constant: 6),
            timeLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            locationLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 4),
            locationLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            locationLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            locationLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, patient: String, time: String, location: String) {
        titleLabel.text = title
        patientLabel.text = patient
        timeLabel.text = time
        locationLabel.text = location
    }
}
