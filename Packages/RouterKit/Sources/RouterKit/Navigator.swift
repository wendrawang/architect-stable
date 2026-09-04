
/// A tab, named by the composition root.
///
/// A `String`-backed struct rather than an enum: an enum here would force
/// `RouterKit` to know every feature's name. The values live in `AppCore` as
/// static members of this type.
public struct TabIdentifier: Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// The only navigation API a call site ever touches.
///
/// A view model holding a `Navigator` can reach any registered destination without
/// its parent declaring anything, which is what removes the per-flow routing objects
/// the legacy app accumulated.
///
/// `isAnimated` has no default on any method: the call site states its intent.
/// The house rule that every `Bool` is `is`-prefixed applies to protocol parameters
/// too, so it is `isAnimated`, not `animated`.
///
/// This protocol is the one exemption from the rule-of-three: it is the swap point
/// for the iOS 16 stack-based navigation API, which is a written 2027 commitment.
@MainActor
public protocol Navigator: AnyObject {
    func push(_ route: any Route, isAnimated: Bool)
    func replaceTop(with route: any Route, isAnimated: Bool)
    func setStack(_ routes: [any Route], isAnimated: Bool)

    func pop(isAnimated: Bool)
    func popToRoot(isAnimated: Bool)
    func popTo<R: Route>(_ type: R.Type, isAnimated: Bool)

    func present(_ route: any Route, as style: PresentationStyle, isAnimated: Bool)
    /// Dismisses the top overlay if one is showing, otherwise the top-most modal.
    func dismiss(isAnimated: Bool)
    func dismissAllModals(isAnimated: Bool)

    func switchTab(_ tab: TabIdentifier, isStackReset: Bool)
}
