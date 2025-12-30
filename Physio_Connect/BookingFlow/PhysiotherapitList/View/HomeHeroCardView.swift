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

    // UI
    private let container = UIView()
    private let imageView = UIImageView()

    private let headingLabel = UILabel()
    private let subLabel = UILabel()
    let primaryButton = UIButton(type: .system)

    // Upcoming details
    private let detailStack = UIStackView()
    private let detailLine1 = UILabel()
    private let detailLine2 = UILabel()
    private let detailLine3 = UILabel()

    private var currentState: State = .bookHomeVisit

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
        apply(state: .bookHomeVisit)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        // Card container style
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        container.layer.cornerRadius = 18
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.08
        container.layer.shadowRadius = 12
        container.layer.shadowOffset = CGSize(width: 0, height: 8)
        addSubview(container)

        // Image
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 14
        imageView.backgroundColor = UIColor.black.withAlphaComponent(0.05)
        container.addSubview(imageView)

        // Text
        headingLabel.font = .boldSystemFont(ofSize: 16)
        headingLabel.textColor = .black
        headingLabel.translatesAutoresizingMaskIntoConstraints = false

        subLabel.font = .systemFont(ofSize: 12, weight: .medium)
        subLabel.textColor = .darkGray
        subLabel.numberOfLines = 2
        subLabel.translatesAutoresizingMaskIntoConstraints = false

        // Button
        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        primaryButton.setTitleColor(.white, for: .normal)
        primaryButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        primaryButton.backgroundColor = UIColor(hex: "1E6EF7")
        primaryButton.layer.cornerRadius = 14
        primaryButton.heightAnchor.constraint(equalToConstant: 38).isActive = true

        // Upcoming details stack (hidden in book state)
        detailStack.axis = .vertical
        detailStack.spacing = 6
        detailStack.translatesAutoresizingMaskIntoConstraints = false

        [detailLine1, detailLine2, detailLine3].forEach {
            $0.font = .systemFont(ofSize: 13, weight: .semibold)
            $0.textColor = UIColor.black.withAlphaComponent(0.75)
            $0.numberOfLines = 0
            detailStack.addArrangedSubview($0)
        }

        container.addSubview(headingLabel)
        container.addSubview(subLabel)
        container.addSubview(primaryButton)
        container.addSubview(detailStack)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor), // ✅ makes self height dynamic

            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            imageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            imageView.widthAnchor.constraint(equalToConstant: 92),
            imageView.heightAnchor.constraint(equalToConstant: 72),

            headingLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
            headingLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            headingLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),

            subLabel.leadingAnchor.constraint(equalTo: headingLabel.leadingAnchor),
            subLabel.trailingAnchor.constraint(equalTo: headingLabel.trailingAnchor),
            subLabel.topAnchor.constraint(equalTo: headingLabel.bottomAnchor, constant: 4),

            primaryButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            primaryButton.topAnchor.constraint(equalTo: subLabel.bottomAnchor, constant: 10),
            primaryButton.widthAnchor.constraint(equalToConstant: 140),

            detailStack.leadingAnchor.constraint(equalTo: headingLabel.leadingAnchor),
            detailStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            detailStack.topAnchor.constraint(equalTo: primaryButton.bottomAnchor, constant: 12),
            detailStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14) // ✅ pushes height
        ])
    }

    func apply(state: State) {
        currentState = state

        switch state {
        case .bookHomeVisit:
            imageView.image = UIImage(named: "home_visit_banner") // optional; can be nil
            headingLabel.text = "Book home visits"
            subLabel.text = "Get certified physiotherapy at your doorsteps"
            primaryButton.setTitle("Book appointment", for: .normal)

            detailStack.isHidden = true

        case .upcoming(let appt):
            imageView.image = UIImage(named: "upcoming_banner") // optional
            headingLabel.text = "Upcoming appointment"
            subLabel.text = "Your booking is confirmed"

            primaryButton.setTitle("View details", for: .normal)
            detailStack.isHidden = false

            let df = DateFormatter()
            df.dateFormat = "dd MMM yyyy • h:mm a"

            detailLine1.text = "Doctor: \(appt.physioName)"
            detailLine2.text = "When: \(df.string(from: appt.startTime))"
            detailLine3.text = "Address: \(appt.address)"
        }

        // Smooth resize animation when state changes
        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
    }
}
