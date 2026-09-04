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

    public init(tabs: [TabIdentifier],
                registry: RouteRegistry,
                overlay: OverlayWindowController,
                logger: any Logger) {
        var built: [TabIdentifier: StackNavigator] = [:]
        var controllers: [UIViewController] = []
        for tab in tabs {
            let navigationController = UINavigationController()
            navigationController.tabBarItem = UITabBarItem(title: tab.rawValue, image: nil, tag: 0)
            built[tab] = StackNavigator(navigationController: navigationController,
                                        registry: registry,
                                        overlay: overlay,
                                        logger: logger)
            controllers.append(navigationController)
        }
        self.tabBarController = UITabBarController()
        self.order = tabs
        self.navigators = built
        self.logger = logger
        tabBarController.viewControllers = controllers
        for navigator in built.values {
            navigator.host = self
        }
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
}
