import UIKit

public extension TabHost {
    /// One tab, as data.
    ///
    /// The bar item arrives fully built. RouterKit never chooses a title, an icon or a
    /// colour: appearance is the design system's job and the composition root's decision,
    /// and a navigation package that knows what "Beranda" looks like is a navigation package
    /// that has to change when a designer does.
    struct Item {
        public let identifier: TabIdentifier
        public let barItem: UITabBarItem
        /// Drawn above the bar and centred on it, as the scan control is. Tapping it selects
        /// this tab, so it behaves like the tab it belongs to and needs no separate wiring.
        public let raisedControl: UIControl?
        /// How far the raised control's centre sits above the bar's top edge. Ignored when
        /// there is no raised control.
        public let raisedOffset: CGFloat

        public init(identifier: TabIdentifier,
                    barItem: UITabBarItem,
                    raisedControl: UIControl?,
                    raisedOffset: CGFloat) {
            self.identifier = identifier
            self.barItem = barItem
            self.raisedControl = raisedControl
            self.raisedOffset = raisedOffset
        }
    }
}
