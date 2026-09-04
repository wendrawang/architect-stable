import UIKit
import SwiftUI
import CoreKit
@testable import RouterKit

// Hand-written test doubles. No mocking framework, by house rule.

final class TestLogger: Logger {
    private(set) var debugMessages: [String] = []
    private(set) var infoMessages: [String] = []
    private(set) var errorMessages: [String] = []

    func debug(_ message: String) { debugMessages.append(message) }
    func info(_ message: String) { infoMessages.append(message) }
    func error(_ message: String) { errorMessages.append(message) }
}

final class TestAnalytics: AnalyticsSink {
    private(set) var events: [String] = []

    func track(event: String, parameters: [String: String]) { events.append(event) }
}

@MainActor
final class TestSnackbar: SnackbarPresenter {
    private(set) var messages: [String] = []

    func show(message: String) { messages.append(message) }
}

struct AlphaRoute: Route, Equatable {
    let value: Int
}

struct BetaRoute: Route, Equatable {
    let value: Int
}

struct GammaRoute: Route, Equatable {
    let value: Int
}

/// Not registered anywhere. Used to prove resolution fails without crashing.
struct OrphanRoute: Route, Equatable {
    let value: Int
}

final class AlphaViewController: UIViewController { }

final class BetaViewController: UIViewController { }

/// Stands in for a feature's view model in leak tests.
@MainActor
final class ProbeViewModel: ObservableObject {
    @Published private(set) var title: String

    init(title: String) {
        self.title = title
        #if DEBUG
        LifecycleTracker.shared.record(init: self)
        #endif
    }

    deinit {
        #if DEBUG
        LifecycleTracker.shared.record(deinit: self)
        #endif
    }
}

struct ProbeView: View {
    @ObservedObject var viewModel: ProbeViewModel

    var body: some View {
        Text(viewModel.title)
    }
}

/// A dependency container that must not be resurrected by the registry.
final class TestContainer {
    let label: String

    init(label: String) {
        self.label = label
    }
}

@MainActor
enum TestFixture {
    static func makeOverlay(logger: any Logger) -> OverlayWindowController {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        return OverlayWindowController(window: window, logger: logger)
    }

    static func makeRegistry() -> RouteRegistry {
        let registry = RouteRegistry()
        registry.register(AlphaRoute.self) { _, _ in AlphaViewController() }
        registry.register(BetaRoute.self) { _, _ in BetaViewController() }
        registry.register(GammaRoute.self) { _, _ in UIViewController() }
        return registry
    }

    static func makeProbeRegistry() -> RouteRegistry {
        let registry = RouteRegistry()
        registry.register(AlphaRoute.self) { route, _ in
            let viewModel = ProbeViewModel(title: "alpha-\(route.value)")
            return HostingScreen(chrome: ScreenChrome(title: "Alpha"),
                                 rootView: ProbeView(viewModel: viewModel))
        }
        return registry
    }
}
