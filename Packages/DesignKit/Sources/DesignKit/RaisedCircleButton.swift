import UIKit

/// The circular control that sits above the tab bar, as on the scan tab.
///
/// It knows its own size, so the host only has to place its centre. Everything it draws
/// comes from the palette and metrics it is given; it holds no constant of its own.
public final class RaisedCircleButton: UIButton {
    private let diameter: CGFloat

    public init(symbolName: String, palette: BrandPalette, metrics: TabBarMetrics) {
        self.diameter = metrics.raisedDiameter
        super.init(frame: .zero)
        let configuration = UIImage.SymbolConfiguration(pointSize: metrics.iconPointSize,
                                                        weight: .semibold)
        setImage(UIImage(systemName: symbolName, withConfiguration: configuration), for: .normal)
        tintColor = palette.onAccent
        backgroundColor = palette.accent
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = metrics.raisedShadowOpacity
        layer.shadowRadius = metrics.raisedShadowRadius
        layer.shadowOffset = .zero
    }

    /// Not supported: this control is created in code, never from a nib.
    @objc dynamic required init?(coder aDecoder: NSCoder) {
        return nil
    }

    override public var intrinsicContentSize: CGSize {
        CGSize(width: diameter, height: diameter)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2.0
    }
}
