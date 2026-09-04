import CoreKit
import RouterKit
import FeatureSample

/// One container, conforming to every feature's dependency protocol.
///
/// It lives for the lifetime of the process, which is what makes a registry factory's
/// strong capture of it safe. Nothing shorter-lived may be captured by a factory.
public final class AppDependencies: SampleDependencies {
    public let logger: any Logger
    public let analytics: any AnalyticsSink
    public let snackbar: any SnackbarPresenter
    public let paymentsTab = TabIdentifier.payments
    private var sessionSnapshot: SessionSnapshot

    public init(logger: any Logger,
                analytics: any AnalyticsSink,
                snackbar: any SnackbarPresenter,
                session: SessionSnapshot) {
        self.logger = logger
        self.analytics = analytics
        self.snackbar = snackbar
        self.sessionSnapshot = session
    }

    public var session: SessionSnapshot {
        sessionSnapshot
    }

    /// The real app updates this from the authentication service. Kept as one setter so
    /// deep-link resolution always reads a value that is current at the moment it runs.
    public func update(session: SessionSnapshot) {
        sessionSnapshot = session
    }
}
