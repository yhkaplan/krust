enum Stmt {
    protocol Visitor {
        associatedtype StmtReturnType // TODO: constrain?

        func visitExpressionStmt(_ stmt: Expression) throws -> StmtReturnType
        func visitPrintStmt(_ stmt: Print) throws -> StmtReturnType
        func visitVarStmt(_ stmt: Var) throws -> StmtReturnType
        func visitBlockStmt(_ stmt: Block) throws -> StmtReturnType
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

    struct Var: Stmt {
        let name: Token
        let initializer: Expr.Expr?

        func accept<V>(_ visitor: V) throws -> V.StmtReturnType where V: Visitor {
            try visitor.visitVarStmt(self)
        }
    }

    struct Block: Stmt {
        let statements: [Stmt]

        func accept<V>(_ visitor: V) throws -> V.StmtReturnType where V : Visitor {
            try visitor.visitBlockStmt(self)
        }
    }
}
