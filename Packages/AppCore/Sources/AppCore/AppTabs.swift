import RouterKit

/// The app's tabs. Declared here, not in RouterKit: naming a tab is a product decision
/// and the navigation package must stay ignorant of it.
public extension TabIdentifier {
    static let dashboard = TabIdentifier(rawValue: "dashboard")
    static let payments = TabIdentifier(rawValue: "payments")
}
