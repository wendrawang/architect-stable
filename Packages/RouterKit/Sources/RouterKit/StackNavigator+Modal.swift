import UIKit
import CoreKit

extension StackNavigator {
    /// Builds a destination, timing the factory. Returns nil instead of trapping when the
    /// route is unregistered: an unresolvable deep link must not take the app down.
    func makeController(for route: any Route) -> UIViewController? {
        let token = signpost.begin(.routeResolve)
        defer { signpost.end(.routeResolve, token: token) }
        do {
            return try registry.resolve(route, navigator: self)
        } catch {
            logger.error("Route resolution failed: \(error)")
            assertionFailure("Route resolution failed: \(error)")
            return nil
        }
    }

    /// The mirror and the real stack must never diverge. In DEBUG a divergence traps;
    /// in RELEASE the mirror is resynchronised by the delegate callback.
    func verifyStackParity() {
        guard let navigationController else { return }
        let actual = navigationController.viewControllers.count
        guard routeStack.count != actual else { return }
        assertionFailure("routeStack has \(routeStack.count) entries, viewControllers has \(actual)")
    }
}

extension StackNavigator {
    public func present(_ route: any Route, as style: PresentationStyle, isAnimated: Bool) {
        guard let navigationController else {
            logger.error("present ignored: the navigation controller is gone")
            return
        }
        guard let controller = makeController(for: route) else { return }
        switch style {
        case .fullScreen:
            controller.modalPresentationStyle = .fullScreen
            topMostPresented(from: navigationController).present(controller, animated: isAnimated)
        case .sheet(let detent):
            AvailabilityShim.applySheetPresentation(to: controller, isMediumDetent: detent == .medium)
            topMostPresented(from: navigationController).present(controller, animated: isAnimated)
        case .overlay(let level):
            overlay.present(controller, level: level)
        }
    }

    public func dismiss(isAnimated: Bool) {
        if overlay.isPresenting {
            overlay.dismissTop()
            return
        }
        guard let navigationController else {
            logger.error("dismiss ignored: the navigation controller is gone")
            return
        }
        let top = topMostPresented(from: navigationController)
        guard let presenter = top.presentingViewController else {
            logger.debug("dismiss ignored: nothing is presented")
            return
        }
        presenter.dismiss(animated: isAnimated, completion: nil)
    }

    public func dismissAllModals(isAnimated: Bool) {
        overlay.dismissAll()
        guard let navigationController else {
            logger.error("dismissAllModals ignored: the navigation controller is gone")
            return
        }
        var root: UIViewController = navigationController
        while let presenter = root.presentingViewController {
            root = presenter
        }
        root.dismiss(animated: isAnimated, completion: nil)
    }

    public func switchTab(_ tab: TabIdentifier, isStackReset: Bool) {
        guard let host else {
            logger.error("switchTab ignored: this navigator has no tab host")
            return
        }
        host.switchTab(tab, isStackReset: isStackReset)
    }

    private func topMostPresented(from root: UIViewController) -> UIViewController {
        var top = root
        while let next = top.presentedViewController {
            top = next
        }
        return top
    }
}

extension StackNavigator: UINavigationControllerDelegate {
    /// Resynchronises the route mirror after any stack change the customer initiated:
    /// an interactive swipe back, a long press on the back button, or a cancelled swipe.
    ///
    /// The stack only ever shrinks from the top, so truncating to the real count is a
    /// complete resynchronisation and needs no per-controller bookkeeping — which is
    /// what keeps this navigator from retaining a single view controller.
    public func navigationController(_ navigationController: UINavigationController,
                                     didShow viewController: UIViewController,
                                     animated: Bool) {
        finishPush()
        let actual = navigationController.viewControllers.count
        guard actual < routeStack.count else { return }
        truncateRouteStack(to: actual)
    }
}
