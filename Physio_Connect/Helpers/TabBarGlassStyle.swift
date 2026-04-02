import UIKit

enum TabBarGlassStyle {
    static func apply(to tabBar: UITabBar, accentColor: UIColor = UITheme.Colors.accent) {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.65)
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.06)

        configureItemAppearance(appearance.stackedLayoutAppearance, accentColor: accentColor)
        configureItemAppearance(appearance.inlineLayoutAppearance, accentColor: accentColor)
        configureItemAppearance(appearance.compactInlineLayoutAppearance, accentColor: accentColor)

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = accentColor
        tabBar.unselectedItemTintColor = UIColor.secondaryLabel.withAlphaComponent(0.72)
        tabBar.isTranslucent = true

        tabBar.layer.cornerRadius = 18
        tabBar.layer.cornerCurve = .continuous
        tabBar.layer.borderWidth = 0.5
        tabBar.layer.borderColor = UIColor.white.withAlphaComponent(0.38).cgColor
        tabBar.layer.masksToBounds = false
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOpacity = 0.08
        tabBar.layer.shadowRadius = 10
        tabBar.layer.shadowOffset = CGSize(width: 0, height: 2)
    }

    static func applyFloatingFrame(to tabBarController: UITabBarController) {
        // Intentionally no-op: keep native tab bar metrics to avoid icon/title spacing glitches.
    }

    private static func configureItemAppearance(_ itemAppearance: UITabBarItemAppearance, accentColor: UIColor) {
        let normalColor = UIColor.secondaryLabel.withAlphaComponent(0.78)
        let selectedColor = accentColor

        itemAppearance.normal.iconColor = normalColor
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: normalColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]

        itemAppearance.selected.iconColor = selectedColor
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
    }

}
