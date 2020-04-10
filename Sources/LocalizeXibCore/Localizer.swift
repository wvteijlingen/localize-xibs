import Foundation
import Rainbow

public struct Localizer {
    public typealias Logger = (_ message: String, _ level: LogLevel) -> Void
    public enum LogLevel {
        case verbose, info, warning, error
    }

    let translationFiles: Set<String>
    let interfaceBuilderFiles: Set<String>
    private let fileSystem: FileSystem = DefaultFileSystem()
    private let logger: Logger?

    public init(translationFiles: Set<String>, interfaceBuilderFiles: Set<String>, logger: Logger?) {
        self.translationFiles = translationFiles
        self.interfaceBuilderFiles = interfaceBuilderFiles
        self.logger = logger
    }

    @discardableResult
    public func localize(strict: Bool = false, verbose: Bool = false) -> Bool {
        var success = true

        let handleError = { (error: Swift.Error) in
            if strict {
                success = false
                self.logger?(error.localizedDescription, .error)
            } else {
                self.logger?(error.localizedDescription, .warning)
            }
        }

        let translationSources = translationFiles.compactMap { (filePath) -> StringsFile? in
            do {
                return try StringsFile(filePath: filePath, fileSystem: fileSystem)
            } catch {
                handleError(error)
                return nil
            }
        }

        let xibs = interfaceBuilderFiles.compactMap {
            try? InterfaceBuilderFile(filePath: $0, fileSystem: fileSystem)
        }

        for source in translationSources {
            logger?("Found \(source.language.blue) translations at \(source.filePath.blue)", .info)

            for xib in xibs {
                guard let outputFile = xib.stringsFile(forLocale: source.locale) else { continue }

                if verbose {
                    logger?("Updating \(outputFile.filePath.green) with translations from \(source.filePath)", .verbose)
                } else {
                    logger?("Updating \(xib.nameAndExtension.green)", .info)
                }

                DefaultShell.run("ibtool \(xib.filePath) --generate-strings-file \(outputFile.filePath)", printCommand: verbose)

                do {
                    let result = try outputFile.update(withReplacements: source.keysAndValues())

                    for key in result.unknownKeys {
                        handleError(Error.unknownTranslation(key))
                    }

                    if verbose {
                        for (key, value) in result.replacedKeys {
                            logger?("Translated \"\(key)\" with \"\(value)\"", .verbose)
                        }
                    }
                } catch {
                    handleError(error)
                }
            }
        }

        return success
    }
}
