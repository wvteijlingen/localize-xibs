import ArgumentParser
import LocalizeXibCore
import PathKit

public enum Error: Swift.Error {
    case generic
    case noInputsSpecified
}

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
        let xibFiles = Path.glob(".{,**}/Base.lproj/*.{xib,storyboard}").map(\.string)

        guard !xibFiles.isEmpty else {
            print("No localizable XIBs or Storyboards were found.")
            return
        }

        let localizer = LocalizeXibCore.Localizer(translationFiles: inputFiles, xibFiles: xibFiles)
        let success = localizer.localize(strict: strict, verbose: verbose)

        if !success {
            Self.exit(withError: Error.generic)
        }
    }
}

Localize.main()
