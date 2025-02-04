protocol ExprVisitor {
    associatedtype ReturnType // TODO: constrain this?

    func visitBinaryExpr(_ expr: ExprBinary) throws -> ReturnType
    func visitGroupingExpr(_ expr: ExprGrouping) throws -> ReturnType
    func visitLiteralExpr(_ expr: ExprLiteral) throws -> ReturnType
    func visitUnaryExpr(_ expr: ExprUnary) throws -> ReturnType
}

protocol Expr {
    func accept<V: ExprVisitor>(_ visitor: V) throws -> V.ReturnType
}

class ExprBinary: Expr {
    let left: Expr
    let `operator`: Token
    let right: Expr

    init(left: Expr, operator: Token, right: Expr) {
        self.left = left
        self.operator = `operator`
        self.right = right
    }

    func accept<V>(_ visitor: V) throws -> V.ReturnType where V: ExprVisitor {
        try visitor.visitBinaryExpr(self)
    }
}

class ExprGrouping: Expr {
    let expression: Expr

    init(expression: Expr) {
        self.expression = expression
    }

    func accept<V>(_ visitor: V) throws -> V.ReturnType where V: ExprVisitor {
        try visitor.visitGroupingExpr(self)
    }
}

class ExprLiteral: Expr {
    let value: LiteralValue

    init(value: LiteralValue) {
        self.value = value
    }

    func accept<V>(_ visitor: V) throws -> V.ReturnType where V: ExprVisitor {
        try visitor.visitLiteralExpr(self)
    }
}

class ExprUnary: Expr {
    let `operator`: Token
    let right: Expr

    init(operator: Token, right: Expr) {
        self.right = right
        self.operator = `operator`
    }

    func accept<V>(_ visitor: V) throws -> V.ReturnType where V: ExprVisitor {
        try visitor.visitUnaryExpr(self)
    }
}
