import Foundation

/// Wire shape. This type must never appear outside `Data/`.
struct PinVerificationDTO: Decodable {
    let isVerified: Bool
    let remainingAttempts: Int

    enum CodingKeys: String, CodingKey {
        case isVerified = "verified"
        case remainingAttempts = "remaining_attempts"
    }
}
