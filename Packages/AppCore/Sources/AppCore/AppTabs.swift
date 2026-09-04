import RouterKit

/// The app's tabs. Declared here, not in RouterKit: naming a tab is a product decision
/// and the navigation package must stay ignorant of it.
public extension TabIdentifier {
    static let home = TabIdentifier(rawValue: "home")
    static let financial = TabIdentifier(rawValue: "financial")
    static let scan = TabIdentifier(rawValue: "scan")
    static let rewards = TabIdentifier(rawValue: "rewards")
    static let more = TabIdentifier(rawValue: "more")
}
