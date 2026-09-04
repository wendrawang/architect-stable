import Foundation
import CoreKit
import RouterKit

/// What this feature needs from outside, and nothing else.
///
/// It refines the cross-cutting set rather than duplicating it. The composition root
/// conforms one container to this and to every other feature's equivalent protocol.
/// Note what is absent: the repository is built inside this package, so it stays internal.
public protocol SampleDependencies: FeatureDependencies {
    var snackbar: any SnackbarPresenter { get }
    /// Supplied by the composition root. A feature must not name another feature's tab.
    var paymentsTab: TabIdentifier { get }
}
