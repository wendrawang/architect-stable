import XCTest
import UIKit
import CoreKit
@testable import RouterKit

/// Part 7 of the brief: the apparatus, not a claim.
///
/// These measure two trivial screens. The numbers they produce are not evidence that the
/// app is fast; they exist so the same harness can be pointed at the transfer flow, which
/// is the first real migration target, and so a regression there fails CI.
///
/// Baselines are set from the first run on the CI device class. They are stored by Xcode
/// alongside the scheme; this package has no `.xcodeproj`, so committing them requires the
/// host application project that Part 1 forbids creating here.
@MainActor
final class NavigationPerformanceTests: XCTestCase {
    func test_pushPopCyclePerformance() {
        let logger = SilentLogger()
        let registry = RouteRegistry()
        registry.register(PerformanceRoute.self) { _, _ in UIViewController() }
        let navigationController = UINavigationController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        let overlay = OverlayWindowController(window: window, logger: logger)
        let navigator = StackNavigator(navigationController: navigationController,
                                       registry: registry,
                                       overlay: overlay,
                                       logger: logger)
        navigator.setStack([PerformanceRoute(value: 0)], isAnimated: false)

        let metrics: [XCTMetric] = [
            XCTClockMetric(),
            XCTMemoryMetric(),
            XCTOSSignpostMetric(subsystem: PerformanceSignpost.subsystem,
                                category: "navigation",
                                name: "route.resolve")
        ]
        measure(metrics: metrics) {
            for index in 1...20 {
                navigator.push(PerformanceRoute(value: index), isAnimated: false)
                navigator.finishPush()
                navigator.pop(isAnimated: false)
            }
        }
    }

    func test_registrationCostIsIndependentOfFeatureCount() {
        let registry = RouteRegistry()
        registry.isDuplicateAssertionEnabled = false
        measure(metrics: [XCTMemoryMetric()]) {
            for _ in 1...200 {
                registry.register(PerformanceRoute.self) { _, _ in UIViewController() }
            }
        }
        XCTAssertEqual(registry.registrationCount, 1, "Registration must never build anything")
    }
}

struct PerformanceRoute: Route, Equatable {
    let value: Int
}

final class SilentLogger: Logger {
    func debug(_ message: String) { }
    func info(_ message: String) { }
    func error(_ message: String) { }
}
