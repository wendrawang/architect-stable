
/// A parsed deep link: the destination stack it asks for, plus its auth requirement.
///
/// Parsing a URL into this is the composition root's job. Keeping the parsed stack in
/// the value is what lets `resolveDeepLink` stay pure and lets `RouterKit` stay ignorant
/// of every feature's URL grammar.
public struct DeepLink {
    /// Opaque identifier for logging. Must not contain PII or query parameters.
    public let identifier: String
    /// The full stack the link asks for, root first. Emitting the whole stack — rather
    /// than routing through the dashboard and pushing one screen — is what makes back
    /// navigation land on the dashboard without the dashboard being the entry point.
    public let stack: [any Route]
    public let isAuthenticationRequired: Bool

    public init(identifier: String, stack: [any Route], isAuthenticationRequired: Bool) {
        self.identifier = identifier
        self.stack = stack
        self.isAuthenticationRequired = isAuthenticationRequired
    }
}

/// Why a deep link was refused outright. A refusal is never retried.
public enum DeepLinkRejection: Equatable, Sendable {
    /// The link parsed to an empty stack.
    case malformed
    /// A route in the stack has no registered destination.
    case unregisteredRoute(String)
    /// The session exists but has timed out. The customer re-authenticates from scratch;
    /// the link is not stashed, because replaying it after a timeout is a security smell.
    case sessionExpired
}
