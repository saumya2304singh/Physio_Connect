//
//  ProfileViewController.swift
//  Physio_Connect
//
//  Created by user@8 on 03/01/26.
//

import UIKit

final class ProfileViewController: UIViewController {

    private let profileView = ProfileView()
    private let model = ProfileModel()
    private var isRefreshing = false

    override func loadView() { view = profileView }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        bind()
        Task { await refreshProfile() }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await refreshProfile() }
    }

    private func bind() {
        profileView.onBack = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }

        profileView.onEdit = { [weak self] in
            self?.showAlert(title: "Edit Profile", message: "Editing profile details is coming soon.")
        }

        profileView.onPrivacyTapped = { [weak self] in
            self?.showAlert(title: "Privacy Policy", message: "Add your privacy policy URL here.")
        }

        profileView.onTermsTapped = { [weak self] in
            self?.showAlert(title: "Terms of Service", message: "Add your terms of service URL here.")
        }

        profileView.onSignOut = { [weak self] in
            self?.signOut()
        }

        profileView.onNotificationsChanged = { [weak self] isOn in
            Task { await self?.model.updateNotifications(enabled: isOn) }
        }

        profileView.onRefresh = { [weak self] in
            Task { await self?.refreshProfile() }
        }
    }

    @objc private func appWillEnterForeground() {
        Task { await refreshProfile() }
    }

    private func refreshProfile() async {
        if isRefreshing { return }
        isRefreshing = true
        await MainActor.run { self.profileView.setRefreshing(true) }
        defer {
            Task { @MainActor in
                self.isRefreshing = false
                self.profileView.setRefreshing(false)
            }
        }

        do {
            let data = try await model.fetchCurrentProfile()
            await MainActor.run {
                self.profileView.apply(data)
            }
        } catch {
            await MainActor.run {
                self.showAlert(title: "Profile Error", message: error.localizedDescription)
            }
        }
    }

    private func signOut() {
        Task {
            do {
                try await model.signOut()
                await MainActor.run {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            } catch {
                await MainActor.run {
                    self.showAlert(title: "Sign Out Failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
