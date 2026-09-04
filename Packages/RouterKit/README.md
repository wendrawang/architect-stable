# RouterKit

Navigation infrastructure for an iOS 15 UIKit shell hosting SwiftUI screens.
There is no routing object per flow. There is a registry, a navigator, and route values.

## How to add a screen

1. Create the folder under your feature package:

```
Packages/FeatureX/Sources/FeatureX/Presentation/ScreenName/
  ScreenNameView.swift        SwiftUI. No logic, no navigator, no Task, no formatting.
  ScreenNameViewModel.swift   @MainActor final class, ObservableObject. Owns the navigator.
  ScreenNameState.swift       One state struct, one action enum.
```

2. The state holds strings that are already formatted. If the view would need to format
   something, the view model formats it first.
3. The view model is the only layer that calls `Navigator`. It is built once, by the route
   factory, before the hosting controller exists.
4. `init` assigns dependencies and computes the initial state. It never performs I/O.
   Loading starts from an explicit `send(.onAppear)`.

## How to add a route

```swift
public struct TransferSummaryRoute: Route, Equatable {
    public let reference: TransactionReference
    public init(reference: TransactionReference) { self.reference = reference }
}
```

- A route is a `struct` in the package that owns the destination.
- Routes carry data. Never a dependency, never a closure.
- **No PII.** No account number, card number, national identity number or full customer
  name. Carry an opaque reference and let the destination resolve it. Routes reach deep
  links, logs and crash reports.
- Conform to `Equatable`; `Route.isEquivalent(to:)` then comes for free and deep-link
  resolution stays comparable in tests.
- Per-flow variation is a configuration value, not a new type. See `PinConfiguration` in
  `FeatureSample`: one screen, three flows, five fields.

## How to register a feature

```swift
@MainActor
public enum TransferRegistrar: FeatureRegistrar {
    public static func register(into registry: RouteRegistry, dependencies: FeatureDependencies) {
        guard let transfer = dependencies as? any TransferDependencies else { return }
        registry.register(TransferSummaryRoute.self) { route, navigator in
            let viewModel = TransferSummaryViewModel(reference: route.reference,
                                                     navigator: navigator,
                                                     submitTransfer: transfer.submitTransfer)
            return HostingScreen(chrome: ScreenChrome(title: "Summary"),
                                 rootView: TransferSummaryView(viewModel: viewModel))
        }
    }
}
```

- The factory runs at **push** time, never at registration time. Registration stores a
  closure and builds nothing. This is the most important rule in the package.
- Each feature declares its own narrow dependency protocol refining `FeatureDependencies`.
  `AppCore` conforms one container to all of them. RouterKit never learns a feature's name.
- A factory may capture the composition root's container strongly, because that container
  lives for the process. Say so in a comment. Capturing anything shorter-lived is a leak.

## What is forbidden

- `AnyView`. `UIViewController` is the erasure boundary.
- Any type named `*Coordinator`, `*Manager`, `*Handler`, `*Provider`, `*Helper`,
  `*Service`, `*Facade`, `*Wrapper`.
- `NavigationView`, `NavigationLink`, `.sheet(isPresented:)`, `.fullScreenCover`. All
  presentation goes through `Navigator`.
- Singletons, `static let shared`, global mutable state. The one exception is
  `LifecycleTracker`, which is DEBUG-only diagnostics and compiled out of RELEASE.
- Default values on dependency parameters. Presentation-only configuration structs may
  have them; dependencies never.
- Force unwrap, `try!`, `as!`.
- iOS 16+ API, including behind an availability check. The single sanctioned location for
  version branching is `CoreKit/Sources/CoreKit/Compat/AvailabilityShim.swift`.
- A DTO outside its feature's `Data/` folder.
- A dependency-injection container, a navigator middleware pipeline, a reducer framework,
  a route DSL, a `BaseViewModel`, a caching layer, or an animation configuration
  abstraction. Manual `init` injection only.

## Ownership contract

| Holder | Holds | Strength |
|---|---|---|
| `TabHost` | `StackNavigator` per tab | strong |
| `TabHost` | `UITabBarController` | strong |
| `StackNavigator` | `UINavigationController` | **weak** |
| `StackNavigator` | `TabHost` | **weak** |
| `StackNavigator` | `OverlayWindowController` | strong (owned by the composition root) |
| `UINavigationController` | `UIViewController` stack | strong |
| `HostingScreen` | `ViewModel` | strong, via `rootView`'s `@ObservedObject` storage |
| `ViewModel` | `Navigator` | strong (the navigator is owned by `TabHost`, so no cycle) |
| `Navigator` | any `ViewModel` or `UIViewController` it created | **never** |
| `RouteRegistry` | factory closures | strong; a closure captures nothing shorter-lived than the composition root |
| `OverlayWindowController` | queued overlay controllers | strong until dismissed, then released |

Rules that follow from it:

- `[weak self]` in every escaping closure declared inside a view model or a navigator,
  including `Task {}` blocks that outlive a single call.
- Every `Task` started by a view model is stored and cancelled in `deinit`, or is
  `Task { [weak self] in }`.
- No selector-based `NotificationCenter.addObserver`. Use the async sequence, or the block
  API with a stored token removed in `deinit`.
- Every view model and every view controller gets a `#if DEBUG` `deinit` that calls
  `LifecycleTracker.shared.record(deinit: self)`.

## Structural performance rules

- Destination view controllers are constructed only when navigated to.
- Nothing happens in `RouteRegistry.register` beyond storing a closure.
- `HostingScreen` must not trigger a SwiftUI body evaluation from `viewWillAppear` or
  `viewWillLayoutSubviews`.
- Nothing in a view model's `init` performs I/O.
- No `.id(UUID())`, and no `.id()` on a value that changes per render.
- `ForEach` uses stable identifiers; `\.self` only for primitives.
- No `GeometryReader` inside a scrolling container.

## Frame budget — unresolved, needs a product decision

60fps is the wrong number to state as a goal. ProMotion devices run to 120Hz, an **8.3 ms**
frame budget rather than 16.7 ms.

- **Option A — do not add `CADisableMinimumFrameDurationOnPhone`.** The app stays capped at
  60Hz, the budget is 16.7 ms, and animations look correct but not premium on ProMotion.
- **Option B — add it.** The budget becomes 8.3 ms and every custom animation has to be
  re-validated on a 120Hz device.

This is a product decision, not an engineering one. **It has not been made.** No
`Info.plist` in this repository sets the key, which is Option A by default rather than by
choice; record the decision here before the first real screen ships.

## Signposts

`PerformanceSignpost` (CoreKit), subsystem `id.co.ocbcnisp.byon`, categories `navigation`
and `screen`. Compiled out of RELEASE unless `PERF_SIGNPOSTS` is set.

| Signpost | Start | End | Budget (p95) |
|---|---|---|---|
| `route.resolve` | `Navigator.push` entry | factory returns a controller | 5 ms |
| `screen.init` | controller init | `viewDidLoad` end | 16 ms |
| `screen.firstFrame` | `Navigator.push` entry | navigation controller reports the screen shown | 250 ms |
| `overlay.present` | present call | overlay window becomes key | 100 ms |

`screen.firstFrame` ends in `UINavigationControllerDelegate.didShow` rather than in the
destination's `viewDidAppear`: the same instant in practice, and it keeps the interval
token inside the navigator instead of threading it through every screen.

## Naming and layout rules that a linter cannot check

- Every `Bool` — stored, computed, parameter or local — is prefixed `is`. This applies to
  the `Navigator` protocol too, which is why it is `isAnimated`, not `animated`.
- Every closure-typed property or parameter representing a callback is prefixed `on`.
  Never `completion`, `handler`, `callback`, `block`.
- Identifiers are 3 to 35 characters. `viewModel`, not `vm`. If a name needs more than 35,
  split the type.
- Escaping closures are allowed for UI event callbacks and never for asynchronous results.
  Closures signal events; `async` returns values.
- No blank line between consecutive property declarations; exactly one blank line between
  the property block and the first method, and between methods; never two blank lines.
- 250 lines per file, 50 lines per method body.
