import Foundation

/// Protocol here, implementation in `Data`. `nonisolated` by default: repositories do
/// their own hopping and are never pinned to the main actor to silence a warning.
protocol PinRepository {
    func verify(code: String, purpose: PinPurpose) async throws -> PinVerification
}
