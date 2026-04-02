import UIKit
import ObjectiveC.runtime

extension UIButton {
    static func enableGlobalPillStyle() {
        _ = Self.globalPillSwizzle
    }

    private static let globalPillSwizzle: Void = {
        guard
            let original = class_getInstanceMethod(UIButton.self, #selector(layoutSubviews)),
            let swizzled = class_getInstanceMethod(UIButton.self, #selector(pc_layoutSubviewsForPill))
        else {
            return
        }
        method_exchangeImplementations(original, swizzled)
    }()

    @objc private func pc_layoutSubviewsForPill() {
        pc_layoutSubviewsForPill()

        guard shouldApplyGlobalPillStyle else { return }
        guard bounds.height > 0 else { return }
        layer.cornerCurve = .continuous
        layer.cornerRadius = bounds.height / 2
        layer.masksToBounds = true
    }

    private var shouldApplyGlobalPillStyle: Bool {
        var view: UIView? = self
        while let current = view {
            if current is UISegmentedControl { return false }
            if current is UITabBar { return false }
            if current is UINavigationBar { return false }
            if current is UIAlertController { return false }
            view = current.superview
        }
        return true
    }
}
