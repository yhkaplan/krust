protocol KrustCallable: CustomStringConvertible {
    var arity: Int { get }
    func call(interpreter: Interpreter, arguments: [LiteralValue]) -> LiteralValue
}
