//
//  AppointmentsViewController.swift
//  Physio_Connect
//
//  Created by user@8 on 02/01/26.
//

import UIKit

final class AppointmentsViewController: UIViewController {

    private let apptView = AppointmentsView()
    private let model = AppointmentsModel()

    private var currentUpcoming: UpcomingAppointment?
    private var isCancelling = false
    private var isRefreshing = false

    override func loadView() { view = apptView }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(true, animated: false)

        bind()
        Task { await refreshAll() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await refreshAll() }
    }

    private func bind() {
        apptView.onProfileTapped = { [weak self] in
            guard let self else { return }
            print("Profile tapped")
        }

        apptView.onCancelTapped = { [weak self] in
            guard let self else { return }
            guard let appt = self.currentUpcoming, !self.isCancelling else { return }
            self.isCancelling = true
            self.apptView.setCancelEnabled(false)
            self.currentUpcoming = nil
            self.apptView.setUpcoming(nil)
            Task {
                do {
                    try await self.model.cancelAppointment(appointmentID: appt.appointmentID)
                    await self.refreshAll()
                } catch {
                    print("❌ Cancel failed:", error)
                    await MainActor.run {
                        self.isCancelling = false
                        self.apptView.setCancelEnabled(true)
                    }
                }
                await MainActor.run {
                    self.isCancelling = false
                    self.apptView.setCancelEnabled(true)
                }
            }
        }

        apptView.onRescheduleTapped = { [weak self] in
            guard let self else { return }
            guard let physioID = self.currentUpcoming?.physioID else { return }

            let vc = PhysiotherapistProfileViewController(physioID: physioID, preloadCard: nil, isReschedule: true)
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }

        apptView.onBookTapped = { [weak self] in
            guard let self else { return }
            let vc = PhysiotherapistListViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        }

        // ✅ Completed list actions (per-row)
        apptView.onCompletedRebookTapped = { [weak self] vm in
            guard let self else { return }
            let vc = PhysiotherapistProfileViewController(physioID: vm.physioID, preloadCard: nil)
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }

        apptView.onCompletedReportTapped = { vm in
            print("View report tapped for:", vm.physioName)
        }
    }

    private func refreshAll() async {
        if isRefreshing { return }
        isRefreshing = true
        defer {
            Task { @MainActor in
                self.isRefreshing = false
            }
        }
        do {
            async let upcoming = model.fetchUpcomingAppointment()
            async let past = model.fetchPastAppointments()

            let upcomingResult = try await upcoming
            let pastResult = try await past

            await MainActor.run {
                self.currentUpcoming = upcomingResult
                self.applyUpcoming(upcomingResult)
                self.applyPast(pastResult)
            }
        } catch {
            print("❌ Appointments fetch error:", error)
            await MainActor.run {
                self.currentUpcoming = nil
                self.apptView.setUpcoming(nil)
                self.apptView.setCompleted([])
            }
        }
    }

    // MARK: - Mapping to your View VMs

    private func applyUpcoming(_ appt: UpcomingAppointment?) {
        guard let appt else {
            apptView.setUpcoming(nil)   // hides the card ✅
            return
        }

        // ✅ If backend returned incomplete rows, hide card instead of showing an empty card
        if appt.physioName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            apptView.setUpcoming(nil)
            return
        }

        let df = DateFormatter()
        df.dateFormat = "MMMM d, yyyy - h:mm a"

        let ratingText: String = {
            let r = appt.rating ?? 0
            let c = appt.reviewsCount ?? 0
            return "⭐️ \(String(format: "%.1f", r))   ·   \(c) reviews"
        }()

        let distanceText = appt.locationText != nil
        ? "📍 \(appt.locationText!)"
        : "📍 Nearby"

        let feeText: String = {
            if let fee = appt.fee {
                return "Consultation fees: ₹\(Int(fee)) / hr"
            }
            return "Consultation fees: --"
        }()

        let vm = AppointmentsView.UpcomingCardVM(
            dateTimeText: df.string(from: appt.startTime),
            physioName: appt.physioName,
            ratingText: ratingText,
            distanceText: distanceText,
            specializationText: appt.specialization,
            feeText: feeText,
            image: nil
        )

        apptView.setUpcoming(vm)
    }


    private func applyPast(_ past: [PastAppointment]) {
        let vms: [CompletedAppointmentVM] = past.map { item in
            let status: CompletedAppointmentVM.Status =
            item.status.lowercased() == "cancelled" ? .cancelled : .completed

            let ratingText: String = {
                let r = item.rating ?? 0
                let c = item.reviewsCount ?? 0
                return "⭐️ \(String(format: "%.1f", r))   ·   \(c) reviews"
            }()

            let distanceText = item.locationText != nil
            ? "📍 \(item.locationText!)"
            : "📍 Nearby"

            let feeText: String = {
                if let fee = item.fee {
                    return "Consultation fees: ₹\(Int(fee)) / hr"
                }
                return "Consultation fees: --"
            }()

            return CompletedAppointmentVM(
                appointmentID: item.appointmentID,
                physioID: item.physioID,
                status: status,
                physioName: item.physioName,
                ratingText: ratingText,
                distanceText: distanceText,
                specializationText: item.specialization,
                feeText: feeText,
                image: nil
            )
        }
        var unique: [UUID: CompletedAppointmentVM] = [:]
        for vm in vms {
            if unique[vm.appointmentID] == nil {
                unique[vm.appointmentID] = vm
            }
        }
        apptView.setCompleted(Array(unique.values))
    }
}
