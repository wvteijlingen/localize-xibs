import Foundation

typealias ShellResult = (output: String?, status: Int32)

protocol Shell {
    @discardableResult
    static func run(_ command: String, printCommand: Bool) -> ShellResult
}

struct DefaultShell: Shell {
    @discardableResult
    static func run(_ command: String, printCommand: Bool = false) -> ShellResult {
        if printCommand {
            print(command)
        }

        let task = Process()

        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        task.waitUntilExit()
        return (output: output, status: task.terminationStatus)
    }
}
