import XCTest
import CoreKit
@testable import RouterKit

@MainActor
final class DeepLinkGateTests: XCTestCase {
    private let loggedOut = SessionSnapshot(isAuthenticated: false, isExpired: false)
    private let loggedIn = SessionSnapshot(isAuthenticated: true, isExpired: false)
    private let expired = SessionSnapshot(isAuthenticated: false, isExpired: true)

    func test_sameLinkStashesWhenLoggedOutAndNavigatesWhenLoggedIn() {
        let registry = TestFixture.makeRegistry()
        let stack: [any Route] = [AlphaRoute(value: 0), BetaRoute(value: 1)]
        let link = DeepLink(identifier: "transfer.receipt", stack: stack, isAuthenticationRequired: true)

        XCTAssertEqual(resolveDeepLink(link, session: loggedOut, registry: registry),
                       .requiresLogin(pending: stack))
        XCTAssertEqual(resolveDeepLink(link, session: loggedIn, registry: registry),
                       .routes(stack))
    }

    func test_theFullStackIsEmittedSoBackLandsOnTheDashboard() {
        let registry = TestFixture.makeRegistry()
        let stack: [any Route] = [AlphaRoute(value: 0), BetaRoute(value: 1), GammaRoute(value: 2)]
        let link = DeepLink(identifier: "deep", stack: stack, isAuthenticationRequired: false)
        guard case .routes(let resolved) = resolveDeepLink(link, session: loggedOut, registry: registry) else {
            return XCTFail("A public link must resolve to routes")
        }
        XCTAssertEqual(resolved.count, 3, "The dashboard must not be the entry point of a deep link")
    }

    func test_unregisteredRouteIsRejectedRatherThanStashed() {
        let registry = TestFixture.makeRegistry()
        let link = DeepLink(identifier: "unknown",
                            stack: [OrphanRoute(value: 1)],
                            isAuthenticationRequired: true)
        guard case .rejected(.unregisteredRoute(let key)) = resolveDeepLink(link,
                                                                            session: loggedIn,
                                                                            registry: registry) else {
            return XCTFail("An unregistered destination must be rejected")
        }
        XCTAssertTrue(key.contains("OrphanRoute"))
    }

    func test_emptyStackIsMalformed() {
        let registry = TestFixture.makeRegistry()
        let link = DeepLink(identifier: "empty", stack: [], isAuthenticationRequired: false)
        XCTAssertEqual(resolveDeepLink(link, session: loggedIn, registry: registry),
                       .rejected(.malformed))
    }

    func test_expiredSessionIsRejectedAndNeverStashed() {
        let registry = TestFixture.makeRegistry()
        let link = DeepLink(identifier: "expired",
                            stack: [AlphaRoute(value: 0)],
                            isAuthenticationRequired: true)
        XCTAssertEqual(resolveDeepLink(link, session: expired, registry: registry),
                       .rejected(.sessionExpired))
    }
}
