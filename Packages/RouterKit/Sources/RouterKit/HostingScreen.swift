import UIKit
import SwiftUI
import CoreKit

/// The SwiftUI-to-UIKit boundary, and the only place erasure happens.
///
/// **Root level only.** Never embed this inside a `UITableViewCell` or a
/// `UICollectionViewCell` on iOS 15: self-sizing hosting cells there mis-measure on
/// first layout, which is the source of the truncated-text defects in the legacy app.
/// Put the whole screen in one instance of this and let SwiftUI lay out inside it.
///
/// Ownership: the hosting controller stores `rootView`, and `@ObservedObject` stores its
/// object strongly, so the view model is retained by this controller for as long as the
/// controller is on a stack. That is why the route factory can build the view model once
/// and hand it over — nothing rebuilds it on a body evaluation.
public final class HostingScreen<Content: View>: UIHostingController<Content> {
    private let chrome: ScreenChrome
    private let signpost = PerformanceSignpost(category: .screen)
    private var initToken: PerformanceSignpost.Token?

    public init(chrome: ScreenChrome, rootView: Content) {
        self.chrome = chrome
        super.init(rootView: rootView)
        self.initToken = signpost.begin(.screenInit)
        #if DEBUG
        LifecycleTracker.shared.record(init: self)
        #endif
    }

    /// Not supported: a screen is created in code by a route factory, never from a nib.
    @objc dynamic required init?(coder aDecoder: NSCoder) {
        return nil
    }

    deinit {
        #if DEBUG
        LifecycleTracker.shared.record(deinit: self)
        #endif
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        title = chrome.title
        navigationItem.largeTitleDisplayMode = chrome.isLargeTitleEnabled ? .always : .never
        navigationItem.hidesBackButton = chrome.backButton == .hidden
        if chrome.backButton == .titleless {
            navigationItem.backButtonDisplayMode = .minimal
        }
        if let token = initToken {
            signpost.end(.screenInit, token: token)
            initToken = nil
        }
    }

    /// Appearance is applied on every appearance, explicitly, so nothing a previously
    /// visible screen configured can leak into this one.
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(chrome.isNavigationBarHidden, animated: animated)
        navigationController?.navigationBar.prefersLargeTitles = chrome.isLargeTitleEnabled
        applyBarAppearance()
    }

    private func applyBarAppearance() {
        guard let bar = navigationController?.navigationBar else { return }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactAppearance = appearance
    }
}
