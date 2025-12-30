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

        // Button action
        homeView.card.primaryButton.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)

        // Load initial card state
        Task { await refreshCard() }
    }

    @objc private func primaryTapped() {
        // If we are in book state -> open physiotherapist list
        // If upcoming state -> open appointment details (optional)
        // For now: always go to physiotherapist list when tapped in book state.

        let vc = PhysiotherapistListViewController() // <-- use your actual VC name
        navigationController?.pushViewController(vc, animated: true)
    }

    private func refreshCard() async {
        do {
            let upcoming = try await model.fetchUpcomingAppointment()
            await MainActor.run {
                if let appt = upcoming {
                    self.homeView.card.apply(state: .upcoming(appt))
                } else {
                    self.homeView.card.apply(state: .bookHomeVisit)
                }
            }
        } catch {
            // On error, fallback to book card
            await MainActor.run {
                self.homeView.card.apply(state: .bookHomeVisit)
            }
            print("❌ Home refresh error:", error)
        }
    }
}
