import Foundation

struct KrustRuntimeError: Error {
    let token: Token
    let message: String
}

struct Return: Error {
    let value: Value?
}

final class Interpreter {
    let globals: Environment
    private var locals: [UUID: Int] = [:]
    private var environment: Environment

    init() {
        let globals = Environment()
        globals.define("clock", .callable(KrustNativeFunction(arity: 0, string: "<native fn>", call: { _, _ in
            .number(Date().timeIntervalSince1970 * 1000)
        })))
        self.globals = globals
        environment = globals
    }

    func interpret(_ statements: [Stmt.Stmt]) {
        do {
            for stmt in statements {
                try execute(stmt)
            }
        } catch let error as KrustRuntimeError {
            ErrorReporter.reportRuntimeError(error)
        } catch {
            fatalError("Unknown error \(error)")
        }
    }

    func resolve(_ expr: Expr.Expr, depth: Int) {
        locals[expr.id] = depth
    }

    private func execute(_ stmt: Stmt.Stmt) throws {
        try stmt.accept(self)
    }

    private func lookupVariable(withName name: Token, expr: Expr.Expr) throws -> Value {
        if let depth = locals[expr.id] {
            environment.getAt(depth: depth, name: name.lexeme)
        } else {
            try globals.get(name)
        }
    }
}

extension Interpreter: Stmt.Visitor {
    func visitThisExpr(_ expr: Expr.This) throws -> Value {
        try lookupVariable(withName: expr.keyword, expr: expr)
    }

    func visitClassStmt(_ stmt: Stmt.Class) throws {
        environment.define(stmt.name.lexeme, .nil)

        var methods: [String: KrustFunction] = [:]
        for method in stmt.methods {
            let function = KrustFunction(declaration: method, closureEnvironment: environment, isInitializer: method.name.lexeme == "init")
            methods[method.name.lexeme] = function
        }

        let `class` = KrustClass(name: stmt.name.lexeme, methods: methods)
        try environment.assign(stmt.name, .callable(`class`))
    }

    func visitReturnStmt(_ stmt: Stmt.Return) throws {
        let value = try stmt.value.flatMap { try evaluate($0) }

        // Hacky way to unwind the stack
        throw Return(value: value)
    }

    func visitFunctionStmt(_ stmt: Stmt.Function) throws {
        // There could be a free function named init, but `this` would not be available, so it should be false
        let function = KrustFunction(declaration: stmt, closureEnvironment: environment, isInitializer: false)
        environment.define(stmt.name.lexeme, .callable(function))
    }

    func visitWhileStmt(_ stmt: Stmt.While) throws {
        while try isTruthy(evaluate(stmt.condition)) {
            try execute(stmt.body)
        }
    }

    func visitIfStmt(_ stmt: Stmt.If) throws {
        if try isTruthy(evaluate(stmt.condition)) {
            try execute(stmt.thenBranch)
        } else if let elseBranch = stmt.elseBranch {
            try execute(elseBranch)
        }
    }

    func visitBlockStmt(_ stmt: Stmt.Block) throws {
        try executeBlock(statements: stmt.statements, environment: Environment(enclosing: environment))
    }

    func executeBlock(statements: [Stmt.Stmt], environment: Environment) throws {
        let previousEnvironment = self.environment
        defer {
            self.environment = previousEnvironment
        }
        self.environment = environment

        for stmt in statements {
            try execute(stmt)
        }
    }

    func visitVarStmt(_ stmt: Stmt.Var) throws {
        let value = try stmt.initializer.flatMap { try evaluate($0) } ?? Value.nil
        environment.define(stmt.name.lexeme, value)
    }

    func visitExpressionStmt(_ stmt: Stmt.Expression) throws {
        _ = try evaluate(stmt.expression)
    }

    func visitPrintStmt(_ stmt: Stmt.Print) throws {
        let literal = try evaluate(stmt.expression)
        switch literal {
        case let .boolean(value):
            print(String(value))
        case .nil:
            print("nil")
        case let .number(value):
            print(String(value))
        case let .string(value):
            print(value)
        case let .callable(function):
            print(String(describing: function))
        case let .classInstance(instance):
            print(String(describing: instance))
        }
    }
}

extension Interpreter: Expr.Visitor {
    func visitSetExpr(_ expr: Expr.Set) throws -> Value {
        let object = try evaluate(expr.object)

        guard case let .classInstance(krustInstance) = object else {
            throw KrustRuntimeError(token: expr.name, message: "Only instances of classes have properties")
        }

        let value = try evaluate(expr.value)
        krustInstance.setField(name: expr.name, value: value)
        return value
    }

    func visitGetExpr(_ expr: Expr.Get) throws -> Value {
        let object = try evaluate(expr.object)
        guard case let .classInstance(krustInstance) = object else {
            throw KrustRuntimeError(token: expr.name, message: "Only instances of classes have properties")
        }

        return try krustInstance.getField(name: expr.name)
    }

    func visitCallExpr(_ expr: Expr.Call) throws -> Value {
        let callee = try evaluate(expr.callee)

        var arguments: [Value] = []
        for arg in expr.arguments {
            try arguments.append(evaluate(arg))
        }

        guard case let .callable(function) = callee else {
            throw KrustRuntimeError(token: expr.paren, message: "Can only call functions and classes")
        }
        guard arguments.count == function.arity else {
            throw KrustRuntimeError(token: expr.paren, message: "Expected \(function.arity) arguments but got \(arguments.count)")
        }
        return function.call(interpreter: self, arguments: arguments)
    }

    func visitLogicalExpr(_ expr: Expr.Logical) throws -> Value {
        let left = try evaluate(expr.left)

        if expr.operator.type == .or {
            if isTruthy(left) { return left }
        } else { // `and`
            if !isTruthy(left) { return left }
        }

        return try evaluate(expr.right)
    }

    func visitAssignExpr(_ expr: Expr.Assign) throws -> Value {
        let value = try evaluate(expr.value)

        if let depth = locals[expr.id] {
            environment.assign(at: depth, name: expr.name, value: value)
        } else {
            try globals.assign(expr.name, value)
        }

        return value
    }

    func visitVariableExpr(_ expr: Expr.Variable) throws -> Value {
        try lookupVariable(withName: expr.name, expr: expr)
    }

    func visitLiteralExpr(_ expr: Expr.Literal) throws -> Value {
        expr.value
    }

    func visitGroupingExpr(_ expr: Expr.Grouping) throws -> Value {
        try evaluate(expr.expression)
    }

    func visitUnaryExpr(_ expr: Expr.Unary) throws -> Value {
        let right = try evaluate(expr.right)

        switch (expr.operator.type, right) {
        case (.bang, _):
            return .boolean(!isTruthy(right))
        case let (.minus, .number(value)):
            return .number(-value)
        default:
            throw KrustRuntimeError(token: expr.operator, message: "Invalid operator or right value")
        }
    }

    func visitBinaryExpr(_ expr: Expr.Binary) throws -> Value {
        let left = try evaluate(expr.left)
        let right = try evaluate(expr.right)

        // string equality,
        if case let .string(leftValue) = left, case let .string(rightValue) = right {
            return switch expr.operator.type {
            // string concatenation
            case .plus: .string(leftValue + rightValue)
            case .bangEqual: .boolean(leftValue != rightValue)
            case .equalEqual: .boolean(leftValue == rightValue)
            default: throw KrustRuntimeError(token: expr.operator, message: "Invalid string operator")
            }
        }

        // null equality
        if case .nil = left, case .nil = right {
            return switch expr.operator.type {
            case .bangEqual: .boolean(false)
            case .equalEqual: .boolean(true)
            default: throw KrustRuntimeError(token: expr.operator, message: "Invalid nil operator")
            }
        }

        // bool equality
        if case let .boolean(leftValue) = left, case let .boolean(rightValue) = right {
            return switch expr.operator.type {
            case .bangEqual: .boolean(leftValue != rightValue)
            case .equalEqual: .boolean(leftValue == rightValue)
            default: throw KrustRuntimeError(token: expr.operator, message: "Invalid boolean operator")
            }
        }

        // arithmetic and comparison
        if case let .number(leftValue) = left, case let .number(rightValue) = right {
            return switch expr.operator.type {
            case .minus: .number(leftValue - rightValue)
            case .slash where rightValue == 0: throw KrustRuntimeError(token: expr.operator, message: "Attempted division by zero")
            case .slash: .number(leftValue / rightValue)
            case .star: .number(leftValue * rightValue)
            case .plus: .number(leftValue + rightValue)
            case .greater: .boolean(leftValue > rightValue)
            case .greaterEqual: .boolean(leftValue >= rightValue)
            case .less: .boolean(leftValue < rightValue)
            case .lessEqual: .boolean(leftValue <= rightValue)
            case .bangEqual: .boolean(leftValue != rightValue)
            case .equalEqual: .boolean(leftValue == rightValue)
            default: throw KrustRuntimeError(token: expr.operator, message: "Invalid number operator")
            }
        }

        // equality of mis-matched types
        return switch expr.operator.type {
        case .bangEqual: .boolean(true)
        case .equalEqual: .boolean(false)
        default: throw KrustRuntimeError(token: expr.operator, message: "Invalid operator on mismatched types")
        }
    }

    private func isTruthy(_ value: Value) -> Bool {
        switch value {
        case .nil, .callable: false
        case .classInstance: false // TODO: support comparing class types and instances
        case let .boolean(boolValue): boolValue
        case let .string(value): !value.isEmpty
        case let .number(numValue): numValue != 0
        }
    }

    private func evaluate(_ expr: Expr.Expr) throws -> Value {
        try expr.accept(self)
    }
}
