import os

/// Interval instrumentation for the navigation path.
///
/// Compiles to nothing in RELEASE unless the `PERF_SIGNPOSTS` condition is set,
/// so shipped builds carry no always-on instrumentation.
public struct PerformanceSignpost {
    public enum Category: String {
        case navigation
        case screen
    }

    /// The four intervals with a written budget. Adding a fifth means adding a budget.
    public enum Interval {
        case routeResolve
        case screenInit
        case screenFirstFrame
        case overlayPresent

        var signpostName: StaticString {
            switch self {
            case .routeResolve: return "route.resolve"
            case .screenInit: return "screen.init"
            case .screenFirstFrame: return "screen.firstFrame"
            case .overlayPresent: return "overlay.present"
            }
        }
    }

    /// Opaque interval receipt. Carries no payload when instrumentation is compiled out.
    public struct Token {
        #if DEBUG || PERF_SIGNPOSTS
        fileprivate let state: OSSignpostIntervalState

        fileprivate init(state: OSSignpostIntervalState) {
            self.state = state
        }
        #else
        fileprivate init() { }
        #endif
    }

    public static let subsystem = "id.co.ocbcnisp.byon"
    #if DEBUG || PERF_SIGNPOSTS
    private let signposter: OSSignposter
    #endif

    public init(category: Category) {
        #if DEBUG || PERF_SIGNPOSTS
        self.signposter = OSSignposter(subsystem: Self.subsystem, category: category.rawValue)
        #endif
    }

    public func begin(_ interval: Interval) -> Token {
        #if DEBUG || PERF_SIGNPOSTS
        return Token(state: signposter.beginInterval(interval.signpostName))
        #else
        return Token()
        #endif
    }

    public func end(_ interval: Interval, token: Token) {
        #if DEBUG || PERF_SIGNPOSTS
        signposter.endInterval(interval.signpostName, token.state)
        #endif
    }
}
