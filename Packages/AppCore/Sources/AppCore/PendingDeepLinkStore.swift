import RouterKit

/// Holds a deep link that arrived before the customer was authenticated.
///
/// It clears on the first successful replay. A pending link that never clears is the root
/// cause of a live production defect: the customer lands on the same stashed screen after
/// every subsequent login until the app is killed.
public final class PendingDeepLinkStore {
    private var routes: [any Route] = []

    public init() { }

    public var isEmpty: Bool {
        routes.isEmpty
    }

    public func stash(_ routes: [any Route]) {
        self.routes = routes
    }

    /// Returns the stashed stack and clears it in the same step, so there is no path
    /// where a caller reads it without consuming it.
    public func consume() -> [any Route] {
        let pending = routes
        routes = []
        return pending
    }
}
