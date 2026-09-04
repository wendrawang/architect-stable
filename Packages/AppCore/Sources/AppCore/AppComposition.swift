import UIKit
import CoreKit
import RouterKit
import FeatureSample

/// The composition root. The only type in the app that knows every feature by name, and
/// the only place concrete implementations are chosen.
@MainActor
public final class AppComposition {
    public let tabHost: TabHost
    private let registry: RouteRegistry
    private let overlay: OverlayWindowController
    private let dependencies: AppDependencies
    private let pendingDeepLinks = PendingDeepLinkStore()
    private let logger: any Logger

    public init(windowScene: UIWindowScene, logger: any Logger, analytics: any AnalyticsSink) {
        let registry = RouteRegistry()
        let overlayWindow = UIWindow(windowScene: windowScene)
        let overlay = OverlayWindowController(window: overlayWindow, logger: logger)
        let dependencies = AppDependencies(logger: logger,
                                           analytics: analytics,
                                           snackbar: LoggingSnackbar(logger: logger),
                                           session: SessionSnapshot(isAuthenticated: false,
                                                                    isExpired: false))
        self.registry = registry
        self.overlay = overlay
        self.dependencies = dependencies
        self.logger = logger
        self.tabHost = TabHost(tabs: [.dashboard, .payments],
                               registry: registry,
                               overlay: overlay,
                               logger: logger)
        SampleRegistrar.register(into: registry, dependencies: dependencies)
        setRootRoutes()
    }

    public func rootViewController() -> UIViewController {
        tabHost.tabBarController
    }

    /// Resolves a link and performs whatever the resolution says. The decision itself is
    /// made by a pure function in RouterKit; this method is the side effect.
    public func handle(_ link: DeepLink) {
        switch resolveDeepLink(link, session: dependencies.session, registry: registry) {
        case .routes(let routes):
            navigate(to: routes)
        case .requiresLogin(let pending):
            pendingDeepLinks.stash(pending)
            logger.info("Deep link \(link.identifier) stashed until login")
        case .rejected(let rejection):
            logger.error("Deep link \(link.identifier) rejected: \(rejection)")
        }
    }

    /// Called once after a successful authentication. `consume` clears the store in the
    /// same step, so a replayed link cannot fire again on the next login.
    public func replayPendingDeepLink() {
        let pending = pendingDeepLinks.consume()
        guard !pending.isEmpty else { return }
        navigate(to: pending)
    }

    public func update(session: SessionSnapshot) {
        dependencies.update(session: session)
    }

    private func navigate(to routes: [any Route]) {
        tabHost.switchTab(.dashboard, isStackReset: false)
        tabHost.navigator(for: .dashboard)?.setStack(routes, isAnimated: false)
    }

    private func setRootRoutes() {
        tabHost.navigator(for: .dashboard)?.setStack([SampleHomeRoute()], isAnimated: false)
        tabHost.navigator(for: .payments)?.setStack([SampleHomeRoute()], isAnimated: false)
    }
}
