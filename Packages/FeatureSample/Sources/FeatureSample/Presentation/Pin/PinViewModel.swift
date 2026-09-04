import Combine
import CoreKit
import RouterKit

/// One view model for every PIN flow. The flow is the configuration.
@MainActor
final class PinViewModel: ObservableObject {
    @Published private(set) var state: PinState
    private let configuration: PinConfiguration
    private let navigator: any Navigator
    private let verifyPin: any VerifyPinUseCase
    private let snackbar: any SnackbarPresenter
    /// Internal rather than private so a test can await the in-flight submission without
    /// a sleep. Never read from production code.
    var submitTask: Task<Void, Never>?

    init(configuration: PinConfiguration,
         navigator: any Navigator,
         verifyPin: any VerifyPinUseCase,
         snackbar: any SnackbarPresenter) {
        self.configuration = configuration
        self.navigator = navigator
        self.verifyPin = verifyPin
        self.snackbar = snackbar
        self.state = PinState(heading: configuration.titleKey.rawValue,
                              instruction: configuration.instructionKey.rawValue,
                              entry: "",
                              status: .idle,
                              attemptsCaption: nil,
                              inlineErrorMessage: nil)
        #if DEBUG
        LifecycleTracker.shared.record(init: self)
        #endif
    }

    deinit {
        submitTask?.cancel()
        #if DEBUG
        LifecycleTracker.shared.record(deinit: self)
        #endif
    }

    func send(_ action: PinAction) {
        switch action {
        case .onAppear:
            break
        case .digitEntered(let digit):
            state.entry.append(digit)
            state.inlineErrorMessage = nil
        case .backspaceTapped:
            guard !state.entry.isEmpty else { return }
            state.entry.removeLast()
        case .submitTapped:
            submit()
        case .cancelTapped:
            navigator.dismiss(isAnimated: true)
        }
    }

    private func submit() {
        submitTask?.cancel()
        state.status = .loading
        let input = VerifyPinInput(code: state.entry, purpose: configuration.purpose)
        submitTask = Task { [weak self] in
            guard let self else { return }
            do {
                let output = try await self.verifyPin.execute(input)
                self.succeed(with: output)
            } catch {
                self.fail(with: error)
            }
        }
    }

    private func succeed(with output: VerifyPinOutput) {
        state.status = .loaded(PinOutcome(message: "Verified."))
        state.attemptsCaption = "Attempts left: \(output.remainingAttempts)"
        perform(configuration.onSuccess)
    }

    /// `onSuccess` is data, so the interpretation lives here and is testable without UIKit.
    private func perform(_ action: PinSuccessAction) {
        switch action {
        case .push(let route):
            navigator.push(route, isAnimated: true)
        case .popTo(let reference):
            navigator.popToRoot(isAnimated: true)
            snackbar.show(message: "Approved \(reference.rawValue)")
        case .dismiss:
            navigator.dismiss(isAnimated: true)
        }
    }

    private func fail(with error: any Error) {
        let appError = (error as? AppError) ?? AppError(kind: .unknown,
                                                        message: "Something went wrong.",
                                                        diagnosticCode: nil)
        state.status = .failed(appError)
        state.entry = ""
        switch configuration.errorPolicy.surface(for: appError) {
        case .snackbar:
            snackbar.show(message: appError.message)
        case .sheet:
            state.inlineErrorMessage = appError.message
        case .blocker:
            state.inlineErrorMessage = appError.message
            navigator.present(SamplePinRoute(configuration: .sessionUnlock),
                              as: .overlay(.blocking),
                              isAnimated: true)
        }
    }
}
