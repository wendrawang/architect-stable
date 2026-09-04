import UIKit
import RouterKit
import AppCore

/// Development harness. This target exists so the navigation infrastructure can be run and
/// looked at; it is not part of the shipping architecture and no package depends on it.
///
/// The two types below are the whole integration. Copy them into a real app target and the
/// packages work unchanged.
@main
final class HostAppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default",
                                                 sessionRole: connectingSceneSession.role)
        configuration.delegateClass = HostSceneDelegate.self
        return configuration
    }
}

/// Everything an app needs to adopt RouterKit: build the composition root, ask it for a root
/// view controller, and hand deep links to it. There is no other integration point.
final class HostSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var composition: AppComposition?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let composition = AppComposition(
            windowScene: windowScene,
            logger: ConsoleLogger(subsystem: "id.co.ocbcnisp.byon", category: "hostapp"),
            analytics: DiscardedAnalytics()
        )
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = composition.rootViewController()
        window.makeKeyAndVisible()
        self.window = window
        self.composition = composition
        composition.update(session: SessionSnapshot(isAuthenticated: true, isExpired: false))
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url, let link = AppDeepLinks.parse(url) else { return }
        composition?.handle(link)
    }
}
