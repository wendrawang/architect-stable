import XCTest
import UIKit
import CoreKit
@testable import RouterKit

@MainActor
final class RouteRegistryTests: XCTestCase {
    func test_resolveReturnsTheRegisteredControllerType() throws {
        let registry = TestFixture.makeRegistry()
        let navigator = try makeNavigator(registry: registry)
        let controller = try registry.resolve(AlphaRoute(value: 1), navigator: navigator)
        XCTAssertTrue(controller is AlphaViewController)
    }

    func test_resolveUnregisteredRouteThrowsInsteadOfCrashing() throws {
        let registry = TestFixture.makeRegistry()
        let navigator = try makeNavigator(registry: registry)
        XCTAssertThrowsError(try registry.resolve(OrphanRoute(value: 1), navigator: navigator)) { error in
            guard let routerError = error as? RouterError,
                  case .unregisteredRoute(let key) = routerError else {
                return XCTFail("Expected unregisteredRoute, got \(error)")
            }
            XCTAssertTrue(key.contains("OrphanRoute"))
        }
    }

    func test_duplicateRegistrationKeepsTheFirstFactory() throws {
        let registry = RouteRegistry()
        registry.isDuplicateAssertionEnabled = false
        registry.register(AlphaRoute.self) { _, _ in AlphaViewController() }
        registry.register(AlphaRoute.self) { _, _ in BetaViewController() }
        XCTAssertEqual(registry.registrationCount, 1)
        let navigator = try makeNavigator(registry: registry)
        let controller = try registry.resolve(AlphaRoute(value: 1), navigator: navigator)
        XCTAssertTrue(controller is AlphaViewController)
    }

    func test_isRegisteredDoesNotBuildTheDestination() throws {
        let registry = RouteRegistry()
        var buildCount = 0
        registry.register(AlphaRoute.self) { _, _ in
            buildCount += 1
            return AlphaViewController()
        }
        XCTAssertTrue(registry.isRegistered(AlphaRoute(value: 1)))
        XCTAssertEqual(buildCount, 0, "Registration and inspection must never build a destination")
    }

    private func makeNavigator(registry: RouteRegistry) throws -> StackNavigator {
        let logger = TestLogger()
        return StackNavigator(navigationController: UINavigationController(),
                              registry: registry,
                              overlay: TestFixture.makeOverlay(logger: logger),
                              logger: logger)
    }
}
