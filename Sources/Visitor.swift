class Visitor<T> {
    func visitBinaryExpr(_ expr: Expr.Binary) throws -> T {
        fatalError()
    }

    func visitGroupingExpr(_ expr: Expr.Grouping) throws -> T {
        fatalError()
    }

    func visitLiteralExpr(_ expr: Expr.Literal) throws -> T {
        fatalError()
    }

    func visitUnaryExpr(_ expr: Expr.Unary) throws -> T {
        fatalError()
    }
}
