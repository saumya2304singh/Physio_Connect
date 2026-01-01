//
//  HomeViewController.swift
//  Physio_Connect
//
//  Created by Ayush Rai on 31/12/25.
//

import UIKit

final class HomeViewController: UIViewController {

    private let homeView = HomeView()
    private let model = HomeModel()

    override func loadView() { view = homeView }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)

        // ✅ Carousel button actions
        homeView.carousel.onViewDetailsTapped = { [weak self] appt in
            guard let self else { return }
            let appointment = self.makeAppointment(from: appt)
            let vc = AppointmentDetailsViewController(appointment: appointment)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        homeView.carousel.onBookTapped = { [weak self] in
            guard let self else { return }
            let vc = PhysiotherapistListViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        }

        Task { await refreshCards() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await refreshCards() }
    }

    private func refreshCards() async {
        do {
            let upcoming = try await model.fetchUpcomingAppointment()
            await MainActor.run {
                self.homeView.setUpcoming(upcoming)
            }
        } catch {
            await MainActor.run {
                self.homeView.setUpcoming(nil)
            }
            print("❌ Home refresh error:", error)
        }
    }

    private func makeAppointment(from appt: HomeUpcomingAppointment) -> Appointment {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, dd MMM"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        let status: AppointmentStatus
        switch appt.status.lowercased() {
        case "completed":
            status = .completed
        case "cancelled", "canceled":
            status = .cancelled
        default:
            status = .upcoming
        }

        return Appointment(
            id: appt.appointmentID,
            doctorName: appt.physioName,
            specialization: appt.specializationText,
            ratingText: appt.ratingText,
            dateText: dateFormatter.string(from: appt.startTime),
            timeText: timeFormatter.string(from: appt.startTime),
            status: status,
            sessionNotes: "",
            phoneNumber: nil,
            locationText: appt.address,
            feeText: appt.consultationFeeText
        )
    }
}
