import Foundation

do {
    try main()
} catch {
    print("Error: \(error.localizedDescription)")
    exit(1)
}

enum KrustCLIError: Error {
    case invalidArguments
}

struct KrustError: LocalizedError {
    let line: Int
    let message: String
    var errorDescription: String? {
        "L\(line): \(message)"
    }
}

func main() throws {
    let arguments = CommandLine.arguments

    switch arguments.count {
    case 1:
        try runPrompt()
    case 2:
        let script = try readFile(arguments[1])
        try run(script)
    default:
        throw KrustCLIError.invalidArguments
    }
}

func runPrompt() throws {
    prompt: while true {
        print("> ", terminator: "")
        guard let line = readLine() else { break prompt }
        switch line {
        case ":exit\n", "e:", ":quit", ":q":
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

    for token in tokens {
        print(token)
    }
}
