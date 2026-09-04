/// How a destination appears. Push is not here — push is `Navigator.push`.
public enum PresentationStyle: Equatable, Sendable {
    case fullScreen
    /// `UISheetPresentationController`, iOS 15 detents only.
    case sheet(SheetDetent)
    /// A separate `UIWindow` above everything the app can present.
    case overlay(OverlayLevel)
}

/// The two detents iOS 15 offers. There is deliberately no `.custom`.
public enum SheetDetent: Equatable, Sendable {
    case medium
    case large
}

/// Overlay precedence. Only the highest level is on screen; the rest queue.
///
/// Raw values are spaced so a level can be inserted between two existing ones
/// without renumbering call sites.
public enum OverlayLevel: Int, Comparable, Sendable {
    case blocking = 100
    case session = 200
    case forceUpdate = 300

    public static func < (lhs: OverlayLevel, rhs: OverlayLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
