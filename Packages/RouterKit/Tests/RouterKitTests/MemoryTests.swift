import XCTest
import UIKit
import SwiftUI
import CoreKit
import CoreKitTestSupport
@testable import RouterKit

/// Part 6 of the brief: a leak is a build failure, not a finding.
@MainActor
final class MemoryTests: XCTestCase {
    private var logger = TestLogger()

    private var probeTypeName: String {
        String(reflecting: ProbeViewModel.self)
    }

    override func setUp() {
        super.setUp()
        #if DEBUG
        LifecycleTracker.shared.reset()
        #endif
    }

    // 6.4.1
    func test_pushThenPopDeallocatesTheControllerAndItsViewModel() {
        weak var weakController: UIViewController?
        weak var weakViewModel: ProbeViewModel?
        let registry = RouteRegistry()
        registry.register(GammaRoute.self) { _, _ in UIViewController() }
        registry.register(AlphaRoute.self) { route, _ in
            let viewModel = ProbeViewModel(title: "alpha-\(route.value)")
            let screen = HostingScreen(chrome: ScreenChrome(title: "Alpha"),
                                       rootView: ProbeView(viewModel: viewModel))
            weakViewModel = viewModel
            weakController = screen
            return screen
        }
        let navigationController = UINavigationController()
        let navigator = makeNavigator(registry: registry, navigationController: navigationController)
        trackForMemoryLeaks(navigator)
        navigator.setStack([GammaRoute(value: 0)], isAnimated: false)

        autoreleasepool {
            navigator.push(AlphaRoute(value: 1), isAnimated: false)
            navigator.finishPush()
            XCTAssertNotNil(weakController)
            XCTAssertNotNil(weakViewModel)
            navigator.pop(isAnimated: false)
        }
        XCTAssertNil(weakController, "The popped view controller is still alive")
        XCTAssertNil(weakViewModel, "The view model outlived its view controller")
    }

    // 6.4.2
    func test_tenPushesThenPopToRootDeallocatesAllTen() {
        #if DEBUG
        let registry = TestFixture.makeProbeRegistry()
        registry.register(GammaRoute.self) { _, _ in UIViewController() }
        let navigationController = UINavigationController()
        let navigator = makeNavigator(registry: registry, navigationController: navigationController)
        navigator.setStack([GammaRoute(value: 0)], isAnimated: false)
        let baseline = LifecycleTracker.shared.liveCount(for: probeTypeName)

        autoreleasepool {
            for index in 1...10 {
                navigator.push(AlphaRoute(value: index), isAnimated: false)
                navigator.finishPush()
            }
            XCTAssertEqual(LifecycleTracker.shared.liveCount(for: probeTypeName), baseline + 10)
            navigator.popToRoot(isAnimated: false)
        }
        XCTAssertEqual(LifecycleTracker.shared.liveCount(for: probeTypeName), baseline,
                       "popToRoot must release every intermediate screen")
        #endif
    }

    // 6.4.3
    func test_presentedSheetDeallocatesAfterDismiss() {
        weak var weakController: UIViewController?
        weak var weakViewModel: ProbeViewModel?
        let registry = RouteRegistry()
        registry.register(GammaRoute.self) { _, _ in UIViewController() }
        registry.register(BetaRoute.self) { _, _ in
            let viewModel = ProbeViewModel(title: "sheet")
            let screen = HostingScreen(chrome: ScreenChrome(title: "Sheet"),
                                       rootView: ProbeView(viewModel: viewModel))
            weakViewModel = viewModel
            weakController = screen
            return screen
        }
        let navigationController = UINavigationController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        let navigator = makeNavigator(registry: registry, navigationController: navigationController)
        navigator.setStack([GammaRoute(value: 0)], isAnimated: false)

        autoreleasepool {
            navigator.present(BetaRoute(value: 1), as: .sheet(.medium), isAnimated: false)
            // `presentedViewController` is set before the presentation transition finishes,
            // and UIKit silently ignores a dismissal issued while that transition is still
            // in flight. Waiting only for the property to be non-nil is what stalled this
            // test: the dismissal was dropped and the sheet was never torn down.
            XCTAssertTrue(waitUntil { isPresentationSettled(on: navigationController) },
                          "The sheet presentation never settled, so nothing below proves anything")
            XCTAssertNotNil(weakController)
            navigator.dismiss(isAnimated: false)
        }

        // The dismissal must also complete while the presenting controller is still in a
        // window, so the window is torn down last. The navigator itself stores no reference
        // to anything it presents.
        XCTAssertTrue(waitUntil { navigationController.presentedViewController == nil },
                      "The dismissal never completed, which is a stalled transition, not a leak")
        XCTAssertTrue(waitUntil { weakController == nil },
                      "The dismissed sheet was still alive after 2s. That is a retain cycle.")
        XCTAssertTrue(waitUntil { weakViewModel == nil },
                      "The sheet's view model was still alive after 2s. That is a retain cycle.")
        window.rootViewController = nil
        window.isHidden = true
    }

    // 6.4.4
    func test_overlayDeallocatesAndClearsTheWindowRoot() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        let overlay = OverlayWindowController(window: window, logger: logger)
        weak var weakController: UIViewController?

        autoreleasepool {
            let controller = UIViewController()
            weakController = controller
            overlay.present(controller, level: .session)
            XCTAssertNotNil(window.rootViewController)
            overlay.dismissTop()
        }
        XCTAssertNil(window.rootViewController, "An inactive overlay window must not block touches")
        XCTAssertNil(weakController, "The overlay view controller is still alive")
    }

    // 6.4.5
    func test_navigatorSurvivesADeadNavigationController() {
        let registry = TestFixture.makeRegistry()
        let navigator: StackNavigator = autoreleasepool {
            StackNavigator(navigationController: UINavigationController(),
                           registry: registry,
                           overlay: TestFixture.makeOverlay(logger: logger),
                           logger: logger)
        }
        XCTAssertNil(navigator.navigationController)
        navigator.push(AlphaRoute(value: 1), isAnimated: false)
        navigator.popToRoot(isAnimated: false)
        navigator.dismissAllModals(isAnimated: false)
        XCTAssertTrue(navigator.routeStack.isEmpty)
        XCTAssertFalse(logger.errorMessages.isEmpty, "Every dead-controller call must be logged")
    }

    // 6.4.6
    func test_registryDoesNotResurrectADeallocatedDependencyContainer() {
        let registry = RouteRegistry()
        weak var weakContainer: TestContainer?

        autoreleasepool {
            let container = TestContainer(label: "sample")
            weakContainer = container
            registry.register(AlphaRoute.self) { [weak container] _, _ in
                let title = container?.label ?? "container is gone"
                let viewModel = ProbeViewModel(title: title)
                return HostingScreen(chrome: ScreenChrome(title: title),
                                     rootView: ProbeView(viewModel: viewModel))
            }
        }
        XCTAssertNil(weakContainer, "The registry captured the container strongly")
        XCTAssertEqual(registry.registrationCount, 1, "The factory must survive its container")
    }

    // 6.5
    func test_fiftyPushPopCyclesReturnToTheLiveCountBaseline() {
        #if DEBUG
        let registry = TestFixture.makeProbeRegistry()
        registry.register(GammaRoute.self) { _, _ in UIViewController() }
        let navigationController = UINavigationController()
        let navigator = makeNavigator(registry: registry, navigationController: navigationController)
        navigator.setStack([GammaRoute(value: 0)], isAnimated: false)
        let baseline = LifecycleTracker.shared.liveCount(for: probeTypeName)

        for index in 1...50 {
            autoreleasepool {
                navigator.push(AlphaRoute(value: index), isAnimated: false)
                navigator.finishPush()
                navigator.pop(isAnimated: false)
            }
        }
        XCTAssertEqual(LifecycleTracker.shared.liveCount(for: probeTypeName), baseline,
                       "One object leaked per navigation is invisible in a single push/pop test")
        #endif
    }

    private func makeNavigator(registry: RouteRegistry,
                               navigationController: UINavigationController) -> StackNavigator {
        StackNavigator(navigationController: navigationController,
                       registry: registry,
                       overlay: TestFixture.makeOverlay(logger: logger),
                       logger: logger)
    }

    /// Spins the run loop until the predicate holds or the deadline passes.
    ///
    /// Returns the moment it holds, so a healthy test costs milliseconds and only a genuine
    /// failure pays the full timeout.
    /// True once a modal is on screen and its presentation transition has finished.
    private func isPresentationSettled(on presenter: UIViewController) -> Bool {
        guard let presented = presenter.presentedViewController else { return false }
        return !presented.isBeingPresented && presented.transitionCoordinator == nil
    }

    private func waitUntil(timeout: TimeInterval = 2, isSatisfied: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if isSatisfied() {
                return true
            }
            autoreleasepool {
                RunLoop.current.run(until: Date().addingTimeInterval(0.02))
            }
        }
        return isSatisfied()
    }
}
