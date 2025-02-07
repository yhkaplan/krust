import Foundation

struct KrustRuntimeError: Error {
    let token: Token
    let message: String
}

struct Return: Error {
    let value: LiteralValue?
}

final class Interpreter {
    let globals: Environment
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

    private func execute(_ stmt: Stmt.Stmt) throws {
        try stmt.accept(self)
    }
}

extension Interpreter: Stmt.Visitor {
    func visitReturnStmt(_ stmt: Stmt.Return) throws {
        let value = try stmt.value.flatMap { try evaluate($0) }

        // Hacky way to unwind the stack
        throw Return(value: value)
    }

    func visitFunctionStmt(_ stmt: Stmt.Function) throws {
        let function = KrustFunction(declaration: stmt, closureEnvironment: environment)
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
        let value = try stmt.initializer.flatMap { try evaluate($0) } ?? LiteralValue.nil
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
        }
    }
}

extension Interpreter: Expr.Visitor {
    func visitCallExpr(_ expr: Expr.Call) throws -> LiteralValue {
        let callee = try evaluate(expr.callee)

        var arguments: [LiteralValue] = []
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

    func visitLogicalExpr(_ expr: Expr.Logical) throws -> LiteralValue {
        let left = try evaluate(expr.left)

        if expr.operator.type == .or {
            if isTruthy(left) { return left }
        } else { // `and`
            if !isTruthy(left) { return left }
        }

        return try evaluate(expr.right)
    }

    func visitAssignExpr(_ expr: Expr.Assign) throws -> LiteralValue {
        let value = try evaluate(expr.value)
        try environment.assign(expr.name, value)
        return value
    }

    func visitVariableExpr(_ expr: Expr.Variable) throws -> LiteralValue {
        try environment.get(expr.name)
    }

    func visitLiteralExpr(_ expr: Expr.Literal) throws -> LiteralValue {
        expr.value
    }

    func visitGroupingExpr(_ expr: Expr.Grouping) throws -> LiteralValue {
        try evaluate(expr.expression)
    }

    func visitUnaryExpr(_ expr: Expr.Unary) throws -> LiteralValue {
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

    func visitBinaryExpr(_ expr: Expr.Binary) throws -> LiteralValue {
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

    private func isTruthy(_ value: LiteralValue) -> Bool {
        switch value {
        case .nil, .callable: false
        case let .boolean(boolValue): boolValue
        case let .string(value): !value.isEmpty
        case let .number(numValue): numValue != 0
        }
    }

    private func evaluate(_ expr: Expr.Expr) throws -> LiteralValue {
        try expr.accept(self)
    }
}
