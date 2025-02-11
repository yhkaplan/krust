/// Runtime representation of an instace of a Krust class
final class KrustInstance: CustomStringConvertible {
    private let krustClass: KrustClass
    private var fields: [String: LiteralValue] = [:]

    var description: String { "\(krustClass.name) instance" }

    init(krustClass: KrustClass) {
        self.krustClass = krustClass
    }

    func getField(name: Token) throws -> LiteralValue {
        guard let value = fields[name.lexeme] else {
            throw KrustRuntimeError(token: name, message: "Undefined property \(name.lexeme)")
        }
        return value
    }

    func setField(name: Token, value: LiteralValue) {
        fields[name.lexeme] = value
    }
}
