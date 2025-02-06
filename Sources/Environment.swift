final class Environment {
    private var values: [String: LiteralValue] = [:]

    func define(_ name: String, _ value: LiteralValue) {
        values[name] = value
    }

    func assign(_ name: Token, _ value: LiteralValue) throws {
        if values[name.lexeme] == nil { throw KrustRuntimeError(token: name, message: "Undefined variable \(name.lexeme)") }
        values[name.lexeme] = value
    }

    func get(_ name: Token) throws -> LiteralValue {
        guard let value = values[name.lexeme] else {
            throw KrustRuntimeError(token: name, message: "Undefined variable \(name.lexeme)")
        }
        return value
    }
}
