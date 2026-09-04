import Foundation

/// Where an error is shown to the customer.
public enum ErrorSurface: String, Equatable, Hashable, Sendable, CaseIterable {
    case snackbar
    case sheet
    case blocker
}

/// Maps an error to the surface that presents it.
///
/// This is **data**, not a closure. A closure would make every configuration
/// carrying a policy non-`Equatable` and non-`Sendable`, which is the same
/// mistake the routing layer avoids by modelling success actions as data.
/// Keeping the mapping as a value keeps route payloads comparable in tests.
public struct ErrorPolicy: Equatable, Hashable, Sendable {
    public let defaultSurface: ErrorSurface
    public let overrides: [AppErrorKind: ErrorSurface]

    public init(defaultSurface: ErrorSurface, overrides: [AppErrorKind: ErrorSurface]) {
        self.defaultSurface = defaultSurface
        self.overrides = overrides
    }

    /// The surface for a concrete failure. The view never calls this; the view model does.
    public func surface(for error: AppError) -> ErrorSurface {
        overrides[error.kind] ?? defaultSurface
    }
}
