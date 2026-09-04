import Foundation

/// Stub transport. Real network calls are out of scope; the point of this type is the
/// mapping boundary — a DTO is decoded here and a domain model leaves here.
struct SamplePinRepository: PinRepository {
    private static let acceptedCode = "123456"
    private static let cannedResponse = #"{"verified": true, "remaining_attempts": 2}"#

    func verify(code: String, purpose: PinPurpose) async throws -> PinVerification {
        let payload = Data(Self.cannedResponse.utf8)
        let dto = try JSONDecoder().decode(PinVerificationDTO.self, from: payload)
        return PinVerification(isVerified: dto.isVerified && code == Self.acceptedCode,
                               remainingAttempts: dto.remainingAttempts)
    }
}
