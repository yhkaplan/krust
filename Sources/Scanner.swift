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
            addToken(try match("=") ? .bangEqual : .bang)
        case "=":
            addToken(try match("=") ? .equalEqual : .equal)
        case "<":
            addToken(try match("=") ? .lessEqual : .less)
        case ">":
            addToken(try match("=") ? .greaterEqual : .greater)

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

    private func addToken(_ type: TokenType, literal: Any? = nil) {
        let lexeme = current.flatMap { end in source[start..<end] } ?? source[start...finalValidIndex]
        let token = Token(type: type, lexeme: lexeme, literal: literal, line: line)
        tokens.append(token)
    }

    private func match(_ expected: Character) throws -> Bool {
        guard let current else { return false }
        if source[current] != expected { return false }

        _ = try advance()
        return true
    }
}
