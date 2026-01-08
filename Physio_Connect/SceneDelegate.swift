import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)

        // Start on role selection until auth check finishes.
        window?.rootViewController = RoleSelectionViewController()
        window?.makeKeyAndVisible()

        Task { @MainActor in
            let session = try? await SupabaseManager.shared.client.auth.session
            guard session != nil else {
                RoleStore.shared.clear()
                window?.rootViewController = RoleSelectionViewController()
                return
            }

            if let role = RoleStore.shared.currentRole {
                switch role {
                case .patient:
                    window?.rootViewController = MainTabBarController()
                case .physiotherapist:
                    let tab = PhysioTabBarController()
                    window?.rootViewController = tab
                }
            } else {
                window?.rootViewController = RoleSelectionViewController()
            }
        }
    }
}
