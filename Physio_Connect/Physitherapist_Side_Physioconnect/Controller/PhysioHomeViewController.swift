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
    private let dashboardModel = PhysioDashboardModel()
    private var isLoading = false

    override func loadView() { view = homeView }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = false
        title = "Dashboard"
        configureProfileButton(image: UIImage(systemName: "person.crop.circle"))
        loadProfileAvatar()
        Task { await loadDashboard() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await loadDashboard() }
    }

    private func loadDashboard() async {
        if isLoading { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let physioID = try await dashboardModel.resolvePhysioID()

            async let summary = dashboardModel.fetchSummary(physioID: physioID)
            async let upcoming = dashboardModel.fetchUpcomingSessions(physioID: physioID)
            async let patients = dashboardModel.fetchPatients(physioID: physioID)

            let summaryValue = (try? await summary) ?? PhysioDashboardSummary(
                todaySessions: 0,
                upcomingAppointments: 0,
                activePrograms: 0
            )
            let upcomingValue = (try? await upcoming) ?? []
            let patientsValue = (try? await patients) ?? []

            await MainActor.run {
                self.homeView.setSummary(
                    todaySessions: summaryValue.todaySessions,
                    upcomingAppointments: summaryValue.upcomingAppointments,
                    activePrograms: summaryValue.activePrograms
                )
                let upcomingItems = upcomingValue.map {
                    PhysioHomeView.UpcomingItem(
                        title: $0.title,
                        patient: $0.patientName,
                        time: $0.timeText,
                        location: $0.locationText
                    )
                }
                self.homeView.setUpcoming(upcomingItems)

                let patientItems = patientsValue.map {
                    PhysioHomeView.PatientItem(
                        name: $0.name,
                        contact: $0.contactLine,
                        location: $0.locationLine
                    )
                }
                self.homeView.setPatients(patientItems)
            }
        } catch {
            // keep last known UI if refresh fails
        }
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
        let size: CGFloat = 36
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
        profileButton.contentEdgeInsets = .zero
        profileButton.imageEdgeInsets = .zero
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
