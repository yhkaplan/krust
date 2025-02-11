enum Value: @unchecked Sendable {
    case number(Double)
    case string(String)
    case boolean(Bool)
    case `nil`
    case callable(KrustCallable)
    case classInstance(KrustInstance)
}
