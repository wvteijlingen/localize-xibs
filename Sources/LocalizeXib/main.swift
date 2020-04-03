import ArgumentParser
import PathKit
import Rainbow

struct Localize: ParsableCommand {
    @Flag(help: "Treat warnings as errors.")
    var strict: Bool

    @Flag(help: "Display extra information while processing.")
    var verbose: Bool

    @Argument(help: "List of .strings files containing the translations.")
    var inputFiles: [String]

    func run() throws {
        let translationSources = inputFiles.compactMap { (filePath) -> TranslationSource? in
            do {
                return try TranslationSource(filePath: filePath)
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
            print("Found translations for locale \(source.locale.green) at \(source.filePath.path.green)")

//            if verbose {
//                print(source.description)
//            }

            let xibs = Path.glob("./**/Base.lproj/*.{xib,storyboard}").map { OutputXib(filePath: $0.url) }

            for xib in xibs {
                guard let outputFile = xib.stringsFile(withLocale: source.locale) else { continue }

                if verbose {
                    print("Updating \(outputFile.filePath.path.green) with translations from \(source.filePath.path)")
                } else {
                    print("Updating \(xib.nameAndExtension.green)")
                }

                DefaultShell.run("ibtool \(xib.filePath.path) --generate-strings-file \(outputFile.filePath.path)", printCommand: verbose)

                let result = try! outputFile.update(withTranslations: source.translations)

                for key in result.unknownKeys {
                    self.logIssue("Unknown translation for \"\(key)\"", strict: self.strict)
                }

                if verbose {
                    for (key, value) in result.replacedKeys {
                        print("Translated \"\(key)\" with \"\(value)\"")
                    }
                }
            }
        }
    }

    private func logIssue(_ message: String, strict: Bool) {
        if strict {
            print("error: \(message)")
        } else {
            print("warning: \(message)")
        }
    }
}

Localize.main()
