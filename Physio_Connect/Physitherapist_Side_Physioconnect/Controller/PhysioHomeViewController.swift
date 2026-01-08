//
//  PhysioHomeViewController.swift
//  Physio_Connect
//
//  Created by Codex on 08/01/26.
//

import UIKit

final class PhysioHomeViewController: UIViewController {

    private let homeView = PhysioHomeView()
    private let profileModel = PhysioProfileModel()
    private let profileButton = UIButton(type: .system)

    override func loadView() { view = homeView }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = false
        title = "Dashboard"
        configureProfileButton(image: UIImage(systemName: "person.crop.circle"))
        configureContent()
        loadProfileAvatar()
    }

    private func configureContent() {
        homeView.setSummary(todaySessions: 4, pendingTasks: 3)
        homeView.setUpcoming(
            sessionTitle: "Knee Rehab Session",
            patient: "Patient: John Mathew",
            time: "Today • 4:30 PM • 45 mins",
            location: "Mode: Home Visit • Adyar, Chennai"
        )
    }

    private func loadProfileAvatar() {
        Task {
            do {
                let data = try await profileModel.fetchProfile()
                await MainActor.run { self.updateProfileButton(with: data.avatarURL) }
            } catch {
                // ignore avatar load errors
            }
        }
    }

    private func configureProfileButton(image: UIImage?) {
        let size: CGFloat = 38
        profileButton.translatesAutoresizingMaskIntoConstraints = false
        profileButton.setImage(image, for: .normal)
        profileButton.imageView?.contentMode = .scaleAspectFill
        profileButton.tintColor = UIColor(hex: "1E6EF7")
        profileButton.backgroundColor = UIColor.white.withAlphaComponent(0.75)
        profileButton.layer.cornerRadius = size / 2
        profileButton.clipsToBounds = true
        profileButton.adjustsImageWhenHighlighted = false
        profileButton.contentHorizontalAlignment = .fill
        profileButton.contentVerticalAlignment = .fill
        profileButton.addTarget(self, action: #selector(profileTapped), for: .touchUpInside)

        let barItem = UIBarButtonItem(customView: profileButton)
        NSLayoutConstraint.activate([
            profileButton.widthAnchor.constraint(equalToConstant: size),
            profileButton.heightAnchor.constraint(equalToConstant: size)
        ])
        navigationItem.rightBarButtonItem = barItem
    }

    private func updateProfileButton(with urlString: String?) {
        let placeholder = UIImage(systemName: "person.crop.circle")
        configureProfileButton(image: placeholder)

        guard let raw = urlString?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return }

        let url: URL?
        if let absolute = URL(string: raw), absolute.scheme != nil {
            url = absolute
        } else if let built = PhysioService.shared.profileImageURL(pathOrUrl: raw, version: nil) {
            url = built
        } else {
            let normalized = raw.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            url = URL(string: "\(SupabaseConfig.url)/storage/v1/object/public/\(normalized)")
        }
        guard let finalURL = url else { return }

        ImageLoader.shared.load(finalURL) { [weak self] image in
            guard let self else { return }
            let rounded = image?.withRenderingMode(.alwaysOriginal)
            DispatchQueue.main.async {
                self.configureProfileButton(image: rounded ?? placeholder)
            }
        }
    }

    @objc private func profileTapped() {
        let vc = PhysioProfileViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

}
