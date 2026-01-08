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
        profileView.onBack = { [weak self] in self?.navigationController?.popViewController(animated: true) }
        profileView.onEdit = { [weak self] in self?.showEditUnavailable() }
        profileView.onSignOut = { [weak self] in self?.signOut() }
        profileView.onSwitchRole = { [weak self] in AppLogout.backToRoleSelection(from: self?.view) }
        profileView.onRefresh = { [weak self] in Task { await self?.loadProfile() } }

        // Hide edit for now; physio profile editing not implemented.
        profileView.setLoggedIn(true)
        loadInitial()
    }

    private func loadInitial() {
        Task { await loadProfile() }
    }

    private func showEditUnavailable() {
        let ac = UIAlertController(title: "Edit coming soon", message: "Editing physiotherapist profile will be available in the next update.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    private func signOut() {
        Task {
            do {
                try await SupabaseManager.shared.client.auth.signOut()
            } catch {
                // ignore
            }
            await MainActor.run {
                AppLogout.backToRoleSelection(from: self.view)
            }
        }
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
