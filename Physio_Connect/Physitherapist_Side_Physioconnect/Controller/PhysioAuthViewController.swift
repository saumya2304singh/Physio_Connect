//
//  PhysioAuthViewController.swift
//  Physio_Connect
//
//  Created by Codex on 08/01/26.
//

import UIKit

final class PhysioAuthViewController: UIViewController {

    private let authView = PhysioAuthView()
    private let model = PhysioAuthModel()

    override func loadView() { view = authView }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = false
        title = "Physio Access"

        authView.modeControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        authView.actionButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        authView.setMode(.login)
    }

    @objc private func modeChanged() {
        let mode: PhysioAuthView.Mode = authView.modeControl.selectedSegmentIndex == 0 ? .login : .signup
        authView.setMode(mode)
        authView.showError(nil)
    }

    @objc private func submitTapped() {
        view.endEditing(true)
        let mode: PhysioAuthView.Mode = authView.modeControl.selectedSegmentIndex == 0 ? .login : .signup
        guard let email = authView.emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty,
              let password = authView.passwordField.text, !password.isEmpty else {
            authView.showError("Please enter email and password.")
            return
        }

        let name = authView.nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if mode == .signup && name.isEmpty {
            authView.showError("Please enter your full name.")
            return
        }

        authView.showError(nil)
        authView.setLoading(true)

        Task {
            do {
                switch mode {
                case .login:
                    _ = try await model.login(email: email, password: password)
                case .signup:
                    let input = PhysioAuthModel.PhysioSignupInput(name: name, email: email, password: password)
                    _ = try await model.signup(input: input)
                }
                await MainActor.run {
                    self.authView.setLoading(false)
                    self.routeToHome()
                }
            } catch {
                await MainActor.run {
                    self.authView.setLoading(false)
                    self.authView.showError(error.localizedDescription)
                }
            }
        }
    }

    private func routeToHome() {
        let homeVC = PhysioHomeViewController()
        if let nav = navigationController {
            nav.setViewControllers([homeVC], animated: true)
        } else {
            let nav = UINavigationController(rootViewController: homeVC)
            RootRouter.setRoot(nav, window: view.window)
        }
    }
}
