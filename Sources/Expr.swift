import Foundation

enum Expr {
    protocol Visitor {
        associatedtype ExprReturnType

        func visitBinaryExpr(_ expr: Binary) throws -> ExprReturnType
        func visitGroupingExpr(_ expr: Grouping) throws -> ExprReturnType
        func visitLiteralExpr(_ expr: Literal) throws -> ExprReturnType
        func visitUnaryExpr(_ expr: Unary) throws -> ExprReturnType
        func visitVariableExpr(_ expr: Variable) throws -> ExprReturnType
        func visitAssignExpr(_ expr: Assign) throws -> ExprReturnType
        func visitLogicalExpr(_ expr: Logical) throws -> ExprReturnType
        func visitCallExpr(_ expr: Call) throws -> ExprReturnType
        func visitGetExpr(_ expr: Get) throws -> ExprReturnType
        func visitSetExpr(_ expr: Set) throws -> ExprReturnType
        func visitThisExpr(_ expr: This) throws -> ExprReturnType
    }

    protocol Expr {
        var id: UUID { get }
        func accept<V: Visitor>(_ visitor: V) throws -> V.ExprReturnType
    }

    struct Binary: Expr {
        let id = UUID()
        let left: Expr
        let `operator`: Token
        let right: Expr

        func accept<V>(_ visitor: V) throws -> V.ExprReturnType where V: Visitor {
            try visitor.visitBinaryExpr(self)
        }
    }

    struct Grouping: Expr {
        let id = UUID()
        let expression: Expr

        func accept<V>(_ visitor: V) throws -> V.ExprReturnType where V: Visitor {
            try visitor.visitGroupingExpr(self)
        }
    }

    struct Literal: Expr {
        let id = UUID()
        let value: Value

        func accept<V>(_ visitor: V) throws -> V.ExprReturnType where V: Visitor {
            try visitor.visitLiteralExpr(self)
        }
    }

    struct Unary: Expr {
        let id = UUID()
        let `operator`: Token
        let right: Expr

        func accept<V>(_ visitor: V) throws -> V.ExprReturnType where V: Visitor {
            try visitor.visitUnaryExpr(self)
        }
    }

    struct Variable: Expr {
        let id = UUID()
        let name: Token

        func accept<V>(_ visitor: V) throws -> V.ExprReturnType where V: Visitor {
            try visitor.visitVariableExpr(self)
        }
    }

    struct Assign: Expr {
        let id = UUID()
        let name: Token
        let value: Expr

        func accept<V>(_ visitor: V) throws -> V.ExprReturnType where V: Visitor {
            try visitor.visitAssignExpr(self)
        }
    }

    struct Logical: Expr {
        let id = UUID()
        let left: Expr
        let `operator`: Token
        let right: Expr

        func accept<V>(_ visitor: V) throws -> V.ExprReturnType where V: Visitor {
            try visitor.visitLogicalExpr(self)
        }
    }

    struct Call: Expr {
        let id = UUID()
        let callee: Expr
        let paren: Token
        let arguments: [Expr]

        func accept<V>(_ visitor: V) throws -> V.ExprReturnType where V: Visitor {
            try visitor.visitCallExpr(self)
        }
    }

    struct Get: Expr {
        let id = UUID()
        let object: Expr
        let name: Token

        func accept<V>(_ visitor: V) throws -> V.ExprReturnType where V: Visitor {
            try visitor.visitGetExpr(self)
        }
    }

    struct Set: Expr {
        let id = UUID()
        let object: Expr
        let name: Token
        let value: Expr

        func accept<V>(_ visitor: V) throws -> V.ExprReturnType where V: Visitor {
            try visitor.visitSetExpr(self)
        }
    }

    struct This: Expr {
        let id = UUID()
        let keyword: Token

        func accept<V>(_ visitor: V) throws -> V.ExprReturnType where V: Visitor {
            try visitor.visitThisExpr(self)
        }
    }
}
