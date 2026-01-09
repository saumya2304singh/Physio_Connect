//
//  PhysioEditProfileViewController.swift
//  Physio_Connect
//
//  Created by Codex on 09/01/26.
//

import UIKit

final class PhysioEditProfileViewController: UIViewController {

    private let editView = PhysioEditProfileView()
    private let model = PhysioProfileModel()
    var onProfileUpdated: (() -> Void)?

    override func loadView() { view = editView }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        bind()
        loadProfile()
    }

    private func bind() {
        editView.onBack = { [weak self] in self?.navigationController?.popViewController(animated: true) }
        editView.onSave = { [weak self] in self?.saveProfile() }
    }

    private func loadProfile() {
        Task {
            do {
                let data = try await model.fetchProfile()
                await MainActor.run { self.editView.apply(data) }
            } catch {
                await MainActor.run { self.showError("Failed to load profile.") }
            }
        }
    }

    private func saveProfile() {
        let input = editView.currentInput()
        editView.setSaving(true)
        Task {
            do {
                try await model.updateProfile(input)
                await MainActor.run {
                    self.editView.setSaving(false)
                    self.onProfileUpdated?()
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                print("❌ Physio profile save error:", error)
                await MainActor.run {
                    self.editView.setSaving(false)
                    self.showError(error.localizedDescription)
                }
            }
        }
    }

    private func showError(_ message: String) {
        let ac = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}
