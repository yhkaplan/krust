enum Stmt {
    protocol Visitor {
        associatedtype StmtReturnType // TODO: constrain?

        func visitExpressionStmt(_ stmt: Expression) throws -> StmtReturnType
        func visitPrintStmt(_ stmt: Print) throws -> StmtReturnType
        func visitVarStmt(_ stmt: Var) throws -> StmtReturnType
        func visitBlockStmt(_ stmt: Block) throws -> StmtReturnType
        func visitIfStmt(_ stmt: If) throws -> StmtReturnType
        func visitWhileStmt(_ stmt: While) throws -> StmtReturnType
        func visitFunctionStmt(_ stmt: Function) throws -> StmtReturnType
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

        func accept<V>(_ visitor: V) throws -> V.StmtReturnType where V: Visitor {
            try visitor.visitBlockStmt(self)
        }
    }

    struct If: Stmt {
        let condition: Expr.Expr
        let thenBranch: Stmt
        let elseBranch: Stmt?

        func accept<V>(_ visitor: V) throws -> V.StmtReturnType where V: Visitor {
            try visitor.visitIfStmt(self)
        }
    }

    struct While: Stmt {
        let condition: Expr.Expr
        let body: Stmt

        func accept<V>(_ visitor: V) throws -> V.StmtReturnType where V: Visitor {
            try visitor.visitWhileStmt(self)
        }
    }

    struct Function: Stmt {
        let name: Token
        let params: [Token]
        let body: [Stmt]

        func accept<V>(_ visitor: V) throws -> V.StmtReturnType where V: Visitor {
            try visitor.visitFunctionStmt(self)
        }
    }
}
