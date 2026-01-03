//
//  LoginViewController.swift
//  Physio_Connect
//
//  Created by user@8 on 06/01/26.
//

import UIKit

final class LoginViewController: UIViewController {

    var onLoginSuccess: (() -> Void)?
    var onSignupTapped: (() -> Void)?

    private let loginView = LoginView()
    private let model = LoginModel()
    private var isPasswordVisible = false

    override func loadView() { view = loginView }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        bind()
        addKeyboardDismissTap()
    }

    private func bind() {
        loginView.backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        loginView.passwordEyeButton.addTarget(self, action: #selector(togglePassword), for: .touchUpInside)
        loginView.loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        loginView.signUpButton.addTarget(self, action: #selector(signupTapped), for: .touchUpInside)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func togglePassword() {
        isPasswordVisible.toggle()
        loginView.passwordField.textField.isSecureTextEntry = !isPasswordVisible
        let name = isPasswordVisible ? "eye.slash" : "eye"
        loginView.passwordEyeButton.setImage(UIImage(systemName: name), for: .normal)

        let text = loginView.passwordField.textField.text
        loginView.passwordField.textField.text = nil
        loginView.passwordField.textField.text = text
    }

    @objc private func loginTapped() {
        let email = (loginView.emailField.textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let password = loginView.passwordField.textField.text ?? ""

        if email.isEmpty || password.isEmpty {
            showAlert(title: "Missing Details", message: "Please enter your email and password.")
            return
        }

        Task {
            do {
                await MainActor.run { self.loginView.loginButton.isEnabled = false }
                try await model.signIn(email: email, password: password)
                await MainActor.run {
                    self.onLoginSuccess?()
                    if self.onLoginSuccess == nil {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    self.showAlert(title: "Login failed", message: error.localizedDescription)
                    self.loginView.loginButton.isEnabled = true
                }
            }
        }
    }

    @objc private func signupTapped() {
        if let onSignupTapped {
            onSignupTapped()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    private func addKeyboardDismissTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingNow))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func endEditingNow() {
        view.endEditing(true)
    }

    private func showAlert(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}
