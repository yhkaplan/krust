// TODO: rewrite as protocols and structs?
class Expr {
    func accept<T>(_: Visitor<T>) -> T {
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

        override func accept<T>(_ visitor: Visitor<T>) -> T {
            visitor.visitBinaryExpr(self)
        }
    }

    class Grouping: Expr {
        let expression: Expr

        init(expression: Expr) {
            self.expression = expression
        }

        override func accept<T>(_ visitor: Visitor<T>) -> T {
            visitor.visitGroupingExpr(self)
        }
    }

    class Literal: Expr {
        let value: Any?

        init(value: Any?) {
            self.value = value
        }

        override func accept<T>(_ visitor: Visitor<T>) -> T {
            visitor.visitLiteralExpr(self)
        }
    }

    class Unary: Expr {
        let `operator`: Token
        let right: Expr

        init(operator: Token, right: Expr) {
            self.right = right
            self.operator = `operator`
        }

        override func accept<T>(_ visitor: Visitor<T>) -> T {
            visitor.visitUnaryExpr(self)
        }
    }
}
