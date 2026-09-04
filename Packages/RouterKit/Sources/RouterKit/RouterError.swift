import Foundation

/// Failures the navigation layer can produce. All of them are recoverable:
/// nothing in `RouterKit` traps in RELEASE.
public enum RouterError: Error, Equatable {
    /// No factory was registered for this route type.
    case unregisteredRoute(String)
    /// A registered factory received a route of a different type than it declared.
    /// Only reachable if the registry key derivation is broken.
    case routeTypeMismatch(String)
}
