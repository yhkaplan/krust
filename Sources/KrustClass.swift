final class KrustClass: CustomStringConvertible {
    let name: String

    init(name: String) {
        self.name = name
    }

    var description: String { name }
}

extension KrustClass: KrustCallable {
    var arity: Int { 0 }

    func call(interpreter: Interpreter, arguments: [LiteralValue]) -> LiteralValue {
        .classInstance(KrustInstance(krustClass: self))
    }
}
