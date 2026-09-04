import RouterKit

/// The sample tab's root. Carries no data.
public struct SampleHomeRoute: Route, Equatable {
    public init() { }
}

/// One screen, many flows. The variation lives in `PinConfiguration`, not in a type.
public struct SamplePinRoute: Route, Equatable {
    public let configuration: PinConfiguration

    public init(configuration: PinConfiguration) {
        self.configuration = configuration
    }
}

/// An opaque handle to a transaction.
///
/// This is what a route is allowed to carry. The account number, the amount and the
/// beneficiary name are resolved by the destination against a repository, so none of
/// them can end up in a deep link, a log line or a crash report.
public struct TransactionReference: Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
