import ArgumentParser
import PathKit
import Rainbow

var hasError = false

struct Localize: ParsableCommand {
    @Flag(help: "Treat warnings as errors.")
    var strict: Bool

    @Flag(help: "Display extra information while processing.")
    var verbose: Bool

    @Argument(help: "List of .strings files containing the translations.")
    var inputFiles: [String]

    func validate() throws {
        if inputFiles.isEmpty {
            throw Error.noInputsSpecified
        }
    }

    func run() throws {
        let translationSources = inputFiles.compactMap { (filePath) -> StringsFile? in
            do {
                return try StringsFile(filePath: filePath)
            } catch {
                switch error {
                case Error.inputFileNotLocalized:
                    logIssue("\(filePath) is not located in an .lproj directory, skipping", strict: strict)
                default:
                    print(error)
                }
            }
            return nil
        }

        for source in translationSources {
            print("Found \(source.language.blue) translations at \(source.filePath.path.blue)")

            let xibs = Path.glob("./**/Base.lproj/*.{xib,storyboard}").compactMap {
                try? InterfaceBuilderFile(filePath: $0.string)
            }

            for xib in xibs {
                guard let outputFile = xib.stringsFile(withLocale: source.locale) else { continue }

                if verbose {
                    print("Updating \(outputFile.filePath.path.green) with translations from \(source.filePath.path)")
                } else {
                    print("Updating \(xib.nameAndExtension.green)")
                }

                DefaultShell.run("ibtool \(xib.filePath.path) --generate-strings-file \(outputFile.filePath.path)", printCommand: verbose)

                let result = try! outputFile.update(withReplacements: source.keysAndValues())

                for key in result.unknownKeys {
                    logIssue("Unknown translation for \"\(key)\"", strict: strict)
                }

                if verbose {
                    for (key, value) in result.replacedKeys {
                        print("Translated \"\(key)\" with \"\(value)\"")
                    }
                }
            }
        }

        if hasError {
            Self.exit(withError: Error.generic)
        }
    }

    private func logIssue(_ message: String, strict: Bool) {
        let prefix: String
        if strict {
            hasError = true
            prefix = "error".red
        } else {
            prefix = "warning".yellow
        }
        print("\(prefix): \(message)")
    }
}

Localize.main()
