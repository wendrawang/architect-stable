import XCTest
import UIKit
import CoreKit
@testable import RouterKit

@MainActor
final class OverlayWindowControllerTests: XCTestCase {
    private var logger = TestLogger()

    func test_rootViewControllerIsNilWhileNoOverlayIsActive() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        let overlay = OverlayWindowController(window: window, logger: logger)
        XCTAssertNil(window.rootViewController, "Touches must pass through when nothing is showing")
        XCTAssertFalse(overlay.isPresenting)
        XCTAssertTrue(window.isHidden)
    }

    func test_lowerPriorityOverlayQueuesBehindAHigherOne() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        let overlay = OverlayWindowController(window: window, logger: logger)
        let forceUpdate = UIViewController()
        let session = UIViewController()

        overlay.present(forceUpdate, level: .forceUpdate)
        XCTAssertTrue(window.rootViewController === forceUpdate)

        overlay.present(session, level: .session)
        XCTAssertTrue(window.rootViewController === forceUpdate,
                      "A lower level must never paint over a higher one")
        XCTAssertEqual(overlay.visibleLevel, .forceUpdate)

        overlay.dismissTop()
        XCTAssertTrue(window.rootViewController === session, "The queued overlay must be revealed")
        XCTAssertEqual(overlay.visibleLevel, .session)

        overlay.dismissTop()
        XCTAssertNil(window.rootViewController)
        XCTAssertTrue(window.isHidden)
    }

    func test_higherPriorityOverlayTakesOverImmediately() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        let overlay = OverlayWindowController(window: window, logger: logger)
        let blocking = UIViewController()
        let forceUpdate = UIViewController()

        overlay.present(blocking, level: .blocking)
        overlay.present(forceUpdate, level: .forceUpdate)
        XCTAssertTrue(window.rootViewController === forceUpdate)

        overlay.dismissTop()
        XCTAssertTrue(window.rootViewController === blocking)
    }

    func test_dismissAllClearsTheQueue() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        let overlay = OverlayWindowController(window: window, logger: logger)
        overlay.present(UIViewController(), level: .blocking)
        overlay.present(UIViewController(), level: .session)
        overlay.dismissAll()
        XCTAssertFalse(overlay.isPresenting)
        XCTAssertNil(window.rootViewController)
    }
}
