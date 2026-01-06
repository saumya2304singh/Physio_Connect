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
    }

    @objc private func patientTapped() {
        model.currentRole = .patient
        switchToPatientApp()
    }

    @objc private func physioTapped() {
        model.currentRole = .physiotherapist
        switchToPhysioApp()
    }

    private func switchToPatientApp() {
        let patientRoot = MainTabBarController() // ✅ your existing patient app
        RootRouter.setRoot(patientRoot, window: currentWindow())
    }

    private func switchToPhysioApp() {
        let physioRoot = PhysioHomePlaceholderViewController()
        let nav = UINavigationController(rootViewController: physioRoot)
        RootRouter.setRoot(nav, window: currentWindow())
    }

    private func currentWindow() -> UIWindow? {
        // Scene-based safe window access
        return (view.window ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow })
    }
}

