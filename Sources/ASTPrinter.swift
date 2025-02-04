class ASTPrinter: ExprVisitor {
    func print(_ expr: Expr) -> String {
        try! expr.accept(self)
    }

    func visitBinaryExpr(_ expr: ExprBinary) -> String {
        parenthesize(name: expr.operator.lexeme, exprs: expr.left, expr.right)
    }

    func visitGroupingExpr(_ expr: ExprGrouping) -> String {
        parenthesize(name: "group", exprs: expr.expression)
    }

    func visitLiteralExpr(_ expr: ExprLiteral) -> String {
        "\(expr.value)"
    }

    func visitUnaryExpr(_ expr: ExprUnary) -> String {
        parenthesize(name: expr.operator.lexeme, exprs: expr.right)
    }

    private func parenthesize(name: Substring, exprs: Expr...) -> String {
        var result = "(\(name)"

        for expr in exprs {
            result.append(" \(try! expr.accept(self))")
        }
        result.append(")")

        return result
    }
}
