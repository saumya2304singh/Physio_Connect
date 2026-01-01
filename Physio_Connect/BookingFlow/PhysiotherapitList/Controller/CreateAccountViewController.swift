//
//  CreateAccountViewController.swift
//  Physio_Connect
//
//  Created by user@8 on 01/01/26.
//

import UIKit
import Supabase

final class CreateAccountViewController: UIViewController {

    // MARK: - Callbacks (MVC friendly)
    var onSignupComplete: (() -> Void)?
    var onLoginTapped: (() -> Void)?

    private let createView = CreateAccountView()
    private let model: CreateAccountModel

    private var isPasswordVisible = false
    private var isConfirmPasswordVisible = false

    // MARK: - Init
    init(model: CreateAccountModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Load View
    override func loadView() {
        view = createView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true

        bind()
        applyAppointmentBanner()
        addKeyboardDismissTap()
    }

    private func bind() {
        createView.backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        createView.termsCheckButton.addTarget(self, action: #selector(termsTapped), for: .touchUpInside)

        createView.passwordEyeButton.addTarget(self, action: #selector(togglePassword), for: .touchUpInside)
        createView.confirmPasswordEyeButton.addTarget(self, action: #selector(toggleConfirmPassword), for: .touchUpInside)

        createView.createAccountButton.addTarget(self, action: #selector(createAccountTapped), for: .touchUpInside)

        createView.googleButton.addTarget(self, action: #selector(googleTapped), for: .touchUpInside)
        createView.appleButton.addTarget(self, action: #selector(appleTapped), for: .touchUpInside)

        createView.loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
    }

    private func applyAppointmentBanner() {
        let appt = model.appointment
        createView.savedLine1.text = "\(appt.dateText) at \(appt.timeText)"
    }

    // MARK: - Actions
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func termsTapped() {
        createView.setTermsChecked(!createView.isTermsChecked)
    }

    @objc private func togglePassword() {
        isPasswordVisible.toggle()
        createView.passwordField.textField.isSecureTextEntry = !isPasswordVisible
        let name = isPasswordVisible ? "eye.slash" : "eye"
        createView.passwordEyeButton.setImage(UIImage(systemName: name), for: .normal)

        // keep cursor position stable
        let text = createView.passwordField.textField.text
        createView.passwordField.textField.text = nil
        createView.passwordField.textField.text = text
    }

    @objc private func toggleConfirmPassword() {
        isConfirmPasswordVisible.toggle()
        createView.confirmPasswordField.textField.isSecureTextEntry = !isConfirmPasswordVisible
        let name = isConfirmPasswordVisible ? "eye.slash" : "eye"
        createView.confirmPasswordEyeButton.setImage(UIImage(systemName: name), for: .normal)

        let text = createView.confirmPasswordField.textField.text
        createView.confirmPasswordField.textField.text = nil
        createView.confirmPasswordField.textField.text = text
    }

    @objc private func createAccountTapped() {
        // 0) Terms check
        guard createView.isTermsChecked else {
            showAlert(title: "Terms Required", message: "Please agree to the terms and conditions.")
            return
        }

        // 1) Read fields
        let fullName = (createView.fullNameField.textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let email = (createView.emailField.textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = (createView.phoneField.textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let password = createView.passwordField.textField.text ?? ""
        let confirm = createView.confirmPasswordField.textField.text ?? ""

        // 2) Validation
        if fullName.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty || confirm.isEmpty {
            showAlert(title: "Missing Details", message: "Please fill in all required fields.")
            return
        }

        if password.count < 8 {
            showAlert(title: "Weak Password", message: "Password must be at least 8 characters.")
            return
        }

        if password != confirm {
            showAlert(title: "Password Mismatch", message: "Passwords do not match.")
            return
        }

        // 3) Supabase signup + save customer + SIGN IN (this is what fixes redirect)
        Task {
            do {
                await MainActor.run {
                    self.createView.createAccountButton.isEnabled = false
                }

                // A) Create user
                let data: [String: AnyJSON] = [
                    "full_name": .string(fullName),
                    "phone": .string(phone)
                ]

                let authResponse = try await SupabaseManager.shared.client.auth.signUp(
                    email: email,
                    password: password,
                    data: data
                )

                // B) Save customer row
                let userId = authResponse.user.id

                struct CustomerInsert: Encodable {
                    let id: UUID
                    let full_name: String
                    let email: String
                    let phone: String
                }

                let payload = CustomerInsert(
                    id: userId,
                    full_name: fullName,
                    email: email,
                    phone: phone
                )

                _ = try await SupabaseManager.shared.client
                    .from("customers")
                    .upsert(payload)
                    .execute()

                // ✅ IMPORTANT FIX:
                // After signup, ensure we have a session by signing in.
                _ = try await SupabaseManager.shared.client.auth.signIn(
                    email: email,
                    password: password
                )


                await MainActor.run {
                    self.onSignupComplete?() // Payment screen will NOT redirect anymore
                }

            } catch {
                await MainActor.run {
                    self.showAlert(title: "Signup failed", message: error.localizedDescription)
                    self.createView.createAccountButton.isEnabled = true
                }
            }
        }
    }

    @objc private func googleTapped() {
        showAlert(title: "Google Sign-In", message: "Hook Google Sign-In here.")
    }

    @objc private func appleTapped() {
        showAlert(title: "Apple Sign-In", message: "Hook Sign in with Apple here.")
    }

    @objc private func loginTapped() {
        onLoginTapped?()
    }

    // MARK: - Helpers
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
