//
//  EditProfileViewController.swift
//  Physio_Connect
//
//  Created by user@8 on 03/01/26.
//

import UIKit

final class EditProfileViewController: UIViewController {

    private let editView = EditProfileView()
    private let model = ProfileModel()
    private let profile: ProfileViewData
    private var isSaving = false

    var onSave: (() -> Void)?

    init(profile: ProfileViewData) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() { view = editView }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "Edit Profile"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = UIColor(hex: "1E6EF7")
        editView.useNativeNavigationChrome()
        editView.apply(profile)

        editView.onBack = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        editView.onSave = { [weak self] in
            self?.saveProfile()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem?.tintColor = UIColor(hex: "1E6EF7")
    }

    private func saveProfile() {
        if isSaving { return }
        guard editView.isPhoneValidForSave() else {
            showAlert(title: "Invalid Phone Number", message: "Enter exactly 10 digits. Country code +91 is added automatically.")
            return
        }
        isSaving = true
        editView.setSaving(true)
        navigationItem.rightBarButtonItem?.isEnabled = false
        let input = editView.currentInput()
        Task {
            do {
                try await model.updateProfile(input)
                await MainActor.run {
                    self.isSaving = false
                    self.editView.setSaving(false)
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    self.onSave?()
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                await MainActor.run {
                    self.isSaving = false
                    self.editView.setSaving(false)
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    self.showAlert(title: "Save Failed", message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func saveTapped() {
        saveProfile()
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
