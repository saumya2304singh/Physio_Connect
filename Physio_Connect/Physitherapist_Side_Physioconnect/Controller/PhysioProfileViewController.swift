//
//  PhysioProfileViewController.swift
//  Physio_Connect
//
//  Created by Codex on 08/01/26.
//

import UIKit

final class PhysioProfileViewController: UIViewController {

    private let profileView = ProfileView()
    private let model = PhysioProfileModel()
    private var isLoading = false

    override func loadView() { view = profileView }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Edit",
            style: .plain,
            target: self,
            action: #selector(editTapped)
        )
        profileView.onBack = { [weak self] in self?.navigationController?.popViewController(animated: true) }
        profileView.onEdit = { [weak self] in self?.showEdit() }
        profileView.onSignOut = { [weak self] in self?.signOut() }
        profileView.onSwitchRole = { [weak self] in self?.confirmSwitchRole() }
        profileView.onRefresh = { [weak self] in Task { await self?.loadProfile() } }

        profileView.setLoggedIn(true)
        loadInitial()
    }

    @objc private func editTapped() {
        showEdit()
    }

    private func loadInitial() {
        Task { await loadProfile() }
    }

    private func showEdit() {
        let vc = PhysioEditProfileViewController()
        vc.onProfileUpdated = { [weak self] in
            Task { await self?.loadProfile() }
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func signOut() {
        Task {
            do {
                try await SupabaseManager.shared.client.auth.signOut()
            } catch {
                // ignore
            }
            await MainActor.run {
                AppLogout.backToRoleSelection(from: self.view, signOut: false)
            }
        }
    }

    private func confirmSwitchRole() {
        let alert = UIAlertController(
            title: "Switch role?",
            message: "You’ll return to the role selection screen.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Switch", style: .destructive, handler: { _ in
            AppLogout.backToRoleSelection(from: self.view, signOut: false)
        }))
        present(alert, animated: true)
    }

    private func setLoading(_ loading: Bool) {
        isLoading = loading
        profileView.setRefreshing(loading)
    }

    private func loadProfile() async {
        if isLoading { return }
        setLoading(true)
        defer { Task { @MainActor in self.setLoading(false) } }
        do {
            let data = try await model.fetchProfile()
            await MainActor.run {
                self.profileView.apply(data)
            }
        } catch {
            await MainActor.run {
                self.profileView.applyLoggedOut()
            }
        }
    }
}
