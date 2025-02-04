import Foundation

nonisolated(unsafe) let interpreter = Interpreter() // sharing same instance across repl runs
main()

struct KrustError: LocalizedError {
    let line: Int
    let message: String
    var errorDescription: String? {
        "L\(line): \(message)"
    }
}

func main() {
    let arguments = CommandLine.arguments

    switch arguments.count {
    case 1:
        do {
            try runPrompt()
        } catch {
            print(error.localizedDescription)
        }
    case 2:
        do {
            let script = try readFile(arguments[1])
            try run(script)
        } catch {
            print(error.localizedDescription)
            if ErrorReporter.hadError {
                exit(65)
            }
            if ErrorReporter.hadRuntimeError {
                exit(70)
            }
        }
    default:
        print("Invalid arguments")
        exit(1)
    }
}

func runPrompt() throws {
    prompt: while true {
        print("> ", terminator: "")
        guard let line = readLine() else { break prompt }
        switch line {
        case ":exit", ":e", ":quit", ":q":
            break prompt
        default:
            try run(line)
        }
    }
}

func readFile(_ path: String) throws -> String {
    let url = URL(filePath: path)
    return try String(contentsOf: url, encoding: .utf8)
}

func run(_ source: String) throws {
    let scanner = Scanner(source: source)
    let tokens = scanner.scanTokens()
    let parser = Parser(tokens: tokens)
    guard let expr = parser.parse() else { return }

    // TODO: stop if there was a syntaxError (hadError == true)
    interpreter.interpret(expr)
}
