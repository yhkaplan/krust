import Foundation

class Scanner {
    private let source: String
    private var tokens: [Token] = []
    private var start: String.Index
    private var current: String.Index?
    private var line = 1

    private var finalValidIndex: String.Index { source.index(before: source.endIndex) }

    private var peek: Character? {
        guard let current else { return nil }
        return source[current]
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
            addToken(try match("=") ? .bangEqual : .bang)
        case "=":
            addToken(try match("=") ? .equalEqual : .equal)
        case "<":
            addToken(try match("=") ? .lessEqual : .less)
        case ">":
            addToken(try match("=") ? .greaterEqual : .greater)
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
            addToken(.string, literal: string)

        default:
            throw KrustError(line: line, message: "Unexpected character \(char)")
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

    private func addToken(_ type: TokenType, literal: Substring? = nil) {
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
}
