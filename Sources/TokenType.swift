enum TokenType {
    // single char
    case leftParen, rightParen, leftBrace, rightBrace, comma, dot, minus, plus, semicolon, slash, star

    // 1 or 2 char
    case bang, bangEqual, equal, equalEqual, greater, greaterEqual, less, lessEqual

    // literals
    case identifier, string, number

    // keywords
    case and, `class`, `else`, `false`, fn, `for`, `if`, `nil`, or, print, `return`, `super`, this, `true`, `var`, `while`

    // other
    case eof
}
