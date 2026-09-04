import CoreKit

/// The cross-cutting services every feature may assume exist.
///
/// It lists services, never feature types. A feature that needs more declares its own
/// protocol refining this one in its own package, and the composition root conforms a
/// single container to all of them.
public protocol FeatureDependencies: AnyObject {
    var logger: any Logger { get }
    var session: SessionSnapshot { get }
    var analytics: any AnalyticsSink { get }
}

/// Federated registration. Each feature package contributes its own routes.
///
/// `RouterKit` never learns a feature's name: the composition root imports the feature
/// and calls its registrar.
@MainActor
public protocol FeatureRegistrar {
    static func register(into registry: RouteRegistry, dependencies: FeatureDependencies)
}
