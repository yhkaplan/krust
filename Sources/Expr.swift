enum Expr {
    protocol Visitor {
        associatedtype ExprReturnType // TODO: constrain this?

        func visitBinaryExpr(_ expr: Binary) throws -> ExprReturnType
        func visitGroupingExpr(_ expr: Grouping) throws -> ExprReturnType
        func visitLiteralExpr(_ expr: Literal) throws -> ExprReturnType
        func visitUnaryExpr(_ expr: Unary) throws -> ExprReturnType
    }

    // TODO: rename?
    protocol Expr {
        func accept<V: Visitor>(_ visitor: V) throws -> V.ExprReturnType
    }

    struct Binary: Expr {
        let left: Expr
        let `operator`: Token
        let right: Expr

        func accept<V>(_ visitor: V) throws -> V.ExprReturnType where V: Visitor {
            try visitor.visitBinaryExpr(self)
        }
    }

    struct Grouping: Expr {
        let expression: Expr

        func accept<V>(_ visitor: V) throws -> V.ExprReturnType where V: Visitor {
            try visitor.visitGroupingExpr(self)
        }
    }

    struct Literal: Expr {
        let value: LiteralValue

        func accept<V>(_ visitor: V) throws -> V.ExprReturnType where V: Visitor {
            try visitor.visitLiteralExpr(self)
        }
    }

    struct Unary: Expr {
        let `operator`: Token
        let right: Expr

        func accept<V>(_ visitor: V) throws -> V.ExprReturnType where V: Visitor {
            try visitor.visitUnaryExpr(self)
        }
    }
}
