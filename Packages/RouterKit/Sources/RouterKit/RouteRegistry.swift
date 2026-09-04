import UIKit

/// Type-safe at registration, erased at resolution.
///
/// Registration stores a closure and nothing else. **No destination is ever built at
/// registration time** — the factory runs when the route is navigated to. This is the
/// single most important rule in the package: the legacy app builds every destination's
/// routing object while merely rendering a link table, and that is where its scroll
/// jank comes from.
@MainActor
public final class RouteRegistry {
    private typealias ErasedFactory = @MainActor (any Route, any Navigator) throws -> UIViewController
    private var factories: [String: ErasedFactory] = [:]
    /// Test seam. Duplicate registration traps in DEBUG, which would make the
    /// keeps-the-first-registration contract untestable; a test turns the trap off to
    /// exercise the RELEASE path. Internal, so the public surface is unchanged.
    var isDuplicateAssertionEnabled = true

    public init() { }

    /// Registers the factory for one route type.
    ///
    /// Registering the same type twice keeps the first registration and traps in DEBUG,
    /// so a duplicate is loud in development and harmless in production.
    public func register<R: Route>(_ type: R.Type,
                                   factory: @escaping @MainActor (R, any Navigator) -> UIViewController) {
        let key = routeKey(for: type)
        guard factories[key] == nil else {
            if isDuplicateAssertionEnabled {
                assertionFailure("Duplicate registration for \(key). The first registration is kept.")
            }
            return
        }
        factories[key] = { route, navigator in
            guard let typed = route as? R else {
                throw RouterError.routeTypeMismatch(key)
            }
            return factory(typed, navigator)
        }
    }

    /// Builds the destination for a route. Throws rather than trapping when unregistered.
    public func resolve(_ route: any Route, navigator: any Navigator) throws -> UIViewController {
        let key = routeKey(for: type(of: route))
        guard let factory = factories[key] else {
            throw RouterError.unregisteredRoute(key)
        }
        return try factory(route, navigator)
    }

    /// Whether a destination exists for this route. Used by deep-link resolution,
    /// which must decide without building anything.
    public func isRegistered(_ route: any Route) -> Bool {
        factories[routeKey(for: type(of: route))] != nil
    }

    /// Number of registered route types. Memory footprint is one closure per type.
    public var registrationCount: Int {
        factories.count
    }
}
