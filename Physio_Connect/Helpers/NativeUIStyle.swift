import UIKit

enum NativeUIStyle {
    static func configureGlobalAppearance() {
        configureNavigationBar()
        configureBarButtons()
        configureSegmentedControl()
        UIButton.enableGlobalPillStyle()
    }

    static func styleSearchBar(_ searchBar: UISearchBar, placeholder: String) {
        searchBar.placeholder = placeholder
        searchBar.searchBarStyle = .minimal
        searchBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        searchBar.isTranslucent = true
        searchBar.backgroundColor = .clear
        searchBar.barTintColor = .clear
        searchBar.searchTextField.backgroundColor = .white
        searchBar.searchTextField.layer.cornerRadius = 20
        searchBar.searchTextField.layer.cornerCurve = .continuous
        searchBar.searchTextField.layer.masksToBounds = true
        searchBar.searchTextField.borderStyle = .none
        searchBar.searchTextField.layer.borderWidth = 0
    }

    static func makeAvatarButton(target: Any?, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        button.setImage(UIImage(systemName: "person.crop.circle", withConfiguration: config), for: .normal)
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 36).isActive = true
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }

    static func makeAvatarBarButtonItem(target: Any?, action: Selector) -> UIBarButtonItem {
        let config = UIImage.SymbolConfiguration(pointSize: 19, weight: .semibold)
        let image = UIImage(systemName: "person.crop.circle", withConfiguration: config)
        let item = UIBarButtonItem(image: image, style: .plain, target: target, action: action)
        item.tintColor = .label
        return item
    }

    static func applyTabRootNavigation(
        for viewController: UIViewController,
        title: String,
        rightItem: UIBarButtonItem?
    ) {
        if viewController.title != title {
            viewController.title = title
        }
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .label
        titleLabel.font = UITheme.Typography.screenTitle
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.sizeToFit()
        let leftTitleItem = UIBarButtonItem(customView: titleLabel)
        if #available(iOS 26.0, *) {
            leftTitleItem.hidesSharedBackground = true
        }
        viewController.navigationItem.title = nil
        viewController.navigationItem.titleView = nil
        if viewController.navigationItem.largeTitleDisplayMode != .never {
            viewController.navigationItem.largeTitleDisplayMode = .never
        }
        viewController.navigationItem.leftItemsSupplementBackButton = false
        viewController.navigationItem.leftBarButtonItem = leftTitleItem
        if viewController.navigationItem.rightBarButtonItem !== rightItem {
            viewController.navigationItem.rightBarButtonItem = rightItem
        }
        let navBar = viewController.navigationController?.navigationBar
        if navBar?.prefersLargeTitles != false {
            navBar?.prefersLargeTitles = false
        }
        navBar?.setNeedsLayout()
    }

    static func styleFloatingSearchButton(_ button: UIButton) {
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let icon = UIImage(systemName: "magnifyingglass", withConfiguration: iconConfig)
        button.setImage(icon, for: .normal)
        button.setImage(icon, for: .highlighted)
        button.tintColor = UIColor(hex: "111827")
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.imageEdgeInsets = .zero

        button.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.88)
        button.layer.cornerRadius = 30
        button.layer.cornerCurve = .continuous
        button.layer.masksToBounds = false
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.62).cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.12
        button.layer.shadowRadius = 12
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
    }

    private static func configureNavigationBar() {
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithTransparentBackground()
        standardAppearance.backgroundEffect = nil
        standardAppearance.backgroundColor = .clear
        standardAppearance.shadowColor = .clear
        standardAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UITheme.Typography.cardTitle,
            .baselineOffset: 1
        ]
        standardAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UITheme.Typography.screenTitle,
            .baselineOffset: 2
        ]

        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()
        scrollEdgeAppearance.backgroundEffect = nil
        scrollEdgeAppearance.backgroundColor = .clear
        scrollEdgeAppearance.shadowColor = .clear
        scrollEdgeAppearance.titleTextAttributes = standardAppearance.titleTextAttributes
        scrollEdgeAppearance.largeTitleTextAttributes = standardAppearance.largeTitleTextAttributes

        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = standardAppearance
        navBar.scrollEdgeAppearance = scrollEdgeAppearance
        navBar.compactAppearance = standardAppearance
        navBar.compactScrollEdgeAppearance = standardAppearance
        navBar.tintColor = UIColor.label
        navBar.prefersLargeTitles = true
        navBar.isTranslucent = true
    }

    private static func configureBarButtons() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UITheme.Typography.button
        ]
        let barButtonAppearance = UIBarButtonItem.appearance()
        barButtonAppearance.setTitleTextAttributes(attributes, for: .normal)
        barButtonAppearance.setTitleTextAttributes(attributes, for: .highlighted)
    }

    private static func configureSegmentedControl() {
        let segmented = UISegmentedControl.appearance()
        segmented.selectedSegmentTintColor = UIColor.tintColor
        segmented.setTitleTextAttributes([
            .foregroundColor: UIColor.label,
            .font: UITheme.Typography.buttonSmall
        ], for: .normal)
        segmented.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UITheme.Typography.buttonSmall
        ], for: .selected)
    }
}

final class NativeEmptyStateView: UIView {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(icon: String, title: String, message: String) {
        iconView.image = UIImage(systemName: icon)
        titleLabel.text = title
        messageLabel.text = message
    }

    private func build() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.white.withAlphaComponent(0.92)
        layer.cornerRadius = 22
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.55).cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 4)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = UIColor(hex: "1E6EF7")
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        iconView.contentMode = .scaleAspectFit

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UITheme.Typography.cardTitle
        titleLabel.textColor = UIColor(hex: "102A43")
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2

        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = UITheme.Typography.bodySmallMedium
        messageLabel.textColor = UIColor.black.withAlphaComponent(0.58)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(messageLabel)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
}
