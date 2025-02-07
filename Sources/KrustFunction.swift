struct KrustFunction: KrustCallable {
    let declaration: Stmt.Function

    var arity: Int { declaration.params.count }

    var description: String { "<fn \(declaration.name.lexeme)>" }

    func call(interpreter: Interpreter, arguments: [LiteralValue]) -> LiteralValue {
        let environment = Environment(enclosing: interpreter.globals)
        for (i, param) in declaration.params.enumerated() {
            environment.define(param.lexeme, arguments[i])
        }

        interpreter.executeBlock(statements: declaration.body, environment: environment)
        return .nil
    }
}
