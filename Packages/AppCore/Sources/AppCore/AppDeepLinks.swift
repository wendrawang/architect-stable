import Foundation
import RouterKit
import FeatureSample

/// URL grammar lives here, in the composition root, because it is the only place that may
/// know both the scheme and every feature's routes.
///
/// Each link parses to the **whole** stack it wants. The dashboard is the first entry, so
/// back navigation lands on it, but it is never the entry point the customer waits through.
public enum AppDeepLinks {
    public static let scheme = "byon"

    public static func parse(_ url: URL) -> DeepLink? {
        guard url.scheme == scheme else { return nil }
        let segments = url.pathComponents.filter { $0 != "/" }
        guard let host = url.host else { return nil }
        switch (host, segments.first) {
        case ("sample", .none):
            return DeepLink(identifier: "sample.home",
                            stack: [SampleHomeRoute()],
                            isAuthenticationRequired: false)
        case ("sample", .some("approve")):
            guard let reference = queryValue(named: "reference", in: url) else { return nil }
            let configuration = PinConfiguration.transactionApproval(
                reference: TransactionReference(rawValue: reference)
            )
            return DeepLink(identifier: "sample.approve",
                            stack: [SampleHomeRoute(), SamplePinRoute(configuration: configuration)],
                            isAuthenticationRequired: true)
        default:
            return nil
        }
    }

    private static func queryValue(named name: String, in url: URL) -> String? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        return components?.queryItems?.first(where: { $0.name == name })?.value
    }
}
