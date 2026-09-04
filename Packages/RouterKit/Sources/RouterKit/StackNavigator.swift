import UIKit
import CoreKit

/// One per tab. Owns the route mirror of a `UINavigationController`'s stack.
///
/// Holds the navigation controller **weakly**: the tab bar controller owns it. If it
/// has gone away every call logs and no-ops rather than trapping.
@MainActor
public final class StackNavigator: NSObject, Navigator {
    /// The routes currently on the stack, root first. Mirrors `viewControllers`.
    public private(set) var routeStack: [any Route] = []
    weak var navigationController: UINavigationController?
    weak var host: TabHost?
    let registry: RouteRegistry
    let overlay: OverlayWindowController
    let logger: any Logger
    let signpost = PerformanceSignpost(category: .navigation)
    /// True between issuing a push and the navigation controller reporting it shown.
    /// Internal rather than private so the guard can be driven deterministically in tests
    /// without a window, a run loop or a transition coordinator test double.
    var isPushInFlight = false
    private var firstFrameToken: PerformanceSignpost.Token?

    public init(navigationController: UINavigationController,
                registry: RouteRegistry,
                overlay: OverlayWindowController,
                logger: any Logger) {
        self.navigationController = navigationController
        self.registry = registry
        self.overlay = overlay
        self.logger = logger
        super.init()
        navigationController.delegate = self
    }

    /// True while a push or an interactive transition is in flight.
    ///
    /// Checked before every push. Two taps on the same row inside one animation is a
    /// real defect class in the legacy app, and the second push is always the wrong one.
    /// The transition coordinator alone is not enough: it is nil for the first frame
    /// after `pushViewController` returns, which is exactly the double-tap window.
    var isTransitioning: Bool {
        if isPushInFlight {
            return true
        }
        return navigationController?.transitionCoordinator != nil
    }

    /// Clears the in-flight marker and closes the first-frame interval.
    func finishPush() {
        isPushInFlight = false
        guard let token = firstFrameToken else { return }
        signpost.end(.screenFirstFrame, token: token)
        firstFrameToken = nil
    }

    /// Resynchronises the mirror after the stack shrank underneath us.
    func truncateRouteStack(to count: Int) {
        guard count >= 0, count < routeStack.count else { return }
        routeStack = Array(routeStack.prefix(count))
    }

    public func push(_ route: any Route, isAnimated: Bool) {
        guard let navigationController else {
            logger.error("push ignored: the navigation controller is gone")
            return
        }
        guard !isTransitioning else {
            logger.debug("push ignored: a transition is already in flight")
            return
        }
        guard let controller = makeController(for: route) else { return }
        firstFrameToken = signpost.begin(.screenFirstFrame)
        isPushInFlight = true
        routeStack.append(route)
        navigationController.pushViewController(controller, animated: isAnimated)
        verifyStackParity()
    }

    public func replaceTop(with route: any Route, isAnimated: Bool) {
        guard let navigationController else {
            logger.error("replaceTop ignored: the navigation controller is gone")
            return
        }
        guard let controller = makeController(for: route) else { return }
        var controllers = navigationController.viewControllers
        guard !controllers.isEmpty, !routeStack.isEmpty else {
            setStack([route], isAnimated: isAnimated)
            return
        }
        controllers[controllers.count - 1] = controller
        routeStack[routeStack.count - 1] = route
        navigationController.setViewControllers(controllers, animated: isAnimated)
        verifyStackParity()
    }

    public func setStack(_ routes: [any Route], isAnimated: Bool) {
        guard let navigationController else {
            logger.error("setStack ignored: the navigation controller is gone")
            return
        }
        var controllers: [UIViewController] = []
        var accepted: [any Route] = []
        for route in routes {
            guard let controller = makeController(for: route) else { continue }
            controllers.append(controller)
            accepted.append(route)
        }
        routeStack = accepted
        navigationController.setViewControllers(controllers, animated: isAnimated)
        verifyStackParity()
    }

    public func pop(isAnimated: Bool) {
        guard let navigationController else {
            logger.error("pop ignored: the navigation controller is gone")
            return
        }
        guard routeStack.count > 1 else {
            logger.debug("pop ignored: already at the root")
            return
        }
        routeStack.removeLast()
        navigationController.popViewController(animated: isAnimated)
        verifyStackParity()
    }

    public func popToRoot(isAnimated: Bool) {
        guard let navigationController else {
            logger.error("popToRoot ignored: the navigation controller is gone")
            return
        }
        guard let root = routeStack.first else { return }
        routeStack = [root]
        navigationController.popToRootViewController(animated: isAnimated)
        verifyStackParity()
    }

    public func popTo<R: Route>(_ type: R.Type, isAnimated: Bool) {
        guard let navigationController else {
            logger.error("popTo ignored: the navigation controller is gone")
            return
        }
        let key = routeKey(for: type)
        guard let index = routeStack.lastIndex(where: { routeKey(for: Swift.type(of: $0)) == key }) else {
            logger.debug("popTo ignored: \(key) is not on the stack")
            return
        }
        guard index < navigationController.viewControllers.count else { return }
        routeStack = Array(routeStack.prefix(index + 1))
        navigationController.popToViewController(navigationController.viewControllers[index],
                                                 animated: isAnimated)
        verifyStackParity()
    }
}
