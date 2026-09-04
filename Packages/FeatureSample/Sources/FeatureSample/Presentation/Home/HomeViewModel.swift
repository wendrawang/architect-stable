import Foundation
import CoreKit
import RouterKit

/// The only layer in this screen that touches the navigator.
///
/// Built exactly once, by the route factory, before the hosting controller exists. That
/// is what structurally removes the "view model rebuilt on every body evaluation" defect:
/// there is no code path that can construct a second one.
@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var state: HomeState
    private let navigator: any Navigator
    private let snackbar: any SnackbarPresenter
    private let paymentsTab: TabIdentifier

    init(navigator: any Navigator, snackbar: any SnackbarPresenter, paymentsTab: TabIdentifier) {
        self.navigator = navigator
        self.snackbar = snackbar
        self.paymentsTab = paymentsTab
        self.state = HomeState(heading: "Sample feature",
                               caption: "One PIN screen, three flows, no routing objects.",
                               rows: Self.rows)
        #if DEBUG
        LifecycleTracker.shared.record(init: self)
        #endif
    }

    deinit {
        #if DEBUG
        LifecycleTracker.shared.record(deinit: self)
        #endif
    }

    func send(_ action: HomeAction) {
        switch action {
        case .onAppear:
            break
        case .approveTransactionTapped:
            let reference = TransactionReference(rawValue: "TRX-000123")
            let configuration = PinConfiguration.transactionApproval(reference: reference)
            navigator.push(SamplePinRoute(configuration: configuration), isAnimated: true)
        case .signInTapped:
            navigator.present(SamplePinRoute(configuration: .login),
                              as: .sheet(.medium),
                              isAnimated: true)
        case .lockSessionTapped:
            navigator.present(SamplePinRoute(configuration: .sessionUnlock),
                              as: .overlay(.session),
                              isAnimated: true)
        case .paymentsTabTapped:
            snackbar.show(message: "Switching to \(paymentsTab.rawValue)")
            navigator.switchTab(paymentsTab, isStackReset: true)
        }
    }

    private static let rows: [HomeRow] = [
        HomeRow(id: "approve", title: "Approve a transaction (push)", action: .approveTransactionTapped),
        HomeRow(id: "signIn", title: "Sign in (sheet)", action: .signInTapped),
        HomeRow(id: "lock", title: "Lock the session (overlay)", action: .lockSessionTapped),
        HomeRow(id: "payments", title: "Go to payments (tab)", action: .paymentsTabTapped)
    ]
}
