import UIKit
import CoreKit

/// Owns the tab bar controller and one `StackNavigator` per tab.
///
/// Strong on the navigators, which are weak on their navigation controllers, which the
/// tab bar controller owns. That is the whole ownership graph and it has no cycle.
@MainActor
public final class TabHost {
    public let tabBarController: UITabBarController
    private let order: [TabIdentifier]
    private let navigators: [TabIdentifier: StackNavigator]
    private let logger: any Logger

    public init(tabs: [Item],
                registry: RouteRegistry,
                overlay: OverlayWindowController,
                logger: any Logger) {
        var built: [TabIdentifier: StackNavigator] = [:]
        var controllers: [UIViewController] = []
        for tab in tabs {
            let navigationController = UINavigationController()
            navigationController.tabBarItem = tab.barItem
            built[tab.identifier] = StackNavigator(navigationController: navigationController,
                                                   registry: registry,
                                                   overlay: overlay,
                                                   logger: logger)
            controllers.append(navigationController)
        }
        self.tabBarController = UITabBarController()
        self.order = tabs.map { $0.identifier }
        self.navigators = built
        self.logger = logger
        tabBarController.viewControllers = controllers
        for navigator in built.values {
            navigator.host = self
        }
        installRaisedControls(tabs)
    }

    public func navigator(for tab: TabIdentifier) -> (any Navigator)? {
        navigators[tab]
    }

    /// Selects a tab, optionally returning it to its root first.
    ///
    /// Resetting is not the default: returning to a tab mid-flow and finding it rewound
    /// is the behaviour customers complain about.
    public func switchTab(_ tab: TabIdentifier, isStackReset: Bool) {
        guard let index = order.firstIndex(of: tab) else {
            logger.error("switchTab ignored: unknown tab \(tab.rawValue)")
            return
        }
        tabBarController.selectedIndex = index
        guard isStackReset else { return }
        navigators[tab]?.popToRoot(isAnimated: false)
    }

    /// Places raised controls in the tab bar controller's own view rather than in the bar.
    ///
    /// A subview that overflows `UITabBar` is drawn but not tappable, because hit testing
    /// stops at the bar's bounds. Hosting it one level up keeps the whole control tappable
    /// without subclassing `UITabBar`, which `UITabBarController` does not allow replacing.
    private func installRaisedControls(_ tabs: [Item]) {
        let bar = tabBarController.tabBar
        for tab in tabs {
            guard let control = tab.raisedControl else { continue }
            control.translatesAutoresizingMaskIntoConstraints = false
            tabBarController.view.addSubview(control)
            NSLayoutConstraint.activate([
                control.centerXAnchor.constraint(equalTo: bar.centerXAnchor),
                control.centerYAnchor.constraint(equalTo: bar.topAnchor,
                                                 constant: -tab.raisedOffset)
            ])
            let identifier = tab.identifier
            control.addAction(UIAction { [weak self] _ in
                self?.switchTab(identifier, isStackReset: false)
            }, for: .touchUpInside)
        }
    }
}
