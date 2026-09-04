import Foundation

/// The outcome of resolving a deep link. Contains no side effect and performs none.
public enum DeepLinkResolution {
    /// Authenticated and every destination exists. Navigate straight there.
    case routes([any Route])
    /// Valid but unauthenticated. Stash and replay exactly once after login.
    case requiresLogin(pending: [any Route])
    case rejected(DeepLinkRejection)
}

extension DeepLinkResolution: Equatable {
    public static func == (lhs: DeepLinkResolution, rhs: DeepLinkResolution) -> Bool {
        switch (lhs, rhs) {
        case let (.routes(left), .routes(right)):
            return routesAreEquivalent(left, right)
        case let (.requiresLogin(left), .requiresLogin(right)):
            return routesAreEquivalent(left, right)
        case let (.rejected(left), .rejected(right)):
            return left == right
        default:
            return false
        }
    }
}

/// Decides what a deep link means. Pure: no I/O, no navigation, no logging.
///
/// The caller performs the navigation. That split is what makes every deep-link rule
/// testable without a window, a session or a network.
@MainActor
public func resolveDeepLink(_ link: DeepLink,
                            session: SessionSnapshot,
                            registry: RouteRegistry) -> DeepLinkResolution {
    guard !link.stack.isEmpty else {
        return .rejected(.malformed)
    }
    if let unknown = link.stack.first(where: { !registry.isRegistered($0) }) {
        return .rejected(.unregisteredRoute(routeKey(for: type(of: unknown))))
    }
    guard link.isAuthenticationRequired else {
        return .routes(link.stack)
    }
    if session.isExpired {
        return .rejected(.sessionExpired)
    }
    guard session.isAuthenticated else {
        return .requiresLogin(pending: link.stack)
    }
    return .routes(link.stack)
}
