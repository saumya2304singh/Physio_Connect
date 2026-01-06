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
    private var lastUpcoming: UpcomingAppointment?
    private var lastPast: [PastAppointment] = []
    private var physioImages: [String: UIImage] = [:]
    private var isCancelling = false
    private var isRefreshing = false
    private var upcomingTimer: Timer?

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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        upcomingTimer?.invalidate()
        upcomingTimer = nil
    }

    private func bind() {
        apptView.onProfileTapped = { [weak self] in
            guard let self else { return }
            let vc = ProfileViewController()
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
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
                self.lastUpcoming = upcomingResult
                self.lastPast = pastResult
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
        upcomingTimer?.invalidate()
        upcomingTimer = nil
        guard let appt else {
            apptView.setUpcoming(nil)   // hides the card ✅
            return
        }

        guard appt.startTime > Date() else {
            apptView.setUpcoming(nil)
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
                return "₹\(Int(fee)) / hr"
            }
            return "₹ -- / hr"
        }()

        let cacheKey = physioImageKey(id: appt.physioID, version: appt.profileImageVersion)
        let vm = AppointmentsView.UpcomingCardVM(
            dateTimeText: df.string(from: appt.startTime),
            physioName: appt.physioName,
            ratingText: ratingText,
            distanceText: distanceText,
            specializationText: appt.specialization,
            feeText: feeText,
            image: physioImages[cacheKey]
        )

        apptView.setUpcoming(vm)

        if physioImages[cacheKey] == nil,
           let path = appt.profileImagePath,
           let url = PhysioService.shared.profileImageURL(pathOrUrl: path, version: appt.profileImageVersion) {
            ImageLoader.shared.load(url) { [weak self] image in
                guard let self, let image else { return }
                self.physioImages[cacheKey] = image
                if let latest = self.lastUpcoming, latest.physioID == appt.physioID {
                    self.applyUpcoming(latest)
                }
            }
        }

        let interval = appt.startTime.timeIntervalSinceNow
        if interval > 0 {
            upcomingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
                Task { await self?.refreshAll() }
            }
        }
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
                    return "₹\(Int(fee)) / hr"
                }
                return "₹ -- / hr"
            }()

            let cacheKey = physioImageKey(id: item.physioID, version: item.profileImageVersion)
            return CompletedAppointmentVM(
                appointmentID: item.appointmentID,
                physioID: item.physioID,
                status: status,
                physioName: item.physioName,
                ratingText: ratingText,
                distanceText: distanceText,
                specializationText: item.specialization,
                feeText: feeText,
                image: physioImages[cacheKey]
            )
        }
        var unique: [UUID: CompletedAppointmentVM] = [:]
        for vm in vms {
            if unique[vm.appointmentID] == nil {
                unique[vm.appointmentID] = vm
            }
        }
        apptView.setCompleted(Array(unique.values))

        for item in past {
            let cacheKey = physioImageKey(id: item.physioID, version: item.profileImageVersion)
            if physioImages[cacheKey] != nil { continue }
            guard let path = item.profileImagePath,
                  let url = PhysioService.shared.profileImageURL(pathOrUrl: path, version: item.profileImageVersion) else { continue }
            ImageLoader.shared.load(url) { [weak self] image in
                guard let self, let image else { return }
                self.physioImages[cacheKey] = image
                self.applyPast(self.lastPast)
            }
        }
    }

    private func physioImageKey(id: UUID, version: String?) -> String {
        "\(id.uuidString)|\(version ?? "")"
    }
}
