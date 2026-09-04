import CoreKit

struct VerifyPinInput: Equatable {
    let code: String
    let purpose: PinPurpose
}

struct VerifyPinOutput: Equatable {
    let isVerified: Bool
    let remainingAttempts: Int
}

protocol VerifyPinUseCase {
    func execute(_ input: VerifyPinInput) async throws -> VerifyPinOutput
}

/// One operation, one type, no UIKit, no navigator.
struct VerifyPin: VerifyPinUseCase {
    private let repository: any PinRepository
    private static let requiredLength = 6

    init(repository: any PinRepository) {
        self.repository = repository
    }

    func execute(_ input: VerifyPinInput) async throws -> VerifyPinOutput {
        guard input.code.count == Self.requiredLength else {
            throw AppError(kind: .validation,
                           message: "Enter all \(Self.requiredLength) digits.",
                           diagnosticCode: "pin.length")
        }
        let verification = try await repository.verify(code: input.code, purpose: input.purpose)
        guard verification.isVerified else {
            throw AppError(kind: .unauthorized,
                           message: "That PIN is not correct.",
                           diagnosticCode: "pin.rejected")
        }
        return VerifyPinOutput(isVerified: true, remainingAttempts: verification.remainingAttempts)
    }
}
