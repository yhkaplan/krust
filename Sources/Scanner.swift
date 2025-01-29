import Foundation

class Scanner {
    private let source: String
    private var tokens: [Token] = []
    private var start: String.Index
    private var current: String.Index?
    private var line = 1

    private var finalValidIndex: String.Index { source.index(before: source.endIndex) }

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
        case "(":
            try addToken(.leftParen)
        case ")":
            try addToken(.rightParen)
        case "{":
            try addToken(.leftBrace)
        case "}":
            try addToken(.rightBrace)
        case ",":
            try addToken(.comma)
        case ".":
            try addToken(.dot)
        case "-":
            try addToken(.minus)
        case "+":
            try addToken(.plus)
        case ";":
            try addToken(.semicolon)
        case "*":
            try addToken(.star)
        default:
            throw KrustError(line: line, message: "Unexpected character \(char)")
        }
    }

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

    private func addToken(_ type: TokenType, literal: Any? = nil) throws {
        let lexeme = current.flatMap { end in source[start..<end] } ?? source[start...finalValidIndex]
        let token = Token(type: type, lexeme: lexeme, literal: literal, line: line)
        tokens.append(token)
    }
}
