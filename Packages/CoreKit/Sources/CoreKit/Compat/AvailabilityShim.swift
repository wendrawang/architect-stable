import UIKit

/// The single sanctioned location for OS-version branching.
///
/// Every other file in every package targets iOS 15 unconditionally. When the
/// deployment target moves, the branch is added here and the call sites stay
/// version-agnostic. Today the shim needs no branching at all: everything it
/// wraps exists in iOS 15, so it is a pure vocabulary boundary.
public enum AvailabilityShim {
    /// Configures a controller for sheet presentation using only iOS 15 API.
    ///
    /// `prefersGrabberVisible` and `prefersScrollingExpandsWhenScrolledToEdge` are
    /// house defaults, applied here so no call site can forget them.
    public static func applySheetPresentation(to controller: UIViewController, isMediumDetent: Bool) {
        controller.modalPresentationStyle = .pageSheet
        guard let sheet = controller.sheetPresentationController else { return }
        // swiftlint:disable:next todo
        // TODO(iOS16): custom-height detents land here as `.custom(resolver:)` once the
        // deployment target moves past iOS 15. Do not add a `.custom` case before then.
        sheet.detents = isMediumDetent ? [.medium()] : [.large()]
        sheet.prefersGrabberVisible = true
        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
    }
}
