struct Token: CustomDebugStringConvertible {
    let type: TokenType
    let lexeme: String.SubSequence
    let literal: Any? // TODO: change type
    let line: Int

    var debugDescription: String {
        "\(type) \(lexeme) \(literal ?? "")"
    }
}
