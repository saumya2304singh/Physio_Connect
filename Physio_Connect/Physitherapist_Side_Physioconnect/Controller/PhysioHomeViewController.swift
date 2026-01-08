//
//  PhysioHomeViewController.swift
//  Physio_Connect
//
//  Created by Codex on 08/01/26.
//

import UIKit

final class PhysioHomeViewController: UIViewController {

    private let homeView = PhysioHomeView()

    override func loadView() { view = homeView }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        title = "Home"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "person.crop.circle"),
            style: .plain,
            target: self,
            action: #selector(profileTapped)
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Logout",
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )
        configureContent()
    }

    private func configureContent() {
        homeView.setSummary(todaySessions: 4, pendingTasks: 3)
        homeView.setUpcoming(
            sessionTitle: "Knee Rehab Session",
            patient: "Patient: John Mathew",
            time: "Today • 4:30 PM • 45 mins",
            location: "Mode: Home Visit • Adyar, Chennai"
        )
    }

    @objc private func profileTapped() {
        let vc = PhysioProfileViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func logoutTapped() {
        Task {
            do {
                try await SupabaseManager.shared.client.auth.signOut()
            } catch {
                // ignore sign-out errors
            }
            await MainActor.run {
                AppLogout.backToRoleSelection(from: self.view)
            }
        }
    }
}
