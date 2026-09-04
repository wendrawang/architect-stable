import XCTest
import CoreKit
import CoreKitTestSupport
import RouterKit
@testable import FeatureSample

@MainActor
final class PinViewModelTests: XCTestCase {
    func test_oneScreenServesThreeFlowsThroughConfigurationAlone() {
        let reference = TransactionReference(rawValue: "TRX-1")
        let approval = PinConfiguration.transactionApproval(reference: reference)
        XCTAssertEqual(approval.onSuccess, .popTo(reference: reference))
        XCTAssertEqual(PinConfiguration.login.onSuccess, .dismiss)
        XCTAssertEqual(PinConfiguration.sessionUnlock.purpose, .sessionUnlock)
        XCTAssertEqual(approval.errorPolicy.surface(for: unauthorized), .blocker)
        XCTAssertEqual(PinConfiguration.login.errorPolicy.surface(for: unauthorized), .snackbar)
    }

    func test_initPerformsNoWorkAndLeavesTheScreenIdle() {
        let navigator = RecordingNavigator()
        let useCase = RecordingVerifyPin(result: .success(VerifyPinOutput(isVerified: true,
                                                                         remainingAttempts: 2)))
        let snackbar = RecordingSnackbar()
        let viewModel = PinViewModel(configuration: .login,
                                     navigator: navigator,
                                     verifyPin: useCase,
                                     snackbar: snackbar)
        trackForMemoryLeaks(viewModel)
        XCTAssertEqual(useCase.executionCount, 0, "init must never perform I/O")
        XCTAssertEqual(viewModel.state.status, .idle)
        XCTAssertTrue(navigator.calls.isEmpty)
    }

    func test_successfulLoginDismissesThroughTheNavigator() async {
        let navigator = RecordingNavigator()
        let useCase = RecordingVerifyPin(result: .success(VerifyPinOutput(isVerified: true,
                                                                         remainingAttempts: 2)))
        let viewModel = PinViewModel(configuration: .login,
                                     navigator: navigator,
                                     verifyPin: useCase,
                                     snackbar: RecordingSnackbar())
        trackForMemoryLeaks(viewModel)
        for digit in ["1", "2", "3", "4", "5", "6"] {
            viewModel.send(.digitEntered(digit))
        }
        viewModel.send(.submitTapped)
        await viewModel.waitForSubmission()
        XCTAssertEqual(navigator.calls, ["dismiss"])
    }

    func test_unauthorizedApprovalRaisesABlockerRatherThanASnackbar() async {
        let navigator = RecordingNavigator()
        let failure = AppError(kind: .unauthorized, message: "nope", diagnosticCode: nil)
        let useCase = RecordingVerifyPin(result: .failure(failure))
        let snackbar = RecordingSnackbar()
        let reference = TransactionReference(rawValue: "TRX-9")
        let viewModel = PinViewModel(configuration: .transactionApproval(reference: reference),
                                     navigator: navigator,
                                     verifyPin: useCase,
                                     snackbar: snackbar)
        trackForMemoryLeaks(viewModel)
        viewModel.send(.digitEntered("9"))
        viewModel.send(.submitTapped)
        await viewModel.waitForSubmission()
        XCTAssertEqual(navigator.calls, ["present.overlay"])
        XCTAssertTrue(snackbar.messages.isEmpty, "The policy chose blocker, not snackbar")
    }

    private var unauthorized: AppError {
        AppError(kind: .unauthorized, message: "nope", diagnosticCode: nil)
    }
}
