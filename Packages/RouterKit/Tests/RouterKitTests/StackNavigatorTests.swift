import XCTest
import UIKit
import CoreKit
@testable import RouterKit

@MainActor
final class StackNavigatorTests: XCTestCase {
    private var logger = TestLogger()

    func test_routeStackMirrorsPushPopAndPopTo() {
        let (navigator, navigationController) = makeNavigator()
        navigator.setStack([AlphaRoute(value: 0)], isAnimated: false)
        navigator.finishPush()
        navigator.push(BetaRoute(value: 1), isAnimated: false)
        navigator.finishPush()
        navigator.push(GammaRoute(value: 2), isAnimated: false)
        navigator.finishPush()
        XCTAssertEqual(navigator.routeStack.count, 3)
        XCTAssertEqual(navigationController.viewControllers.count, 3)

        navigator.pop(isAnimated: false)
        XCTAssertEqual(navigator.routeStack.count, 2)
        XCTAssertEqual(navigationController.viewControllers.count, 2)

        navigator.push(GammaRoute(value: 3), isAnimated: false)
        navigator.finishPush()
        navigator.popTo(AlphaRoute.self, isAnimated: false)
        XCTAssertEqual(navigator.routeStack.count, 1)
        XCTAssertEqual(navigationController.viewControllers.count, 1)
    }

    func test_setStackReplacesTheWholeStackInOneStep() {
        let (navigator, navigationController) = makeNavigator()
        navigator.setStack([AlphaRoute(value: 0), BetaRoute(value: 1), GammaRoute(value: 2)],
                           isAnimated: false)
        XCTAssertEqual(navigator.routeStack.count, 3)
        XCTAssertEqual(navigationController.viewControllers.count, 3)

        navigator.setStack([AlphaRoute(value: 9)], isAnimated: false)
        XCTAssertEqual(navigator.routeStack.count, 1)
        XCTAssertEqual(navigationController.viewControllers.count, 1)
    }

    func test_replaceTopSwapsOnlyTheTopEntry() {
        let (navigator, navigationController) = makeNavigator()
        navigator.setStack([AlphaRoute(value: 0), BetaRoute(value: 1)], isAnimated: false)
        navigator.replaceTop(with: GammaRoute(value: 7), isAnimated: false)
        XCTAssertEqual(navigator.routeStack.count, 2)
        XCTAssertEqual(navigationController.viewControllers.count, 2)
        XCTAssertTrue(navigator.routeStack[1].isEquivalent(to: GammaRoute(value: 7)))
    }

    func test_routeStackResyncsAfterAnInteractivePop() {
        let (navigator, navigationController) = makeNavigator()
        navigator.setStack([AlphaRoute(value: 0), BetaRoute(value: 1), GammaRoute(value: 2)],
                           isAnimated: false)
        XCTAssertEqual(navigator.routeStack.count, 3)

        // The customer swipes back: UIKit shortens the stack without going through us.
        let shortened = Array(navigationController.viewControllers.dropLast())
        navigationController.setViewControllers(shortened, animated: false)
        navigator.navigationController(navigationController,
                                       didShow: shortened[shortened.count - 1],
                                       animated: false)
        XCTAssertEqual(navigator.routeStack.count, 2)
        XCTAssertTrue(navigator.routeStack[1].isEquivalent(to: BetaRoute(value: 1)))
    }

    func test_pushIsIgnoredWhileATransitionIsInFlight() {
        let (navigator, navigationController) = makeNavigator()
        navigator.setStack([AlphaRoute(value: 0)], isAnimated: false)
        navigator.finishPush()

        navigator.isPushInFlight = true
        navigator.push(BetaRoute(value: 1), isAnimated: false)
        XCTAssertEqual(navigator.routeStack.count, 1, "A push during a transition must be dropped")
        XCTAssertEqual(navigationController.viewControllers.count, 1)

        navigator.navigationController(navigationController,
                                       didShow: navigationController.viewControllers[0],
                                       animated: false)
        navigator.push(BetaRoute(value: 1), isAnimated: false)
        XCTAssertEqual(navigator.routeStack.count, 2, "The next push after didShow must land")
    }

    func test_pushAfterTheNavigationControllerIsGoneLogsAndNoOps() {
        let registry = TestFixture.makeRegistry()
        let navigator: StackNavigator = autoreleasepool {
            let navigationController = UINavigationController()
            return StackNavigator(navigationController: navigationController,
                                  registry: registry,
                                  overlay: TestFixture.makeOverlay(logger: logger),
                                  logger: logger)
        }
        XCTAssertNil(navigator.navigationController, "The tab bar controller owns the stack, not us")
        navigator.push(AlphaRoute(value: 1), isAnimated: false)
        XCTAssertTrue(navigator.routeStack.isEmpty)
        XCTAssertFalse(logger.errorMessages.isEmpty, "A dead navigation controller must be logged")
    }

    private func makeNavigator() -> (StackNavigator, UINavigationController) {
        let navigationController = UINavigationController()
        let navigator = StackNavigator(navigationController: navigationController,
                                       registry: TestFixture.makeRegistry(),
                                       overlay: TestFixture.makeOverlay(logger: logger),
                                       logger: logger)
        return (navigator, navigationController)
    }
}
