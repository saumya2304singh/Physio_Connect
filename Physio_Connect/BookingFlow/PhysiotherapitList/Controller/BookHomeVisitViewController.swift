//
//  BookHomeVisitViewController.swift
//  Physio_Connect
//
//  Created by user@8 on 31/12/25.
//
//
//  BookHomeVisitViewController.swift
//  Physio_Connect
//

import UIKit

final class BookHomeVisitViewController: UIViewController {

    private let bookView = BookHomeVisitView()
    private let physioID: UUID

    private var physioNameForSummary: String?
    private var slots: [SlotRow] = []
    private var selectedSlot: SlotRow?
    private var bookingConfirmedOverlay: BookingConfirmedOverlayView?

    // MARK: - Init
    init(physioID: UUID) {
        self.physioID = physioID
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() { view = bookView }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(true, animated: false)

        // Actions
        bookView.backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        bookView.confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        bookView.calendarButton.addTarget(self, action: #selector(calendarTapped), for: .touchUpInside)

        // Date picker
        bookView.datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        // ✅ Disable past dates (today onwards only)
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        bookView.datePicker.minimumDate = todayStart
        bookView.setDate(bookView.datePicker.date)

        // TextView placeholder behaviour
        bookView.instructionsTextView.delegate = self

        // Live summary updates
        bookView.addressField.addTarget(self, action: #selector(addressChanged), for: .editingChanged)

        // Fetch
        fetchPhysioHeader()
        fetchSlots(for: bookView.datePicker.date)

        // Initial summary
        bookView.updateAppointmentSummary(
            doctorName: nil,
            date: bookView.datePicker.date,
            time: nil,
            address: nil
        )
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func calendarTapped() {
        bookView.toggleDatePickerVisible()
    }

    @objc private func dateChanged() {
        // reset selection
        selectedSlot = nil
        bookView.setDate(bookView.datePicker.date)
        bookView.setSelectedTimeText(nil)

        // update summary
        bookView.updateAppointmentSummary(
            doctorName: physioNameForSummary,
            date: bookView.datePicker.date,
            time: nil,
            address: bookView.addressField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        fetchSlots(for: bookView.datePicker.date)
    }

    @objc private func addressChanged() {
        bookView.updateAppointmentSummary(
            doctorName: physioNameForSummary,
            date: bookView.datePicker.date,
            time: selectedSlotTimeText(),
            address: bookView.addressField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    // MARK: - Fetch Doctor (Name/Spec/Rating/Fee)
    private func fetchPhysioHeader() {
        Task {
            do {
                async let p = PhysioService.shared.fetchPhysiotherapist(by: physioID)
                async let specs = PhysioService.shared.fetchSpecializationNames(for: physioID)

                let physio = try await p
                let specNames = (try? await specs) ?? []
                let spec = specNames.first ?? "Physiotherapy specialist"

                let fee = Int(physio.consultation_fee ?? 0)
                let feeText = "₹\(fee)/hr"

                let avg = physio.avg_rating ?? 0
                let count = physio.reviews_count ?? 0
                let ratingText = "⭐️ \(String(format: "%.1f", avg)) | \(count) reviews"

                await MainActor.run {
                    self.physioNameForSummary = physio.name

                    self.bookView.setPhysio(
                        name: physio.name,
                        spec: spec,
                        rating: ratingText,
                        fee: feeText
                    )

                    self.bookView.updateAppointmentSummary(
                        doctorName: physio.name,
                        date: self.bookView.datePicker.date,
                        time: self.selectedSlotTimeText(),
                        address: self.bookView.addressField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                }

            } catch {
                print("❌ fetchPhysioHeader error:", error)
            }
        }
    }

    // MARK: - Fetch Slots from physio_availability_slots
    private func fetchSlots(for date: Date) {
        Task {
            do {
                let rows = try await PhysioService.shared.fetchUpcomingAvailableSlots(
                    physioID: physioID,
                    from: Date(),
                    limit: 20
                )
                print("🧠 Physio ID:", physioID)
                print("🕒 Available slots fetched:", rows.count)

                await MainActor.run {
                    self.slots = rows
                    self.renderSlots()
                }
            } catch {
                print("❌ fetchSlots error:", error)
                await MainActor.run {
                    self.slots = []
                    self.renderSlots()
                }
            }
        }
    }

    private func renderSlots() {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"

        let vms: [BookHomeVisitView.SlotVM] = slots.map {
            .init(id: $0.id, title: fmt.string(from: $0.start_time), isBooked: $0.is_booked)
        }

        bookView.renderSlots(vms, selectedID: selectedSlot?.id) { [weak self] tappedID in
            guard let self else { return }
            guard let slot = self.slots.first(where: { $0.id == tappedID }),
                  slot.is_booked == false else { return }

            self.selectedSlot = slot
            self.bookView.setSelectedTimeText(fmt.string(from: slot.start_time))

            self.bookView.updateAppointmentSummary(
                doctorName: self.physioNameForSummary,
                date: self.bookView.datePicker.date,
                time: fmt.string(from: slot.start_time),
                address: self.bookView.addressField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            self.renderSlots()
        }
    }

    private func selectedSlotTimeText() -> String? {
        guard let s = selectedSlot else { return nil }
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return fmt.string(from: s.start_time)
    }

    // MARK: - Confirm: insert appointment + mark slot booked
    @objc private func confirmTapped() {

        guard let slot = selectedSlot else {
            showAlert("Select a time slot", "Please choose an available time slot to proceed.")
            return
        }

        let address = bookView.addressField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let phone = bookView.phoneField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let rawNotes = bookView.instructionsTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let notesIsPlaceholder = (bookView.instructionsTextView.textColor == .lightGray)
        let notes = (notesIsPlaceholder || rawNotes.isEmpty) ? nil : rawNotes

        if address.isEmpty {
            showAlert("Missing address", "Please enter your home address.")
            return
        }
        if phone.isEmpty {
            showAlert("Missing phone number", "Please enter a contact number.")
            return
        }

        Task {
            do {
                // ✅ Proper way to get logged-in user UUID
                let session = try await SupabaseManager.shared.client.auth.session
                let userUUID = session.user.id

                // ✅ Match your appointments table columns (based on your schema screenshot)
                struct AppointmentPayload: Encodable {
                    let customerID: UUID
                    let physioID: UUID
                    let slotID: UUID
                    let serviceMode: String
                    let addressText: String
                    let contactPhone: String
                    let instructions: String?
                    let status: String

                    enum CodingKeys: String, CodingKey {
                        case customerID = "customer_id"
                        case physioID = "physio_id"
                        case slotID = "slot_id"
                        case serviceMode = "service_mode"
                        case addressText = "address_text"
                        case contactPhone = "contact_phone"
                        case instructions
                        case status
                    }
                }

                let payload = AppointmentPayload(
                    customerID: userUUID,
                    physioID: physioID,
                    slotID: slot.id,
                    serviceMode: "home",
                    addressText: address,
                    contactPhone: phone,
                    instructions: notes,
                    status: "booked"
                )

                // 1) insert appointment
                _ = try await SupabaseManager.shared.client
                    .from("appointments")
                    .insert(payload)
                    .execute()

                // 2) mark slot booked
                try await PhysioService.shared.markSlotBooked(slotID: slot.id)

                await MainActor.run {
                    // Show a proper booking confirmed popup (instead of a basic alert)
                    self.presentBookingConfirmedPopup()
                }

                // 3) refresh slots
                fetchSlots(for: bookView.datePicker.date)

            } catch {
                print("❌ confirmTapped booking error:", error)
                await MainActor.run {
                    self.showAlert("Booking failed", "Please try again.")
                }
            }
        }
    }

    // MARK: - Booking Confirmed Popup
    private func presentBookingConfirmedPopup() {
        // Prevent duplicates
        bookingConfirmedOverlay?.removeFromSuperview()

        let overlay = BookingConfirmedOverlayView()
        overlay.translatesAutoresizingMaskIntoConstraints = false

        // Compose details
        let df = DateFormatter()
        df.dateFormat = "dd MMM yyyy"
        let tf = DateFormatter()
        tf.dateFormat = "h:mm a"

        let doctor = physioNameForSummary ?? "Physiotherapist"
        let dateText = df.string(from: bookView.datePicker.date)
        let timeText = selectedSlot.map { tf.string(from: $0.start_time) } ?? "--"

        overlay.configure(
            title: "Booking Confirmed",
            message: "Your home visit has been booked successfully.",
            detailLine1: "Doctor: \(doctor)",
            detailLine2: "When: \(dateText) · \(timeText)"
        )

        overlay.onPrimaryTap = { [weak self] in
            guard let self else { return }
            self.dismissBookingConfirmedPopup(popToRoot: true)
        }

        overlay.onSecondaryTap = { [weak self] in
            guard let self else { return }
            self.dismissBookingConfirmedPopup(popToRoot: false)
        }

        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        bookingConfirmedOverlay = overlay
        overlay.animateIn()
    }

    private func dismissBookingConfirmedPopup(popToRoot: Bool) {
        guard let overlay = bookingConfirmedOverlay else { return }
        overlay.animateOut { [weak self] in
            overlay.removeFromSuperview()
            self?.bookingConfirmedOverlay = nil
            if popToRoot {
                self?.navigationController?.popToRootViewController(animated: true)
            }
        }
    }

    private final class BookingConfirmedOverlayView: UIView {

        var onPrimaryTap: (() -> Void)?
        var onSecondaryTap: (() -> Void)?

        private let dimView = UIView()
        private let card = UIView()

        private let iconCircle = UIView()
        private let iconView = UIImageView()

        private let titleLabel = UILabel()
        private let messageLabel = UILabel()
        private let detail1Label = UILabel()
        private let detail2Label = UILabel()

        private let primaryButton = UIButton(type: .system)
        private let secondaryButton = UIButton(type: .system)

        override init(frame: CGRect) {
            super.init(frame: frame)
            build()
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        func configure(title: String, message: String, detailLine1: String, detailLine2: String) {
            titleLabel.text = title
            messageLabel.text = message
            detail1Label.text = detailLine1
            detail2Label.text = detailLine2
        }

        private func build() {
            // Dim background
            dimView.translatesAutoresizingMaskIntoConstraints = false
            dimView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
            addSubview(dimView)

            // Card
            card.translatesAutoresizingMaskIntoConstraints = false
            card.backgroundColor = .white
            card.layer.cornerRadius = 18
            card.layer.shadowColor = UIColor.black.cgColor
            card.layer.shadowOpacity = 0.12
            card.layer.shadowRadius = 18
            card.layer.shadowOffset = CGSize(width: 0, height: 10)
            addSubview(card)

            // Icon
            iconCircle.translatesAutoresizingMaskIntoConstraints = false
            iconCircle.backgroundColor = UIColor(hex: "1E6EF7")
            iconCircle.layer.cornerRadius = 26

            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconView.image = UIImage(systemName: "checkmark")
            iconView.tintColor = .white
            iconView.contentMode = .scaleAspectFit

            iconCircle.addSubview(iconView)

            // Text
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.font = .boldSystemFont(ofSize: 20)
            titleLabel.textAlignment = .center

            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            messageLabel.font = .systemFont(ofSize: 14, weight: .medium)
            messageLabel.textColor = UIColor.black.withAlphaComponent(0.65)
            messageLabel.textAlignment = .center
            messageLabel.numberOfLines = 0

            detail1Label.translatesAutoresizingMaskIntoConstraints = false
            detail1Label.font = .systemFont(ofSize: 14, weight: .semibold)
            detail1Label.textAlignment = .center
            detail1Label.numberOfLines = 0

            detail2Label.translatesAutoresizingMaskIntoConstraints = false
            detail2Label.font = .systemFont(ofSize: 13, weight: .medium)
            detail2Label.textColor = UIColor.black.withAlphaComponent(0.65)
            detail2Label.textAlignment = .center
            detail2Label.numberOfLines = 0

            // Buttons
            primaryButton.translatesAutoresizingMaskIntoConstraints = false
            primaryButton.setTitle("Done", for: .normal)
            primaryButton.setTitleColor(.white, for: .normal)
            primaryButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
            primaryButton.backgroundColor = UIColor(hex: "1E6EF7")
            primaryButton.layer.cornerRadius = 14
            primaryButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
            primaryButton.addAction(UIAction(handler: { [weak self] _ in
                self?.onPrimaryTap?()
            }), for: .touchUpInside)

            secondaryButton.translatesAutoresizingMaskIntoConstraints = false
            secondaryButton.setTitle("Stay Here", for: .normal)
            secondaryButton.setTitleColor(UIColor(hex: "1E6EF7"), for: .normal)
            secondaryButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            secondaryButton.backgroundColor = UIColor.black.withAlphaComponent(0.04)
            secondaryButton.layer.cornerRadius = 14
            secondaryButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
            secondaryButton.addAction(UIAction(handler: { [weak self] _ in
                self?.onSecondaryTap?()
            }), for: .touchUpInside)

            let buttonStack = UIStackView(arrangedSubviews: [primaryButton, secondaryButton])
            buttonStack.axis = .vertical
            buttonStack.spacing = 10
            buttonStack.translatesAutoresizingMaskIntoConstraints = false

            let contentStack = UIStackView(arrangedSubviews: [iconCircle, titleLabel, messageLabel, detail1Label, detail2Label, buttonStack])
            contentStack.axis = .vertical
            contentStack.spacing = 10
            contentStack.alignment = .fill
            contentStack.translatesAutoresizingMaskIntoConstraints = false

            card.addSubview(contentStack)

            NSLayoutConstraint.activate([
                dimView.topAnchor.constraint(equalTo: topAnchor),
                dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
                dimView.trailingAnchor.constraint(equalTo: trailingAnchor),
                dimView.bottomAnchor.constraint(equalTo: bottomAnchor),

                card.centerXAnchor.constraint(equalTo: centerXAnchor),
                card.centerYAnchor.constraint(equalTo: centerYAnchor),
                card.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
                card.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24),
                card.widthAnchor.constraint(lessThanOrEqualToConstant: 380),

                iconCircle.heightAnchor.constraint(equalToConstant: 52),
                iconCircle.widthAnchor.constraint(equalToConstant: 52),

                iconView.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor),
                iconView.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: 22),
                iconView.heightAnchor.constraint(equalToConstant: 22),

                contentStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
                contentStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
                contentStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
                contentStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
            ])

            // Allow tap outside to dismiss (secondary action)
            let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
            dimView.addGestureRecognizer(tap)

            // Start hidden for animation
            alpha = 0
            card.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }

        @objc private func backgroundTapped() {
            onSecondaryTap?()
        }

        func animateIn() {
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut]) {
                self.alpha = 1
                self.card.transform = .identity
            }
        }

        func animateOut(completion: @escaping () -> Void) {
            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseIn]) {
                self.alpha = 0
                self.card.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            } completion: { _ in
                completion()
            }
        }
    }

    private func showAlert(_ title: String, _ message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - UITextView placeholder handling
extension BookHomeVisitViewController: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = ""
            textView.textColor = .darkGray
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        let t = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty {
            textView.textColor = .lightGray
            textView.text = "Special instructions (parking, floor, access etc.)"
        }
    }
}
