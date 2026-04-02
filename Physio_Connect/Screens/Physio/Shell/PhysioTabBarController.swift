//
//  PhysioTabBarController.swift
//  Physio_Connect
//
//  Created by user@8 on 08/01/26.
//

import UIKit

final class PhysioTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        styleTabBar()
    }

    private func setupTabs() {
        let home = UINavigationController(rootViewController: PhysioHomeViewController())
        home.navigationBar.prefersLargeTitles = true
        home.tabBarItem = UITabBarItem(
            title: "Dashboard",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        let appointments = UINavigationController(rootViewController: PhysioAppointmentsViewController())
        appointments.navigationBar.prefersLargeTitles = true
        appointments.tabBarItem = UITabBarItem(
            title: "Appointments",
            image: UIImage(systemName: "calendar"),
            selectedImage: UIImage(systemName: "calendar.circle.fill")
        )

        let programs = UINavigationController(rootViewController: PhysioProgramsViewController())
        programs.navigationBar.prefersLargeTitles = true
        programs.tabBarItem = UITabBarItem(
            title: "Programs",
            image: UIImage(systemName: "square.grid.2x2"),
            selectedImage: UIImage(systemName: "square.grid.2x2.fill")
        )

        let reports = UINavigationController(rootViewController: PhysioReportsViewController())
        reports.navigationBar.prefersLargeTitles = true
        reports.tabBarItem = UITabBarItem(
            title: "Reports",
            image: UIImage(systemName: "chart.bar"),
            selectedImage: UIImage(systemName: "chart.bar.fill")
        )

        viewControllers = [home, appointments, programs, reports]
        selectedIndex = 0
    }

    private func styleTabBar() {
        TabBarGlassStyle.apply(to: tabBar, accentColor: UIColor(hex: "1E6EF7"))
    }
}

// Simple placeholder until real screens are wired
private final class PlaceholderViewController: UIViewController {
    init(title: String) {
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "E6F1FF")
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = UIColor.black.withAlphaComponent(0.7)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
