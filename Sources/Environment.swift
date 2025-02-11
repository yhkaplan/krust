final class Environment {
    var enclosing: Environment?
    private var values: [String: Value] = [:]

    init(enclosing: Environment? = nil) {
        self.enclosing = enclosing
    }

    func define(_ name: String, _ value: Value) {
        values[name] = value
    }

    func assign(at depth: Int, name: Token, value: Value) {
        ancestor(depth)?.values[name.lexeme] = value
    }

    func assign(_ name: Token, _ value: Value) throws {
        if values[name.lexeme] != nil {
            values[name.lexeme] = value
        } else if let enclosing {
            try enclosing.assign(name, value)
        } else {
            throw KrustRuntimeError(token: name, message: "Undefined variable \(name.lexeme)")
        }
    }

    func getAt(depth: Int, name: String) -> Value {
        ancestor(depth)?.values[name] ?? .nil
    }

    private func ancestor(_ depth: Int) -> Environment? {
        var environment: Environment? = self
        for _ in 0..<depth {
            environment = environment?.enclosing
        }

        return environment
    }

    func get(_ name: Token) throws -> Value {
        if let value = values[name.lexeme] {
            return value
        } else if let value = try enclosing?.get(name) {
            return value
        } else {
            throw KrustRuntimeError(token: name, message: "Undefined variable \(name.lexeme)")
        }
    }
}
