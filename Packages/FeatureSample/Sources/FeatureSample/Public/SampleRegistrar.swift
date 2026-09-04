import CoreKit
import RouterKit

/// Builds this feature's destinations. Runs once, at composition time.
///
/// Every closure below captures `dependencies` and the use case strongly. That is safe
/// only because the composition root owns both for the lifetime of the process — it is
/// stated here rather than left implicit, because a factory capturing a shorter-lived
/// container is exactly how a registry starts leaking.
@MainActor
public enum SampleRegistrar: FeatureRegistrar {
    public static func register(into registry: RouteRegistry, dependencies: FeatureDependencies) {
        guard let sample = dependencies as? any SampleDependencies else {
            dependencies.logger.error("SampleRegistrar: the container does not provide SampleDependencies")
            assertionFailure("Conform the composition root's container to SampleDependencies")
            return
        }
        let verifyPin = VerifyPin(repository: SamplePinRepository())
        registry.register(SampleHomeRoute.self) { _, navigator in
            let viewModel = HomeViewModel(navigator: navigator,
                                          snackbar: sample.snackbar,
                                          financialTab: sample.financialTab)
            return HostingScreen(chrome: ScreenChrome(title: "Sample", isLargeTitleEnabled: true),
                                 rootView: HomeView(viewModel: viewModel))
        }
        registry.register(SamplePinRoute.self) { route, navigator in
            let viewModel = PinViewModel(configuration: route.configuration,
                                         navigator: navigator,
                                         verifyPin: verifyPin,
                                         snackbar: sample.snackbar)
            let chrome = ScreenChrome(title: route.configuration.titleKey.rawValue,
                                      backButton: .titleless)
            return HostingScreen(chrome: chrome, rootView: PinView(viewModel: viewModel))
        }
    }
}
