//
//  AppLogout.swift
//  Physio_Connect
//
//  Created by user@8 on 07/01/26.
//
import UIKit

enum AppLogout {

    static func backToRoleSelection(from view: UIView?) {
        // 1) clear stored role
        RoleStore.shared.clear()

        // 2) reset root
        let roleVC = RoleSelectionViewController()
        RootRouter.setRoot(roleVC, window: findWindow(from: view))
    }

    private static func findWindow(from view: UIView?) -> UIWindow? {
        if let w = view?.window { return w }
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

