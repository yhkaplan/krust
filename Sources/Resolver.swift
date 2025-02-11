enum FunctionType {
    case function, method
}

enum ClassType { case `class` }

final class Resolver {
    private let interpreter: Interpreter
    private var scopes: [[String: Bool]] = []
    private var currentFunction: FunctionType?
    private var currentClass: ClassType?

    init(interpreter: Interpreter) {
        self.interpreter = interpreter
    }

    func resolve(_ statements: [Stmt.Stmt]) throws {
        for stmt in statements {
            try resolve(stmt)
        }
    }

    private func resolve(_ stmt: Stmt.Stmt) throws {
        try stmt.accept(self)
    }

    private func resolve(_ expr: Expr.Expr) throws {
        try expr.accept(self)
    }

    private func beginScope() {
        scopes.append([String: Bool]())
    }

    private func endScope() {
        _ = scopes.popLast()
    }

    private func declare(_ name: Token) {
        if scopes.isEmpty { return }

        if scopes[scopes.count - 1][name.lexeme] != nil {
            ErrorReporter.reportError(token: name, message: "Already a variable with this name in this scope")
        }

        // The value associated with a key in the scope map represents whether or not we have finished resolving that variable’s initializer.
        scopes[scopes.count - 1][name.lexeme] = false
    }

    private func define(_ name: Token) {
        if scopes.isEmpty { return }
        // set the variable’s value in the scope map to true to mark it as fully initialized and available for use
        scopes[scopes.count - 1][name.lexeme] = true
    }

    private func resolveLocal(expr: Expr.Expr, name: Token) {
        loop: for (depth, scope) in scopes.reversed().enumerated() { // Yes, we want the last element to be depth of 0, etc
            if scope[name.lexeme] == nil { continue }
            interpreter.resolve(expr, depth: depth)
            break loop
        }
    }

    private func resolveFunction(_ function: Stmt.Function, type: FunctionType) throws {
        let enclosingFunction = currentFunction
        currentFunction = type

        beginScope()
        for param in function.params {
            declare(param)
            define(param)
        }
        try resolve(function.body)
        endScope()
        currentFunction = enclosingFunction
    }
}

extension Resolver: Expr.Visitor {
    func visitThisExpr(_ expr: Expr.This) throws {
        if currentClass == nil {
            ErrorReporter.reportError(token: expr.keyword, message: "Can't use 'this' outside of a class")
            return
        }

        resolveLocal(expr: expr, name: expr.keyword)
    }

    func visitBinaryExpr(_ expr: Expr.Binary) throws {
        try resolve(expr.left)
        try resolve(expr.right)
    }

    func visitGroupingExpr(_ expr: Expr.Grouping) throws {
        try resolve(expr.expression)
    }

    func visitLiteralExpr(_ expr: Expr.Literal) throws {
        // Nothing to do here
    }

    func visitUnaryExpr(_ expr: Expr.Unary) throws {
        try resolve(expr.right)
    }

    func visitVariableExpr(_ expr: Expr.Variable) throws {
        if scopes.last?[expr.name.lexeme] == false {
            ErrorReporter.reportError(token: expr.name, message: "Can't read local variable in its own initializer")
        }

        resolveLocal(expr: expr, name: expr.name)
    }

    func visitAssignExpr(_ expr: Expr.Assign) throws {
        try resolve(expr.value)
        resolveLocal(expr: expr, name: expr.name)
    }

    func visitLogicalExpr(_ expr: Expr.Logical) throws {
        try resolve(expr.left)
        try resolve(expr.right)
    }

    func visitCallExpr(_ expr: Expr.Call) throws {
        try resolve(expr.callee)

        for arg in expr.arguments {
            try resolve(arg)
        }
    }
}

extension Resolver: Stmt.Visitor {
    func visitSetExpr(_ expr: Expr.Set) throws {
        try resolve(expr.value)
        try resolve(expr.object)
    }

    func visitGetExpr(_ expr: Expr.Get) throws {
        try resolve(expr.object)
    }

    func visitClassStmt(_ stmt: Stmt.Class) throws {
        let enclosingClass = currentClass
        currentClass = .class

        declare(stmt.name)
        define(stmt.name)

        beginScope()
        scopes[scopes.count - 1]["this"] = true

        for method in stmt.methods {
            try resolveFunction(method, type: .method)
        }

        endScope()

        currentClass = enclosingClass
    }

    func visitExpressionStmt(_ stmt: Stmt.Expression) throws {
        try resolve(stmt.expression)
    }

    func visitPrintStmt(_ stmt: Stmt.Print) throws {
        try resolve(stmt.expression)
    }

    func visitVarStmt(_ stmt: Stmt.Var) throws {
        declare(stmt.name)
        if let initializer = stmt.initializer {
            try resolve(initializer)
        }
        define(stmt.name)
    }

    func visitBlockStmt(_ stmt: Stmt.Block) throws {
        beginScope()
        try resolve(stmt.statements)
        endScope()
    }

    func visitIfStmt(_ stmt: Stmt.If) throws {
        try resolve(stmt.condition)
        try resolve(stmt.thenBranch)
        if let elseBranch = stmt.elseBranch {
            try resolve(elseBranch)
        }
    }

    func visitWhileStmt(_ stmt: Stmt.While) throws {
        try resolve(stmt.condition)
        try resolve(stmt.body)
    }

    func visitFunctionStmt(_ stmt: Stmt.Function) throws {
        declare(stmt.name)
        define(stmt.name)

        try resolveFunction(stmt, type: .function)
    }

    func visitReturnStmt(_ stmt: Stmt.Return) throws {
        if currentFunction == nil {
            ErrorReporter.reportError(token: stmt.keyword, message: "Can't return from top-level code")
        }
        guard let value = stmt.value else { return }
        try resolve(value)
    }
}
