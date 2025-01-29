import Foundation

do {
    try main()
} catch {
    print("Error: \(error.localizedDescription)")
    exit(1)
}

enum KrustError: Error {
    case invalidArguments
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
        throw KrustError.invalidArguments
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

func run(_ script: String) throws {}
