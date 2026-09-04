# architect-stable

Navigation foundation for a greenfield iOS 15 rewrite. Local SPM packages only, no
`.xcodeproj`, no third-party dependencies.

```
Packages/
  CoreKit/        errors, LoadState, ErrorPolicy, Logger, availability shim, diagnostics
  RouterKit/      navigation infrastructure                     depends on CoreKit
  DesignKit/      placeholder                                   depends on CoreKit
  NetworkKit/     placeholder                                   depends on CoreKit
  FeatureSample/  one throwaway feature, end to end             CoreKit + RouterKit + DesignKit
  AppCore/        composition root                              everything above
```

`Packages/RouterKit/README.md` is the working document: how to add a screen, add a route,
register a feature, the ownership contract, and what is forbidden.

## Verification status — read this first

The brief's Part 5 and Part 9.4 gates are:

```bash
xcodebuild -scheme RouterKit -destination 'generic/platform=iOS' build
xcodebuild -scheme RouterKit -destination 'platform=iOS Simulator,name=iPhone 15' test
swiftlint --strict --config .swiftlint.yml
swiftlint analyze --strict --compiler-log-path build.log
```

**None of these were run here.** This work was produced in a Linux container with no Swift
toolchain, no Xcode and no UIKit — and the container's network policy blocks
`download.swift.org`, so even a parse-only check was unavailable. The code has never been
compiled and the tests have never executed on this machine. Treat every Swift file as
unbuilt until the gates go green. Nothing below claims otherwise.

They are now wired to run automatically. `.github/workflows/ci.yml` runs all four on a
`macos-14` runner on every pull request, plus the structural job on Linux.
`Tools/gates-macos.sh` runs the same sequence locally. **The first CI run on this branch is
the real verification of this change** — read it before reading anything else here.

What *was* run in this container, and passes:

```bash
bash Tools/verify.sh
```

- `Tools/lint_custom_rules.py` evaluates the fifteen `custom_rules` regexes from
  `.swiftlint.yml` verbatim against `Packages/*/Sources`. It honours
  `// swiftlint:disable:next`. It does **not** evaluate a single built-in SwiftLint rule,
  so `line_length`, `file_length`, `identifier_name`, `modifier_order` and the rest are
  unchecked by machine here — only by hand.
- `Tools/budgets.py` reports the Part 8 budgets and the Part 9.4 early-warning counts.
- `Tools/verify.sh` also checks the Part 5 structural confirmations and the dependency
  edges between packages.

Current output: 0 custom-rule violations, 0 budget failures, 0 structural failures.

### Part 5 confirmations

| Confirmation | Result |
|---|---|
| No `AnyView` in any file | confirmed, 0 occurrences |
| No `if #available` outside `AvailabilityShim.swift` | confirmed, 0 occurrences anywhere — the shim needs none today |
| No banned iOS 16 API present | confirmed, 0 occurrences |
| No default parameter value on any dependency in any `init` | confirmed |
| No feature package importing another feature package | confirmed, and unwritable: no feature manifest lists another |

### Part 8 budgets

| Metric | Actual | Limit |
|---|---|---|
| `RouterKit` source files (excl. tests) | 15 | 20 |
| `RouterKit` non-comment lines | 573 | 1,500 |
| `RouterKit` public symbols | 21 | 25 |
| `CoreKit` public symbols | 12 | 30 |
| Parameters in any `init` | 5 | 5 |
| Nesting depth of generics | 1 | 1 |
| Protocols with `associatedtype` in any public API | 0 | 0 |

### Part 9.4 early warnings

Files over 200 non-comment lines: **0**. Methods over 40 lines: **0**. Identifiers over
30 characters: **0**. Nothing is near a ceiling.

## What could not be delivered, and why

- **Nothing was compiled, linted with SwiftLint, or tested in this container.** See above.
  This is the single largest caveat on the whole delivery; CI closes it on the first run.
- **Part 6.6, the manual memory pass** (Debug Memory Graph, Instruments Leaks +
  Allocations, `MallocStackLogging`) requires Xcode and a device or simulator. Not run,
  and no findings are reported — reporting "no leaks found" from an unrun tool would be a
  fabrication. The deterministic leak tests from 6.4 and the 50-cycle test from 6.5 are
  written and are in `Packages/RouterKit/Tests/RouterKitTests/MemoryTests.swift`.
- **Part 7.4's UI test target** using `XCTOSSignpostMetric.navigationTransitionMetric`
  needs a host application target, which needs an `.xcodeproj`, which Part 1 forbids
  creating. The same applies to committing XCTest performance baselines: they live in the
  scheme's `xcshareddata`, not in a package. Both are blocked by the constraints as
  written, not by effort. If the transition metric matters — and it is the only thing that
  measures real smoothness — the "local SPM packages only" rule needs one exception: a thin
  host app target in a project file that contains nothing but the app delegate.
- **A runnable app.** `AppCore.AppComposition` is a complete composition root, but without
  an app target there is nothing to launch. Hosting it is three lines in a scene delegate:
  build `AppComposition(windowScene:logger:analytics:)`, set
  `window.rootViewController = composition.rootViewController()`, call
  `makeKeyAndVisible()`.

## Performance: what this task did and did not earn

`FeatureSample` has two screens with a `Text` and some `Button`s. **Any frame-rate number
measured against it is meaningless** and none is reported. What is delivered is the
apparatus and the budgets: `PerformanceSignpost` with the four intervals and their p95
targets, `RouterKitPerformanceTests` wired to `XCTClockMetric`, `XCTMemoryMetric` and
`XCTOSSignpostMetric`, and the structural rules in `Packages/RouterKit/README.md` that
actually govern whether the real screens are fast. Enforce the budgets against the transfer
flow, which is the first migration target. There is no "60fps achieved" claim here, and the
120Hz question is flagged as unresolved in the RouterKit README rather than decided quietly.

## Deviations from the brief, and the reasoning

Each of these is a place where the brief contradicts itself or its own linter. They are
listed rather than resolved silently.

1. **`animated:` became `isAnimated:`, `resetStack:` became `isStackReset:`.**
   Part 2.4 specifies `func pop(animated: Bool)`. Part 9's `bool_param_is_prefix` rule
   matches `\(\s*(?!is[A-Z])([a-z]\w*)\s*:\s*Bool\b`, which `pop(animated: Bool)` hits, at
   `severity: error`. Part 9 declares itself non-negotiable and Part 9.2 forbids relaxing a
   rule to make the build pass, so the signature moved. Note the rule only catches a Bool
   in *first* parameter position, so `push(_:animated:)` would have slipped through — the
   rename is for consistency with the stated convention, not just to clear the linter.
2. **`Route` gained one requirement: `isEquivalent(to:)`.** Part 2.1 specifies an empty
   marker protocol; Part 2.9 specifies `DeepLinkResolution: Equatable` carrying
   `[any Route]`. Those cannot both hold — `any Route` has no `==`. A conforming route
   declares `: Route, Equatable` and gets the implementation free from a protocol
   extension. The alternative was comparing type names, which would report two different
   `PinRoute` values as equal and make the deep-link tests worthless.
3. **`ErrorPolicy` is data, not a closure.** Part 3.4 specifies
   `struct ErrorPolicy { let map: (AppError) -> ErrorSurface }`. A stored closure makes
   every type containing it non-`Equatable` and non-`Sendable` — and Part 3.3 requires
   `PinConfiguration: Sendable, Equatable` while containing an `ErrorPolicy`. The closure
   form also trips the brief's own `callback_on_prefix` rule. It is now
   `defaultSurface` plus an `[AppErrorKind: ErrorSurface]` override map, with
   `surface(for:)`. This is the same argument Part 3.3 makes for `onSuccess`.
4. **`TabIdentifier` is declared in RouterKit; its values are declared in AppCore.**
   Part 2.8 says the type belongs to `AppCore`, but Part 2.4 puts it in `Navigator`'s
   signature, which lives in RouterKit. The type is a `String`-backed struct in RouterKit —
   never an enum, which is what would force RouterKit to know feature names — and
   `AppCore` declares `.dashboard` and `.payments` in an extension.
5. **`OverlayWindowController` takes its `UIWindow` rather than a `UIWindowScene`.**
   It still sets `windowLevel` to `.alert - 1` itself. Injecting the window is what makes
   leak test 6.4.4 runnable without a scene, and the composition root still creates the
   window in the main window's scene.
6. **`screen.firstFrame` ends in `UINavigationControllerDelegate.didShow`**, not in the
   destination's `viewDidAppear`. Same instant in practice; it keeps the interval token
   inside the navigator instead of threading it through every screen.
7. **`FeatureRegistrar` conformances downcast.** Part 2.3 fixes the signature at
   `register(into:dependencies: FeatureDependencies)`, so a feature needing more must cast
   to its own protocol. It is guarded, logged and asserted. Worth noting that by the Part 8
   rule-of-three, the protocol earns its place only once three features exist; with one
   feature, `AppCore` calling `SampleRegistrar.register` directly would be simpler. The
   protocol is kept because the brief mandates it and the third feature is not
   hypothetical.
8. **Three internal test seams.** `RouteRegistry.isDuplicateAssertionEnabled`,
   `StackNavigator.isPushInFlight` and `PinViewModel.submitTask` are `internal`, not
   `private`. Duplicate registration traps in DEBUG, which makes the
   "keeps the first registration" contract untestable, and the double-push guard cannot be
   driven deterministically without a `UIViewControllerTransitionCoordinator` test double
   with twenty members. None of them widens the public surface.
9. **`LifecycleTracker.shared` carries a one-line `swiftlint:disable:next`.** The brief
   mandates the call shape in 6.2 and its own `no_shared_singleton` rule forbids it. The
   whole file is inside `#if DEBUG`, but SwiftLint lints text, not build configurations.
10. **`// TODO(iOS16)` carries a `swiftlint:disable:next todo`.** The default `todo` rule
    is enabled (the config sets no `disabled_rules`) and would fail `--strict`.
11. **The sample has one extra PIN configuration, not one extra screen.** Part 3.3 asks
    for two configurations; there are three — login (sheet), transaction approval (push),
    session unlock (overlay). The third exists so the overlay blocker is demonstrated
    without adding a screen, which is a stronger proof of the pattern than a second screen
    would have been.

## Abstractions created, and why (Part 8.4)

Call sites are counted in `Sources`, excluding tests.

| Type | What it is | Call sites | Why it exists |
|---|---|---|---|
| `Route` | marker + value equality for a destination | 5 route types, every navigator method | The unit the whole package moves around. |
| `RouterError` | two recoverable failures | 3 | Lets resolution throw instead of trapping in RELEASE. |
| `RouteRegistry` | route type → factory closure | 4 | The lazy-construction guarantee lives here. |
| `FeatureDependencies` | cross-cutting services | 2 | Federated registration without RouterKit knowing a feature. |
| `FeatureRegistrar` | a feature's registration entry point | 2 | Same. See deviation 7 — one real conformance today. |
| `Navigator` | the whole call-site API | every view model | **Exempt from the rule of three**: written swap point for the iOS 16 stack API in 2027. |
| `TabIdentifier` | a tab name | 5 | Keeps feature names out of RouterKit. |
| `PresentationStyle` / `SheetDetent` / `OverlayLevel` | how a destination appears | 6 | Three genuinely different mechanisms; the enum is the dispatch. |
| `StackNavigator` | `Navigator` over `UINavigationController` | 1 per tab, 2 today | The only `Navigator` implementation. Deleting it deletes the package. |
| `OverlayWindowController` | second-window overlay queue | 3 | The only mechanism that covers presented sheets. |
| `TabHost` | tab bar + navigators | 2 | Owns the navigators; nothing else can. |
| `SessionSnapshot` | auth state at resolution time | 3 | Keeps `resolveDeepLink` pure. |
| `DeepLink` / `DeepLinkRejection` / `DeepLinkResolution` | link input and outcome | 4 | Separates the decision from the navigation. |
| `resolveDeepLink` | the decision | 2 | Pure function; the whole point. |
| `HostingScreen` | SwiftUI/UIKit boundary | every screen | The erasure boundary that replaces `AnyView`. |
| `ScreenChrome` / `BackButtonStyle` | navigation-bar configuration | every screen | One owner for the bar. |
| `AppError` / `AppErrorKind` | the error crossing layers | many | — |
| `LoadState` | asked / asking / got / failed | 1 today | Below the rule of three. Kept because it is the stated replacement for the 9,382 defaulted properties, and the second and third call sites arrive with the first real screen. **Flagged, not justified away.** |
| `ErrorPolicy` / `ErrorSurface` | which surface shows an error | 3 | Moves the decision out of the view. |
| `Logger` | three methods | many | — |
| `AnalyticsSink` | write-only analytics | 2 | Stub boundary, per Part 10. |
| `LocalizedKey` | a key, not a string | 4 | Keeps configuration `Equatable` across locales. |
| `SnackbarPresenter` | transient message surface | 3 | Required by Part 3.4. |
| `AvailabilityShim` | version-agnostic sheet setup | 1 | Below the rule of three. Kept because it is the *designated* single location for future branching and it already owns the house sheet defaults. |
| `PerformanceSignpost` | four instrumented intervals | 4 | Part 7. Compiled out of RELEASE. |
| `LifecycleTracker` | live instance counter | DEBUG only | Part 6. Compiled out of RELEASE. |
| `PendingDeepLinkStore` | stash-once, replay-once | 2 | Fixes a named production defect. |
| `AppDependencies` / `AppComposition` | composition root | 1 each | — |

Two entries are below two call sites and are flagged above rather than removed:
`LoadState` and `AvailabilityShim`. Both have a written reason. Everything else clears the
bar. Nothing here is a dependency-injection container, a middleware pipeline, a reducer,
a route DSL, a `BaseViewModel`, or a caching layer.

## Known gaps in the supplied linter config

Reported, not worked around:

- `newline_between_methods` only fires when a method's closing brace is on its own line.
  Two adjacent single-line methods (`func first() { }` / `func second() { }`) pass. Verified
  against the regex as written.
- `bool_param_is_prefix` only inspects the first parameter after `(`. A `Bool` in any later
  position is invisible to it, which is why the `isAnimated` rename was a convention
  decision rather than a linter-forced one.
- `no_availability_outside_shim` has no path exclusion, so it would fire inside
  `AvailabilityShim.swift` itself. Not an issue today — the shim needs no branch — but the
  first branch added there will need a `disable:next`, or the rule needs an `excluded` key.
