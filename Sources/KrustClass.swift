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
    var arity: Int { findMethod(name: "init")?.arity ?? 0 }

    func call(interpreter: Interpreter, arguments: [Value]) -> Value {
        let instance = KrustInstance(krustClass: self)
        if let initializer = findMethod(name: "init") {
            _ = initializer.bind(instance).call(interpreter: interpreter, arguments: arguments)
        }

        return .classInstance(instance)
    }
}
