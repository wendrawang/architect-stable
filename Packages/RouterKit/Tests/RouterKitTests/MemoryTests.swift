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

    // 6.4.3 — "present a sheet, dismiss it, assert deallocation" — cannot be delivered as a
    // unit test here, and five CI rounds established why rather than assuming it:
    //
    //   1. A 50 ms sleep after dismissal was too short.        -> 2 failures
    //   2. A 2 s deadline did not help; the waits ran out.     -> 2 failures, suite 0.4s -> 8.6s
    //   3. Splitting the dismissal into its own assertion.     -> 3 failures: the dismissal stalls
    //   4. Waiting for the presentation to settle first.       -> 4 failures: it never settles
    //   5. Dropping the window entirely.                       -> UIKit never retains the
    //      controller at all, so a non-retention assertion cannot fail and proves nothing.
    //
    // A SwiftPM test target has no application or scene lifecycle, so `present` never
    // completes and every assertion downstream of it is either stalled or vacuous. End-to-end
    // modal deallocation belongs to the Part 6.6 Instruments pass, which README.md lists as
    // not run. The two tests below replace what is provable without UIKit's presentation
    // lifecycle; neither is a weakened version of 6.4.3 and neither is skipped.

    /// The house sheet defaults are the shim's contract, so they are asserted on the shim.
    ///
    /// Going through `Navigator.present` made this depend on UIKit's presentation lifecycle:
    /// round 5 showed the detents and grabber being discarded when UIKit built a fresh
    /// presentation controller for a transition that then never settled.
    func test_sheetDefaultsAreAppliedByTheShim() throws {
        let controller = UIViewController()
        AvailabilityShim.applySheetPresentation(to: controller, isMediumDetent: true)
        XCTAssertEqual(controller.modalPresentationStyle, .pageSheet)
        let sheet = try XCTUnwrap(controller.sheetPresentationController)
        XCTAssertEqual(sheet.detents, [.medium()])
        XCTAssertTrue(sheet.prefersGrabberVisible)
        XCTAssertFalse(sheet.prefersScrollingExpandsWhenScrolledToEdge)

        let large = UIViewController()
        AvailabilityShim.applySheetPresentation(to: large, isMediumDetent: false)
        XCTAssertEqual(large.sheetPresentationController?.detents, [.large()])
    }

    /// A modal is built once, through the registry, and never enters the route mirror.
    ///
    /// Asserted on our own state rather than on UIKit's, so it holds whatever the host does
    /// with the presentation afterwards.
    func test_presentBuildsTheDestinationOnceAndLeavesTheStackAlone() {
        var buildCount = 0
        let registry = RouteRegistry()
        registry.register(GammaRoute.self) { _, _ in UIViewController() }
        registry.register(BetaRoute.self) { _, _ in
            buildCount += 1
            return UIViewController()
        }
        let navigationController = UINavigationController()
        let navigator = makeNavigator(registry: registry, navigationController: navigationController)
        navigator.setStack([GammaRoute(value: 0)], isAnimated: false)
        XCTAssertEqual(buildCount, 0, "Registration must not build anything")

        navigator.present(BetaRoute(value: 1), as: .sheet(.medium), isAnimated: false)
        XCTAssertEqual(buildCount, 1, "The factory runs once, at present time")
        XCTAssertEqual(navigator.routeStack.count, 1, "A modal must not enter the route mirror")
        XCTAssertEqual(navigationController.viewControllers.count, 1)
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
}
