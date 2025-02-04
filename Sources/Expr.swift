class Expr {
    func accept<T>(_: Visitor<T>) throws -> T {
        fatalError()
    }

    class Binary: Expr {
        let left: Expr
        let `operator`: Token
        let right: Expr

        init(left: Expr, operator: Token, right: Expr) {
            self.left = left
            self.operator = `operator`
            self.right = right
        }

        override func accept<T>(_ visitor: Visitor<T>) throws -> T {
            try visitor.visitBinaryExpr(self)
        }
    }

    class Grouping: Expr {
        let expression: Expr

        init(expression: Expr) {
            self.expression = expression
        }

        override func accept<T>(_ visitor: Visitor<T>) throws -> T {
            try visitor.visitGroupingExpr(self)
        }
    }

    class Literal: Expr {
        let value: LiteralValue

        init(value: LiteralValue) {
            self.value = value
        }

        override func accept<T>(_ visitor: Visitor<T>) throws -> T {
            try visitor.visitLiteralExpr(self)
        }
    }

    class Unary: Expr {
        let `operator`: Token
        let right: Expr

        init(operator: Token, right: Expr) {
            self.right = right
            self.operator = `operator`
        }

        override func accept<T>(_ visitor: Visitor<T>) throws -> T {
            try visitor.visitUnaryExpr(self)
        }
    }
}
