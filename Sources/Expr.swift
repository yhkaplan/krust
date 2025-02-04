enum Expr {
    protocol Visitor {
        associatedtype ReturnType // TODO: constrain this?

        func visitBinaryExpr(_ expr: Binary) throws -> ReturnType
        func visitGroupingExpr(_ expr: Grouping) throws -> ReturnType
        func visitLiteralExpr(_ expr: Literal) throws -> ReturnType
        func visitUnaryExpr(_ expr: Unary) throws -> ReturnType
    }

    // TODO: rename?
    protocol Expr {
        func accept<V: Visitor>(_ visitor: V) throws -> V.ReturnType
    }

    struct Binary: Expr {
        let left: Expr
        let `operator`: Token
        let right: Expr

        func accept<V>(_ visitor: V) throws -> V.ReturnType where V: Visitor {
            try visitor.visitBinaryExpr(self)
        }
    }

    struct Grouping: Expr {
        let expression: Expr

        func accept<V>(_ visitor: V) throws -> V.ReturnType where V: Visitor {
            try visitor.visitGroupingExpr(self)
        }
    }

    struct Literal: Expr {
        let value: LiteralValue

        func accept<V>(_ visitor: V) throws -> V.ReturnType where V: Visitor {
            try visitor.visitLiteralExpr(self)
        }
    }

    struct Unary: Expr {
        let `operator`: Token
        let right: Expr

        func accept<V>(_ visitor: V) throws -> V.ReturnType where V: Visitor {
            try visitor.visitUnaryExpr(self)
        }
    }
}
