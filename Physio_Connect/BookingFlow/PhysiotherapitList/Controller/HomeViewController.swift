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

        // ✅ Carousel button actions
        homeView.carousel.onBookTapped = { [weak self] in
            guard let self else { return }
            let vc = PhysiotherapistListViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        }

        homeView.carousel.onUpcomingTapped = { [weak self] in
            guard let self else { return }
            // TODO: open AppointmentDetailsViewController when you make it
            // For now:
            //let vc = PhysiotherapistListViewController()
            //self.navigationController?.pushViewController(vc, animated: true)
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
}
