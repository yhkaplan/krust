class Visitor<T> {
    func visitBinaryExpr(_ expr: Expr.Binary) -> T {
        fatalError()
    }

    func visitGroupingExpr(_ expr: Expr.Grouping) -> T {
        fatalError()
    }

    func visitLiteralExpr(_ expr: Expr.Literal) -> T {
        fatalError()
    }

    func visitUnaryExpr(_ expr: Expr.Unary) -> T {
        fatalError()
    }
}
