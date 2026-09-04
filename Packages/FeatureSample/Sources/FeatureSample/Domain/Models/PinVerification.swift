/// Domain model. No transport concern reaches this type.
struct PinVerification: Equatable {
    let isVerified: Bool
    let remainingAttempts: Int
}
