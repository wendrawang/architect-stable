/// Sizes for the tab bar and its raised centre control.
///
/// Every number the tab bar needs lives here. A layout constant written anywhere else is a
/// review-blocking error, because that is how two screens end up half a point apart.
public struct TabBarMetrics {
    public let iconPointSize: CGFloat
    public let raisedDiameter: CGFloat
    /// How far the raised control's centre sits above the top edge of the bar.
    public let raisedOffset: CGFloat
    public let raisedShadowRadius: CGFloat
    public let raisedShadowOpacity: Float

    public init(iconPointSize: CGFloat,
                raisedDiameter: CGFloat,
                raisedOffset: CGFloat,
                raisedShadowRadius: CGFloat,
                raisedShadowOpacity: Float) {
        self.iconPointSize = iconPointSize
        self.raisedDiameter = raisedDiameter
        self.raisedOffset = raisedOffset
        self.raisedShadowRadius = raisedShadowRadius
        self.raisedShadowOpacity = raisedShadowOpacity
    }
}

public extension TabBarMetrics {
    static let standard = TabBarMetrics(iconPointSize: 22.0,
                                        raisedDiameter: 64.0,
                                        raisedOffset: 12.0,
                                        raisedShadowRadius: 8.0,
                                        raisedShadowOpacity: 0.2)
}
