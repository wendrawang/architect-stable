
/// A localisation key, not a localised string.
///
/// Carrying keys rather than resolved copy keeps configuration values
/// `Equatable` across locales and keeps translation out of the domain layer.
/// Localisation itself is out of scope for this task: the sample renders `rawValue`.
public struct LocalizedKey: Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}
