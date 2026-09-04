#if DEBUG
import Foundation

/// Live-instance counter keyed by type name. DEBUG only — the whole file is
/// compiled out of RELEASE, so it cannot become a runtime dependency.
///
/// The process-wide instance below is diagnostics, not architecture: nothing in
/// `Sources` reads state from it, and removing it changes no production behaviour.
public final class LifecycleTracker: @unchecked Sendable {
    // Process-wide by necessity: `deinit` cannot reach an injected container.
    // swiftlint:disable:next no_shared_singleton
    public static let shared = LifecycleTracker()
    private let lock = NSLock()
    private var counts: [String: Int] = [:]

    public init() { }

    public func record(init instance: AnyObject) {
        mutate(typeName: String(reflecting: type(of: instance)), delta: 1)
    }

    public func record(deinit instance: AnyObject) {
        mutate(typeName: String(reflecting: type(of: instance)), delta: -1)
    }

    public func liveCount(for typeName: String) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return counts[typeName] ?? 0
    }

    public func snapshot() -> [String: Int] {
        lock.lock()
        defer { lock.unlock() }
        return counts
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        counts.removeAll()
    }

    private func mutate(typeName: String, delta: Int) {
        lock.lock()
        defer { lock.unlock() }
        counts[typeName] = (counts[typeName] ?? 0) + delta
    }
}
#endif
