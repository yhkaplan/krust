struct KrustNativeFunction: KrustCallable {
    let arity: Int
    private let string: String
    private let _call: (Interpreter, [LiteralValue]) -> LiteralValue

    init(arity: Int, string: String, call: @escaping (Interpreter, [LiteralValue]) -> LiteralValue) {
        self.arity = arity
        self.string = string
        _call = call
    }

    var description: String { "<fn \(string)>" }

    func call(interpreter: Interpreter, arguments: [LiteralValue]) -> LiteralValue {
        _call(interpreter, arguments)
    }
}
