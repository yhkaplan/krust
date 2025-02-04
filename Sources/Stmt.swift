enum Stmt {
    protocol Visitor {
        associatedtype StmtReturnType // TODO: constrain?

        func visitExpressionStmt(_ stmt: Expression) throws -> StmtReturnType
        func visitPrintStmt(_ stmt: Print) throws -> StmtReturnType
    }

    protocol Stmt {
        func accept<V: Visitor>(_ visitor: V) throws -> V.StmtReturnType
    }

    struct Expression: Stmt {
        let expression: Expr.Expr

        func accept<V>(_ visitor: V) throws -> V.StmtReturnType where V: Visitor {
            try visitor.visitExpressionStmt(self)
        }
    }

    struct Print: Stmt {
        let expression: Expr.Expr

        func accept<V>(_ visitor: V) throws -> V.StmtReturnType where V: Visitor {
            try visitor.visitPrintStmt(self)
        }
    }
}
