//
//  RoleSelectionViewController.swift
//  Physio_Connect
//
//  Created by user@8 on 07/01/26.
//
import UIKit

final class RoleSelectionViewController: UIViewController {

    private let roleView = RoleSelectionView()
    private let model = RoleStore.shared

    override func loadView() { view = roleView }

    override func viewDidLoad() {
        super.viewDidLoad()

        // If you have an asset, put it in Assets.xcassets as "welcome_hero"
        roleView.setHeroImage(UIImage(named: "welcome_hero"))

        roleView.patientButton.addTarget(self, action: #selector(patientTapped), for: .touchUpInside)
        roleView.physioButton.addTarget(self, action: #selector(physioTapped), for: .touchUpInside)
        roleView.backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    @objc private func patientTapped() {
        model.currentRole = .patient
        Task { await switchToPatientApp() }
    }

    @objc private func physioTapped() {
        model.currentRole = .physiotherapist
        switchToPhysioApp()
    }

    private func switchToPatientApp() async {
        let window = await MainActor.run { self.currentWindow() }

        await MainActor.run {
            guard let window else { return }

            let loginVC = LoginViewController()
            loginVC.onLoginSuccess = { [weak self] in
                self?.launchPatientHome()
            }
            loginVC.onSignupTapped = { [weak self, weak loginVC] in
                self?.showPatientSignup(from: loginVC)
            }

            let nav = UINavigationController(rootViewController: loginVC)
            RootRouter.setRoot(nav, window: window)
        }

        // Clear any lingering session (e.g., doctor) in the background without blocking UI
        Task { try? await SupabaseManager.shared.client.auth.signOut() }
    }

    @MainActor
    private func showPatientSignup(from loginVC: LoginViewController?) {
        guard let nav = loginVC?.navigationController else { return }
        let signupDraft = AppointmentDraft(
            dateText: "—",
            timeText: "—",
            therapistName: "Physiotherapist",
            addressText: "—"
        )
        let model = CreateAccountModel(appointment: signupDraft)
        let signupVC = CreateAccountViewController(model: model)
        signupVC.onSignupComplete = { [weak self] in
            self?.launchPatientHome()
        }
        signupVC.onLoginTapped = { [weak nav] in
            nav?.popViewController(animated: true)
        }
        nav.pushViewController(signupVC, animated: true)
    }

    @MainActor
    private func launchPatientHome() {
        RootRouter.setRoot(MainTabBarController(), window: currentWindow())
    }

    private func switchToPhysioApp() {
        let window = currentWindow()
        Task {
            let hasSession = (try? await SupabaseManager.shared.client.auth.session) != nil
            await MainActor.run {
                guard let window else { return }
                if hasSession {
                    // Keep existing physio session
                    let tab = PhysioTabBarController()
                    RootRouter.setRoot(tab, window: window)
                } else {
                    let physioRoot = PhysioAuthViewController()
                    let nav = UINavigationController(rootViewController: physioRoot)
                    RootRouter.setRoot(nav, window: window)
                }
            }
        }
    }

    @objc private func backTapped() {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
            return
        }
        if presentingViewController != nil {
            dismiss(animated: true)
            return
        }

        // Fallback: return to the last selected role if any, else to patient home.
        if let role = model.currentRole {
            switch role {
            case .patient:
                RootRouter.setRoot(MainTabBarController(), window: currentWindow())
            case .physiotherapist:
                let nav = UINavigationController(rootViewController: PhysioHomeViewController())
                RootRouter.setRoot(nav, window: currentWindow())
            }
        } else {
            RootRouter.setRoot(MainTabBarController(), window: currentWindow())
        }
    }

    private func currentWindow() -> UIWindow? {
        // Scene-based safe window access
        return (view.window ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow })
    }
}
