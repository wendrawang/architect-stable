import os
import CoreKit

/// The one logger. Three methods, one subsystem, no levels enum and no sinks.
public final class ConsoleLogger: Logger {
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
