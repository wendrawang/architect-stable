/// The single error type crossing layer boundaries.
///
/// Repositories map transport and decoding failures into `AppError` at the data
/// boundary; use cases add business meaning; view models turn it into a surface
/// through `ErrorPolicy`. Nothing above the data layer ever sees a transport error.
public struct AppError: Error, Equatable, Sendable {
    public let kind: AppErrorKind
    public let message: String
    public let diagnosticCode: String?

    public init(kind: AppErrorKind, message: String, diagnosticCode: String?) {
        self.kind = kind
        self.message = message
        self.diagnosticCode = diagnosticCode
    }
}

/// The closed set of failure categories the presentation layer may branch on.
///
/// It is deliberately small. A new case is a product decision, not a convenience:
/// every case here becomes a branch somewhere in `ErrorPolicy`.
public enum AppErrorKind: String, Equatable, Hashable, Sendable, CaseIterable {
    case network
    case unauthorized
    case validation
    case notFound
    case server
    case cancelled
    case unknown
}
