import UIKit
import DesignKit
import RouterKit

/// The tab bar, as data.
///
/// Every string and every symbol name the bar needs is a named constant below, so there is
/// no literal anywhere else and no second place to change one. Localisation is out of scope
/// for now; when it arrives these titles become keys and nothing else here moves.
public enum AppTabBar {
    private static let homeTitle = "Beranda"
    private static let financialTitle = "Finansial"
    private static let scanTitle = "Scan"
    private static let rewardsTitle = "Rewards"
    private static let moreTitle = "Lainnya"
    private static let homeSymbol = "house.fill"
    private static let financialSymbol = "chart.pie.fill"
    private static let rewardsSymbol = "gift.fill"
    private static let moreSymbol = "circle.grid.2x2.fill"
    /// Stands in for the QRIS mark, which is a brand asset and belongs in an asset catalog.
    private static let scanSymbol = "qrcode.viewfinder"

    /// The bar's five tabs, in order. The scan tab carries the raised control.
    public static func items(palette: BrandPalette, metrics: TabBarMetrics) -> [TabHost.Item] {
        [
            item(.home, title: homeTitle, symbolName: homeSymbol, metrics: metrics),
            item(.financial, title: financialTitle, symbolName: financialSymbol, metrics: metrics),
            scanItem(palette: palette, metrics: metrics),
            item(.rewards, title: rewardsTitle, symbolName: rewardsSymbol, metrics: metrics),
            item(.more, title: moreTitle, symbolName: moreSymbol, metrics: metrics)
        ]
    }

    /// Applies the palette to the bar itself. Called once, by the composition root.
    public static func applyAppearance(to bar: UITabBar, palette: BrandPalette) {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = palette.tabBackground
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.tintColor = palette.tabSelected
        bar.unselectedItemTintColor = palette.tabUnselected
    }

    private static func item(_ identifier: TabIdentifier,
                             title: String,
                             symbolName: String,
                             metrics: TabBarMetrics) -> TabHost.Item {
        let configuration = UIImage.SymbolConfiguration(pointSize: metrics.iconPointSize)
        let image = UIImage(systemName: symbolName, withConfiguration: configuration)
        return TabHost.Item(identifier: identifier,
                            barItem: UITabBarItem(title: title, image: image, selectedImage: image),
                            raisedControl: nil,
                            raisedOffset: 0.0)
    }

    /// The scan tab shows its title only: the raised control stands where the icon would be.
    private static func scanItem(palette: BrandPalette, metrics: TabBarMetrics) -> TabHost.Item {
        let button = RaisedCircleButton(symbolName: scanSymbol, palette: palette, metrics: metrics)
        return TabHost.Item(identifier: .scan,
                            barItem: UITabBarItem(title: scanTitle, image: nil, selectedImage: nil),
                            raisedControl: button,
                            raisedOffset: metrics.raisedOffset)
    }
}
