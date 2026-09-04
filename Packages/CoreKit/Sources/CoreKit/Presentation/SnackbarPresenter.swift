import Foundation

/// Transient, non-blocking message surface.
///
/// Injected into a view model at `init` so the view model can honour an
/// `ErrorPolicy` that resolves to `.snackbar` without reaching for the navigator.
@MainActor
public protocol SnackbarPresenter: AnyObject {
    func show(message: String)
}
