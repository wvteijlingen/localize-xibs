import Foundation
import ArgumentParser
import LocalizeXibCore

struct StandardError: TextOutputStream {
  mutating func write(_ string: String) {
    for byte in string.utf8 { putc(numericCast(byte), stderr) }
  }
}

var standardError = StandardError()

struct Localize: ParsableCommand {
    @Flag(help: "Treat warnings as errors.")
    var strict: Bool

    @Flag(help: "Display extra information while processing.")
    var verbose: Bool

    @Argument(help: "List of .strings files containing translations.")
    var inputFiles: [String]

    func validate() throws {
        if inputFiles.isEmpty {
            throw ValidationError("No input files specified.")
        }
    }

    func run() throws {
        let glob = Glob(pattern: "./**/Base.lproj/*.{xib,storyboard}")
        let interfaceBuilderFiles = Set(glob.paths)

        guard !interfaceBuilderFiles.isEmpty else {
            log("No localizable XIBs or Storyboards were found. Make sure you use Base Internationalization and your XIBs and Storyboards are located in Base.lproj directories.", level: .warning)
            return
        }

        let localizer = Localizer(translationFiles: Set(inputFiles), interfaceBuilderFiles: interfaceBuilderFiles, logger: log)
        let success = localizer.localize(strict: strict, verbose: verbose)

        if success == false && strict {
            throw ExitCode.failure
        }
    }

    private func log(_ message: String, level: Localizer.LogLevel) {
        // We use lowercase "warning" and "error" here so it will be picked up by the Xcode Issue Navigator.

        switch level {
        case .verbose, .info:
            print(message)
        case .warning:
            print("warning: \(message)")
        case .error:
            print("error: \(message)", to: &standardError)
        }
    }
}

Localize.main()
