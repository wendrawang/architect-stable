import UIKit

/// Every colour the app uses, in one value.
///
/// Nothing downstream may invent a colour. Note how few literals there are: the tab bar
/// takes its background and its unselected tint from system colours, so dark mode works
/// without a second palette, and the brand red is the only value written by hand.
public struct BrandPalette {
    public let accent: UIColor
    public let onAccent: UIColor
    public let tabSelected: UIColor
    public let tabUnselected: UIColor
    public let tabBackground: UIColor

    public init(accent: UIColor,
                onAccent: UIColor,
                tabSelected: UIColor,
                tabUnselected: UIColor,
                tabBackground: UIColor) {
        self.accent = accent
        self.onAccent = onAccent
        self.tabSelected = tabSelected
        self.tabUnselected = tabUnselected
        self.tabBackground = tabBackground
    }
}

public extension BrandPalette {
    /// The single source of the brand red. Change it here and the whole app follows.
    static let accentRed = UIColor(red: 228.0 / 255.0, green: 0.0, blue: 43.0 / 255.0, alpha: 1.0)

    static let nyala = BrandPalette(accent: accentRed,
                                    onAccent: .white,
                                    tabSelected: accentRed,
                                    tabUnselected: .label,
                                    tabBackground: .systemBackground)
}
