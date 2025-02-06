final class Environment {
    private var enclosing: Environment?
    private var values: [String: LiteralValue] = [:]

    init(enclosing: Environment? = nil) {
        self.enclosing = enclosing
    }

    func define(_ name: String, _ value: LiteralValue) {
        values[name] = value
    }

    func assign(_ name: Token, _ value: LiteralValue) throws {
        if values[name.lexeme] != nil {
            values[name.lexeme] = value
        } else if let enclosing {
            try enclosing.assign(name, value)
        } else {
            throw KrustRuntimeError(token: name, message: "Undefined variable \(name.lexeme)")
        }
    }

    func get(_ name: Token) throws -> LiteralValue {
        if let value = values[name.lexeme] {
            return value
        } else if let value = try enclosing?.get(name) {
            return value
        } else {
            throw KrustRuntimeError(token: name, message: "Undefined variable \(name.lexeme)")
        }
    }
}
