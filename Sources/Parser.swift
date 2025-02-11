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

    func parse() -> [Stmt.Stmt] {
        do {
            var statements: [Stmt.Stmt] = []
            while !isAtEnd {
                guard let declaration = try declaration() else { continue }
                statements.append(declaration)
            }
            return statements
        } catch {
            // TODO: handle error?
            return []
        }
    }

    private func declaration() throws -> Stmt.Stmt? {
        do {
            if try match(.class) { return try classDeclaration() }
            if try match(.fn) { return try function(kind: "function") }
            if try match(.var) { return try varDeclaration() }

            return try statement()
        } catch {
            try synchronize()
            return nil
        }
    }

    private func classDeclaration() throws -> Stmt.Class {
        let name = try consume(.identifier, errorMessage: "Expect class name")
        try consume(.leftBrace, errorMessage: "Expect '{' before class body")

        var methods: [Stmt.Function] = []
        while !check(.rightBrace), !isAtEnd {
            try methods.append(function(kind: "method"))
        }

        try consume(.rightBrace, errorMessage: "Expect '}' after class body")

        return Stmt.Class(name: name, superclass: nil, methods: methods)
    }

    private func function(kind: String) throws -> Stmt.Function {
        let name = try consume(.identifier, errorMessage: "Expect \(kind) name")
        try consume(.leftParen, errorMessage: "Expect '(' after \(kind) name")

        var params: [Token] = []
        if !check(.rightParen) {
            repeat {
                if params.count >= 255 {
                    throw makeError(withToken: peek, message: "Can't have more than 255 parameters")
                }

                try params.append(consume(.identifier, errorMessage: "Expect parameter name"))
            } while try match(.comma)
        }
        try consume(.rightParen, errorMessage: "Expect ')' after parameters")

        try consume(.leftBrace, errorMessage: "Expect '{' before \(kind) body")
        let body = try block()
        return Stmt.Function(name: name, params: params, body: body)
    }

    private func varDeclaration() throws -> Stmt.Stmt {
        let name = try consume(.identifier, errorMessage: "Expect variable name")
        var initializer: Expr.Expr?
        if try match(.equal) {
            initializer = try expression()
        }

        try consume(.semicolon, errorMessage: "Expect ';' after variable declaration")
        return Stmt.Var(name: name, initializer: initializer)
    }

    private func statement() throws -> Stmt.Stmt {
        if try match(.for) { return try forStatement() }
        if try match(.if) { return try ifStatement() }
        if try match(.print) { return try printStatement() }
        if try match(.return) { return try returnStatement() }
        if try match(.while) { return try whileStatement() }
        if try match(.leftBrace) { return try Stmt.Block(statements: block()) }
        return try expressionStatement()
    }

    private func returnStatement() throws -> Stmt.Stmt {
        let keyword = previous
        let value = check(.semicolon) ? nil : try expression()

        try consume(.semicolon, errorMessage: "Expect ';' after return value")
        return Stmt.Return(keyword: keyword, value: value)
    }

    private func forStatement() throws -> Stmt.Stmt {
        try consume(.leftParen, errorMessage: "Expect '(' after 'for'")

        var initializer: Stmt.Stmt?
        if try match(.semicolon) {
            // init is nil
        } else if try match(.var) {
            initializer = try varDeclaration()
        } else {
            initializer = try expressionStatement()
        }

        let condition = check(.semicolon) ? Expr.Literal(value: .boolean(true)) : try expression()
        try consume(.semicolon, errorMessage: "Expect ';' after loop condition")

        let increment = check(.rightParen) ? nil : try expression()
        try consume(.rightParen, errorMessage: "Expect ')' after for clauses")

        var body = try statement()

        if let increment {
            body = Stmt.Block(statements: [body, Stmt.Expression(expression: increment)])
        }

        body = Stmt.While(condition: condition, body: body)

        if let initializer {
            body = Stmt.Block(statements: [initializer, body])
        }

        return body
    }

    private func whileStatement() throws -> Stmt.Stmt {
        try consume(.leftParen, errorMessage: "Expect '(' after 'while'")
        let condition = try expression()
        try consume(.rightParen, errorMessage: "Expect ')' after 'while'")
        let body = try statement()

        return Stmt.While(condition: condition, body: body)
    }

    private func ifStatement() throws -> Stmt.Stmt {
        try consume(.leftParen, errorMessage: "Expect '(' after 'if'")
        let condition = try expression()
        try consume(.rightParen, errorMessage: "Expect ')' after 'if'")

        let thenBranch = try statement()
        let elseBranch = try match(.else) ? try statement() : nil

        return Stmt.If(condition: condition, thenBranch: thenBranch, elseBranch: elseBranch)
    }

    private func block() throws -> [Stmt.Stmt] {
        var statements: [Stmt.Stmt] = []
        while !check(.rightBrace), !isAtEnd {
            if let dclr = try declaration() {
                statements.append(dclr)
            }
        }

        try consume(.rightBrace, errorMessage: "Expect '}' after block")
        return statements
    }

    private func printStatement() throws -> Stmt.Stmt {
        let value = try expression()
        try consume(.semicolon, errorMessage: "Expect ';' after value")
        return Stmt.Print(expression: value)
    }

    private func expressionStatement() throws -> Stmt.Stmt {
        let expr = try expression()
        try consume(.semicolon, errorMessage: "Expect ';' after expression")
        return Stmt.Expression(expression: expr)
    }

    private func expression() throws -> Expr.Expr { try assignment() }

    private func assignment() throws -> Expr.Expr {
        let expr = try or()

        if try match(.equal) {
            let equals = previous
            let value = try assignment()

            if let name = (expr as? Expr.Variable)?.name {
                return Expr.Assign(name: name, value: value)
            }

            throw makeError(withToken: equals, message: "Invalid assignement target")
        }

        return expr
    }

    private func or() throws -> Expr.Expr {
        var expr = try and()

        while try match(.or) {
            let `operator` = previous
            let right = try and()
            expr = Expr.Logical(left: expr, operator: `operator`, right: right)
        }

        return expr
    }

    private func and() throws -> Expr.Expr {
        var expr = try equality()

        while try match(.and) {
            let `operator` = previous
            let right = try equality()
            expr = Expr.Logical(left: expr, operator: `operator`, right: right)
        }

        return expr
    }

    private func equality() throws -> Expr.Expr {
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

    private func comparison() throws -> Expr.Expr {
        var expr = try term()

        while try match(.greater, .greaterEqual, .less, .lessEqual) {
            let `operator` = previous
            let right = try term()
            expr = Expr.Binary(left: expr, operator: `operator`, right: right)
        }

        return expr
    }

    private func term() throws -> Expr.Expr {
        var expr = try factor()

        while try match(.minus, .plus) {
            let `operator` = previous
            let right = try factor()
            expr = Expr.Binary(left: expr, operator: `operator`, right: right)
        }

        return expr
    }

    private func factor() throws -> Expr.Expr {
        var expr = try unary()

        while try match(.slash, .star) {
            let `operator` = previous
            let right = try unary()
            expr = Expr.Binary(left: expr, operator: `operator`, right: right)
        }

        return expr
    }

    private func unary() throws -> Expr.Expr {
        if try match(.bang, .minus) {
            let `operator` = previous
            let right = try unary()
            return Expr.Unary(operator: `operator`, right: right)
        }

        return try call()
    }

    private func call() throws -> Expr.Expr {
        var expr = try primary()

        while true {
            if try match(.leftParen) {
                expr = try finishCall(expr)
            } else {
                break
            }
        }

        return expr
    }

    private func finishCall(_ callee: Expr.Expr) throws -> Expr.Expr {
        var arguments: [Expr.Expr] = []

        if !check(.rightParen) {
            repeat {
                if arguments.count >= 255 {
                    throw makeError(withToken: peek, message: "Can't have more than 255 arguments")
                }
                try arguments.append(expression())
            } while try match(.comma)
        }

        let paren = try consume(.rightParen, errorMessage: "Expect ')' after arguments")
        return Expr.Call(callee: callee, paren: paren, arguments: arguments)
    }

    private func primary() throws -> Expr.Expr {
        if try match(.false) { return Expr.Literal(value: .boolean(false)) }
        if try match(.true) { return Expr.Literal(value: .boolean(true)) }
        if try match(.nil) { return Expr.Literal(value: .nil) }

        if try match(.number, .string) {
            guard let previousLiteral = previous.literal else {
                throw makeError(withToken: previous, message: "Literal token missing value")
            }
            switch previousLiteral {
            case .number, .string:
                return Expr.Literal(value: previousLiteral)
            default:
                throw makeError(withToken: previous, message: "Unexpected token literal")
            }
        }

        if try match(.identifier) {
            return Expr.Variable(name: previous)
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
