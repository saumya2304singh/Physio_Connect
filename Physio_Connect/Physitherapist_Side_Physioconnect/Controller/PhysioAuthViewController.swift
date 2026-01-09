//
//  PhysioAuthViewController.swift
//  Physio_Connect
//
//  Created by Codex on 08/01/26.
//

import UIKit

final class PhysioAuthViewController: UIViewController {

    private enum Mode {
        case login
        case signup
    }

    private let loginView = PhysioLoginView()
    private let signupView = PhysioSignupView()
    private let model = PhysioAuthModel()
    private var mode: Mode = .login

    override func loadView() {
        view = UIView()
        view.backgroundColor = UIColor(hex: "E6F1FF")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = false
        title = "Physio Access"

        layoutViews()
        bind()
        show(mode: .login, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure buttons are re-enabled after any previous attempts
        loginView.setLoading(false)
        loginView.showError(nil)
    }

    private func layoutViews() {
        [loginView, signupView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
            NSLayoutConstraint.activate([
                $0.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                $0.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                $0.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        signupView.isHidden = true
    }

    private func bind() {
        loginView.onBack = { [weak self] in
            // Always return to role selection to avoid no-op pops when this is root
            AppLogout.backToRoleSelection(from: self?.view, signOut: false)
        }
        loginView.onSignupTapped = { [weak self] in self?.show(mode: .signup, animated: true) }
        loginView.onLogin = { [weak self] email, password in
            self?.handleLogin(email: email, password: password)
        }

        signupView.onBack = { [weak self] in self?.popOrDismiss() }
        signupView.onLoginLink = { [weak self] in self?.show(mode: .login, animated: true) }
        signupView.onCreateAccount = { [weak self] input in
            self?.handleSignup(input: input)
        }
    }

    private func show(mode: Mode, animated: Bool) {
        self.mode = mode
        let showLogin = (mode == .login)
        let duration: TimeInterval = animated ? 0.2 : 0.0
        loginView.showError(nil)
        signupView.showError(nil)
        UIView.transition(with: view, duration: duration, options: .transitionCrossDissolve, animations: {
            self.loginView.isHidden = !showLogin
            self.signupView.isHidden = showLogin
        })
    }

    private func handleLogin(email: String, password: String) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            loginView.setLoading(false)
            presentInlineAlert(title: "Missing Details", message: "Please enter your email and password.")
            return
        }
        loginView.showError(nil)
        loginView.setLoading(true)

        Task {
            do {
                _ = try await model.login(email: trimmedEmail, password: password)
                await MainActor.run {
                    self.loginView.setLoading(false)
                    self.routeToHome()
                }
            } catch {
                await MainActor.run {
                    self.loginView.setLoading(false)
                    self.presentInlineAlert(title: "Login Failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func handleSignup(input: PhysioSignupInput) {
        let email = input.email.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = input.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            signupView.setLoading(false)
            showInlineError("Please enter your full name.")
            return
        }
        guard !email.isEmpty else {
            signupView.setLoading(false)
            showInlineError("Please enter your email.")
            return
        }
        guard !input.password.isEmpty, input.password.count >= 8 else {
            signupView.setLoading(false)
            showInlineError("Password must be at least 8 characters.")
            return
        }
        guard input.password == input.confirmPassword else {
            signupView.setLoading(false)
            showInlineError("Passwords do not match.")
            return
        }
        guard input.acceptedTerms else {
            signupView.setLoading(false)
            showInlineError("Please accept the Terms to continue.")
            return
        }

        showInlineError(nil)
        signupView.setLoading(true)

        Task {
            do {
                let signupInput = PhysioAuthModel.PhysioSignupInput(name: name, email: email, password: input.password)
                _ = try await model.signup(input: signupInput)
                await MainActor.run {
                    self.signupView.setLoading(false)
                    self.routeToHome()
                }
            } catch {
                await MainActor.run {
                    self.signupView.setLoading(false)
                    self.presentInlineAlert(title: "Signup Failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func showInlineError(_ message: String?) {
        if mode == .login {
            loginView.showError(message)
        } else {
            signupView.showError(message)
        }
    }

    private func presentInlineAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func routeToHome() {
        let tab = PhysioTabBarController()
        if let nav = navigationController {
            nav.setViewControllers([tab], animated: true)
        } else {
            RootRouter.setRoot(tab, window: view.window)
        }
    }

    private func popOrDismiss() {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}
