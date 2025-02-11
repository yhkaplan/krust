final class KrustClass: CustomStringConvertible {
    let name: String
    private var methods: [String: KrustFunction]

    var description: String { name }

    init(name: String, methods: [String: KrustFunction] = [:]) {
        self.name = name
        self.methods = methods
    }

    func findMethod(name: String) -> KrustFunction? { methods[name] }
}

extension KrustClass: KrustCallable {
    var arity: Int { 0 }

    func call(interpreter: Interpreter, arguments: [LiteralValue]) -> LiteralValue {
        .classInstance(KrustInstance(krustClass: self))
    }
}
