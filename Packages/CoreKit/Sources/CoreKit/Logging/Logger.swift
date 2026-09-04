
/// Three methods. No levels enum, no sinks, no formatters.
///
/// If structured logging is needed later it is a new conformance, not a wider protocol.
public protocol Logger: AnyObject {
    func debug(_ message: String)
    func info(_ message: String)
    func error(_ message: String)
}

/// Write-only analytics boundary. Stubbed for this task; the real transport is out of scope.
public protocol AnalyticsSink: AnyObject {
    func track(event: String, parameters: [String: String])
}
