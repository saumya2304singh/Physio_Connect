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
                // Default to auth, then swap to home if a session is present.
                let nav = UINavigationController(rootViewController: PhysioAuthViewController())
                window?.rootViewController = nav
                Task { @MainActor in
                    let hasSession = (try? await SupabaseManager.shared.client.auth.session) != nil
                    if hasSession {
                        nav.setViewControllers([PhysioHomeViewController()], animated: false)
                    }
                }
            }
        } else {
            // First time: show Continue screen
            window?.rootViewController = RoleSelectionViewController()
        }

        window?.makeKeyAndVisible()
    }
}
