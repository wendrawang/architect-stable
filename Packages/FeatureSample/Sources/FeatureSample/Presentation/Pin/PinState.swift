import Foundation
import CoreKit

/// The result the screen shows on success. A domain value, already formatted.
struct PinOutcome: Equatable {
    let message: String
}

/// Absence is `Optional` and `LoadState`, never a sentinel default. There is no
/// `remainingAttempts: Int = 0` here: zero attempts left is a real state and must not
/// be indistinguishable from "we have not asked yet".
struct PinState: Equatable {
    let heading: String
    let instruction: String
    var entry: String
    var status: LoadState<PinOutcome>
    var attemptsCaption: String?
    var inlineErrorMessage: String?

    /// Presentation-derived, not a stored flag. The view asks; it does not decide.
    var isSubmitDisabled: Bool {
        status == .loading || entry.isEmpty
    }
}

enum PinAction: Equatable {
    case onAppear
    case digitEntered(String)
    case backspaceTapped
    case submitTapped
    case cancelTapped
}
