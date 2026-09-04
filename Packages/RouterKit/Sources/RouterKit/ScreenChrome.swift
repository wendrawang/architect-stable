
/// How the back button of the *next* screen is drawn.
public enum BackButtonStyle: Equatable, Sendable {
    /// System chevron plus the previous screen's title.
    case system
    /// System chevron, no title.
    case titleless
    /// No back affordance at all. Use for flow entry points, not to trap the customer.
    case hidden
}

/// Navigation-bar configuration, supplied by the route factory.
///
/// The bar belongs to `UIKit`, so `UIKit` configures it. SwiftUI never calls a
/// navigation-title modifier: two owners of one bar is how appearance leaks between
/// screens in the legacy app.
///
/// Presentation-only value type, so defaults are allowed here. Dependencies never have them.
public struct ScreenChrome: Equatable, Sendable {
    public let title: String?
    public let backButton: BackButtonStyle
    public let isLargeTitleEnabled: Bool
    public let isNavigationBarHidden: Bool

    public init(title: String?,
                backButton: BackButtonStyle = .system,
                isLargeTitleEnabled: Bool = false,
                isNavigationBarHidden: Bool = false) {
        self.title = title
        self.backButton = backButton
        self.isLargeTitleEnabled = isLargeTitleEnabled
        self.isNavigationBarHidden = isNavigationBarHidden
    }
}
