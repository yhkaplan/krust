enum ErrorReporter {
    static func reportError(token: Token, message: String) {
        switch token.type {
        case .eof:
            print("L\(token.line) at end \(message)")
        default:
            print("L\(token.line) at \(token.lexeme) \(message)")
        }
    }
}
