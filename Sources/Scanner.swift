import Foundation

class Scanner {
    private let source: String
    private var tokens: [Token] = []
    private var start: String.Index
    private var current: String.Index?
    private var line = 1

    private let keywords: [String.SubSequence: TokenType] = [
        "and": .and,
        "class": .class,
        "else": .else,
        "false": .false,
        "for": .for,
        "fn": .fn,
        "if": .if,
        "nil": .nil,
        "or": .or,
        "print": .print,
        "return": .return,
        "super": .super,
        "this": .this,
        "true": .true,
        "var": .var,
        "while": .while,
    ]

    private var finalValidIndex: String.Index { source.index(before: source.endIndex) }

    private var peek: Character? {
        guard let current else { return nil }
        return source[current]
    }

    private var peekNext: Character? {
        guard let current, current < finalValidIndex else { return nil }
        return source[source.index(after: current)]
    }

    init(source: String) {
        self.source = source
        current = source.startIndex
        start = source.startIndex
    }

    func scanTokens() -> [Token] {
        while let current {
            start = current
            do {
                try scanToken()
            } catch {
                print(error.localizedDescription)
            }
        }

        let token = Token(type: .eof, lexeme: "", literal: nil, line: line)
        tokens.append(token)
        return tokens
    }

    private func scanToken() throws {
        let char = try advance()
        switch char {
        // meaningless trivia
        case " ", "\r", "\t":
            ()
        case "\n":
            line += 1

        // 1 char tokens
        case "(":
            addToken(.leftParen)
        case ")":
            addToken(.rightParen)
        case "{":
            addToken(.leftBrace)
        case "}":
            addToken(.rightBrace)
        case ",":
            addToken(.comma)
        case ".":
            addToken(.dot)
        case "-":
            addToken(.minus)
        case "+":
            addToken(.plus)
        case ";":
            addToken(.semicolon)
        case "*":
            addToken(.star)

        // 1 or 2 char tokens
        case "!":
            try addToken(match("=") ? .bangEqual : .bang)
        case "=":
            try addToken(match("=") ? .equalEqual : .equal)
        case "<":
            try addToken(match("=") ? .lessEqual : .less)
        case ">":
            try addToken(match("=") ? .greaterEqual : .greater)
        case "/":
            if try match("/") {
                // Comment goes until the end of the line
                while let peek, peek != "\n" {
                    try advance()
                }
            } else {
                addToken(.slash)
            }

        // 2 or more
        case "\"":
            while let peek, peek != "\"" {
                if peek == "\n" {
                    line += 1
                }
                try advance()
            }

            guard let current else { throw KrustError(line: line, message: "Unterminated string") }

            try advance() // handle closing "

            let stringIndices = (start: source.index(after: start), end: source.index(before: current))
            let string = source[stringIndices.start...stringIndices.end]
            addToken(.string, literal: .string(String(string)))
        default:
            if char.isNumber {
                try handleNumberLiteral()
            } else if char.isLetter || char == "_" {
                try handleIdentifier()
            } else {
                throw KrustError(line: line, message: "Unexpected character \(char)")
            }
        }
    }

    @discardableResult
    private func advance() throws -> Character {
        guard let current else {
            throw KrustError(line: line, message: "Unexpected string index in \(#function)")
        }
        let char = source[current]
        let isLastValidIndex = finalValidIndex == current
        if isLastValidIndex {
            self.current = nil
        } else {
            self.current = source.index(after: current)
        }
        return char
    }

    private func addToken(_ type: TokenType, literal: LiteralValue? = nil) {
        let lexeme = current.flatMap { end in source[start..<end] } ?? source[start...finalValidIndex]
        let token = Token(type: type, lexeme: lexeme, literal: literal, line: line)
        tokens.append(token)
    }

    private func match(_ expected: Character) throws -> Bool {
        guard let current else { return false }
        if source[current] != expected { return false }

        try advance()
        return true
    }

    private func handleNumberLiteral() throws {
        while let peek, peek.isNumber {
            try advance()
        }

        if peek == ".", let peekNext, peekNext.isNumber {
            // consume the .
            try advance()

            while let peek, peek.isNumber {
                try advance()
            }
        }

        let number = current.flatMap { source[start..<$0] } ?? source[start...finalValidIndex]
        guard let numberLiteral = Double(number) else { throw KrustError(line: line, message: "Invalid number literal from \(number)") }

        addToken(.number, literal: .number(numberLiteral))
    }

    private func handleIdentifier() throws {
        while let peek, peek.isLetter || peek.isNumber || peek == "_" {
            try advance()
        }

        let lexeme = source[start...(current ?? finalValidIndex)]
        let type = keywords[lexeme, default: .identifier]
        addToken(type)
    }
}
