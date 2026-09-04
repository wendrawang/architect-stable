import UIKit
import CoreKit

/// One queued overlay.
private struct OverlayEntry {
    let level: OverlayLevel
    let controller: UIViewController
}

/// Renders session blockers above everything the app can present.
///
/// A second `UIWindow` is the only mechanism that clears presented sheets and the app's
/// own alerts. A z-index or a full-screen SwiftUI cover cannot: both live inside the
/// window whose content the blocker has to cover.
///
/// The window's `rootViewController` is `nil` whenever no overlay is active, so touches
/// pass straight through to the app.
@MainActor
public final class OverlayWindowController {
    private let window: UIWindow
    private let logger: any Logger
    private let signpost = PerformanceSignpost(category: .navigation)
    private var entries: [OverlayEntry] = []

    /// The window is injected rather than built here so the composition root can put it in
    /// the same `UIWindowScene` as the main window, and so tests can pass a scene-less one.
    public init(window: UIWindow, logger: any Logger) {
        self.window = window
        self.logger = logger
        window.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.alert.rawValue - 1)
        window.isHidden = true
        window.rootViewController = nil
    }

    public var isPresenting: Bool {
        !entries.isEmpty
    }

    /// The level currently on screen, if any. The queue is invisible to callers.
    public var visibleLevel: OverlayLevel? {
        entries.last?.level
    }

    /// Shows `controller` if it outranks everything queued, otherwise queues it.
    ///
    /// A lower-priority overlay never replaces a higher one: a network blocker must not
    /// paint over a force-update screen.
    public func present(_ controller: UIViewController, level: OverlayLevel) {
        let token = signpost.begin(.overlayPresent)
        defer { signpost.end(.overlayPresent, token: token) }
        let entry = OverlayEntry(level: level, controller: controller)
        let index = entries.firstIndex(where: { $0.level > level }) ?? entries.count
        entries.insert(entry, at: index)
        showTop()
    }

    /// Dismisses the visible overlay and reveals the next highest, if there is one.
    public func dismissTop() {
        guard !entries.isEmpty else {
            logger.debug("dismissTop ignored: no overlay is showing")
            return
        }
        entries.removeLast()
        showTop()
    }

    public func dismissAll() {
        entries.removeAll()
        showTop()
    }

    private func showTop() {
        guard let top = entries.last else {
            window.rootViewController = nil
            window.isHidden = true
            return
        }
        guard window.rootViewController !== top.controller else { return }
        window.rootViewController = top.controller
        window.makeKeyAndVisible()
    }
}
