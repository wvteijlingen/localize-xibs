import Foundation
import ArgumentParser
import LocalizeXibCore
import PathKit

public enum Error: Swift.Error, LocalizedError {
    case generic
    case noInputFilesSpecified
    case noLocalizableFilesFound

    public var errorDescription: String? {
        switch self {
        case .noInputFilesSpecified:
            return "No input files specified. Run localize-xib -h for usage."
        case .noLocalizableFilesFound:
            return "No localizable XIBs or Storyboards were found. Make sure you use Base Internationalization and your XIBs and Storyboards are located in Base.lproj directories."
        case .generic:
            return "localize-xib failed with errors"
        }
    }
}

struct Localize: ParsableCommand {
    @Flag(help: "Treat warnings as errors.")
    var strict: Bool

    @Flag(help: "Display extra information while processing.")
    var verbose: Bool

    @Argument(help: "List of .strings files containing translations.")
    var inputFiles: [String]

    func validate() throws {
        if inputFiles.isEmpty {
            throw Error.noInputFilesSpecified
        }
    }

    func run() throws {
        let interfaceBuilderFiles = Path.glob(".{,**}/Base.lproj/*.{xib,storyboard}").map(\.string)

        guard !interfaceBuilderFiles.isEmpty else {
            throw Error.noLocalizableFilesFound
        }

        let localizer = Localizer(translationFiles: inputFiles, interfaceBuilderFiles: interfaceBuilderFiles)
        let success = localizer.localize(strict: strict, verbose: verbose)

        if !success {
            Self.exit(withError: Error.generic)
        }
    }
}

Localize.main()
