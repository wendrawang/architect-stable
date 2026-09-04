import Foundation

/// A navigable destination, expressed as data.
///
/// Every route is a `struct` declared in the package that owns the destination and
/// carries everything that destination needs to build itself. Routes carry **data
/// only**: never dependencies, never closures. A destination that needs to tell the
/// caller something pushes the next route itself instead of invoking a callback.
///
/// **PII rule.** A route must never carry an account number, a card number, a
/// national identity number, or a full customer name. Carry an opaque reference
/// (`TransactionReference`, `AccountToken`) and let the destination resolve it
/// against a repository. Routes end up in deep links, logs and crash reports;
/// treat every field as if it will be printed.
public protocol Route: Sendable {
    /// Value equality across the existential.
    ///
    /// `any Route` cannot use `==` directly, and deep-link resolution has to be
    /// comparable to be testable. Conform your route to `Equatable` and the default
    /// implementation below gives you this for free.
    func isEquivalent(to other: any Route) -> Bool
}

public extension Route where Self: Equatable {
    func isEquivalent(to other: any Route) -> Bool {
        guard let other = other as? Self else { return false }
        return self == other
    }
}

extension Array where Element == any Route {
    func isEquivalent(to other: [any Route]) -> Bool {
        guard count == other.count else { return false }
        for (index, route) in enumerated() where !route.isEquivalent(to: other[index]) {
            return false
        }
        return true
    }
}

/// Stable key for a route type. Registration and resolution must agree on it.
func routeKey(for type: any Route.Type) -> String {
    String(reflecting: type)
}
