class ASTPrinter: Visitor<String> {
    func print(_ expr: Expr) -> String {
        expr.accept(self)
    }

    override func visitBinaryExpr(_ expr: Expr.Binary) -> String {
        parenthesize(name: expr.operator.lexeme, exprs: expr.left, expr.right)
    }

    override func visitGroupingExpr(_ expr: Expr.Grouping) -> String {
        parenthesize(name: "group", exprs: expr.expression)
    }

    override func visitLiteralExpr(_ expr: Expr.Literal) -> String {
        guard let value = expr.value else { return "nil" }
        return "\(value)"
    }

    override func visitUnaryExpr(_ expr: Expr.Unary) -> String {
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
