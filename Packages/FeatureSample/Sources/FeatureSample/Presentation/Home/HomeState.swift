import Foundation

/// A row the view renders verbatim. The title is already formatted; the view never
/// formats, branches on a business condition, or decides what a tap means.
struct HomeRow: Equatable, Identifiable {
    let id: String
    let title: String
    let action: HomeAction
}

struct HomeState: Equatable {
    let heading: String
    let caption: String
    let rows: [HomeRow]
}

enum HomeAction: Equatable {
    case onAppear
    case approveTransactionTapped
    case signInTapped
    case lockSessionTapped
    case paymentsTabTapped
}
