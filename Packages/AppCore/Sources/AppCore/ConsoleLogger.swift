import os
import CoreKit

/// The one logger. Three methods, one subsystem, no levels enum and no sinks.
///
/// The conformance is qualified because this file imports `os`, which also exports a type
/// named `Logger`. Any file importing both `os` and `CoreKit` has to disambiguate; this is
/// the only one that does. See README.md for the naming trade-off.
public final class ConsoleLogger: CoreKit.Logger {
    private let log: OSLog

    public init(subsystem: String, category: String) {
        self.log = OSLog(subsystem: subsystem, category: category)
    }

    public func debug(_ message: String) {
        os_log("%{public}@", log: log, type: .debug, message)
    }

    public func info(_ message: String) {
        os_log("%{public}@", log: log, type: .info, message)
    }

    public func error(_ message: String) {
        os_log("%{public}@", log: log, type: .error, message)
    }
}
