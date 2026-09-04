import CoreKit

/// Analytics transport is out of scope. This conformance exists so features can be wired
/// and tested today without a stub creeping into a feature package.
public final class DiscardedAnalytics: AnalyticsSink {
    public init() { }

    public func track(event: String, parameters: [String: String]) { }
}

/// Snackbar rendering belongs to DesignKit, which is a stub in this task. Until it exists
/// the message is logged, so the routing decision is still observable end to end.
@MainActor
public final class LoggingSnackbar: SnackbarPresenter {
    private let logger: any Logger

    public init(logger: any Logger) {
        self.logger = logger
    }

    public func show(message: String) {
        logger.info("snackbar: \(message)")
    }
}
