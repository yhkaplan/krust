struct KrustFunction: KrustCallable {
    let declaration: Stmt.Function
    let closureEnvironment: Environment
    let isInitializer: Bool

    var arity: Int { declaration.params.count }

    var description: String { "<fn \(declaration.name.lexeme)>" }

    func call(interpreter: Interpreter, arguments: [Value]) -> Value {
        let environment = Environment(enclosing: closureEnvironment)
        for (i, param) in declaration.params.enumerated() {
            environment.define(param.lexeme, arguments[i])
        }

        do {
            try interpreter.executeBlock(statements: declaration.body, environment: environment)
        } catch let error as Return { // Hack to unwind the stack
            // A valid early return inside an initializer
            if isInitializer { return closureEnvironment.getAt(depth: 0, name: "this") }
            return error.value ?? .nil
        } catch {
            // TODO: handle error
        }

        if isInitializer { return closureEnvironment.getAt(depth: 0, name: "this") }
        return .nil
    }

    func bind(_ instance: KrustInstance) -> KrustFunction {
        let environment = Environment(enclosing: closureEnvironment)
        environment.define("this", .classInstance(instance))
        return KrustFunction(declaration: declaration, closureEnvironment: environment, isInitializer: isInitializer)
    }
}
