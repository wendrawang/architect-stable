import CoreKit
import RouterKit

/// Why the customer is being asked for a PIN. Drives copy and the use-case input.
public enum PinPurpose: String, Equatable, Sendable {
    case login
    case transactionApproval
    case sessionUnlock
}

/// What happens after a correct PIN — as data, never as a closure.
///
/// A closure here would break `Equatable`, make the flow untestable without running it,
/// and give the route a retain edge into whoever created it. The view model interprets
/// these cases; the route only carries them.
public enum PinSuccessAction: Sendable {
    case push(any Route)
    case popTo(reference: TransactionReference)
    case dismiss
}

extension PinSuccessAction: Equatable {
    public static func == (lhs: PinSuccessAction, rhs: PinSuccessAction) -> Bool {
        switch (lhs, rhs) {
        case let (.push(left), .push(right)):
            return left.isEquivalent(to: right)
        case let (.popTo(left), .popTo(right)):
            return left == right
        case (.dismiss, .dismiss):
            return true
        default:
            return false
        }
    }
}

/// The whole of a PIN flow's variation, as one value.
///
/// The legacy app has 95 PIN routing objects that differ only in these five fields.
/// Here they are five fields.
public struct PinConfiguration: Sendable, Equatable {
    public let titleKey: LocalizedKey
    public let instructionKey: LocalizedKey
    public let purpose: PinPurpose
    public let onSuccess: PinSuccessAction
    public let errorPolicy: ErrorPolicy

    public init(titleKey: LocalizedKey,
                instructionKey: LocalizedKey,
                purpose: PinPurpose,
                onSuccess: PinSuccessAction,
                errorPolicy: ErrorPolicy) {
        self.titleKey = titleKey
        self.instructionKey = instructionKey
        self.purpose = purpose
        self.onSuccess = onSuccess
        self.errorPolicy = errorPolicy
    }
}

public extension PinConfiguration {
    /// Presented as a sheet. A failed login is a snackbar, never a blocker.
    static let login = PinConfiguration(
        titleKey: "pin.login.title",
        instructionKey: "pin.login.instruction",
        purpose: .login,
        onSuccess: .dismiss,
        errorPolicy: ErrorPolicy(defaultSurface: .snackbar, overrides: [:])
    )

    /// Presented as an overlay above everything, including sheets.
    static let sessionUnlock = PinConfiguration(
        titleKey: "pin.unlock.title",
        instructionKey: "pin.unlock.instruction",
        purpose: .sessionUnlock,
        onSuccess: .dismiss,
        errorPolicy: ErrorPolicy(defaultSurface: .snackbar, overrides: [:])
    )

    /// Pushed onto the stack. An expired session here must block, not whisper.
    static func transactionApproval(reference: TransactionReference) -> PinConfiguration {
        PinConfiguration(
            titleKey: "pin.approve.title",
            instructionKey: "pin.approve.instruction",
            purpose: .transactionApproval,
            onSuccess: .popTo(reference: reference),
            errorPolicy: ErrorPolicy(defaultSurface: .sheet,
                                     overrides: [.unauthorized: .blocker, .network: .snackbar])
        )
    }
}
