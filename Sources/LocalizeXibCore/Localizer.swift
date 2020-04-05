import Foundation
import Rainbow

public struct Localizer {
    let translationFiles: [String]
    let interfaceBuilderFiles: [String]
    private let fileSystem: FileSystem = DefaultFileSystem()

    public init(translationFiles: [String], interfaceBuilderFiles: [String]) {
        self.translationFiles = translationFiles
        self.interfaceBuilderFiles = interfaceBuilderFiles
    }

    @discardableResult
    public func localize(strict: Bool = false, verbose: Bool = false) -> Bool {
        var success = true

        let logError = { (error: Swift.Error) in
            let prefix: String
            if strict {
                success = false
                prefix = "error".red
            } else {
                prefix = "warning".yellow
            }
            print("\(prefix): \(error.localizedDescription)")
        }

        let translationSources = translationFiles.compactMap { (filePath) -> StringsFile? in
            do {
                return try StringsFile(filePath: filePath, fileSystem: fileSystem)
            } catch {
                logError(error)
            }
            return nil
        }

        let xibs = interfaceBuilderFiles.compactMap {
            try? InterfaceBuilderFile(filePath: $0, fileSystem: fileSystem)
        }

        for source in translationSources {
            print("Found \(source.language.blue) translations at \(source.filePath.blue)")

            for xib in xibs {
                guard let outputFile = xib.stringsFile(forLocale: source.locale) else { continue }

                if verbose {
                    print("Updating \(outputFile.filePath.green) with translations from \(source.filePath)")
                } else {
                    print("Updating \(xib.nameAndExtension.green)")
                }

                DefaultShell.run("ibtool \(xib.filePath) --generate-strings-file \(outputFile.filePath)", printCommand: verbose)

                do {
                    let result = try outputFile.update(withReplacements: source.keysAndValues())

                    for key in result.unknownKeys {
                        logError(Error.unknownTranslation(key))
                    }

                    if verbose {
                        for (key, value) in result.replacedKeys {
                            print("Translated \"\(key)\" with \"\(value)\"")
                        }
                    }
                } catch {
                    logError(error)
                }
            }
        }

        return success
    }
}
