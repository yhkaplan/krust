struct Token: CustomDebugStringConvertible {
    let type: TokenType
    let lexeme: String.SubSequence
    let literal: Substring?
    let line: Int

    var debugDescription: String {
        "\(type) \(lexeme) \(literal ?? "")"
    }
}
