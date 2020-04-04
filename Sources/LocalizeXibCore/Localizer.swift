import Rainbow

public struct Localizer {
    let translationFiles: [String]
    let xibFiles: [String]
    private let fileSystem: FileSystem = DefaultFileSystem()

    public init(translationFiles: [String], xibFiles: [String]) {
        self.translationFiles = translationFiles
        self.xibFiles = xibFiles
    }

    @discardableResult
    public func localize(strict: Bool = false, verbose: Bool = false) -> Bool {
        var success = true

        let logIssue = { (message: String, strict: Bool) in
            let prefix: String
            if strict {
                success = false
                prefix = "error".red
            } else {
                prefix = "warning".yellow
            }
            print("\(prefix): \(message)")
        }

        let translationSources = translationFiles.compactMap { (filePath) -> StringsFile? in
            do {
                return try StringsFile(filePath: filePath, fileSystem: fileSystem)
            } catch {
                switch error {
                case Error.fileNotLocalized:
                    logIssue("\(filePath) is not located in an .lproj directory, skipping", strict)
                default:
                    print(error)
                }
            }
            return nil
        }

        let xibs = xibFiles.compactMap {
            try? InterfaceBuilderFile(filePath: $0, fileSystem: fileSystem)
        }

        for source in translationSources {
            print("Found \(source.language.blue) translations at \(source.filePath.blue)")

            for xib in xibs {
                guard let outputFile = xib.stringsFile(withLocale: source.locale) else { continue }

                if verbose {
                    print("Updating \(outputFile.filePath.green) with translations from \(source.filePath)")
                } else {
                    print("Updating \(xib.nameAndExtension.green)")
                }

                DefaultShell.run("ibtool \(xib.filePath) --generate-strings-file \(outputFile.filePath)", printCommand: verbose)

                let result = try! outputFile.update(withReplacements: source.keysAndValues())

                for key in result.unknownKeys {
                    logIssue("Unknown translation for \"\(key)\"", strict)
                }

                if verbose {
                    for (key, value) in result.replacedKeys {
                        print("Translated \"\(key)\" with \"\(value)\"")
                    }
                }
            }
        }

        return success
    }
}
