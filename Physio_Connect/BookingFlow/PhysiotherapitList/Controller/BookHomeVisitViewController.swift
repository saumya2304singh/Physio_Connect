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
                let rows = try await PhysioService.shared.fetchAvailableSlots(
                    physioID: physioID,
                    forDayContaining: date
                )

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
                    self.showAlert("Booked ✅", "Your home visit has been confirmed.")
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
