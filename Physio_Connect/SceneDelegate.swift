import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)

        // Decide root based on selected role
        if let role = RoleStore.shared.currentRole {
            switch role {
            case .patient:
                window?.rootViewController = MainTabBarController() // ✅ keep patient app same
            case .physiotherapist:
                window?.rootViewController = UINavigationController(rootViewController: PhysioHomePlaceholderViewController())
            }
        } else {
            // First time: show Continue screen
            window?.rootViewController = RoleSelectionViewController()
        }

        window?.makeKeyAndVisible()
    }
}
