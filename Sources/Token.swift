struct Token: CustomDebugStringConvertible {
    let type: TokenType
    let lexeme: String
    let literal: Value?
    let line: Int

    var debugDescription: String {
        "\(type) \(lexeme) \(String(describing: literal))"
    }
}
