enum ErrorReporter {
    nonisolated(unsafe) static var hadRuntimeError = false
    nonisolated(unsafe) static var hadError = false

    static func reportError(token: Token, message: String) {
        switch token.type {
        case .eof:
            print("L\(token.line) at end \(message)")
        default:
            print("L\(token.line) at \(token.lexeme) \(message)")
        }
        hadError = true
    }

    static func reportRuntimeError(_ error: KrustRuntimeError) {
        print("\(error.message) \n[line \(error.token.line)]")
        hadRuntimeError = true
    }
}
