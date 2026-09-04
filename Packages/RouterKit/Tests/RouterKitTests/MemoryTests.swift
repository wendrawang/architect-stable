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

    // 6.4.3, narrowed. See the note below and README.md.
    //
    // The brief asks for "present a sheet, dismiss it, assert deallocation". That cannot be
    // proved in this test bundle. A SwiftPM test target has no application or scene
    // lifecycle, so a modal presentation half-happens — `presentedViewController` is set —
    // but its transition never settles: across three CI runs `isBeingPresented` stayed true
    // and the transition coordinator stayed non-nil until the deadline. UIKit drops any
    // dismissal issued while a presentation is in flight, so the sheet could never be torn
    // down and the deallocation assertion could never mean anything.
    //
    // What is provable here is the ownership row that actually matters: the navigator holds
    // no reference to a controller it created. That is asserted below, without a window, so
    // no stalled transition can hold the controller instead. End-to-end modal deallocation
    // belongs to the Part 6.6 Instruments pass, which is listed as not-run in README.md.
    // It is not silently dropped and the test is not disabled.
    func test_navigatorRetainsNothingItPresents() {
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
        let navigator: StackNavigator = autoreleasepool {
            let navigationController = UINavigationController()
            let created = makeNavigator(registry: registry, navigationController: navigationController)
            created.setStack([GammaRoute(value: 0)], isAnimated: false)
            created.present(BetaRoute(value: 1), as: .sheet(.medium), isAnimated: false)
            XCTAssertNotNil(weakController, "The sheet was never built, so nothing is proved")
            XCTAssertNotNil(weakViewModel)
            return created
        }
        // The presenting stack is gone. Anything still alive is held by the navigator.
        XCTAssertNil(navigator.navigationController)
        XCTAssertTrue(waitUntil { weakController == nil },
                      "The navigator is retaining a controller it presented")
        XCTAssertTrue(waitUntil { weakViewModel == nil },
                      "The navigator is retaining a view model it never owned")
    }

    /// Recovers the coverage the narrowing above gives up: that `.sheet` really does route
    /// through the shim and apply the house defaults. This needs no completed transition.
    func test_sheetPresentationAppliesTheHouseDefaults() throws {
        var presented: UIViewController?
        let registry = RouteRegistry()
        registry.register(GammaRoute.self) { _, _ in UIViewController() }
        registry.register(BetaRoute.self) { _, _ in
            let controller = UIViewController()
            presented = controller
            return controller
        }
        let navigationController = UINavigationController()
        let navigator = makeNavigator(registry: registry, navigationController: navigationController)
        navigator.setStack([GammaRoute(value: 0)], isAnimated: false)
        navigator.present(BetaRoute(value: 1), as: .sheet(.medium), isAnimated: false)

        let controller = try XCTUnwrap(presented, "The sheet route was never resolved")
        XCTAssertEqual(controller.modalPresentationStyle, .pageSheet)
        let sheet = try XCTUnwrap(controller.sheetPresentationController)
        XCTAssertEqual(sheet.detents, [.medium()])
        XCTAssertTrue(sheet.prefersGrabberVisible)
        XCTAssertFalse(sheet.prefersScrollingExpandsWhenScrolledToEdge)
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
