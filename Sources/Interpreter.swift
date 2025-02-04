struct KrustRuntimeError: Error {
    let token: Token
    let message: String
}

final class Interpreter {
    func interpret(_ expr: Expr.Expr) {
        do {
            let value = try evaluate(expr)
            print(value)
        } catch let error as KrustRuntimeError {
            ErrorReporter.reportRuntimeError(error)
        } catch {
            fatalError("Unknown error \(error)")
        }
    }
}

extension Interpreter: Expr.Visitor {
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
        return switch value {
        case .nil: false
        case let .boolean(boolValue): boolValue
        case let .string(value): !value.isEmpty
        case let .number(numValue): numValue != 0
        }
    }

    private func evaluate(_ expr: Expr.Expr) throws -> LiteralValue {
        try expr.accept(self)
    }
}
