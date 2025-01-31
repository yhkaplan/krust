// TODO: rewrite as protocols and structs?
class Expr {
    func accept<T>(_ visitor: Visitor<T>) -> T {
        fatalError()
    }
}

class Visitor<T> {
    func visitBinaryExpr(_ expr: Binary) -> T {
        fatalError()
    }
    func visitGroupingExpr(_ expr: Grouping) -> T {
        fatalError()
    }
    func visitLiteralExpr(_ expr: Literal) -> T {
        fatalError()
    }
    func visitUnaryExpr(_ expr: Unary) -> T {
        fatalError()
    }
}

class Binary: Expr {
    let left: Expr
    let `operator`: Token
    let right: Expr

    init(left: Expr, operator: Token, right: Expr) {
        self.left = left
        self.operator = `operator`
        self.right = right
    }

    override func accept<T>(_ visitor: Visitor<T>) -> T {
        visitor.visitBinaryExpr(self)
    }
}

class Grouping: Expr {
    let expression: Expr

    init(expression: Expr) {
        self.expression = expression
    }

    override func accept<T>(_ visitor: Visitor<T>) -> T {
        visitor.visitGroupingExpr(self)
    }
}

class Literal: Expr {
    let value: Any // TODO: use generic, string, or Any?

    init(value: Any) {
        self.value = value
    }

    override func accept<T>(_ visitor: Visitor<T>) -> T {
        visitor.visitLiteralExpr(self)
    }
}

class Unary: Expr {
    let `operator`: Token
    let right: Expr

    init(right: Expr, operator: Token) {
        self.right = right
        self.operator = `operator`
    }

    override func accept<T>(_ visitor: Visitor<T>) -> T {
        visitor.visitUnaryExpr(self)
    }
}

class ASTPrinter: Visitor<String> {
    func print(_ expr: Expr) -> String {
        expr.accept(self)
    }

    override func visitBinaryExpr(_ expr: Binary) -> String {
        parenthesize(name: expr.operator.lexeme, exprs: expr.left, expr.right)
    }

    override func visitGroupingExpr(_ expr: Grouping) -> String {
        parenthesize(name: "group", exprs: expr.expression)
    }

    override func visitLiteralExpr(_ expr: Literal) -> String {
        guard let value = expr.value as? String else { return "nil" }
        return value
    }

    override func visitUnaryExpr(_ expr: Unary) -> String {
        parenthesize(name: expr.operator.lexeme, exprs: expr.right)
    }

    private func parenthesize(name: Substring, exprs: Expr...) -> String {
        var result = "(\(name)"

        for expr in exprs {
            result.append(" \(expr.accept(self))")
        }
        result.append(")")

        return result
    }
}
