//
//  MainTabBarController.swift
//  Physio_Connect
//
//  Created by user@8 on 02/01/26.
//
import UIKit

final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        styleTabBar()
        delegate = self
    }

    private func setupTabs() {
        // Home
        let homeVC = HomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.navigationBar.prefersLargeTitles = true
        homeNav.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        // Appointments
        let apptVC = AppointmentsViewController() // we will build next
        let apptNav = UINavigationController(rootViewController: apptVC)
        apptNav.navigationBar.prefersLargeTitles = true
        apptNav.tabBarItem = UITabBarItem(
            title: "Appointments",
            image: UIImage(systemName: "calendar"),
            selectedImage: UIImage(systemName: "calendar.circle.fill")
        )

        // Videos
        let videosVC = VideosViewController() // placeholder if you already have
        let videosNav = UINavigationController(rootViewController: videosVC)
        videosNav.navigationBar.prefersLargeTitles = true
        videosNav.tabBarItem = UITabBarItem(
            title: "Videos",
            image: UIImage(systemName: "play.rectangle"),
            selectedImage: UIImage(systemName: "play.rectangle.fill")
        )

        // Articles
        let articlesVC = ArticlesViewController() // placeholder if you already have
        let articlesNav = UINavigationController(rootViewController: articlesVC)
        articlesNav.navigationBar.prefersLargeTitles = true
        articlesNav.tabBarItem = UITabBarItem(
            title: "Articles",
            image: UIImage(systemName: "doc.text"),
            selectedImage: UIImage(systemName: "doc.text.fill")
        )

        viewControllers = [homeNav, apptNav, videosNav, articlesNav]
        selectedIndex = 0
    }

    private func styleTabBar() {
        TabBarGlassStyle.apply(to: tabBar, accentColor: UIColor(hex: "1E6EF7"))
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        tabBar.isUserInteractionEnabled = true
        guard let nav = viewController as? UINavigationController,
              let visible = nav.visibleViewController else { return }
        nav.setNavigationBarHidden(false, animated: false)
        nav.navigationBar.prefersLargeTitles = true
        visible.navigationItem.largeTitleDisplayMode = .automatic
        nav.navigationBar.setNeedsLayout()
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        true
    }
}
