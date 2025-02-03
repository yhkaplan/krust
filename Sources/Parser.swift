/// Recursive decent parser
final class Parser {
    struct ParserError: Error {}

    private let tokens: [Token]
    private var currentIndex = 0

    private var isAtEnd: Bool {
        peek.type == .eof
    }

    private var peek: Token {
        tokens[currentIndex]
    }

    private var previous: Token {
        tokens[currentIndex - 1]
    }

    init(tokens: [Token]) {
        self.tokens = tokens
    }

    func parse() -> Expr? {
        do {
            return try expression()
        } catch {
            // TODO: do something with error?
            return nil
        }
    }

    private func expression() throws -> Expr { try equality() }

    private func equality() throws -> Expr {
        var expr = try comparison()

        while try match(.bangEqual, .equalEqual) {
            let `operator` = previous
            let right = try comparison()
            expr = Expr.Binary(left: expr, operator: `operator`, right: right)
        }

        return expr
    }

    private func match(_ types: TokenType...) throws -> Bool {
        for type in types {
            if check(type) {
                try advance()
                return true
            }
        }
        return false
    }

    private func check(_ type: TokenType) -> Bool {
        if isAtEnd { return false }
        return peek.type == type
    }

    @discardableResult
    private func advance() throws -> Token {
        if !isAtEnd { currentIndex += 1 }
        return previous
    }

    private func comparison() throws -> Expr {
        var expr = try term()

        while try match(.greater, .greaterEqual, .less, .lessEqual) {
            let `operator` = previous
            let right = try term()
            expr = Expr.Binary(left: expr, operator: `operator`, right: right)
        }

        return expr
    }

    // TODO: refactor code with higher order func
    private func term() throws -> Expr {
        var expr = try factor()

        while try match(.minus, .plus) {
            let `operator` = previous
            let right = try factor()
            expr = Expr.Binary(left: expr, operator: `operator`, right: right)
        }

        return expr
    }

    private func factor() throws -> Expr {
        var expr = try unary()

        while try match(.slash, .star) {
            let `operator` = previous
            let right = try unary()
            expr = Expr.Binary(left: expr, operator: `operator`, right: right)
        }

        return expr
    }

    private func unary() throws -> Expr {
        if try match(.bang, .minus) {
            let `operator` = previous
            let right = try unary()
            return Expr.Unary(operator: `operator`, right: right)
        }

        return try primary()
    }

    private func primary() throws -> Expr {
        if try match(.false) { return Expr.Literal(value: false) }
        if try match(.true) { return Expr.Literal(value: true) }
        if try match(.nil) { return Expr.Literal(value: nil) }

        if try match(.number, .string) {
            return Expr.Literal(value: previous.literal)
        }

        if try match(.leftParen) {
            let expr = try expression()
            try consume(.rightParen, errorMessage: "Expect ')' after expression.")
            return Expr.Grouping(expression: expr)
        }

        throw makeError(withToken: peek, message: "Expected expression")
    }

    @discardableResult
    private func consume(_ type: TokenType, errorMessage: String) throws -> Token {
        if check(type) { return try advance() }
        throw makeError(withToken: peek, message: errorMessage)
    }

    private func makeError(withToken token: Token, message: String) -> Error {
        ErrorReporter.reportError(token: token, message: message)
        return ParserError()
    }

    private func synchronize() throws {
        try advance()

        while !isAtEnd {
            if previous.type == .semicolon { return }

            switch peek.type {
            case .class, .fn, .var, .for, .if, .while, .print, .return: return
            default: try advance()
            }
        }
    }
}
