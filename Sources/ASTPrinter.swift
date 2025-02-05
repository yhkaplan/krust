class ASTPrinter: Expr.Visitor {
    func visitVariableExpr(_ expr: Expr.Variable) throws -> String {
        fatalError("Not supported yet")
    }

    func print(_ expr: Expr.Expr) -> String {
        try! expr.accept(self)
    }

    func visitBinaryExpr(_ expr: Expr.Binary) -> String {
        parenthesize(name: expr.operator.lexeme, exprs: expr.left, expr.right)
    }

    func visitGroupingExpr(_ expr: Expr.Grouping) -> String {
        parenthesize(name: "group", exprs: expr.expression)
    }

    func visitLiteralExpr(_ expr: Expr.Literal) -> String {
        "\(expr.value)"
    }

    func visitUnaryExpr(_ expr: Expr.Unary) -> String {
        parenthesize(name: expr.operator.lexeme, exprs: expr.right)
    }

    private func parenthesize(name: String, exprs: Expr.Expr...) -> String {
        var result = "(\(name)"

        for expr in exprs {
            result.append(" \(try! expr.accept(self))")
        }
        result.append(")")

        return result
    }
}
