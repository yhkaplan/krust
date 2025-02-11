/// Runtime representation of an instace of a Krust class
final class KrustInstance: CustomStringConvertible {
    private let krustClass: KrustClass
    private var fields: [String: LiteralValue] = [:]

    var description: String { "\(krustClass.name) instance" }

    init(krustClass: KrustClass) {
        self.krustClass = krustClass
    }

    func getField(name: Token) throws -> LiteralValue {
        if let value = fields[name.lexeme] {
            return value
        } else if let method = krustClass.findMethod(name: name.lexeme) {
            return .callable(method.bind(self))
        }
        throw KrustRuntimeError(token: name, message: "Undefined property \(name.lexeme)")
    }

    func setField(name: Token, value: LiteralValue) {
        fields[name.lexeme] = value
    }
}
