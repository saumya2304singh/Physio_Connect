//
//  ProfileViewController.swift
//  Physio_Connect
//
//  Created by user@8 on 03/01/26.
//

import UIKit
import PhotosUI

final class ProfileViewController: UIViewController, PHPickerViewControllerDelegate {

    private let profileView = ProfileView()
    private let model = ProfileModel()
    private var isRefreshing = false
    private var isUploadingAvatar = false
    private var isLoggedInState = true
    private var currentProfile: ProfileViewData?

    override func loadView() { view = profileView }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationChrome()
        bind()
        profileView.preloadAvatar(urlString: ProfileModel.cachedAvatarURL())
        Task { await refreshProfile() }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationChrome()
        Task { await refreshProfile() }
    }

    private func configureNavigationChrome() {
        guard let nav = navigationController else {
            profileView.useInViewNavigationChrome(showBack: true, showEdit: true, title: "Profile")
            return
        }

        nav.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "Profile"
        navigationItem.largeTitleDisplayMode = .never
        profileView.useNativeNavigationChrome()

        let showEdit = isLoggedInState
        navigationItem.rightBarButtonItem = showEdit
            ? UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editTapped))
            : nil

        if nav.viewControllers.count > 1 {
            navigationItem.leftBarButtonItem = nil
        } else {
            let fallbackBack = UIBarButtonItem(
                image: UIImage(systemName: "chevron.left"),
                style: .plain,
                target: self,
                action: #selector(goHomeTapped)
            )
            navigationItem.leftBarButtonItem = fallbackBack
        }
    }

    private func bind() {
        profileView.onBack = { [weak self] in self?.navigationController?.popViewController(animated: true) }
        profileView.onEdit = { [weak self] in self?.openEditProfile() }

        profileView.onPrivacyTapped = { [weak self] in
            self?.showAlert(title: "Privacy Policy", message: "Add your privacy policy URL here.")
        }

        profileView.onTermsTapped = { [weak self] in
            self?.showAlert(title: "Terms of Service", message: "Add your terms of service URL here.")
        }

        profileView.onSignOut = { [weak self] in
            self?.signOut()
        }

        profileView.onLogin = { [weak self] in
            self?.showLogin()
        }

        profileView.onSignup = { [weak self] in
            self?.showSignup()
        }

        profileView.onNotificationsChanged = { [weak self] isOn in
            Task { await self?.model.updateNotifications(enabled: isOn) }
        }

        profileView.onRefresh = { [weak self] in
            Task { await self?.refreshProfile() }
        }

        profileView.onAvatarTapped = { [weak self] in
            self?.presentAvatarPicker()
        }
        
        profileView.onSwitchRole = { [weak self] in
            self?.switchRoleTapped()
        }

    }

    @objc private func appWillEnterForeground() {
        Task { await refreshProfile() }
    }
    
    
    @objc private func switchRoleTapped() {
        let alert = UIAlertController(
            title: "Switch role?",
            message: "You’ll return to the role selection screen.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Switch", style: .destructive, handler: { _ in
            AppLogout.backToRoleSelection(from: self.view)
        }))
        present(alert, animated: true)
    }


    private func refreshProfile() async {
        if isRefreshing { return }
        isRefreshing = true
        await MainActor.run { self.profileView.setRefreshing(true) }
        defer {
            Task { @MainActor in
                self.isRefreshing = false
                self.profileView.setRefreshing(false)
            }
        }

        let hasSession = await model.hasActiveSession()
        await MainActor.run {
            self.isLoggedInState = hasSession
            self.configureNavigationChrome()
        }
        guard hasSession else {
            await MainActor.run {
                self.profileView.applyLoggedOut()
            }
            return
        }

        do {
            let data = try await model.fetchCurrentProfile()
            await MainActor.run {
                self.currentProfile = data
                self.profileView.apply(data)
            }
        } catch {
            await MainActor.run {
                self.showAlert(title: "Profile Error", message: error.localizedDescription)
            }
        }
    }

    private func signOut() {
        Task {
            do {
                try await model.signOut()
                ProfileModel.clearCachedAvatarURL()
                await MainActor.run {
                    self.profileView.applyLoggedOut()
                }
            } catch {
                await MainActor.run {
                    self.showAlert(title: "Sign Out Failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func showLogin() {
        let vc = LoginViewController()
        vc.onLoginSuccess = { [weak self] in
            self?.handlePostAuthSuccess()
        }
        vc.onSignupTapped = { [weak self] in
            self?.showSignup()
        }
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    private func showSignup() {
        let signupDraft = AppointmentDraft(
            dateText: "—",
            timeText: "—",
            therapistName: "Physiotherapist",
            addressText: "—"
        )
        let model = CreateAccountModel(appointment: signupDraft)
        let vc = CreateAccountViewController(model: model)
        vc.onSignupComplete = { [weak self] in
            self?.handlePostAuthSuccess()
        }
        vc.onLoginTapped = { [weak self] in
            self?.showLogin()
        }
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func openEditProfile() {
        guard let currentProfile else {
            showAlert(title: "Edit Profile", message: "Profile data is still loading.")
            return
        }
        let vc = EditProfileViewController(profile: currentProfile)
        vc.onSave = { [weak self] in
            Task { await self?.refreshProfile() }
        }
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func editTapped() {
        openEditProfile()
    }

    @objc private func goHomeTapped() {
        routeToHomeRoot()
    }

    private func handlePostAuthSuccess() {
        Task { await refreshProfile() }
        routeToHomeRoot()
    }

    private func routeToHomeRoot() {
        if let tabs = tabBarController as? MainTabBarController {
            tabs.selectedIndex = 0
            if let navs = tabs.viewControllers as? [UINavigationController], let homeNav = navs.first {
                homeNav.popToRootViewController(animated: false)
            }
            navigationController?.popToRootViewController(animated: true)
            return
        }

        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popToRootViewController(animated: true)
            return
        }

        let window = view.window ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        RootRouter.setRoot(MainTabBarController(), window: window)
    }

    private func presentAvatarPicker() {
        guard !isUploadingAvatar else { return }
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider else { return }
        guard provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let self, let image = object as? UIImage else { return }
            guard let data = image.jpegData(compressionQuality: 0.85) else { return }
            Task { await self.uploadAvatar(image: image, data: data) }
        }
    }

    @MainActor
    private func setAvatarUploadState(_ uploading: Bool) {
        isUploadingAvatar = uploading
        profileView.setRefreshing(uploading)
    }

    private func uploadAvatar(image: UIImage, data: Data) async {
        await MainActor.run {
            self.profileView.setAvatarPreview(image)
            self.setAvatarUploadState(true)
        }
        defer { Task { @MainActor in self.setAvatarUploadState(false) } }

        do {
            try await model.uploadAvatarImage(data)
            await refreshProfile()
        } catch {
            await MainActor.run {
                self.showAlert(title: "Upload Failed", message: error.localizedDescription)
            }
        }
    }
}
