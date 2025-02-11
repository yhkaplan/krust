struct KrustNativeFunction: KrustCallable {
    let arity: Int
    private let string: String
    private let _call: (Interpreter, [Value]) -> Value

    init(arity: Int, string: String, call: @escaping (Interpreter, [Value]) -> Value) {
        self.arity = arity
        self.string = string
        _call = call
    }

    var description: String { "<fn \(string)>" }

    func call(interpreter: Interpreter, arguments: [Value]) -> Value {
        _call(interpreter, arguments)
    }
}
