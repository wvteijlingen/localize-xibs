import Foundation

private extension String {
    var fileURL: URL { URL(fileURLWithPath: self) }
}

public enum Error: Swift.Error, LocalizedError {
    case fileNotLocalized(filePath: String)
    case invalidFileFormat(filePath: String)
    case unknownTranslation(String)

    public var errorDescription: String? {
        switch self {
        case .fileNotLocalized(let filePath):
            return "The file \(filePath) is not located in an *.lproj directory."
        case .invalidFileFormat(let filePath):
            return "The file \(filePath) could not be loaded."
        case .unknownTranslation(let key):
            return "Unknown translation for \"\(key)\""
        }
    }
}

/// A file that is localized by Xcode and sits inside an *.lproj directory.
protocol LocalizedFile {
    /// The path to the file.
    var filePath: String { get }

    /// The locale's language code of the file's contents, as derived from the .lproj directory name.
    var locale: String { get }

    /// The human readable language name of the file's contents, in English.
    /// Example: For a file with locale `nl`, this would be `Dutch`.
    var language: String { get }

    /// The name of the file without the file extension.
    var name: String { get }

    /// The name of the file including the file extension.
    var nameAndExtension: String { get }
}

extension LocalizedFile {
    var locale: String {
        filePath.fileURL.deletingLastPathComponent().deletingPathExtension().lastPathComponent
    }
    var language: String {
        Locale(identifier: "en").localizedString(forLanguageCode: locale) ?? locale
    }
    var name: String {
        filePath.fileURL.deletingPathExtension().lastPathComponent
    }
    var nameAndExtension: String {
        filePath.fileURL.lastPathComponent
    }
}

/// A XIB or Storyboard file.
struct InterfaceBuilderFile: LocalizedFile {
    let filePath: String
    let fileSystem: FileSystem

    init(filePath: String, fileSystem: FileSystem) throws {
        guard filePath.fileURL.deletingLastPathComponent().lastPathComponent.hasSuffix(".lproj") else {
            throw Error.fileNotLocalized(filePath: filePath)
        }
        self.filePath = filePath
        self.fileSystem = fileSystem
    }

    /// The .strings file for the given locale belonging to this file, or nil if no such file exists.
    ///
    /// Example: If the receiver represents the file `Root/Base.lproj/Main.xib`,
    /// and this method is called with `locale: nl`, this would return a `StringsFile`
    /// representing `Root/nl.lproj/Main.strings` if such a file exists.
    func stringsFile(forLocale locale: String) -> StringsFile? {
        let path = filePath
            .fileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("\(locale).lproj")
            .appendingPathComponent("\(name).strings")

        guard fileSystem.fileExists(atPath: path.path) else { return nil }

        return try? StringsFile(filePath: path.path, fileSystem: fileSystem)
    }
}

/// A .strings file.
struct StringsFile: LocalizedFile {
    let filePath: String
    let fileSystem: FileSystem

    init(filePath: String, fileSystem: FileSystem) throws {
        guard filePath.fileURL.deletingLastPathComponent().lastPathComponent.hasSuffix(".lproj") else {
            throw Error.fileNotLocalized(filePath: filePath)
        }
        self.filePath = filePath
        self.fileSystem = fileSystem
    }

    /// Returns all keys and values in this file.
    /// - Throws: Error.invalidFileFormat
    /// - Returns: All keys and values
    func keysAndValues() throws -> [String: String] {
        let data = try fileSystem.contents(ofFile: filePath)
        let plist = try PropertyListSerialization.propertyList(from: data.data(using: .utf8)!, format: nil)

        guard let dict = plist as? [String: String] else {
          throw Error.invalidFileFormat(filePath: filePath)
        }

        return dict
    }

    /// Updates the file by replacing the given values with their replacements.
    /// The entries in the output file will be sorted a-z on key.
    /// - note: The keys in the replacements dictionary are not the keys in the .strings file,
    ///         but the existing values in the .strings file.
    @discardableResult func update(withReplacements replacements: [String: String]) throws -> UpdateResult {
        var updateResult = UpdateResult()
        let entries = try keysAndValues()
        let replacedEntries = entries.mapValues { (key) -> String in
            guard key.hasPrefix("t:") else { return key }
            let key = String(key.dropFirst(2))
            if let replacement = replacements[key] {
                updateResult.registerReplacedKey(key, value: replacement)
                return replacement.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n")
            } else {
                updateResult.registerUnknownKey(key)
                return "__\(key)__"
            }
        }

        let output = replacedEntries.map { (key, value) in
            "\"\(key)\" = \"\(value)\";"
        }.sorted().joined(separator: "\n")

        try fileSystem.write(output, to: filePath)

        return updateResult
    }
}

struct UpdateResult {
    var unknownKeys: [String] = []
    var replacedKeys: [String: String] = [:]

    mutating func registerUnknownKey(_ key: String) {
        unknownKeys.append(key)
    }

    mutating func registerReplacedKey(_ key: String, value: String) {
        replacedKeys[key] = value
    }
}
