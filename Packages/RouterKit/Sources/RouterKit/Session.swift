import Foundation

/// What deep-link resolution needs to know about the session, and nothing more.
///
/// A value, read at the moment of resolution, so `resolveDeepLink` stays pure.
public struct SessionSnapshot: Equatable, Sendable {
    public let isAuthenticated: Bool
    public let isExpired: Bool

    public init(isAuthenticated: Bool, isExpired: Bool) {
        self.isAuthenticated = isAuthenticated
        self.isExpired = isExpired
    }
}
