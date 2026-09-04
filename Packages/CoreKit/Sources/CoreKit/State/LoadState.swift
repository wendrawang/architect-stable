
/// The only sanctioned way to model "a value that may not be here yet".
///
/// Sentinel defaults (`""`, a zeroed struct) hide the difference between
/// "not asked", "asking" and "asked and failed". Use `Optional` for genuine
/// absence and `LoadState` for anything fetched.
public enum LoadState<Value: Equatable>: Equatable {
    case idle
    case loading
    case loaded(Value)
    case failed(AppError)
}
