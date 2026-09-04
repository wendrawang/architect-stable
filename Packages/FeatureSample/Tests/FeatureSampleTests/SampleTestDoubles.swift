import Foundation
import CoreKit
import RouterKit
@testable import FeatureSample

@MainActor
final class RecordingNavigator: Navigator {
    private(set) var calls: [String] = []

    func push(_ route: any Route, isAnimated: Bool) { calls.append("push") }
    func replaceTop(with route: any Route, isAnimated: Bool) { calls.append("replaceTop") }
    func setStack(_ routes: [any Route], isAnimated: Bool) { calls.append("setStack") }
    func pop(isAnimated: Bool) { calls.append("pop") }
    func popToRoot(isAnimated: Bool) { calls.append("popToRoot") }
    func popTo<R: Route>(_ type: R.Type, isAnimated: Bool) { calls.append("popTo") }
    func dismiss(isAnimated: Bool) { calls.append("dismiss") }
    func dismissAllModals(isAnimated: Bool) { calls.append("dismissAllModals") }
    func switchTab(_ tab: TabIdentifier, isStackReset: Bool) { calls.append("switchTab") }

    func present(_ route: any Route, as style: PresentationStyle, isAnimated: Bool) {
        switch style {
        case .fullScreen: calls.append("present.fullScreen")
        case .sheet: calls.append("present.sheet")
        case .overlay: calls.append("present.overlay")
        }
    }
}

@MainActor
final class RecordingSnackbar: SnackbarPresenter {
    private(set) var messages: [String] = []

    func show(message: String) { messages.append(message) }
}

final class RecordingVerifyPin: VerifyPinUseCase, @unchecked Sendable {
    private(set) var executionCount = 0
    private let result: Result<VerifyPinOutput, AppError>

    init(result: Result<VerifyPinOutput, AppError>) {
        self.result = result
    }

    func execute(_ input: VerifyPinInput) async throws -> VerifyPinOutput {
        executionCount += 1
        return try result.get()
    }
}

extension PinViewModel {
    /// Lets a test await the in-flight submission without exposing the task publicly.
    func waitForSubmission() async {
        await submitTask?.value
    }
}
